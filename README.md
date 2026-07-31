# Hysteria 2 with WebUI Version 2

Fast, Secure, and Automated Hysteria 2 VPN Server setup with a feature-rich, modern Web Panel for User Management.

## ✨ အသစ်ပါဝင်လာသော စနစ်များ (Major Features)
- 🚀 **One-Click Setup:** Code တစ်ကြောင်းတည်း Run ရုံဖြင့် Hysteria 2 + Web Panel + SSL အစုံအလင် တပ်ဆင်ပေးခြင်း။
- 🌍 **Advanced Anti-Censorship (Obfuscation):** Salamander Obfuscation စနစ်ကို အလိုအလျောက် ထည့်သွင်းပေးထားသောကြောင့် တင်းကျပ်သော DPI (ဥပမာ - MPT/Ooredoo) ပိတ်ဆို့မှုများကို အလွယ်တကူ ကျော်ဖြတ်နိုင်ပြီး V2rayN, NekoBox, Sing-box အစရှိသည့် App အားလုံးတွင် ချိတ်ဆက်အသုံးပြုနိုင်ပါသည်။
- 🎨 **Modern Responsive UI:** သပ်ရပ်လှပသော UI အသစ်။ (List View နှင့် Card View ကို စိတ်ကြိုက် ပြောင်းလဲကြည့်ရှုနိုင်ပြီး Mobile screen များတွင်ပါ အဆင်ပြေစေပါသည်။)
- 🟢 **Real-Time Online Status:** လက်ရှိချိတ်ဆက်အသုံးပြုနေသော User များကို **Live** အနေဖြင့် (Pulsing Green Dot & Connection Count) တိုက်ရိုက် ကြည့်ရှုနိုင်ခြင်း။
- ⏱️ **Last Seen Tracking:** Offline ဖြစ်သွားသော User များ နောက်ဆုံးချိတ်ဆက်ခဲ့သည့်အချိန် (ဥပမာ - *Last seen: 5m ago*) ကို ပြသပေးခြင်း။
- 💾 **Backup & Restore System:** User အချက်အလက်များ (Passwords, Data limit, Usage စသည်) အားလုံးကို `.json` ဖိုင်ဖြင့် Download လုပ်၍ သိမ်းဆည်းထားနိုင်ပြီး၊ ဆာဗာအသစ် ပြောင်းသည့်အခါ Click တစ်ချက်နှိပ်ရုံဖြင့် အလွယ်တကူ ပြန်လည် (Restore) ထည့်သွင်းနိုင်ခြင်း။ (Merge & Replace mode များ ပါဝင်သည်။)
- 👥 **Advanced User Management:** Data Limit (GB) ဖြတ်တောက်ခြင်း၊ Device အကန့်အသတ်ထားခြင်း၊ Expire Date သတ်မှတ်ခြင်း နှင့် Data အသုံးပြုမှု (Traffic) ကို Live ခြေရာခံခြင်း။
- 🔐 **Admin Security:** Web Panel ကို ဝင်ရောက်ရန် လုံခြုံသော Authentication စနစ် (Username/Password အလွယ်တကူ ပြောင်းလဲနိုင်ခြင်း)။

---

## 🚀 ၁။ အလွယ်ဆုံးတပ်ဆင်နည်း (Setup / Installation)

