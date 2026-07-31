[◀️ ယခင်အခန်း (Previous Chapter)](02_API_Design_and_Communication.md) | [🏠 မာတိကာ (Main Menu)](README.md) | [▶️ နောက်တစ်ခန်း (Next Chapter)](04_AI_Collaboration_and_Best_Practices.md)

---

# Chapter 3: 🛡️ Comprehensive Security (Security-First Mindset)

Security ဆိုတာ App ကြီးတစ်ခုလုံး ပြီးသွားမှ နောက်ဆုံးမှ ဆေးသုတ်သလို သုတ်ရတဲ့အရာ မဟုတ်ပါဘူး။ ပရောဂျက် စလုပ်ကတည်းက အုတ်မြစ်ထဲမှာ ထည့်တည်ဆောက်ရမယ့် (Security-First Mindset) အရာဖြစ်ပါတယ်။

## ၁။ Code ထဲမှာ လုံးဝ (လုံးဝ) မပါသင့်တဲ့ အရာများ

Beginner တွေ အများဆုံး မှားတတ်တဲ့ အမှားကတော့ အရေးကြီးတဲ့ အချက်အလက် (Secrets) တွေကို Code ထဲမှာ ရေးမိတာပါပဲ။

- **မရေးရမည့်အရာများ:** Database Passwords, API Keys (e.g. OpenAI, Stripe), JWT Secret Keys.
- **ဘာကြောင့်လဲ:** သင့် Code ကို Github ပေါ်တင်လိုက်တဲ့အခါ (သို့) တခြားသူက Code ကို ဖတ်ခွင့်ရတဲ့အခါ Hacker တွေက အလွယ်တကူ ယူသုံးသွားနိုင်လို့ပါ။
- **အမှန်တကယ် လုပ်ရမည့်နည်းလမ်း:** `.env` (Environment Variables) ဖိုင်ကို သုံးရပါမယ်။ လျှို့ဝှက်ကုဒ်တွေကို `.env` ဖိုင်ထဲမှာပဲ ရေးပြီး Code (ဥပမာ Python) ထဲကနေ `os.getenv('DATABASE_URL')` ဆိုပြီး လှမ်းခေါ်သုံးရပါမယ်။ ပြီးရင် အဲဒီ `.env` ဖိုင်ကို Github ပေါ် မရောက်သွားအောင် `.gitignore` ထဲမှာ ထည့်ပိတ်ထားရပါမယ်။

## ၂။ အဖြစ်များသော တိုက်ခိုက်မှုများနဲ့ ကာကွယ်နည်းများ (OWASP Top 10)

AI ကို Code ရေးခိုင်းတဲ့အခါ ဒီတိုက်ခိုက်မှုတွေကို ကာကွယ်နိုင်အောင် အမြဲ သတိပေးရပါမယ်။

### A. SQL Injection
- **သဘောတရား:** Hacker က Login ဖောင် (သို့) Search ဖောင်ကနေတစ်ဆင့် Database ကို ဖျက်ဆီးမယ့် SQL Code တွေ ရိုက်ထည့်တာပါ။
- **ကာကွယ်နည်း:** Database ကို တိုက်ရိုက် String ပေါင်းပြီး မခေါ်ပါနဲ့။ `ORM` (ဥပမာ SQLAlchemy) သို့မဟုတ် Parameterized Queries ကို အမြဲသုံးပါ။

### B. XSS (Cross-Site Scripting)
- **သဘောတရား:** Hacker က နာမည်ပေးတဲ့ နေရာမှာ JavaScript Code လေးတွေ (ဥပမာ `<script>alert('Hacked')</script>`) ရိုက်ထည့်သွားတာပါ။ အဲဒီနာမည်ကို တခြား User တွေက လာကြည့်တဲ့အခါ သူတို့ Browser မှာ အဲဒီ Code အလုပ်လုပ်သွားပြီး အကောင့် အခိုးခံရပါတယ်။
- **ကာကွယ်နည်း:** Frontend မှာ Data တွေကို ပြတဲ့အခါ အမြဲတမ်း Encode (Escape) လုပ်ရပါမယ်။ ယနေ့ခေတ် React, Vue တွေက အလိုအလျောက် ကာကွယ်ပေးပေမယ့်၊ Vanilla JS မှာဆိုရင် `innerHTML` အစား `textContent` ကို သုံးဖို့ သတိထားရပါမယ်။

