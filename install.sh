#!/bin/bash

echo "========================================================"
echo "🚀 Hysteria 2 & Web Panel One-Click Installer"
echo "========================================================"

if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။ (sudo su ဝင်ရောက်ပြီးမှ ပြန်လည် run ပါ)"
    exit 1
fi

# Go to root directory to prevent getcwd errors if the script is run from a deleted directory
cd /root || exit

# 1. Ask for Domain
read -p "Enter your Domain Name (e.g., vpn.yourdomain.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "Error: Domain name is required."
    exit 1
fi

read -p "Enter Admin Password for Web Panel (leave blank for random): " ADMIN_PASS
if [ -z "$ADMIN_PASS" ]; then
    ADMIN_PASS=$(head -c 12 /dev/urandom | base64)
fi


echo -e "\n[1/7] Installing System Dependencies..."
apt-get update
apt-get install -y curl wget nginx certbot python3 python3-venv python3-pip sqlite3 ufw git

echo -e "\n[2/7] Optimizing Network (BBR & Sysctl) & Firewall..."
# Enable BBR and optimize network for VPN
if ! grep -q "net.core.default_qdisc=fq" /etc/sysctl.conf; then
    cat << EOF_SYSCTL >> /etc/sysctl.conf
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
net.ipv4.tcp_fastopen=3
# High-performance UDP buffers for QUIC/Hysteria2 (64MB)
net.core.rmem_max=67108864
net.core.wmem_max=67108864
net.core.rmem_default=4194304
net.core.wmem_default=4194304
net.ipv4.udp_mem=8388608 16777216 33554432
EOF_SYSCTL
    sysctl -p
fi

# Setup UFW Firewall Ports
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw allow 20000:50000/udp

# Block SMTP ports to prevent spam abuse
ufw deny out 25/tcp
ufw deny out 465/tcp
ufw deny out 587/tcp

echo -e "\n[3/7] Configuring UDP Port Hopping (UFW NAT)..."
# Add NAT rules to UFW before.rules for port hopping (with conntrack to prevent drops)
if ! grep -q "20000:50000.*REDIRECT" /etc/ufw/before.rules; then
    sed -i '/^\*filter/i *nat\n:PREROUTING ACCEPT [0:0]\n-A PREROUTING -p udp --dport 20000:50000 -m conntrack ! --ctstate ESTABLISHED,RELATED -j REDIRECT --to-port 443\nCOMMIT\n' /etc/ufw/before.rules
fi
# Clean up duplicate rules in active memory before reloading
while iptables -t nat -D PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-port 443 2>/dev/null; do :; done
while iptables -t nat -D PREROUTING -p udp --dport 20000:50000 -m conntrack ! --ctstate ESTABLISHED,RELATED -j REDIRECT --to-port 443 2>/dev/null; do :; done
ufw --force enable
ufw reload

echo -e "\n[4/7] Installing Hysteria 2 Core..."
# Download directly from GitHub to bypass app.hysteria.network DNS issues
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    HY2_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    HY2_ARCH="arm64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi
wget -qO /usr/local/bin/hysteria https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-${HY2_ARCH}
chmod +x /usr/local/bin/hysteria

# Set up systemd service
cat << EOF_HY2_SERVICE > /etc/systemd/system/hysteria-server.service
[Unit]
Description=Hysteria 2 Server
# Wait for full network stack (DNS resolution + IP) before starting
# This prevents TLS cert path failures on reboot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/hysteria
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
Restart=always
# Delay restart to prevent crash loops on config errors
RestartSec=5s
# Limit rapid restart attempts
StartLimitIntervalSec=60s
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF_HY2_SERVICE

echo -e "\n[5/7] Generating SSL Certificate (Let's Encrypt)..."
systemctl stop nginx
certbot certonly --standalone -d $DOMAIN --agree-tos --register-unsafely-without-email --non-interactive \
    --pre-hook "systemctl stop nginx" \
    --post-hook "systemctl start nginx" \
    --deploy-hook "systemctl restart hysteria-server.service"

if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "Error: Failed to get SSL certificate. Check if your domain is correctly pointed to this VPS IP."
    systemctl start nginx
    exit 1
fi
systemctl start nginx

echo -e "\n[6/7] Configuring Hysteria 2 & Web Panel..."
mkdir -p /etc/hysteria
echo "$DOMAIN" > /etc/hysteria/domain.txt

cat << EOF_HY2 > /etc/hysteria/config.yaml
listen: :443

tls:
  cert: /etc/letsencrypt/live/$DOMAIN/fullchain.pem
  key: /etc/letsencrypt/live/$DOMAIN/privkey.pem

auth:
  type: http
  http:
    url: http://127.0.0.1:3000/auth

masquerade:
  type: proxy
  proxy:
    url: https://www.cloudflare.com/
    rewriteHost: true

trafficStats:
  listen: 127.0.0.1:8080

# Cellular NAT & App Stability Optimizations (Ultra-Persistent Connection - Max allowed 120s)
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
EOF_HY2

# (Web Panel installation proceeds...)
cd /opt
if [ -d "hy2-panel" ]; then
    rm -rf hy2-panel
fi
git clone https://github.com/uzinlay85/zin-hy2-with-webui_version2.git /opt/hy2-panel
cd /opt/hy2-panel

# Inject generated passwords into Panel code
sed -i "s/ADMIN_PASSWORD_PLACEHOLDER/$ADMIN_PASS/g" /opt/hy2-panel/main.py
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Setup Systemd Service for Web Panel
cat << EOF_SERVICE > /etc/systemd/system/hy2-panel.service
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
EOF_SERVICE

# Stop legacy hy2-api service if present and free port 3000
systemctl stop hy2-api.service 2>/dev/null || true
systemctl disable hy2-api.service 2>/dev/null || true
fuser -k 3000/tcp 2>/dev/null || true

echo -e "\n[7/7] Configuring Nginx Reverse Proxy (/hy2-api/)..."
cat << EOF_NGINX > /etc/nginx/sites-available/hy2-panel
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
    # Cache SSL sessions to avoid repeated handshakes (10MB ≈ 40,000 sessions)
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
        # WebSocket support (for future real-time features)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }
    
    # Redirect root to /hy2-api/ for convenience, or leave it for other panels (e.g. 3x-ui)
    location = / {
        return 302 /hy2-api/;
    }
}
EOF_NGINX

ln -sf /etc/nginx/sites-available/hy2-panel /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# Start Services
systemctl enable hysteria-server.service
systemctl restart hysteria-server.service
systemctl enable hy2-panel.service
systemctl restart hy2-panel.service

echo "========================================================"
echo "✅ Installation Completed Successfully!"
echo "========================================================"
echo "Web Panel URL: https://$DOMAIN/hy2-api/"
echo "Admin Login  : admin"
echo "Password     : $ADMIN_PASS"
echo "========================================================"
echo "မှတ်ချက်။ ။ ပထမဆုံး Login ဝင်ပြီးပါက Admin Settings တွင် Password အသစ် ပြောင်းလဲပါ။"
