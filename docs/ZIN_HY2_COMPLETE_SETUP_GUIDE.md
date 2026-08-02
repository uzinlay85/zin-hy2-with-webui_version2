# Zin-Hy2 Hysteria 2 Server: Domain Name, Web Panel & Port Hopping အသုံးပြု၍ Setup လုပ်နည်း (Complete Guide)

> **Zin-Hy2 Version 2** သည် Hysteria 2 Protocol (QUIC / HTTP3) ကို အခြေခံထားသော High-Performance VPN System ဖြစ်ပြီး, Multi-User Web Panel (FastAPI)၊ 64MB QUIC Receive Windows၊ Cloudflare Masquerade၊ Let's Encrypt SSL Certificate နှင့် UDP Port Hopping (20000-50000) စနစ်များ အပြည့်အဝ ပါဝင်ပါသည်။

---

## ⚡ Zin-Hy2 VPN တည်ဆောက်နည်း အကျဉ်းချုပ် (Quick Setup Summary)

### ၁။ DNS Setup (Cloudflare)
- မိမိ Domain Name (ဥပမာ- `vpn.yourdomain.com`) ၏ **A Record** တွင် VPS IP ကို ထည့်ပါ။
- Proxy Status ကို **"DNS Only" (Grey Cloud / မီးခိုးရောင် တိမ်တိုက်)** အဖြစ် သတ်မှတ်ပါ။ *(မှတ်ချက်- Orange Cloud ခံ၍ မရပါ)*။

---

### ၂။ Port စစ်ဆေးခြင်းနှင့် Firewall ဖွင့်ခြင်း

```bash
# Port 80, 443 နှင့် UDP 20000-50000 လွတ်နေသလား စစ်ပါ
sudo ss -tulnp | grep -E ':80|:443|:20000'

# Firewall တွင် လိုအပ်သော Port များကို ဖွင့်ပေးရန်
sudo ufw allow 80/tcp && sudo ufw allow 443/tcp && sudo ufw allow 443/udp && sudo ufw allow 20000:50000/udp && sudo ufw reload
```

---

### ၃။ One-Click Installation (စနစ် အစအဆုံး တည်ဆောက်ခြင်း)

Terminal တွင် အောက်ပါ Command တစ်ကြောင်းတည်းကို ရိုက်ထည့်၍ မောင်းနှင်ပါ:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/install.sh)
```

- Prompt ပေါ်လာပါက မိမိ၏ **Domain Name** (ဥပမာ- `vpn.yourdomain.com`) နှင့် **Web Panel Admin Password** ကို ရိုက်ထည့်ပေးပါ။
- Script မှ SSL Certificate၊ FastAPI Web Panel၊ Hysteria 2 Core၊ 64MB QUIC Buffers နှင့် iptables Port Hopping များကို အလိုအလျောက် သွင်းယူ တည်ဆောက်သွားမည် ဖြစ်သည်။

---

### ၄။ Web Panel ဝင်ရောက်ခြင်းနှင့် CLI Shortcut

- **Web Panel Dashboard URL**:  
  `https://vpn.yourdomain.com/hy2-api/`
- **Default Username**: `admin`
- **Password**: Install လုပ်ချိန်က သတ်မှတ်ခဲ့သော Password

#### ⚡ CLI Command Shortcut (`hy2`)
VPS Terminal ထဲတွင် အောက်ပါ စာလုံးတိုလေး ရိုက်လိုက်ရုံဖြင့် Management & Diagnostic Menu ကို တိုက်ရိုက် ဖွင့်နိုင်ပါသည်:

```bash
hy2
```

---

### ၅။ စနစ် အလိုအလျောက် ပြုပြင်ခြင်းနှင့် Update ပြုလုပ်နည်း (Maintenance)

အကယ်၍ စနစ်ကို Update ပြုလုပ်လိုပါက သို့မဟုတ် အခက်အခဲ တစ်စုံတစ်ရာ ရှိ၍ ပြန်လည် စစ်ဆေး ပြုပြင်လိုပါက:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/server_fix.sh)
```
*(သို့မဟုတ် Terminal တွင် `hy2` ဟု ရိုက်၍ Option 9 auto update ကို ရွေးချယ်နိုင်ပါသည်)*