### C. Brute-Force & DDoS (ကျွန်တော်တို့ ဖြေရှင်းခဲ့ပုံ)
- **သဘောတရား:** Hacker က စက်ရုပ် (Bot) တွေသုံးပြီး Password ကို တစ်စက္ကန့် အခါ ၁၀၀၀ လောက် ခန့်မှန်းပြီး Login ဝင်ဖို့ ကြိုးစားတာမျိုးပါ။
- **ကာကွယ်နည်း:** Rate Limiting ပါ။ (ကျွန်တော်တို့ ပရောဂျက်မှာ `slowapi` သုံးပြီး တစ်မိနစ်ကို ၅ ခါပဲ Login ဝင်ခွင့်ပေးထားပါတယ်)။ ဒုတိယအချက်အနေနဲ့ Password တွေကို Data အဖြစ် အစိမ်းအတိုင်း (Plain text) မသိမ်းဘဲ `bcrypt` ကို သုံးပြီး (Hash) ဖြတ်သိမ်းရပါမယ်။

## ၃။ API လုံခြုံရေးအတွက် AI ကို ခိုင်းစေနည်း (Pro Tip)

AI ဟာ သင့်ကို အလုပ်လုပ်တဲ့ (Working Code) ကိုပဲ ရေးပေးလေ့ရှိပါတယ်။ လုံခြုံတဲ့ (Secure Code) ကို ရေးပေးချင်မှ ရေးပေးပါလိမ့်မယ်။ ဒါကြောင့် သင်က တောင်းဆိုရပါမယ်။

**ဥပမာ Prompt တွေ -**
- *"Login API လေးရေးပေးပါ။ ဒါပေမယ့် ပုံမှန် မရေးပါနဲ့။ Password ကို `bcrypt` နဲ့ Hash လုပ်ပေးပါ။ JWT token ထုတ်ပေးတဲ့အခါ Expiry Time 1 နာရီပဲ ထားပေးပါ။"*
- *"ဒီ Code ကို Security Audit (OWASP Top 10) စံနှုန်းနဲ့ စစ်ပေးပါ။ လုံခြုံရေး အားနည်းချက် ရှိရင် အခုပဲ ပြင်ပေးပါ။"* (ကျွန်တော်တို့ `.cursorrules` မှာ ထည့်ရေးထားသလိုမျိုးပါ။)

## ၄။ Server (VPS) လုံခြုံရေး (Server Hardening)

Web App လုံခြုံရုံနဲ့ မရပါဘူး။ Web App တင်ထားတဲ့ ဆာဗာ လုံခြုံဖို့လည်း လိုပါတယ်။
1. **Firewall (UFW):** လိုအပ်တဲ့ Port တွေ (ဥပမာ - HTTP/HTTPS, Hysteria port) တွေကိုပဲ ဖွင့်ထားပါ။ ကျန်တာ အကုန်ပိတ်ပါ။
2. **SSH Keys:** Root account ကို Password နဲ့ ဝင်ခွင့်ပိတ်ပါ။ SSH Key ဖြင့်သာ ဝင်ခွင့်ပြုပါ။
3. **Fail2Ban:** မှားယွင်းတဲ့ Password တွေ ဆက်တိုက် ရိုက်သွင်းသူတွေကို အလိုအလျောက် IP Block ပေးတဲ့ `fail2ban` ကို သွင်းထားပါ။

(လုံခြုံရေးဆိုတာ ၁၀၀% စိတ်ချရတယ်ဆိုတာ မရှိပါဘူး။ ဒါပေမယ့် Hacker တွေ လက်လျှော့သွားလောက်အောင် ခက်ခဲအောင် လုပ်ထားလို့ ရပါတယ်။)

---
[◀️ ယခင်အခန်း (Previous Chapter)](02_API_Design_and_Communication.md) | [🏠 မာတိကာ (Main Menu)](README.md) | [▶️ နောက်တစ်ခန်း (Next Chapter)](04_AI_Collaboration_and_Best_Practices.md)
