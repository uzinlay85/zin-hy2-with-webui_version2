# Hysteria 2 GitHub Issue #1365 Study: Mobile Phone Screen Sleep & Idle Disconnections

> **ပြဿနာ ခဲယဉ်းမှု:** GitHub Issue #1365 - "Disconnections on mobile phones (Android / iOS screen sleep & idle disconnects)"
> **ဖြစ်စဉ်:** Android (Samsung, Xiaomi, Pixel) နှင့် iOS ဖုန်းများတွင် Screen Lock ပိတ်ထားချိန် (သို့မဟုတ်) 1 မိနစ်ခန့် မသုံးဘဲ ထားလိုက်ပါက WhatsApp Call / Telegram Notification များ မဝင်တော့ဘဲ ဖုန်းကို ပြန်လည် Unlock လုပ်ချိန်တွင် Connect ပြန်ဖြစ်ရန် ၁၀ စက္ကန့်မှ စက္ကန့် ၃၀ အထိ ကြန့်ကြာခြင်း။

---

## 🔍 Root Cause Analysis (အကြောင်းရင်း အသေးစိတ် ဆန်းစစ်ချက်)

### ၁။ Mobile CGNAT & QUIC Idle Timeout (RFC 9000 §10.3)
- မိုဘိုင်းဖုန်းများတွင် Screen ပိတ်လိုက်ပါက OS ၏ Battery Saver စနစ်မှ Background UDP Sockets များကို အိပ်စက် (Sleep) ခိုင်းလိုက်သည်။
- အကယ်၍ Server ဘက်မှ အမြဲမပြတ် PING မပို့ပါက (သို့မဟုတ် `keepAlivePeriod` မပါပါက) မိုဘိုင်း အင်တာနက် Operator များ၏ CGNAT Port Table မှ UDP State ကို ၁၅ စက္ကန့်မှ မိနစ်ပိုင်းအတွင်း ဖျက်ဆီးလိုက်သည်။
- ဖုန်းမျက်နှာပြင် ပြန်ဖွင့်ချိန်တွင် Client မှ Server သို့ Packet ပို့သော်လည်း Server ဘက်တွင် Session ကုန်သွားသဖြင့် Client ဘက်တွင် Disconnect/Timeout ပြန်ဖြစ်ပြီး Re-dial အသစ် ပြန်လုပ်ရန် ၁၀ စက္ကန့်ခန့် ကြန့်ကြာသွားခြင်း ဖြစ်သည်။

---

## 🛡️ ငါတို့ Zin-Hy2 Version 2 စနစ်၏ အဆင့်မြှင့်တင် ဖြေရှင်းထားမှုများ

ကျွန်ုပ်တို့၏ စနစ်တွင် အထက်ပါ Issue #1365 Mobile Sleep Disconnect ပြဿနာအား အောက်ပါအတိုင်း **အဆင့်မြှင့်တင် ဖြေရှင်းထားပြီး ဖြစ်ပါသည်**:

1. **`keepAlivePeriod: 5s` (၅ စက္ကန့်တိုင်း Active PING ပို့ခြင်း)**:
   - Server Config တွင် `keepAlivePeriod: 5s` ကို မဖြစ်မနေ ထည့်သွင်းထားသဖြင့် ဖုန်းမျက်နှာပြင် ပိတ်ထားစဉ်တွင်ပင် ၅ စက္ကန့်တိုင်း Active QUIC PING Packet ကို ပို့ပေးပြီး မိုဘိုင်း CGNAT Port Mapping ကို ၂၄ နာရီပတ်လုံး အမြဲမပြတ် သက်ဝင်စေပါသည်။

2. **`maxIdleTimeout: 120s` (Hysteria 2 Core ၏ အမြင့်ဆုံး Persistent Time)**:
   - Mobile Background Push Services မျာဖြစ်သော WhatsApp, Telegram, Viber Call များနှင့် Notification များကို လိုင်းမပြုတ်ဘဲ အမြဲတမ်း ဝင်ရောက်စေရန် ၁၂၀ စက္ကန့်အထိ Persistent Time သတ်မှတ်ပေးထားပါသည်။

3. **64MB QUIC Connection Windows (`67108864`)**:
   - Mobile Cell Towers (4G/5G) သို့မဟုတ် Wi-Fi <-> Cellular ပြောင်းလဲချိန်များတွင် Data Bursts ပြတ်တောက်မှု မရှိစေရန် Receive Windows ကို 64MB အထိ အမြင့်ဆုံး မြှင့်တင်ပေးထားပါသည်။