မည်သူမဆို အောက်ပါ Command တစ်ကြောင်းတည်းကိုသာ သင်၏ Ubuntu VPS တွင် Run ရန် လိုအပ်ပါသည် -

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/install.sh)
```

**လုပ်ဆောင်ရမည့်အဆင့်များ:**
1. အထက်ပါ Command ကို Run ပါ။
2. `Enter your Domain Name:` ဟုတောင်းပါက သင်၏ Domain (ဥပမာ - `vpn.yourdomain.com`) ကို ရိုက်ထည့်ပြီး Enter ခေါက်ပါ။
3. ကျန်သည့် Hysteria 2 တပ်ဆင်ခြင်း၊ SSL ယူခြင်း၊ Nginx ချိန်ခြင်း အစရှိသည်တို့အားလုံးကို Script မှ အလိုအလျောက် ၅ မိနစ်အတွင်း အပြီးသတ်ပေးသွားမည် ဖြစ်သည်။

**တပ်ဆင်ပြီးပါက Web Panel သို့ ဝင်ရောက်ရန်:**
- **URL:** `https://yourdomain.com/hy2-api/`
- **Username:** `admin`
- **Password:** `Install လုပ်စဉ်က သင်ပေးခဲ့သော Password (သို့မဟုတ်) Terminal တွင် ပြသသွားသော အလိုအလျောက်ထုတ်ပေးသည့် Password`
*(မှတ်ချက်။ Login ဝင်ပြီးပါက ညာဘက်အပေါ်ထောင့်ရှိ "⚙️ Settings" တွင် Password ကို အချိန်မရွေး ပြောင်းလဲအသုံးပြုနိုင်ပါသည်။)*

---

## 🔄 ၂။ Update ပြုလုပ်နည်း (How to Update)

Web Panel တွင် Feature အသစ်များ ပါလာသည့်အခါ (သို့) ပြုပြင်ပြောင်းလဲမှုများ ရှိလာပါက ဆာဗာတွင် အောက်ပါ Command များကို Run ၍ Update ပြုလုပ်နိုင်ပါသည် -

```bash
cd /opt/hy2-panel
git pull
systemctl restart hy2-panel.service
```
Update လုပ်ပြီးပါက Browser တွင် **`Ctrl + Shift + R`** (Hard Refresh) နှိပ်၍ အသုံးပြုပါ။

*(မှတ်ချက်: System Update အသစ်များ ပါလာပါက Install script အသစ်အတိုင်း Database Backup ယူပြီး ပြန်လည် Install ပြုလုပ်ရန် အကြံပြုပါသည်။)*

---

## 🔍 ၃။ ဆာဗာ အခြေအနေ စစ်ဆေးနည်းများ (Diagnostic Tool)

Hysteria 2 Server သို့မဟုတ် Web Panel တွင် အခက်အခဲ တစ်စုံတစ်ရာ ရှိပါက (သို့မဟုတ်) Port များနှင့် Error Log များကို တစ်နေရာတည်းတွင် စစ်ဆေးလိုပါက အောက်ပါ Command ကို Run ပါ -

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/status.sh)
```
ဤ Script သည် Config ဖိုင်များ၊ Service အလုပ်လုပ်/မလုပ်၊ Firewall Port Hopping အခြေအနေနှင့် နောက်ဆုံးပေါ်နေသော Error Log များကို တစ်ပေါင်းတည်း စစ်ဆေးပြသပေးပါမည်။

**🔴 Real-Time (Live) Server Log ကို စောင့်ကြည့်ရန်:**
ဆာဗာ ပုံမှန်အလုပ်လုပ်နေသလား၊ User တွေ ချိတ်ဆက်မှုပြတ်တောက်သွားသလား၊ Error တက်နေသလား ဆိုတာကို စက္ကန့်နဲ့အမျှ (Live) ကြည့်ရှုလိုပါက အောက်ပါ Command ကို Run ပါ -
```bash
journalctl -u hysteria-server.service -f
```
*(Live ကြည့်နေသည်ကို ရပ်တန့်လိုပါက Keyboard မှ **`Ctrl + C`** ကို နှိပ်ပါ။)*

---

## 💾 ၄။ Backup & Restore ပြုလုပ်နည်း (Data Migration)

ဆာဗာအသစ်သို့ ပြောင်းရွှေ့သည့်အခါ User များ ပြန်လည်ချိတ်ဆက်ရန် မလိုဘဲ အရင်အတိုင်း ဆက်လက်အသုံးပြုနိုင်ရန် ဤစနစ်ကို အသုံးပြုပါ။

1. **Backup ယူခြင်း:** လက်ရှိ Web Panel သို့ဝင်ပါ၊ **"💾 Backup"** ခလုတ်ကို နှိပ်ပြီး **"Download Backup File"** ကို ရွေးချယ်ကာ `.json` ဖိုင်ကို သိမ်းဆည်းထားပါ။
2. **ဆာဗာအသစ် တပ်ဆင်ခြင်း:** ဆာဗာအသစ်တွင် အပေါ်ရှိ **Setup** နည်းလမ်းအတိုင်း Panel ကို အသစ်တပ်ဆင်ပါ။
3. **Restore လုပ်ခြင်း:** ဆာဗာအသစ်၏ Web Panel သို့ဝင်ပါ၊ **"💾 Backup"** ကို နှိပ်ပြီး သိမ်းဆည်းထားသော `.json` ဖိုင်ကို ရွေးချယ်ပါ။
4. **Mode ရွေးချယ်ခြင်း:**
   - **Merge:** ရှိပြီးသား User များကို ချန်လှပ်၍ အသစ်များကိုသာ ပေါင်းထည့်မည်။
   - **Replace:** ရှိသမျှ User ဟောင်းများကို ဖျက်ပြီး Backup ထဲမှအတိုင်း အစားထိုးမည်။
5. **"Restore Now"** ကို နှိပ်လိုက်သည်နှင့် ပြီးစီးပါပြီ။ Client များဘက်တွင် မည်သည့်အရာမှ ပြောင်းလဲရန် မလိုတော့ပါ။

---

## 🗑️ ၅။ အပြီးအပိုင် ဖျက်သိမ်းနည်း (Uninstall)

အကယ်၍ အကုန်ဖျက်ပြီး အသစ်ပြန်လည် တပ်ဆင်လိုပါက (သို့မဟုတ်) Panel ကို အပြီးတိုင် ဖျက်သိမ်းလိုပါက အောက်ပါ Command ကို Run ပါ -

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/uninstall.sh)
```

