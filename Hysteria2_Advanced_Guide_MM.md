# 🚀 Hysteria 2: ခေတ်မီဆင်ဆာဖြတ်တောက်မှုများကို ကျော်ဖြတ်နိုင်သော Advanced VPN System (Knowledge Base & Architecture)

## 📖 နိဒါန်း (Introduction)
ယနေ့ခေတ်တွင် နိုင်ငံအများအပြားရှိ အစိုးရများနှင့် အင်တာနက် ဝန်ဆောင်မှုပေးသူများ (ISPs) သည် **Deep Packet Inspection (DPI)** နည်းပညာများကို အသုံးပြု၍ OpenVPN, WireGuard နှင့် သာမန် Shadowsocks ကဲ့သို့သော ရိုးရာ VPN များကို အလွယ်တကူ ရှာဖွေပိတ်ဆို့လာကြသည်။ ဤပြဿနာကို ဖြေရှင်းရန် ပေါ်ထွက်လာသော နည်းပညာများထဲတွင် **Hysteria 2** သည် အမြန်နှုန်းနှင့် လုံခြုံရေးအတွက် အကောင်းဆုံး ရွေးချယ်မှုတစ်ခု ဖြစ်လာသည်။

Hysteria 2 သည် **QUIC** (HTTP/3 ၏ အခြေခံ Protocol) ကို အသုံးပြုထားပြီး၊ မတည်ငြိမ်သော (Lossy) ကွန်ရက်များတွင်ပင် အကောင်းဆုံး အမြန်နှုန်းကို ရရှိစေရန် **Brutal Congestion Control** ကို အသုံးပြုထားသည်။ သို့သော် DPI နည်းပညာများ ပိုမိုတိုးတက်လာသည်နှင့်အမျှ Hysteria 2 ကိုယ်တိုင်သည်လည်း အဆင့်မြှင့်တင်မှုများ ပြုလုပ်ရန် လိုအပ်လာသည်။

---

## 🛑 စိန်ခေါ်မှုများ (The Challenges of Modern DPI)
Hysteria 2 ၏ မူလပုံစံသည် သာမန် HTTPS (QUIC) Traffic များနှင့် တူညီအောင် ဖန်တီးထားသော်လည်း၊ တင်းကျပ်သော ဆင်ဆာစနစ်များ (ဥပမာ - GFW သို့မဟုတ် မြန်မာနိုင်ငံရှိ MPT/Ooredoo ကဲ့သို့သော ISPs များ) သည် အောက်ပါနည်းလမ်းများဖြင့် ပိတ်ဆို့ရန် ကြိုးစားလာကြသည်-

