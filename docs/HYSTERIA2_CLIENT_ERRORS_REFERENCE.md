# Hysteria 2 Client Troubleshooting & Error Code Reference

> **မှတ်ချက်:** ဤ စာရွက်စာတမ်းသည် Hysteria 2 Client App များ (NekoBox, Hiddify, V2rayN, Sing-Box, SagerNet) တွင် တွေ့ရှိရလေ့ရှိသော Error Code များနှင့် ၎င်းတို့အား ဖြေရှင်းရန် Official Fix များ၏ နည်းပညာ အကိုးအကား ဖြစ်ပါသည်။

---

## 🔍 Hysteria 2 Client Error Codes & Solutions

### 1. `[FATA] Out of retries, exiting…` / `libhysteria exits too fast (exit code: 1)`
- **အကြောင်းရင်း**: Client မှ Hysteria Server သို့ ချိတ်ဆက်ရန် ကြိုးပမ်းမှု အကြိမ်အရေအတွက် ပြည့်သွားသော်လည်း Handshake မအောင်မြင်၍ App ပိတ်သွားခြင်း ဖြစ်သည်။
- **ဖြေရှင်းနည်း**: ၎င်း Error ၏ အထက်တွင် ရှိသော ရှေ့မှ Log ကြောင်းများကို စစ်ဆေးပါ။

---

### 2. `[ERRO] [error:timeout: no recent network activity]`
- **အကြောင်းရင်း**: Client နှင့် Server အကြား UDP Connection မပေါက်ဘဲ အချိန်ကျော်သွားခြင်း (Timeout ဖြစ်ခြင်း)။
  - ISP မှ UDP Traffic ကို ပိတ်ဆို့ထားခြင်း သို့မဟုတ် သတ်မှတ်ထားသော Port အား Firewall မှ ပိတ်ထားခြင်း။
  - Server IP/Port သို့မဟုတ် Obfs Parameter မကိုက်ညီခြင်း။
- **ငါတို့စနစ်၏ ဖြေရှင်းထားမှု**:
  - UDP Port Hopping (`mport=20000-50000`) ဖြင့် ISP Port Block ကို ကျော်ဖြတ်ထားသည်။
  - 64MB UDP Buffer Size နှင့် BBR Congestion Control ဖြင့် Packet Loss ကို ကာကွယ်ထားသည်။

---

### 3. `[ERRO] [error:Application error 0x1: protocol error]`
- **အကြောင်းရင်း**: Client ၏ Protocol Version နှင့် Server ၏ Version မကိုက်ညီခြင်း (ဥပမာ - Hysteria 1 Client ဖြင့် Hysteria 2 Server သို့ ချိတ်မိခြင်း)။
- **ဖြေရှင်းနည်း**: Client အက်ပ်တွင် Protocol ကို `hysteria2://` သို့မဟုတ် Hysteria 2 V2 Core ဖြစ်ကြောင်း သေချာပါစေ။

---

### 4. `[ERRO] [error:Application error 0x2: auth error]`
- **အကြောင်းရင်း**: Client တွင် ထည့်သွင်းထားသော Password မှားယွင်းနေသဖြင့် Server မှ Authentication ကို ငြင်းပယ်လိုက်ခြင်း။
- **ဖြေရှင်းနည်း**: Web Panel မှ ထုတ်ပေးသော Link ထဲရှိ Password (Auth key) မှန်မမှန် စစ်ဆေးပါ။

---

### 5. `[FATA] [file:./config.json] [error:illegal base64 data at input byte 8]`
- **အကြောင်းရင်း**: Client Config တွင် `auth` field ကို ရိုးရိုး String မဟုတ်ဘဲ Base64 Format လွဲမှားစွာ သုံးမိခြင်း။
- **ဖြေရှင်းနည်း**: Client Config တွင် `auth` အစား `auth_str` သို့မဟုတ် Standard `hysteria2://` URI Format ကို သုံးပါ။

---

### 6. `[ERRO] [error:CRYPTO_ERROR (0x12a): x509: certificate signed by unknown authority]`
- **အကြောင်းရင်း**: Server မှ ပေးပို့သော SSL Certificate ကို Client မှ ယုံကြည်စိတ်ချရသော CA Certificate မဟုတ်ဟု ယူဆ၍ ငြင်းပယ်ခြင်း။
- **ငါတို့စနစ်၏ ဖြေရှင်းထားမှု**:
  - Let's Encrypt ၏ တရားဝင် Fullchain CA Certificate (`fullchain.pem`) ကို သုံးစွဲထားသည်။
  - URI Link ထဲတွင် `insecure=0` အတိအလင်း ထည့်ပေးထားသဖြင့် Client များတွင် TLS Certificate Verification ကို အဆင်ပြေစွာ အတည်ပြုနိုင်သည်။

---

### 7. `[ERRO] [error:CRYPTO_ERROR (0x178): tls: no application protocol]`
- **အကြောင်းရင်း**: Client နှင့် Server အကြား ALPN (Application-Layer Protocol Negotiation) Parameter မကိုက်ညီခြင်း။

---

### 8. `[ERRO] [error:CRYPTO_ERROR (0x12a): x509: certificate is valid for A, not B]`
- **အကြောင်းရင်း**: Client တွင် ထည့်သွင်းထားသော `server_name` သို့မဟုတ် `sni` Domain သည် Server SSL Certificate ၏ Domain Name နှင့် မကိုက်ညီခြင်း။
- **ငါတို့စနစ်၏ ဖြေရှင်းထားမှု**:
  - Web Panel မှ ထုတ်ပေးသော URI Link ထဲတွင် `sni=${domain}` ကို အလိုအလျောက် ၁:၁ တိကျစွာ ထည့်ပေးထားသဖြင့် ဤ Error ကို ၁၀၀% ကာကွယ်ထားပြီး ဖြစ်သည်။
