[◀️ ယခင်အခန်း (Previous Chapter)](01_System_Architecture_and_Databases.md) | [🏠 မာတိကာ (Main Menu)](README.md) | [▶️ နောက်တစ်ခန်း (Next Chapter)](03_Comprehensive_Security.md)

---

# Chapter 2: 🔌 API Design & Communication

Web App တွေမှာ Frontend နဲ့ Backend က ဘာသာစကားမတူပါဘူး။ နေရာလည်း မတူပါဘူး။ သူတို့နှစ်ခုကြား နားလည်အောင် စကားပြန်ပေးတာကို **API (Application Programming Interface)** လို့ ခေါ်ပါတယ်။

## ၁။ RESTful API သဘောတရား

ယနေ့ခေတ် Web App အများစုဟာ **RESTful** ဆိုတဲ့ စည်းမျဉ်းကို လိုက်နာပြီး API တွေ တည်ဆောက်ကြပါတယ်။

အဓိကအားဖြင့် **HTTP Methods (4) မျိုး** ကို သုံးပါတယ်-
- **GET:** Data ကို လှမ်းတောင်းတာ (ဖတ်ရန်သီးသန့်)။ ဥပမာ - `GET /api/users` (User စာရင်းကို ပြပါ)
- **POST:** Data အသစ်ဖန်တီးတာ။ ဥပမာ - `POST /api/users` (User အသစ် ထည့်ပါ)
- **PUT:** ရှိပြီးသား Data ကို ပြင်တာ။ ဥပမာ - `PUT /api/users/5` (ID 5 ရှိသော User ကို ပြင်ပါ)
- **DELETE:** Data ကို ဖျက်တာ။ ဥပမာ - `DELETE /api/users/5` (ID 5 ကို ဖျက်ပါ)

## ၂။ လက်တွေ့ ဥပမာ (ကျွန်တော်တို့ ပရောဂျက်မှ)

ကျွန်တော်တို့ရဲ့ Hysteria Web Panel ဘယ်လို အလုပ်လုပ်လဲ ကြည့်ရအောင်-

၁။ **Browser (Frontend):** သင်က Web Panel ထဲ ဝင်လိုက်တယ်။
၂။ **Fetch API:** Browser ကနေ နောက်ကွယ်မှာ `GET /api/users` ဆိုပြီး လှမ်းခေါ်လိုက်တယ်။
၃။ **FastAPI (Backend):** `main.py` က အဲဒီ တောင်းဆိုမှုကို လက်ခံရရှိတယ်။ သူက `database.db` ထဲမှာ User တွေကို ရှာတယ်။
၄။ **JSON Response:** Backend က ရှာတွေ့တဲ့ User တွေကို JSON (စက်တွေ နားလည်တဲ့ ဖော်မတ်) အနေနဲ့ ပြန်ပို့ပေးတယ်။
```json
{
  "users": [
    { "id": 1, "username": "zin", "data_limit_gb": 0 },
    { "id": 2, "username": "test", "data_limit_gb": 10 }
  ]
}
```
၅။ **Render (Frontend):** ပြီးမှ JavaScript က အဲဒီ JSON တွေကို ယူပြီး HTML (Card တွေ၊ ဇယားတွေ) အဖြစ် ဖန်တီးပြီး သင့်မျက်စိရှေ့ ချပြလိုက်တာပါ။

## ၃။ HTTP Status Codes ကို နားလည်ခြင်း

API တွေက စာချည်းပဲ ပြန်မပို့ပါဘူး။ သူတို့ရဲ့ အခြေအနေကို ဂဏန်းတွေ (Status Code) နဲ့ပါ ပြန်ပို့ပါတယ်။ 
ဒီကုဒ်တွေကို ကြည့်ပြီး Error ကို ရှာရပါတယ်။

- **200 OK:** အားလုံး အောင်မြင်တယ်။
- **201 Created:** အသစ်တစ်ခု အောင်မြင်စွာ ဖန်တီးပြီးပြီ (POST သုံးပြီးနောက်)။
- **400 Bad Request:** Frontend က ပို့လိုက်တဲ့ Data က မှားယွင်းနေတယ် (ဥပမာ - Password မပါတာမျိုး)။
- **401 Unauthorized:** Login မဝင်ရသေးဘူး (သို့) Password မှားနေတယ်။
- **403 Forbidden:** Login ဝင်ထားပေမယ့် အဲဒီလုပ်ဆောင်ချက်ကို လုပ်ပိုင်ခွင့် မရှိဘူး။
- **404 Not Found:** ရှာမတွေ့ဘူး။
- **500 Internal Server Error:** Backend ဆာဗာမှာ Code အမှား (Bug) ရှိနေတယ်။ 

**💡 AI ကို ခိုင်းတဲ့အခါ (Pro Tip):**
AI ကို API ရေးခိုင်းတဲ့အခါ - *"User add တဲ့ API လေး ရေးပေး"* လို့ မခိုင်းပါနဲ့။ 
*"POST /api/users ကို ရေးပေးပါ။ Payload က {username, password} ဖြစ်ရမယ်။ အောင်မြင်ရင် 201 ပြန်ပေးပြီး၊ Duplicate ဖြစ်နေရင် 400 ပြန်ပေးပါ"* လို့ အတိအကျ ခိုင်းပါ။

## ၄။ API လုံခြုံရေး (Authentication & CORS)

API တွေကို အကာအကွယ်မရှိ လွှင့်ထားလို့ မရပါဘူး။
- **CORS (Cross-Origin Resource Sharing):** သင့် API ကို တခြား Domain ကနေ လှမ်းခေါ်လို့ရမလား သတ်မှတ်တာပါ။ (ဥပမာ - `example.com` က API ကို `hacker.com` ကနေ လှမ်းခေါ်ရင် Browser က ပိတ်ချလိုက်တာမျိုးပါ)။
- **Auth Tokens:** `/api/users` ကို ခေါ်ချင်ရင် Token ပါမှ ခေါ်ခွင့်ပြုရပါမယ်။ (ကျွန်တော်တို့ ပရောဂျက်မှာ Basic Auth Token ကို Session Storage မှာ သိမ်းထားပြီး ခေါ်တိုင်း ထည့်ပို့ပေးပါတယ်)။

---
[◀️ ယခင်အခန်း (Previous Chapter)](01_System_Architecture_and_Databases.md) | [🏠 မာတိကာ (Main Menu)](README.md) | [▶️ နောက်တစ်ခန်း (Next Chapter)](03_Comprehensive_Security.md)
