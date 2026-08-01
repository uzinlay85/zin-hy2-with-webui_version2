#!/bin/bash

# Color Definitions
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

show_banner() {
    echo -e "\n${CYAN}========================================================${NC}"
    echo -e "${CYAN}🔍 Hysteria 2 & Web Panel Diagnostic & Check Tool${NC}"
    echo -e "${CYAN}========================================================${NC}"
}

check_hysteria() {
    echo -e "\n${YELLOW}=== ၁။ Hysteria 2 Config ဖိုင် အခြေအနေ ===${NC}"
    if [ -f /etc/hysteria/config.yaml ]; then
        cat /etc/hysteria/config.yaml
    else
        echo -e "${RED}Config ဖိုင်ကို /etc/hysteria/config.yaml တွင် မတွေ့ပါ။${NC}"
    fi

    echo -e "\n${YELLOW}=== ၂။ Hysteria 2 Service အလုပ်လုပ်/မလုပ် ===${NC}"
    systemctl status hysteria-server --no-pager 2>/dev/null || echo -e "${RED}Hysteria Service ကို ရှာမတွေ့ပါ။${NC}"
}

check_panel() {
    echo -e "\n${YELLOW}=== Web Panel (FastAPI) Service & Database အခြေအနေ ===${NC}"
    systemctl status hy2-panel --no-pager 2>/dev/null || echo -e "${RED}Web Panel Service ကို ရှာမတွေ့ပါ။${NC}"
    
    if [ -f /opt/hy2-panel/database.db ]; then
        echo -e "\n${GREEN}=== SQLite Database Status ===${NC}"
        sqlite3 /opt/hy2-panel/database.db "SELECT count(*) FROM users WHERE role != 'admin';" 2>/dev/null | xargs -I {} echo "Total Users in DB: {}"
    fi
}

check_network() {
    echo -e "\n${YELLOW}=== UDP Port Hopping & Sysctl Buffer အခြေအနေ ===${NC}"
    echo -e "${GREEN}--- UFW Status ---${NC}"
    ufw status 2>/dev/null || echo "UFW မသုံးထားပါ။"
    
    echo -e "\n${GREEN}--- iptables Port Hopping Rules ---${NC}"
    iptables -t nat -L PREROUTING -n -v | grep -E "20000|50000|443" || echo -e "${RED}Port Hopping အတွက် iptables rule မတွေ့ပါ။${NC}"
    
    echo -e "\n${GREEN}--- Linux Sysctl Buffer Settings ---${NC}"
    sysctl net.core.rmem_max net.core.wmem_max net.ipv4.tcp_congestion_control 2>/dev/null
}

check_online() {
    echo -e "\n${YELLOW}=== လက်ရှိ ချိတ်ဆက်နေသော Online Users အခြေအနေ ===${NC}"
    curl -s http://127.0.0.1:8080/online 2>/dev/null | python3 -m json.tool 2>/dev/null || echo -e "${RED}Online Traffic Stats API သို့ လှမ်းယူ၍ မရပါ။${NC}"
}

check_logs() {
    echo -e "\n${YELLOW}=== Hysteria 2 နောက်ဆုံး Error Logs (၁၀ ကြောင်း) ===${NC}"
    journalctl -u hysteria-server -n 10 --no-pager 2>/dev/null || echo -e "${RED}Hysteria Log မတွေ့ပါ။${NC}"
    
    echo -e "\n${YELLOW}=== Web Panel နောက်ဆုံး Error Logs (၁၀ ကြောင်း) ===${NC}"
    journalctl -u hy2-panel -n 10 --no-pager 2>/dev/null || echo -e "${RED}Panel Log မတွေ့ပါ။${NC}"
}

check_ssl() {
    echo -e "\n${YELLOW}=== SSL Certificate အခြေအနေ ===${NC}"
    certbot certificates 2>/dev/null || echo -e "${RED}Certbot မတွေ့ပါ။${NC}"
}

full_diagnostic() {
    show_banner
    check_hysteria
    check_panel
    check_network
    check_online
    check_logs
    check_ssl
    echo -e "\n${GREEN}========================================================${NC}"
    echo -e "${GREEN}✅ စစ်ဆေးမှု အားလုံး ပြီးဆုံးပါပြီ${NC}"
    echo -e "${GREEN}========================================================${NC}\n"
}

# If stdin is not a tty or passed --all, run full diagnostic automatically
if [ ! -t 0 ] && [ ! -c /dev/tty ] || [ "$1" == "--all" ] || [ "$1" == "-a" ]; then
    full_diagnostic
    exit 0
fi

# Interactive Menu mode
while true; do
    show_banner
    echo -e "${GREEN}၁)${NC} Full System Diagnostic (စနစ်တစ်ခုလုံး အစအဆုံး စစ်မည်)"
    echo -e "${GREEN}၂)${NC} Hysteria 2 Config & Service အခြေအနေ စစ်မည်"
    echo -e "${GREEN}၃)${NC} Web Panel (FastAPI) Service & Database စစ်မည်"
    echo -e "${GREEN}၄)${NC} Port Hopping NAT & Sysctl Buffer Settings စစ်မည်"
    echo -e "${GREEN}၅)${NC} Online Users & Real-time Traffic စစ်မည်"
    echo -e "${GREEN}၆)${NC} Error Logs (Hysteria & Web Panel) ကြည့်မည်"
    echo -e "${GREEN}၇)${NC} SSL Certificate သက်တမ်း စစ်မည်"
    echo -e "${GREEN}၈)${NC} Exit (ထွက်မည်)"
    echo -e "${CYAN}========================================================${NC}"
    
    read -p "ရွေးချယ်ရန် နံပါတ်နှိပ်ပါ [1-8]: " choice < /dev/tty
    
    case $choice in
        1) full_diagnostic ;;
        2) check_hysteria ;;
        3) check_panel ;;
        4) check_network ;;
        5) check_online ;;
        6) check_logs ;;
        7) check_ssl ;;
        8) echo -e "\n${GREEN}Bye!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}မှားယွင်းသော ရွေးချယ်မှုဖြစ်သည်!${NC}" ;;
    esac
done
