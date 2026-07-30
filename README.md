# ၅ မိနစ်အတွင်း အမြန်တပ်ဆင်နိုင်သော API Setup (Foolproof Steps)

ကွန်ပျူတာနှင့် VPS ချိတ်ဆက်ရာတွင် စာလုံးကျန်ခဲ့ခြင်းနှင့် SSL configuration လွဲမှားခြင်းများ လုံးဝမဖြစ်ပေါ်စေရန် အောက်ပါ အဆင်သင့်ပြင်ဆင်ပေးထားသော အဆင့် ၅ ဆင့်အတိုင်း VPS terminal တွင် အစဉ်လိုက် Run ပေးသွားရုံပါပဲခင်ဗျာ -

---

## 🚀 အမြန်ဆုံး တပ်ဆင်နည်း (One-Click Automation Script - Recommended)

အောက်ပါ အဆင့် ၅ ဆင့်လုံးကို တစ်ကြောင်းချင်းစီ ကူးထည့်နေစရာမလိုဘဲ လုံခြုံရေးအတွက် `hysteria` (Non-Root User) ဖြင့် အလိုအလျောက် သီးသန့် run ပေးမည့် One-Click Script ဖြစ်ပါတယ်။ VPS Terminal တွင် အောက်ပါ command ကို ကူးယူပြီး run လိုက်ရုံပါပဲ -

```bash
cat << 'EOF' > /root/install.sh && chmod +x /root/install.sh && /root/install.sh
#!/bin/bash

echo "========================================================"
echo "🚀 Hysteria2 + API + Nginx Complete Auto-Setup"
echo "========================================================"

if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။ (sudo su ဝင်ရောက်ပြီးမှ ပြန်လည် run ပါ)"
    exit 1
fi

DOMAIN=$(cat /etc/hysteria/domain.txt 2>/dev/null)
if [ -z "$DOMAIN" ]; then
    read -p "သင့် Domain အမည်ကို ရိုက်ထည့်ပါ (ဥပမာ- hy2.example.com): " DOMAIN
fi

read -p "API Username ကို ရိုက်ပါ [default: admin]: " API_USER
API_USER=${API_USER:-admin}
read -p "API Password ကို ရိုက်ပါ: " API_PASS
if [ -z "$API_PASS" ]; then
    echo "Error: Password မဖြစ်မနေ လိုအပ်ပါသည်။"
    exit 1
fi

echo -e "\n[Step 1/6] Installing Dependencies & Getting SSL Certificate..."
apt-get update && apt-get install -y certbot curl wget
systemctl stop nginx 2>/dev/null
certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email
if [ ! -f "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    echo "Error: SSL Certificate ရယူခြင်း မအောင်မြင်ပါ။ Domain ကို Server IP သို့ Point လုပ်ထားခြင်း ရှိမရှိ စစ်ဆေးပါ။"
    exit 1
fi

echo -e "\n[Step 2/6] Installing Hysteria 2 Core..."
bash <(curl -fsSL https://get.hy2.sh/)
systemctl stop hysteria-server.service

echo -e "\n[Step 3/6] Configuring Hysteria 2 & Setting Permissions..."
mkdir -p /etc/hysteria
echo "$DOMAIN" > /etc/hysteria/domain.txt

cat << EOF_HY2 > /etc/hysteria/config.yaml
listen: :443

tls:
  cert: /etc/letsencrypt/live/$DOMAIN/fullchain.pem
  key: /etc/letsencrypt/live/$DOMAIN/privkey.pem

auth:
  type: userpass
  userpass:
EOF_HY2

chgrp -R hysteria /etc/letsencrypt/live /etc/letsencrypt/archive
chmod -R 750 /etc/letsencrypt/live /etc/letsencrypt/archive
chown -R hysteria:hysteria /etc/hysteria
usermod -d /etc/hysteria hysteria

echo -e "\n[Step 4/6] Installing Hysteria API Script..."
curl -s https://paste.rs/wd0js > /usr/local/bin/hy2-api.py
sed -i 's/os.system("systemctl/os.system("sudo systemctl/' /usr/local/bin/hy2-api.py
chmod +x /usr/local/bin/hy2-api.py
chown hysteria:hysteria /usr/local/bin/hy2-api.py
echo "hysteria ALL=(ALL) NOPASSWD: /bin/systemctl restart hysteria-server.service" > /etc/sudoers.d/hysteria

echo -e "\n[Step 5/6] Configuring Nginx Reverse Proxy..."
tee /etc/nginx/sites-available/$DOMAIN <<EOF_NGINX
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    location /hy2-api/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location / {
        proxy_pass https://www.bing.com;
        proxy_set_header Host www.bing.com;
        proxy_set_header Referer https://www.bing.com;
        proxy_set_header User-Agent \$http_user_agent;
    }
}
EOF_NGINX

ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo -e "\n[Step 6/6] Configuring API Service and Starting All Services..."
tee /etc/systemd/system/hy2-api.service <<EOF_SERVICE
[Unit]
Description=Hysteria2 Standalone API Server
After=network.target

[Service]
Type=simple
User=hysteria
ExecStart=/usr/bin/python3 /usr/local/bin/hy2-api.py $API_USER $API_PASS 3000
Restart=always

[Install]
WantedBy=multi-user.target
EOF_SERVICE

systemctl daemon-reload
systemctl enable --now hysteria-server.service
systemctl restart hysteria-server.service
systemctl enable --now hy2-api.service
systemctl restart hy2-api.service
systemctl restart nginx

echo -e "\n========================================================"
echo -e "🎉 API, Nginx & Hysteria2 Auto-Setup အောင်မြင်စွာ ပြီးစီးပါပြီ!"
echo -e "========================================================"
echo -e "Protocol:      Hysteria2"
echo -e "API URL:       https://$DOMAIN/hy2-api"
echo -e "Auth Username: $API_USER"
echo -e "Auth Password: $API_PASS"
echo -e "========================================================\n"
EOF
```

