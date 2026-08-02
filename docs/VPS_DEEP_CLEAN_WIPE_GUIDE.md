# Ubuntu Linux VPS Deep Clean & Factory Reset Guide (Ultimate Wiping Guide)

> **ဆန်းစစ်ချက် အကျဉ်းချုပ်:** Ubuntu Linux VPS တစ်ခုတွင် VPN, Proxy (Outline, VLESS, X-UI, Hysteria 2, WireGuard, Docker, Nginx, Caddy) အစရှိသော စမ်းသပ်ထားသမျှ အမှိုက်ဖိုင်များနှင့် Background Services များကို အစအန မကျန်စေဘဲ ၁၀၀% အမြစ်ပြတ် ဖျက်ဆီး ရှင်းလင်းသည့် နည်းလမ်း အပြည့်အစုံ ဖြစ်ပါသည်။

---

## 🌟 နည်းလမ်း (၁) - VPS Provider Dashboard မှ OS Reinstall ပြုလုပ်ခြင်း (အပြည့်စုံဆုံး နည်းလမ်း)

> **အကြံပြုချက်:** အမှိုက်ဖိုင်များနှင့် ဘက်ဂျက်ကျန် ခဲနေသော Configurations များကို အစမက ၁၀၀% အကင်းစင်ဆုံး ဖြစ်စေရန် VPS Provider Dashboard ရှိ **Reinstall OS / Rebuild** ခလုတ်ကို နှိပ်၍ Ubuntu 24.04 LTS အဖြစ် ပြန်လည် Reinstall ပြုလုပ်ခြင်းသည် အကောင်းဆုံး ဖြစ်ပါသည်။

---

## 🛠️ နည်းလမ်း (၂) - SSH Terminal ထဲမှ ၁၀၀% အမြစ်ပြတ် ဖျက်ချခြင်း (Ultimate Wiping Script)

အကယ်၍ VPS Dashboard သို့ ဝင်ရောက်ခွင့် မရှိဘဲ Terminal (SSH) ထဲမှသာ ရှိသမျှ စမ်းသပ်ထားသော တန်ဆာဆင်မှုများကို အပြီးသတ် ဖျက်ဆီးလိုပါက အောက်ပါ **Full Deep Clean Command** များကို Copy ကူး၍ Run နိုင်ပါသည်:

```bash
# 1. Background Cron jobs များကို အကုန်ဖျက်ပါ
sudo crontab -r 2>/dev/null
sudo rm -rf /etc/cron.* /var/spool/cron/crontabs/*

# 2. Docker & Containers အားလုံးကို အမြစ်ပြတ် ဖျက်ပါ
sudo docker stop $(sudo docker ps -aq) 2>/dev/null
sudo docker rm $(sudo docker ps -aq) 2>/dev/null
sudo docker system prune -af --volumes 2>/dev/null
sudo apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
sudo rm -rf /var/lib/docker /etc/docker /opt/outline

# 3. Proxy & VPN Services/Folders အားလုံးကို ဖျက်ပါ
sudo systemctl stop hysteria-server hy2-panel x-ui xray v2ray nginx caddy 2>/dev/null
sudo systemctl disable hysteria-server hy2-panel x-ui xray v2ray nginx caddy 2>/dev/null
sudo rm -rf /etc/hysteria /opt/hy2-panel /etc/x-ui /usr/local/x-ui /etc/xray /etc/v2ray /usr/local/etc/xray /var/log/xray /var/log/v2ray /etc/nginx /etc/caddy /etc/letsencrypt

# 4. Binaries ဖိုင်များကို ရှင်းထုတ်ပါ
sudo rm -f /usr/local/bin/hysteria /usr/local/bin/xray /usr/local/bin/v2ray /usr/local/bin/hy2 /usr/local/bin/sing-box

# 5. Network & Firewall Reset ရိုက်ပါ
sudo ufw --force reset
sudo ufw disable
sudo iptables -F && sudo iptables -X && sudo iptables -t nat -F && sudo iptables -t nat -X

# 6. System Clean
sudo apt-get autoremove --purge -y && sudo apt-get clean
```

---

## 🎯 နိဂုံးချုပ်

စမ်းသပ်ထားသမျှ အမှိုက်များ အကင်းစင်ဆုံး ဖြစ်စေရန် **VPS Provider Dashboard မှ Reinstall / Rebuild ပြုလုပ်ခြင်းသည် အကောင်းဆုံး နည်းလမ်း ဖြစ်ပါသည် ခင်ဗျာ!** 🚀
