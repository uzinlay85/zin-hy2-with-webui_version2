#!/bin/bash

echo "========================================================"
echo "🗑️  Hysteria 2 & Web Panel Uninstaller"
echo "========================================================"

if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။ (sudo su ဝင်ရောက်ပြီးမှ ပြန်လည် run ပါ)"
    exit 1
fi

echo -e "\n[1/4] Stopping Services..."
systemctl stop hy2-panel.service 2>/dev/null
systemctl disable hy2-panel.service 2>/dev/null
rm -f /etc/systemd/system/hy2-panel.service

systemctl stop hysteria-server.service 2>/dev/null
systemctl disable hysteria-server.service 2>/dev/null
rm -f /etc/systemd/system/hysteria-server.service

systemctl daemon-reload

echo -e "\n[2/4] Removing Hysteria 2 Core and Configs..."
rm -rf /etc/hysteria
rm -f /usr/local/bin/hysteria

echo -e "\n[3/4] Removing Web Panel Files..."
rm -rf /opt/hy2-panel

echo -e "\n[4/4] Removing Nginx Configurations..."
rm -f /etc/nginx/sites-enabled/hy2-panel
rm -f /etc/nginx/sites-available/hy2-panel
systemctl restart nginx 2>/dev/null

echo -e "\n✅ Uninstall ပြီးစီးပါပြီ။ အားလုံးပြောင်စင်သွားပါပြီ!"
echo "သင် အသစ်ပြန်လည် တပ်ဆင်လိုပါက install.sh အသစ်ဖြင့် ပြန်လည် Run နိုင်ပါပြီ။"
