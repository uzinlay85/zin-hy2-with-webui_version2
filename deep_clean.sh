#!/bin/bash
# ========================================================
# 🧹 Ubuntu Linux VPS Deep Clean & Factory Reset Script
# ========================================================

echo "========================================================"
echo "🧹 Starting VPS Deep Clean & Wiping Process..."
echo "========================================================"

if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။ (sudo su ဝင်ရောက်ပြီးမှ ပြန်လည် run ပါ)"
    exit 1
fi

echo -e "\n[1/6] Wiping Background Cron jobs..."
crontab -r 2>/dev/null
rm -rf /etc/cron.* /var/spool/cron/crontabs/*

echo -e "\n[2/6] Purging Docker & Containers..."
docker stop $(docker ps -aq) 2>/dev/null
docker rm $(docker ps -aq) 2>/dev/null
docker system prune -af --volumes 2>/dev/null
apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
rm -rf /var/lib/docker /etc/docker /opt/outline

echo -e "\n[3/6] Purging Proxy & VPN Services/Folders..."
systemctl stop hysteria-server hy2-panel x-ui xray v2ray nginx caddy 2>/dev/null
systemctl disable hysteria-server hy2-panel x-ui xray v2ray nginx caddy 2>/dev/null
rm -rf /etc/hysteria /opt/hy2-panel /etc/x-ui /usr/local/x-ui /etc/xray /etc/v2ray /usr/local/etc/xray /var/log/xray /var/log/v2ray /etc/nginx /etc/caddy /etc/letsencrypt

echo -e "\n[4/6] Cleaning Binary Executables..."
rm -f /usr/local/bin/hysteria /usr/local/bin/xray /usr/local/bin/v2ray /usr/local/bin/hy2 /usr/local/bin/sing-box

echo -e "\n[5/6] Resetting Firewall & iptables NAT Rules..."
ufw --force reset 2>/dev/null
ufw disable 2>/dev/null
iptables -F && iptables -X && iptables -t nat -F && iptables -t nat -X

echo -e "\n[6/6] Autoremoving & Cleaning Packages..."
apt-get autoremove --purge -y && apt-get clean

echo "========================================================"
echo "✅ VPS Deep Clean Completed Successfully!"
echo "========================================================"