1. **QUIC Fingerprinting:** Hysteria ၏ QUIC Client Hello (CHLO) ပုံစံကို မှတ်သား၍ ပိတ်ဆို့ခြင်း။
2. **UDP Blocking & Throttling:** UDP Port 443 ကို အသုံးပြုမှုများလွန်းပါက အလိုအလျောက် ဖြတ်ချခြင်း သို့မဟုတ် အမြန်နှုန်း လျှော့ချခြင်း (Throttling)။
3. **Self-signed Certificates:** တရားဝင် CA (Let's Encrypt) မဟုတ်သော SSL များကို အလွယ်တကူ ရှာဖွေပိတ်ဆို့ခြင်း။
4. **QUIC-in-QUIC Loop:** Browser များမှ HTTP/3 ဖြင့် ချိတ်ဆက်သောအခါ Proxy အလုပ်မလုပ်ဘဲ Loop ဖြစ်သွားခြင်း။

---

## 🛠️ ကျွန်ုပ်တို့၏ အဆင့်မြင့် တည်ဆောက်ပုံ (Our System Architecture)

အထက်ပါ စိန်ခေါ်မှုများနှင့် ကမ္ဘာတစ်လွှားမှ ကျွမ်းကျင်သူများ၏ ဝေဖန်အကြံပြုချက်များကို လေ့လာပြီးနောက်၊ ကျွန်ုပ်တို့သည် အောက်ပါအတိုင်း **အပြည့်စုံဆုံးနှင့် အလုံခြုံဆုံးသော စနစ်တစ်ခု** ကို တည်ဆောက်ခဲ့သည်-

### ၁။ 🦎 Salamander Obfuscation (Anti-DPI)
Hysteria 2 ၏ မူလ QUIC Traffic ကို DPI များမှ မခွဲခြားနိုင်စေရန် **Salamander** အမည်ရှိ Obfuscation (ဖုံးကွယ်ခြင်း) နည်းပညာကို မဖြစ်မနေ ထည့်သွင်းထားပါသည်။
- **လုပ်ဆောင်ပုံ:** Random ထုတ်ပေးထားသော ခိုင်မာသည့် Password ကို အသုံးပြု၍ QUIC packet များကို ပြောင်းလဲ (Mask) ပစ်လိုက်သည်။ ထို့ကြောင့် ISP များအနေဖြင့် ၎င်းသည် မည်သည့် Protocol ဖြစ်ကြောင်း လုံးဝ (လုံးဝ) ခွဲခြားနိုင်မည် မဟုတ်ပါ။

### ၂။ 🔀 UDP Port Hopping (Dynamic Ports)
UDP Port 443 တစ်ခုတည်းကိုသာ အသုံးပြုပါက ISP မှ သံသယဖြစ်လာနိုင်သောကြောင့်၊ Port Range (20000 မှ 50000) ကြားတွင် ကျပန်းပြောင်းလဲ အသုံးပြုနိုင်မည့် (Port Hopping) စနစ်ကို ဖန်တီးခဲ့သည်။
- **လုပ်ဆောင်ပုံ:** Linux ၏ `iptables` (UFW NAT) ကို အသုံးပြု၍ `PREROUTING REDIRECT` Rule များ ရေးဆွဲကာ၊ Port 20000-50000 သို့ ဝင်လာသော UDP Traffic မှန်သမျှကို Hysteria ၏ ပင်မ Port 443 သို့ အလိုအလျောက် ပို့ဆောင်ပေးသည်။

### ၃။ 🎭 Active Masquerading & TLS
- Hysteria ဆာဗာသို့ သာမန် Browser ဖြင့် ဝင်ရောက်လာပါက၊ `bing.com` သို့ အလိုအလျောက် လွှဲပြောင်းပေးမည့် **Proxy Masquerade** စနစ်ကို ထည့်သွင်းထားသည်။ (Active Probing ကို ကာကွယ်ရန်)
- Self-signed cert များကို လုံးဝအသုံးမပြုဘဲ၊ **Let's Encrypt (Certbot)** ဖြင့် တရားဝင် သက်တမ်းရှိသော SSL (Domain ဖြင့်) ကိုသာ အသုံးပြုထားသည်။

### ၄။ 🛡️ လုံခြုံရေး တင်းကျပ်ခြင်း (Security Hardening)
- **Spamming ကာကွယ်ခြင်း:** Hysteria ဆာဗာမှတစ်ဆင့် Spam Email များ ပို့ဆောင်ခြင်း (Abuse) မပြုလုပ်နိုင်ရန် UFW မှတစ်ဆင့် အထွက် Port များ (25, 465, 587) ကို ပိတ်ပင်ထားသည်။
- **QUIC-in-QUIC Loop ကာကွယ်ခြင်း:** Hysteria Config `acl` တွင် `reject(all, udp/443)` ကို ထည့်သွင်းထားခြင်းဖြင့် QUIC လည်နေသည့် ပြဿနာကို ဖြေရှင်းထားသည်။
- **Automated Password Generation:** Script တပ်ဆင်စဉ်အတွင်း `admin123` ကဲ့သို့သော လွယ်ကူသည့် စကားဝှက်များအစား `/dev/urandom` မှတစ်ဆင့် Base64 ဖြင့် လုံခြုံသော စကားဝှက်များကို အလိုအလျောက် ထုတ်ပေးသည့်စနစ်ကို အသုံးပြုထားသည်။
- **CPU Architecture Detection:** AMD64 နှင့် ARM64 (Oracle Cloud) နှစ်မျိုးလုံးအတွက် အလိုအလျောက် သိရှိပြီး မှန်ကန်သော Core ကို Download ဆွဲပေးသည်။

---

## 💻 Web Panel (Management UI) ၏ အခန်းကဏ္ဍ
ကျွန်ုပ်တို့ ရေးသားထားသော FastAPI Web Panel သည် Hysteria 2 နှင့် အောက်ပါအတိုင်း ချိတ်ဆက်အလုပ်လုပ်သည်-

1. **Authentication (HTTP Auth):** User များ ချိတ်ဆက်လာတိုင်း Hysteria 2 သည် Web Panel ၏ `/auth` Endpoint သို့ လှမ်းမေးပြီး Password, Expiry Date နှင့် Data Limit များကို စစ်ဆေးသည်။
2. **Traffic & Online Stats:** Panel ရှိ Background Task (Poller) သည် Hysteria ၏ Traffic API သို့ စက္ကန့်အနည်းငယ်ခြားတိုင်း လှမ်း၍ Data အသုံးပြုမှုနှင့် လက်ရှိ Online ဖြစ်နေသူများကို တွက်ချက်ကာ Database တွင် မှတ်တမ်းတင်သည်။ Data Limit ပြည့်သွားသူများကို ချက်ချင်း Kick ထုတ်သည်။

---

## 🎯 နိဂုံး (Conclusion)

ဤတည်ဆောက်မှုသည် သာမန် VPN Setup တစ်ခုထက် အများကြီး ပိုမိုသာလွန်ပါသည်။ **Hysteria 2 ၏ အမြန်နှုန်း**၊ **Salamander ၏ လုံခြုံမှု (Anti-DPI)**၊ **Port Hopping ၏ Throttling ကာကွယ်မှု** နှင့် **Web Panel ၏ စီမံခန့်ခွဲရ လွယ်ကူမှု** တို့ကို စနစ်တကျ ပေါင်းစပ်ထားသောကြောင့် အနာဂတ်တွင် ကြုံတွေ့လာနိုင်မည့် ဆင်ဆာဖြတ်တောက်မှုများကိုပါ ကြံ့ကြံ့ခံ ရင်ဆိုင်နိုင်မည့် အကောင်းဆုံး စနစ်တစ်ခုအဖြစ် မှတ်တမ်းတင်အပ်ပါသည်။

> *"The goal of anti-censorship is not just to evade the wall today, but to build a tunnel invisible to the wall of tomorrow."*
