#!/bin/bash
# ============================================================
# Hysteria 2 Panel - One-Time Stability & Security Fix Script
# ============================================================
# Usage (on your VPS):
# bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/server_fix.sh)
# ============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။"
    exit 1
fi

cd /root || exit

echo "========================================================"
echo "🔧 Hysteria 2 Panel - Stability & Security Fix"
echo "========================================================"

# ----------------------------------------------------------------
# [FIX 1] Sysctl - UDP Buffer 64MB (QUIC Performance)
# ----------------------------------------------------------------
echo -e "\n[1/5] Optimizing UDP Buffer Size for QUIC (8MB → 64MB)..."

sed -i '/net.core.rmem_max=/d' /etc/sysctl.conf
sed -i '/net.core.wmem_max=/d' /etc/sysctl.conf
sed -i '/net.core.rmem_default=/d' /etc/sysctl.conf
sed -i '/net.core.wmem_default=/d' /etc/sysctl.conf
sed -i '/net.ipv4.udp_mem=/d' /etc/sysctl.conf

cat >> /etc/sysctl.conf << 'EOF_SYSCTL'
# High-performance UDP buffers for QUIC/Hysteria2 (64MB)
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=4194304
net.core.wmem_default=4194304
net.ipv4.udp_mem=8388608 16777216 33554432
EOF_SYSCTL

sysctl -p > /dev/null 2>&1
RMEM=$(sysctl -n net.core.rmem_max)
echo "  ✅ UDP rmem_max = ${RMEM} bytes ($(( RMEM / 1024 / 1024 ))MB)"

# ----------------------------------------------------------------
# [FIX 2 & 3] Systemd - hysteria-server & hy2-panel services
# ----------------------------------------------------------------
echo -e "\n[2/5] Rewriting hysteria-server.service (network-online.target + RestartSec)..."

HYSTERIA_CONFIG=""
if [ -f /etc/hysteria/config.yaml ]; then
    HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
fi

cat > /etc/systemd/system/hysteria-server.service << EOF_SVC1
[Unit]
Description=Hysteria 2 Server
After=network-online.target
Wants=network-online.target
StartLimitIntervalSec=60s
StartLimitBurst=5

[Service]
Type=simple
User=root
WorkingDirectory=/etc/hysteria
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF_SVC1
echo "  ✅ hysteria-server.service updated"

echo -e "\n[3/5] Rewriting hy2-panel.service (network-online.target + RestartSec)..."

cat > /etc/systemd/system/hy2-panel.service << EOF_SVC2
[Unit]
Description=Hysteria 2 Web Panel (FastAPI)
After=network-online.target hysteria-server.service
Wants=network-online.target
StartLimitIntervalSec=60s
StartLimitBurst=5

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hy2-panel
ExecStart=/opt/hy2-panel/venv/bin/uvicorn main:app --host 127.0.0.1 --port 3000
Restart=always
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF_SVC2

# Stop legacy hy2-api service if present and free port 3000
systemctl stop hy2-api.service 2>/dev/null || true
systemctl disable hy2-api.service 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true

echo "  ✅ hy2-panel.service updated"

systemctl daemon-reload

# ----------------------------------------------------------------
# [FIX 4] Nginx - SSL Session Cache + Security Headers
# ----------------------------------------------------------------
echo -e "\n[4/5] Updating Nginx SSL config..."

# Read domain from hysteria config
DOMAIN=""
if [ -f /etc/hysteria/domain.txt ]; then
    DOMAIN=$(cat /etc/hysteria/domain.txt)
fi

if [ -z "$DOMAIN" ] && [ -f /etc/hysteria/config.yaml ]; then
    DOMAIN=$(grep -oP '(?<=live/)([^/]+)' /etc/hysteria/config.yaml | head -1)
fi

if [ -n "$DOMAIN" ] && [ -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    cat > /etc/nginx/sites-available/hy2-panel << NGINX_EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    # SSL Performance & Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header Referrer-Policy no-referrer;

    location /hy2-api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }

    location = / {
        return 302 /hy2-api/;
    }
}
NGINX_EOF

    nginx -t > /dev/null 2>&1 && systemctl reload nginx && echo "  ✅ Nginx config updated for domain: $DOMAIN"