*(အပေါ်က One-Click Script ကို run လိုက်တာနဲ့ အောက်မှာပြထားတဲ့ အဆင့် ၅ ဆင့်လုံးကို ကိုယ်တိုင်လုပ်စရာမလိုဘဲ အလိုအလျောက် ပြီးစီးသွားမှာဖြစ်ပါတယ်။)*

---

## 🖥️ Universal Web Panel ထဲသို့ ဖြည့်သွင်းချိတ်ဆက်ပုံ

သင့် Web Panel ၏ Add Server နေရာတွင် အပေါ်မှ ထွက်ရှိလာသော အချက်အလက်များအတိုင်း ဖြည့်သွင်းပါ -

*   **API URL:** `https://သင့်ဒိုမိန်းအသစ်/hy2-api` (ထွက်လာသည့် link အတိုင်း)
*   **Auth Username:** (ထွက်လာသည့် Username အတိုင်း)
*   **Auth Password:** (ထွက်လာသည့် စကားဝှက်အတိုင်း)

---

## 🔍 API ချိတ်ဆက်မှု အချက်အလက်များအား ပြန်လည်ထုတ်ယူကြည့်ရှုနည်း (Retrieve Credentials)

ဝဘ်ဆိုက် Panel တွင် ဆာဗာအသစ်ပြန်လည်ထည့်သွင်းရန်အတွက် သို့မဟုတ် ချိတ်ဆက်မှုအချက်အလက်များကို ပြန်လည်ကြည့်ရှုလိုပါက သင့် VPS Terminal တွင် အောက်ပါ command ကို ကူးယူပြီး Paste ချ၍ Run ပေးလိုက်ပါခင်ဗျာ -

```bash
DOMAIN=$(cat /etc/hysteria/domain.txt 2>/dev/null || echo "သင့်ဒိုမိန်း")
LINE=$(grep "hy2-api.py" /etc/systemd/system/hy2-api.service 2>/dev/null)
USER=$(echo "$LINE" | awk '{print $3}')
PASSWORD=$(echo "$LINE" | awk '{print $4}')

echo -e "\n========================================================"
echo -e "🖥️  UNIVERSAL WEB PANEL ချိတ်ဆက်ရန် အချက်အလက်များ"
echo -e "========================================================"
echo -e "Protocol:      Hysteria2"
echo -e "API URL:       https://$DOMAIN/hy2-api"
echo -e "Auth Username: $USER"
echo -e "Auth Password: $PASSWORD"
echo -e "========================================================\n"
```

*(၎င်း command ကို run လိုက်ပါက Web Panel တွင် ဖြည့်သွင်းရမည့် API URL၊ Username နှင့် Password တို့ကို VPS က တိုက်ရိုက် ပြန်လည်တွက်ချက်ထုတ်ပြပေးသွားမည် ဖြစ်ပါသည်)*

---

## 🔐 API Username နှင့် Password အား လွယ်ကူစွာ ပြောင်းလဲနည်း (Security Update)

အကယ်၍ သတ်မှတ်ထားသော Username နှင့် Password တို့အား ပိုမိုလုံခြုံသော စကားဝှက်သို့ လွယ်ကူစွာ ပြောင်းလဲလိုပါက VPS Terminal တွင် အောက်ပါအတိုင်း လုပ်ဆောင်ပါ -

**၁။ အောက်ပါ command တွင် `newadmin` နှင့် `NewSecurePassword789` နေရာများ၌ မိမိအလိုရှိသော Username နှင့် Password ကို အစားထိုးပြီး VPS ၌ Run လိုက်ပါ -**

```bash
# Username နှင့် Password အသစ်အား service တွင် အလိုအလျောက် သတ်မှတ်ခြင်း
sudo sed -i 's|ExecStart=.*|ExecStart=/usr/bin/python3 /root/hy2-api.py newadmin NewSecurePassword789 3000|' /etc/systemd/system/hy2-api.service

# Service အား reload လုပ်ပြီး restart ချခြင်း
sudo systemctl daemon-reload
sudo systemctl restart hy2-api.service
```

**၂။ အပြောင်းအလဲ အောင်မြင်ကြောင်း စစ်ဆေးရန် အောက်ပါ command ကို run ပြီး စစ်ဆေးပါ -**

```bash
systemctl cat hy2-api.service | grep ExecStart
```

*(ထို့နောက် Web Panel တွင်လည်း ၎င်း Username/Password အသစ်အတိုင်း ပြောင်းလဲဖြည့်သွင်းပေးရပါမည်)*

---

## 🌐 Web Panel တပ်ဆင်နည်း (Optional)

အကယ်၍ Hysteria 2 အတွက် သီးသန့် Web Panel ကိုပါ တပ်ဆင်အသုံးပြုလိုပါက အောက်ပါ command ကို VPS Terminal တွင် run နိုင်ပါသည် -

```bash
# Web Panel တပ်ဆင်ရန် Script အား run ခြင်း
curl -s https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/panel_install.sh | sudo bash
```

*(မှတ်ချက် - ၎င်းသည် Web Panel အတွက် လိုအပ်သော Python environments များကို install လုပ်ပြီး `hy2-panel` service ကို အလိုအလျောက် သတ်မှတ်ပေးမည်ဖြစ်ပါသည်။)*
