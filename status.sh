#!/bin/bash

echo -e "\n\033[1;36m========================================================\033[0m"
echo -e "\033[1;36m🔍 Hysteria 2 & Web Panel Diagnostic Tool\033[0m"
echo -e "\033[1;36m========================================================\033[0m"

echo -e "\n\033[1;33m=== ၁။ Hysteria 2 Config ဖိုင် အခြေအနေ ===\033[0m"
if [ -f /etc/hysteria/config.yaml ]; then
    cat /etc/hysteria/config.yaml
else
    echo -e "\033[1;31mConfig ဖိုင်ကို ပုံမှန်လမ်းကြောင်းများတွင် မတွေ့ပါ။\033[0m"
fi

echo -e "\n\033[1;33m=== ၂။ Hysteria 2 Service အလုပ်လုပ်/မလုပ် ===\033[0m"
systemctl status hysteria-server --no-pager 2>/dev/null || echo -e "\033[1;31mHysteria Service ကို ရှာမတွေ့ပါ။\033[0m"

echo -e "\n\033[1;33m=== ၃။ Web Panel (FastAPI) Service အလုပ်လုပ်/မလုပ် ===\033[0m"
systemctl status hy2-panel --no-pager 2>/dev/null || echo -e "\033[1;31mWeb Panel Service ကို ရှာမတွေ့ပါ။\033[0m"

echo -e "\n\033[1;33m=== ၄။ Firewall နှင့် Port များ အခြေအနေ ===\033[0m"
echo -e "\033[1;32m--- UFW Status ---\033[0m"
ufw status 2>/dev/null || echo "UFW မသုံးထားပါ။"
echo -e "\n\033[1;32m--- iptables Port Hopping Rules ---\033[0m"
iptables -t nat -L PREROUTING -n -v | grep -E "20000|50000|443" || echo -e "\033[1;31mPort Hopping အတွက် iptables rule မတွေ့ပါ။\033[0m"

echo -e "\n\033[1;33m=== ၅။ Hysteria 2 နောက်ဆုံး Error Logs များ (စာကြောင်း ၁၀ ကြောင်း) ===\033[0m"
journalctl -u hysteria-server -n 10 --no-pager 2>/dev/null || echo -e "\033[1;31mLog မှတ်တမ်းများ မတွေ့ပါ။\033[0m"

echo -e "\n\033[1;33m=== ၆။ Web Panel နောက်ဆုံး Error Logs များ (စာကြောင်း ၁၀ ကြောင်း) ===\033[0m"
journalctl -u hy2-panel -n 10 --no-pager 2>/dev/null || echo -e "\033[1;31mLog မှတ်တမ်းများ မတွေ့ပါ။\033[0m"

echo -e "\n\033[1;32m========================================================\033[0m"
echo -e "\033[1;32m✅ စစ်ဆေးမှု ပြီးဆုံးပါပြီ\033[0m"
echo -e "\033[1;32m========================================================\033[0m\n"