else
    echo "  ⚠️  Domain/cert ရှာမတွေ့ပါ - Nginx ကို manual ပြင်ပါ"
fi

# ----------------------------------------------------------------
# [FIX 5] Panel Code Update (GitHub မှ Pull)
# ----------------------------------------------------------------
echo -e "\n[5/6] Updating Web Panel code from GitHub..."

PANEL_DIR="/opt/hy2-panel"
if [ -d "$PANEL_DIR/.git" ]; then
    cd "$PANEL_DIR"
    git fetch origin main 2>/dev/null && git reset --hard origin/main 2>/dev/null
    echo "  ✅ Panel code updated from GitHub"
else
    echo "  ⚠️  Git repo မတွေ့ပါ - Manual update လုပ်ပါ"
fi
cd /root

# ----------------------------------------------------------------
# [FIX 6] Hysteria 2 Config - QUIC Keep-Alive & DNS Resolver
# ----------------------------------------------------------------
echo -e "\n[6/6] Optimizing Hysteria 2 config (QUIC Keep-Alive + Cloudflare DNS)..."

if [ -f /etc/hysteria/config.yaml ]; then
    # Update masquerade to Cloudflare if still using bing.com
    sed -i 's|url: https://bing.com/|url: https://www.cloudflare.com/|g' /etc/hysteria/config.yaml
    # Upgrade QUIC timeouts for persistent connection (max 120s allowed by Hysteria 2)
    sed -i 's|300s|120s|g' /etc/hysteria/config.yaml
    sed -i -E 's|[M|m]ax[I|i]dle[T|t]imeout:.*|maxIdleTimeout: 120s|g' /etc/hysteria/config.yaml
    sed -i -E 's|[K|k]eep[A|a]live[P|p]eriod:.*|keepAlivePeriod: 5s|g' /etc/hysteria/config.yaml

    if ! grep -q "keepAlivePeriod:" /etc/hysteria/config.yaml; then
        cat >> /etc/hysteria/config.yaml << 'EOF_HY2_OPT'

# Cellular NAT & App Stability Optimizations (Ultra-Persistent Connection)
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 120s
  keepAlivePeriod: 5s

resolver:
  type: udp
  udp:
    addr: 1.1.1.1:53
    timeout: 4s

bandwidth:
  up: 1 gbps
  down: 1 gbps
EOF_HY2_OPT
        echo "  ✅ QUIC Keep-Alive (10s) and Cloudflare DNS added to /etc/hysteria/config.yaml"
    else
        echo "  ✅ config.yaml already contains QUIC optimizations"
    fi
fi

# ----------------------------------------------------------------
# Restart Services
# ----------------------------------------------------------------
echo -e "\n🔄 Restarting all services..."
systemctl restart hysteria-server.service
systemctl restart hy2-panel.service
sleep 3

# ----------------------------------------------------------------
# Verification
# ----------------------------------------------------------------
echo ""
echo "========================================================"
echo "✅ Fix Completed! Verification:"
echo "========================================================"

echo ""
echo "--- Service Status ---"
systemctl is-active --quiet hysteria-server.service && echo "✅ hysteria-server : RUNNING" || echo "❌ hysteria-server : FAILED"
systemctl is-active --quiet hy2-panel.service      && echo "✅ hy2-panel       : RUNNING" || echo "❌ hy2-panel       : FAILED"

echo ""
echo "--- UDP Buffer Size ---"
echo "  rmem_max = $(sysctl -n net.core.rmem_max) ($(( $(sysctl -n net.core.rmem_max) / 1024 / 1024 ))MB)"
echo "  wmem_max = $(sysctl -n net.core.wmem_max) ($(( $(sysctl -n net.core.wmem_max) / 1024 / 1024 ))MB)"

echo ""
echo "--- iptables Port Hopping ---"
iptables -t nat -L PREROUTING -n -v 2>/dev/null | grep -E "20000|50000|443" || echo "⚠️  Port Hopping rule မတွေ့ပါ"

echo ""
echo "========================================================"
echo "🎉 Done! Monitor: journalctl -u hysteria-server.service -f"
echo "========================================================"
