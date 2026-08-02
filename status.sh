#!/bin/bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

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
    echo -e "\n${YELLOW}=== 1. Hysteria 2 Config (ဖိုင် အခြေအနေ) ===${NC}"
    if [ -f /etc/hysteria/config.yaml ]; then
        cat /etc/hysteria/config.yaml
    else
        echo -e "${RED}Config ဖိုင်ကို /etc/hysteria/config.yaml တွင် မတွေ့ပါ။${NC}"
    fi

    echo -e "\n${YELLOW}=== 2. Hysteria 2 Service (အလုပ်လုပ်/မလုပ်) ===${NC}"
    systemctl status hysteria-server --no-pager 2>/dev/null || echo -e "${RED}Hysteria Service ကို ရှာမတွေ့ပါ။${NC}"
}

check_panel() {
    echo -e "\n${YELLOW}=== 3. Web Panel Service & Database (အခြေအနေ) ===${NC}"
    systemctl status hy2-panel --no-pager 2>/dev/null || echo -e "${RED}Web Panel Service ကို ရှာမတွေ့ပါ။${NC}"
    
    echo -e "\n${GREEN}--- Nginx Reverse Proxy Status ---${NC}"
    systemctl status nginx --no-pager 2>/dev/null || echo -e "${RED}Nginx Service ကို ရှာမတွေ့ပါ။${NC}"
    
    if [ -f /opt/hy2-panel/database.db ]; then
        echo -e "\n${GREEN}=== SQLite Database Status ===${NC}"
        sqlite3 /opt/hy2-panel/database.db "SELECT count(*) FROM users WHERE role != 'admin';" 2>/dev/null | xargs -I {} echo "Total Users in DB: {}"
    fi
}

check_network() {
    echo -e "\n${YELLOW}=== 4. UDP Port Hopping & Sysctl Buffers (အခြေအနေ) ===${NC}"
    echo -e "${GREEN}--- UFW Status ---${NC}"
    ufw status 2>/dev/null || echo "UFW မသုံးထားပါ။"
    
    echo -e "\n${GREEN}--- iptables Port Hopping Rules ---${NC}"
    iptables -t nat -L PREROUTING -n -v | grep -E "20000|50000|443" || echo -e "${RED}Port Hopping အတွက် iptables rule မတွေ့ပါ။${NC}"
    
    echo -e "\n${GREEN}--- Linux Sysctl Buffer Settings ---${NC}"
    sysctl net.core.rmem_max net.core.wmem_max net.ipv4.tcp_congestion_control 2>/dev/null
}

check_online() {
    echo -e "\n${YELLOW}=== 5. Online Users (လက်ရှိ ချိတ်ဆက်သူများ) ===${NC}"
    curl -s http://127.0.0.1:8080/online 2>/dev/null | python3 -m json.tool 2>/dev/null || echo -e "${RED}Online Traffic Stats API သို့ လှမ်းယူ၍ မရပါ။${NC}"
}

check_logs() {
    echo -e "\n${YELLOW}=== 6. Hysteria 2 Error Logs (နောက်ဆုံး ၁၀ ကြောင်း) ===${NC}"
    journalctl -u hysteria-server -n 10 --no-pager 2>/dev/null || echo -e "${RED}Hysteria Log မတွေ့ပါ။${NC}"
    
    echo -e "\n${YELLOW}=== Web Panel Error Logs (နောက်ဆုံး ၁၀ ကြောင်း) ===${NC}"
    journalctl -u hy2-panel -n 10 --no-pager 2>/dev/null || echo -e "${RED}Panel Log မတွေ့ပါ။${NC}"
}

check_ssl() {
    echo -e "\n${YELLOW}=== SSL Certificate အခြေအနေ ===${NC}"
    certbot certificates 2>/dev/null || echo -e "${RED}Certbot မတွေ့ပါ။${NC}"
}

