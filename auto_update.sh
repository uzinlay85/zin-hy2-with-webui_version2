#!/bin/bash

# ========================================================
# 🚀 Hysteria 2 & Web Panel - Manual Update Script
# ========================================================
# ဤ Script သည် ဆာဗာရှိ စနစ်များကို နောက်ဆုံးပေါ်ဖြစ်စေရန် အလိုအလျောက် Update ပြုလုပ်ပေးပါသည်။
# လိုအပ်သော အချိန်တိုင်း "bash auto_update.sh" ဟု Run ၍ အသုံးပြုနိုင်ပါသည်။

echo "========================================================"
echo "🔄 Starting System & Panel Update Process..."
echo "========================================================"

# Root user စစ်ဆေးခြင်း
if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။ (sudo su ဝင်ရောက်ပြီးမှ ပြန်လည် run ပါ)"
    exit 1
fi

# ==========================================
# 1. OS Security & System Updates
# ==========================================
echo -e "\n[1/3] Checking OS Security & Package Updates..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
echo "✅ OS packages updated successfully."

# ==========================================
# 2. Hysteria 2 Core Update
# ==========================================
echo -e "\n[2/3] Checking Hysteria 2 Core Updates..."

# လက်ရှိ version စစ်ဆေးခြင်း
if [ -f "/usr/local/bin/hysteria" ]; then
    LOCAL_VERSION=$(/usr/local/bin/hysteria version | head -n 1 | awk '{print $3}')
else
    LOCAL_VERSION="none"
fi

# Github မှ နောက်ဆုံးထွက် version ကို ရယူခြင်း
LATEST_VERSION=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_VERSION" ]; then
    echo "⚠️ Failed to fetch the latest Hysteria 2 version from GitHub. Skipping..."
else
    if [ "$LOCAL_VERSION" != "$LATEST_VERSION" ]; then
        echo "⬇️ New version found! Updating Hysteria 2 from $LOCAL_VERSION to $LATEST_VERSION..."
        
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            HY2_ARCH="amd64"
        elif [ "$ARCH" = "aarch64" ]; then
            HY2_ARCH="arm64"
        else
            echo "⚠️ Unsupported architecture: $ARCH. Skipping Hysteria 2 update."
            HY2_ARCH=""
        fi

        if [ -n "$HY2_ARCH" ]; then
            systemctl stop hysteria-server.service
            wget -qO /usr/local/bin/hysteria "https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-${HY2_ARCH}"
            chmod +x /usr/local/bin/hysteria
            systemctl start hysteria-server.service
            echo "✅ Hysteria 2 successfully updated to $LATEST_VERSION."
        fi
    else
        echo "✅ Hysteria 2 is already up-to-date ($LOCAL_VERSION)."
    fi
fi

# ==========================================
# 3. Web Panel & Python Libraries Update
# ==========================================
echo -e "\n[3/3] Checking Web Panel & Python Library Updates..."

PANEL_DIR="/opt/hy2-panel"

if [ -d "$PANEL_DIR" ]; then
    cd "$PANEL_DIR" || exit

    # GitHub မှ Web Panel Code အသစ်များ ဆွဲယူခြင်း
    echo "⬇️ Pulling latest Web Panel code from GitHub..."
    git checkout -- static/index.html 2>/dev/null # Discard any uncommitted frontend changes if existed to prevent conflicts
    git pull origin main

    # Python Library များ အသစ်ထွက်ပါက အလိုအလျောက် သွင်းယူခြင်း
    if [ -d "venv" ]; then
        echo "📦 Updating Python libraries (if any)..."
        source venv/bin/activate
        pip install --upgrade -r requirements.txt
        deactivate
    else
        echo "⚠️ Python venv not found. Skipping library updates."
    fi

    # Web Panel ကို Restart ချခြင်း
    echo "🔄 Restarting Web Panel service..."
    systemctl restart hy2-panel.service
    echo "✅ Web Panel updated successfully."

    # Create/update CLI command shortcut 'hy2'
    cat > /usr/local/bin/hy2 << 'EOF_HY2_CLI'
#!/bin/bash
if [ -f /opt/hy2-panel/status.sh ]; then
    bash /opt/hy2-panel/status.sh "$@"
else
    bash <(curl -fsSL https://raw.githubusercontent.com/uzinlay85/zin-hy2-with-webui_version2/main/status.sh) "$@"
fi
EOF_HY2_CLI
    chmod +x /usr/local/bin/hy2
else
    echo "⚠️ Web Panel directory ($PANEL_DIR) not found. Skipping..."
fi

echo -e "\n========================================================"
echo "🎉 All Updates Completed Successfully!"
echo "Browser တွင် Panel သို့ ဝင်ရောက်၍ Ctrl + F5 နှိပ်ကာ အသစ်ပြန်လည် အသုံးပြုနိုင်ပါပြီ။"
echo "========================================================"
