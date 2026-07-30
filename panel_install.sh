#!/bin/bash

echo "========================================================"
echo "🚀 Hysteria 2 Lightweight Web Panel Installer"
echo "========================================================"

if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။ (sudo su ဝင်ရောက်ပြီးမှ ပြန်လည် run ပါ)"
    exit 1
fi

echo -e "\n[1/4] Installing Dependencies..."
apt-get update
apt-get install -y python3 python3-venv python3-pip

echo -e "\n[2/4] Setting up Python Environment..."
cd /opt
if [ -d "hy2-panel" ]; then
    echo "Updating existing panel..."
    cd hy2-panel
else
    echo "Downloading panel..."
    # Normally we would git clone, but since we are copying files manually, we assume they are here
    # If the user downloaded the zip, they should run this script from inside the extracted folder.
    cd "$(dirname "$0")"
    cp -r . /opt/hy2-panel
    cd /opt/hy2-panel
fi

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

echo -e "\n[3/4] Configuring Hysteria 2 for HTTP Auth and Traffic API..."
DOMAIN=$(cat /etc/hysteria/domain.txt 2>/dev/null)
if [ -z "$DOMAIN" ]; then
    echo "Error: Hysteria domain not found in /etc/hysteria/domain.txt. Install Hysteria first."
    exit 1
fi

cat << EOF_HY2 > /etc/hysteria/config.yaml
listen: :443

tls:
  cert: /etc/letsencrypt/live/$DOMAIN/fullchain.pem
  key: /etc/letsencrypt/live/$DOMAIN/privkey.pem

auth:
  type: http
  http:
    url: http://127.0.0.1:3000/auth

trafficStats:
  listen: 127.0.0.1:8080
EOF_HY2
chown hysteria:hysteria /etc/hysteria/config.yaml

echo -e "\n[4/4] Setting up Panel Systemd Service..."
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

systemctl daemon-reload

# If old api is running, stop it
systemctl stop hy2-api.service 2>/dev/null
systemctl disable hy2-api.service 2>/dev/null

systemctl enable --now hysteria-server.service
systemctl restart hysteria-server.service

systemctl enable --now hy2-panel.service
systemctl restart hy2-panel.service
systemctl restart nginx

echo -e "\n========================================================"
echo -e "🎉 Panel တပ်ဆင်ခြင်း အောင်မြင်စွာ ပြီးစီးပါပြီ!"
echo -e "========================================================"
echo -e "Web Panel URL: https://$DOMAIN/hy2-api/"
echo -e "Admin Login: No login required on this simple setup yet (Accessible via /hy2-api/)"
echo -e "(To secure it, you should add HTTP Basic Auth in Nginx later)"
echo -e "========================================================\n"
