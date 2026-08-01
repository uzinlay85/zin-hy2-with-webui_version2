# Hysteria 2 GitHub Issue #1251 Technical Study & Prevention Analysis

> **ပြဿနာ ခဲယဉ်းမှု:** GitHub Issue #1251 - "connect error: timeout: no recent network activity"
> **ဖြစ်စဉ်:** User သည် Hysteria 2 ကို ACME (Auto TLS) ဖြင့် `:8443` port တွင် တည်ဆောက်ခဲ့ရာ ၃ ရက်တိုင်တိုင် Connection Timeout ဖြစ်ပြီး ၃ ရက်မြောက်မှ အလိုအလျောက် ရုတ်တရက် အဆင်ပြေသွားသည့် ဖြစ်စဉ်။

---

## 🔍 Root Cause Analysis (အကြောင်းရင်း အသေးစိတ် ဆန်းစစ်ချက်)

### ၁။ Hysteria Built-in ACME Certificate ထုတ်ယူမှု ကြန့်ကြာခြင်း
- `config.yaml` တွင် `acme:` (Let's Encrypt) ဖြင့် တိုက်ရိုက် သုံးထားသဖြင့် Hysteria Core စတင်ချိန်တွင် Domain ၏ DNS Propagation သို့မဟုတ် Port 80 Challenge အချိန်မီ မပြီးသေးဘဲ SSL Certificate မထွက်မီ လိုင်းချိတ်ဆက်ရန် ကြိုးစားမှုများ Timeout ဖြစ်သွားခြင်း။
- DNS propagation ပြည့်စုံသွားသည့် ၃ ရက်မြောက်တွင်မှ Let's Encrypt Certificate အပြည့်အဝ ထွက်ရှိလာပြီး ချိတ်ဆက်မှု အဆင်ပြေသွားခြင်း ဖြစ်သည်။

### ၂။ Non-Standard Port (:8443) တွင် UDP Filter ထိခြင်း
- Custom UDP Port `:8443` ကို သုံးစွဲထားသဖြင့် VPS Provider Firewall (Huawei Cloud / Alibaba Cloud / AWS) ၏ Security Group မှ UDP Traffic ကို Block လုပ်ထားခြင်း သို့မဟုတ် ISP မှ Port Filter လုပ်ထားခြင်း။

---

## 🛡️ ငါတို့ Zin-Hy2 Version 2 စနစ်၏ ကြိုတင် ကာကွယ်ထားမှုများ

ကျွန်ုပ်တို့ စနစ်တွင် အထက်ပါ Issue #1251 ပြဿနာမျိုး **လုံးဝ (လုံးဝ) မဖြစ်ပွားစေရန် အောက်ပါအတိုင်း အဆင့်မြင့် စီမံထားပါသည်**:

1. **Certbot Standalone Certificate Management**:
   - Hysteria Core ၏ Built-in ACME ကို အားမကိုးဘဲ တရားဝင် `certbot` ဖြင့် စနစ်မစတင်မီ SSL Fullchain Certificate (`fullchain.pem`) ကို အပြည့်အဝ ထုတ်ယူပြီးမှသာ Hysteria Server ကို မောင်းနှင်ပါသည်။ (ACME Pending ကြောင့် Timeout ဖြစ်ခြင်း လုံးဝ မရှိပါ)။

2. **Standard Port 443 + Kernel UDP Port Hopping**:
   - Standard UDP Port `:443` တွင် ငြိမ်သက်စွာ ဖွင့်လှစ်ထားပြီး Kernel `iptables REDIRECT` ဖြင့် Port Hopping (`20000-50000`) ပြုလုပ်ထားသဖြင့် Provider Security Group နှင့် ISP UDP Blocking များကို ၁၀၀% ကြိုတင် ကျော်ဖြတ်ထားပါသည်။
