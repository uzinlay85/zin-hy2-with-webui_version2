# Hysteria 2 Log Interpretation & Troubleshooting Guide

> **မှတ်ချက်:** ဤ စာရွက်စာတမ်းသည် Hysteria 2 Server Log များ (`journalctl -u hysteria-server`) နှင့် Web Panel Log များကို မှန်ကန်စွာ ဖတ်ရှုဆန်းစစ်ရန် နည်းပညာ လမ်းညွှန် ဖြစ်ပါသည်။

---

## 🔍 Log Line အဓိပ္ပါယ်များ ဆန်းစစ်ချက်

### 1. `client connected {"addr": "37.111.41.0:51375", "id": "me_new_us_02", "tx": 0}`
- **အဓိပ္ပါယ်**: Client မှ Hysteria Server သို့ Incoming QUIC Connection အသစ် ချိတ်ဆက်မှု အောင်မြင်စွာ စတင်လိုက်ခြင်း ဖြစ်သည်။
- **ဆန်းစစ်နည်း**:
  - `id`: User နာမည် (အကောင့်အမည်) ဖြစ်သည်။
  - `addr`: Client ၏ ဖုန်း သို့မဟုတ် မိုဘိုင်းလိုင်းမှ ထွက်လာသော Public IP နှင့် Dynamic Port ဖြစ်သည်။

### 2. `client disconnected {"addr": "...", "id": "...", "error": "..."}`
- **အဓိပ္ပါယ်**: User လိုင်းပိတ်လိုက်ခြင်း၊ ဖုန်း Screen ပိတ်သွားခြင်း သို့မဟုတ် Cellular Tower ချိန်းသွားသဖြင့် QUIC Stream ပိတ်သွားခြင်း ဖြစ်သည်။

---

## 🛠️ Log များကို စစ်ဆေးရာတွင် ဆောင်ရွက်ရန် အကောင်းဆုံး နည်းလမ်းများ

1. **Hysteria Log နှင့် Web Panel Auth Log များကို ယှဉ်တွဲ စစ်ဆေးခြင်း**:
   - `hy2` Check Tool ၏ **`Option 6 (Error Logs)`** ကို သုံး၍ Hysteria Server Log တွင် `client connected` တွေ့ချိန်၌ Web Panel Log တွင် `/auth` သို့ `200 OK` ပြန်မပြန် ယှဉ်တွဲ ကြည့်ရှုပါ။

2. **Public Domain & IP Reachability စစ်ဆေးခြင်း**:
   - Client App များ (NekoBox, Hiddify, V2rayN) တွင် ထည့်သွင်းထားသော Server Address သည် Public Domain (`hostvds-hy2.truehand.top`) အစစ်အမှန် ဖြစ်ကြောင်း သေချာပါစေ။

3. **Firewall & Port Hopping Rule များ စစ်ဆေးခြင်း**:
   - `hy2` ၏ **`Option 4`** ကို သုံး၍ UFW Firewall တွင် Port 443/udp နှင့် 20000:50000/udp ဖွင့်ထားခြင်း ရှိမရှိ စစ်ဆေးပါ။
