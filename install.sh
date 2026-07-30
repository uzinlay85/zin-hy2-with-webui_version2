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

echo -e "\n[1/6] Installing System Dependencies..."
apt-get update
apt-get install -y curl wget nginx certbot python3 python3-venv python3-pip sqlite3

echo -e "\n[2/6] Installing Hysteria 2 Core..."
bash <(curl -fsSL https://raw.githubusercontent.com/apernet/hysteria/main/install-server.sh)

echo -e "\n[3/6] Generating SSL Certificate (Let's Encrypt)..."
systemctl stop nginx
certbot certonly --standalone -d $DOMAIN --agree-tos --register-unsafely-without-email --non-interactive
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "Error: Failed to get SSL certificate. Check if your domain is correctly pointed to this VPS IP."
    systemctl start nginx
    exit 1
fi
systemctl start nginx

echo -e "\n[4/6] Configuring Hysteria 2..."
mkdir -p /etc/hysteria
echo "$DOMAIN" > /etc/hysteria/domain.txt

cat << EOF_HY2 > /etc/hysteria/config.yaml
listen: :443

tls:
  cert: /etc/letsencrypt/live/$DOMAIN/fullchain.pem
  key: /etc/letsencrypt/live/$DOMAIN/privkey.pem

obfs:
  type: salamander
  salamander:
    password: "zin-super-obfs"

auth:
  type: http
  http:
    url: http://127.0.0.1:3000/auth

trafficStats:
  listen: 127.0.0.1:8080
EOF_HY2
chown hysteria:hysteria /etc/hysteria/config.yaml

echo -e "\n[5/6] Installing Web Panel..."
cd /opt
if [ -d "hy2-panel" ]; then
    rm -rf hy2-panel
fi
git clone https://github.com/uzinlay85/zin-hy2-with-webui_version2.git /opt/hy2-panel
cd /opt/hy2-panel
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Setup Systemd Service for Web Panel
cat << EOF_SERVICE > /etc/systemd/system/hy2-panel.service
[Unit]
Description=Hysteria 2 Web Panel (FastAPI)
After=network.target hysteria-server.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/hy2-panel
ExecStart=/opt/hy2-panel/venv/bin/uvicorn main:app --host 127.0.0.1 --port 3000
Restart=always

[Install]
WantedBy=multi-user.target
EOF_SERVICE

echo -e "\n[6/6] Configuring Nginx Reverse Proxy..."
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

    # Basic SSL configs
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
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
echo "Web Panel URL: https://$DOMAIN"
echo "Admin Login  : admin"
echo "Password     : admin123"
echo "========================================================"
echo "မှတ်ချက်။ ။ ပထမဆုံး Login ဝင်ပြီးပါက Admin Settings တွင် Password အသစ် ပြောင်းလဲပါ။"