check_system_resources() {
    echo -e "\n${YELLOW}=== ၇။ System Resources Summary (CPU / RAM / Disk) ===${NC}"
    echo -e "${GREEN}--- System Load Average ---${NC}"
    uptime | awk -F'load average:' '{printf "  Load Average:%s\n", $2}' 2>/dev/null
    
    echo -e "\n${GREEN}--- RAM (Memory) Usage ---${NC}"
    free -m | awk '/Mem:/ {printf "  RAM Used: %d MB / %d MB (%.1f%% used)\n", $3, $2, $3/$2*100}' 2>/dev/null
    
    echo -e "\n${GREEN}--- Disk Storage Usage ---${NC}"
    df -h / | awk 'NR==2 {printf "  Disk Used: %s / %s (%s used)\n", $3, $2, $5}' 2>/dev/null
    
    echo -e "\n${GREEN}--- Core Process Resource Usage ---${NC}"
    ps aux | grep -E "hysteria|uvicorn" | grep -v grep | awk '{printf "  • %-15s (PID: %-6s | CPU: %-4s%% | RAM: %d MB)\n", $11, $2, $3, int($6/1024)}' 2>/dev/null
}

show_btop() {
    if command -v btop &> /dev/null; then
        btop
    elif command -v htop &> /dev/null; then
        htop
    else
        echo -e "\n${YELLOW}=== btop Monitor ကို သွင်းယူနေပါသည်... ===${NC}"
        apt-get update && apt-get install btop -y
        btop 2>/dev/null || htop
    fi
}

reset_admin_pass() {
    echo -e "\n${YELLOW}=== Web Panel Admin Password အသစ် သတ်မှတ်ခြင်း ===${NC}"
    read -p "Admin Password အသစ် ရိုက်ထည့်ပါ: " NEW_PASS < /dev/tty
    if [ -n "$NEW_PASS" ] && [ -f /opt/hy2-panel/database.db ]; then
        /opt/hy2-panel/venv/bin/python3 -c "
import sqlite3, bcrypt
conn = sqlite3.connect('/opt/hy2-panel/database.db')
c = conn.cursor()
hashed = bcrypt.hashpw('''$NEW_PASS'''.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
c.execute(\"DELETE FROM users WHERE role='admin'\")
c.execute(\"INSERT INTO users (username, password, role) VALUES ('admin', ?, 'admin')\", (hashed,))
conn.commit()
conn.close()
"
        systemctl restart hy2-panel.service
        echo -e "\n${GREEN}✅ Admin Password ကို '$NEW_PASS' သို့ အောင်မြင်စွာ ပြောင်းလဲလိုက်ပါပြီ!${NC}\n"
    else
        echo -e "\n${RED}မှားယွင်းသော Password ဖြစ်ပါသည်။${NC}\n"
    fi
}

do_update() {
    echo -e "\n${YELLOW}=== စနစ်တစ်ခုလုံးကို အလိုအလျောက် Update ပြုလုပ်နေပါသည်... ===${NC}"
    if [ -f /opt/hy2-panel/auto_update.sh ]; then
        bash /opt/hy2-panel/auto_update.sh
    else
        bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/auto_update.sh)
    fi
}

full_diagnostic() {
    show_banner
    check_hysteria
    check_panel
    check_network
    check_online
    check_logs
    check_ssl
    check_system_resources
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
    echo -e "${GREEN}၈)${NC} Live System Resource Monitor (btop ဖြင့် CPU/RAM/Network ကြည့်မည်)"
    echo -e "${GREEN}၉)${NC} Web Panel Admin Password အသစ် ပြောင်းမည်"
    echo -e "${GREEN}၁၀)${NC} Auto-Update System (စနစ်တစ်ခုလုံးကို အလိုအလျောက် Update ပြုလုပ်မည်)"
    echo -e "${GREEN}၁၁)${NC} Exit (ထွက်မည်)"
    echo -e "${CYAN}========================================================${NC}"
    
    read -p "ရွေးချယ်ရန် နံပါတ်နှိပ်ပါ [1-11]: " choice < /dev/tty
    
    case $choice in
        1) full_diagnostic ;;
        2) check_hysteria ;;
        3) check_panel ;;
        4) check_network ;;
        5) check_online ;;
        6) check_logs ;;
        7) check_ssl ;;
        8) show_btop ;;
        9) reset_admin_pass ;;
        10) do_update ;;
        11) echo -e "\n${GREEN}Bye!${NC}\n"; exit 0 ;;
        *) echo -e "\n${RED}မှားယွင်းသော ရွေးချယ်မှုဖြစ်သည်!${NC}" ;;
    esac
done
