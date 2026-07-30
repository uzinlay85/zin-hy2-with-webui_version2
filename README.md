# Hysteria 2 with WebUI Version 2

Fast, Secure, and Automated Hysteria 2 VPN Server setup with a lightweight Web Panel for User Management.

## အသစ်ပါဝင်လာသော စနစ်များ (New Features)
- 🚀 **One-Click Setup:** Code တစ်ကြောင်းတည်း Run ရုံဖြင့် Hysteria 2 + Web Panel + SSL အစုံအလင် တပ်ဆင်ပေးခြင်း။
- 🔐 **Admin Login UI:** Web Panel ကို ဝင်ရောက်ရန် လုံခြုံသော Authentication စနစ် (Username/Password ပြောင်းလဲနိုင်ခြင်း)။
- 🛡️ **Salamander Obfuscation:** မြန်မာပြည်တွင်း အင်တာနက်လိုင်းများ (MPT, Atom စသည်) ၏ ပိတ်ဆို့မှုများကို ကျော်လွှားနိုင်ရန် Obfuscation စနစ် အသင့်ပါဝင်ခြင်း။
- 🔄 **Real-Time Traffic Monitoring:** User တစ်ဦးချင်းစီ၏ Data အသုံးပြုမှုကို Live ကြည့်ရှုနိုင်ခြင်း။
- 👥 **User Management:** Data Limit (GB) ဖြတ်တောက်ခြင်း၊ Device အကန့်အသတ်ထားခြင်း၊ Expire Date သတ်မှတ်ခြင်းများ ပါဝင်သည်။

---

## 🚀 One-Click ဖြင့် အလွယ်ဆုံးတပ်ဆင်နည်း (Installation)

မည်သူမဆို အောက်ပါ Command တစ်ကြောင်းတည်းကိုသာ သင်၏ Ubuntu VPS တွင် Run ရန် လိုအပ်ပါသည် -

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/install.sh)
```

**လုပ်ဆောင်ရမည့်အဆင့်များ:**
1. အထက်ပါ Command ကို Run ပါ။
2. `Enter your Domain Name:` ဟုတောင်းပါက သင်၏ Domain (ဥပမာ - `vpn.yourdomain.com`) ကို ရိုက်ထည့်ပြီး Enter ခေါက်ပါ။
3. ကျန်သည့် Hysteria 2 တပ်ဆင်ခြင်း၊ SSL ယူခြင်း၊ Nginx ချိန်ခြင်း အစရှိသည်တို့အားလုံးကို Script မှ အလိုအလျောက် ၅ မိနစ်အတွင်း အပြီးသတ်ပေးသွားမည် ဖြစ်သည်။

**တပ်ဆင်ပြီးပါက ဝင်ရောက်ရမည့် အချက်အလက်များ:**
- **URL:** `https://yourdomain.com`
- **Username:** `admin`
- **Password:** `admin123`
*(မှတ်ချက်။ ပထမဆုံး Login ဝင်ပြီးပါက "Admin Settings" တွင် Password အသစ် ချက်ချင်း ပြောင်းလဲအသုံးပြုပါ။)*

---

## 🗑️ Uninstall ပြုလုပ်နည်း (How to Remove)

အကယ်၍ အရင်ပုံစံအဟောင်းဖြင့် တပ်ဆင်ထားသည်များကို အကုန်ဖျက်ပြီး အသစ်ပြန်လည် တပ်ဆင်လိုပါက (သို့မဟုတ်) Panel ကို ဖျက်လိုပါက အောက်ပါ Command ကို Run ပါ -

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/uninstall.sh)
```

ဤ Script သည် Hysteria 2 Service၊ Web Panel နှင့် Nginx Config များကို အစအနမကျန် အလိုအလျောက် ဖျက်သိမ်းပေးသွားမည် ဖြစ်သည်။ ထို့နောက် `install.sh` အသစ်ဖြင့် အစမှ ပြန်လည် တပ်ဆင်နိုင်ပါသည်။

---

## Client တွင် အသုံးပြုခြင်း
Web Panel မှ `Copy Link` ကိုနှိပ်ပြီး ရလာသော Key အား v2rayN (Windows) သို့မဟုတ် Nekobox (Android) တို့တွင် `Import from Clipboard` ဖြင့် တိုက်ရိုက် ထည့်သွင်းအသုံးပြုနိုင်ပါသည်။

*Routing ကို `Global` သို့ ပြောင်းလဲအသုံးပြုရန် အကြံပြုအပ်ပါသည်။*