ဤ Script သည် Hysteria 2 Service၊ Web Panel၊ Database နှင့် Nginx Config များကို အစအနမကျန် အလိုအလျောက် သန့်ရှင်းစွာ ဖျက်သိမ်းပေးသွားမည် ဖြစ်သည်။

---

## ⚠️ ၆။ အဖြစ်များသော ပြဿနာများ ဖြေရှင်းနည်း (Troubleshooting)

**UDP Port Hopping Rules (REDIRECT) များ ထပ်နေခြင်း (Duplicate Rules):**
`status.sh` ဖြင့် စစ်ဆေးသောအခါ `iptables Port Hopping Rules` အောက်တွင် `REDIRECT ... udp dpts:20000:50000 redir ports 443` စာကြောင်းများ အများကြီး ထပ်နေသည်ကို တွေ့ရပါက အောက်ပါ Command ကို Terminal တွင် Run ၍ ဖြေရှင်းနိုင်ပါသည် -

```bash
# ၁။ ထပ်နေသော Rule အဟောင်းများအားလုံးကို မှတ်ဉာဏ်ထဲမှ ရှင်းလင်းရန်
while iptables -t nat -D PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports 443 2>/dev/null; do :; done

# ၂။ Rule အသစ် တစ်ကြောင်းတည်းသာ ပြန်လည်ထည့်သွင်းရန်
iptables -t nat -A PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports 443
```
*(မှတ်ချက် - ဤနည်းလမ်းသည် ဆာဗာ Restart မချခင်အထိ မှတ်ဉာဏ်ထဲတွင် ရှင်းလင်းသွားစေပြီး ပိုမို ပေါ့ပါးသွက်လက်စေပါသည်။)*

---

## 📱 Client တွင် အသုံးပြုခြင်း (Client Usage)

Web Panel မှ User တစ်ဦးစီ၏ **`🔗 Copy`** (Copy Link) ကို နှိပ်ပြီး ရလာသော `hysteria2://` URI ကို App (V2rayN, NekoBox, Sing-box, etc.) များတွင် **`Import from Clipboard`** ပြုလုပ်၍ တိုက်ရိုက် ထည့်သွင်း အသုံးပြုနိုင်ပါသည်။

*Routing (သို့မဟုတ်) Rule ကို `Global` သို့ ပြောင်းလဲအသုံးပြုရန် အကြံပြုအပ်ပါသည်။*
