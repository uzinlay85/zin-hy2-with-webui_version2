#!/bin/bash

echo "========================================"
echo "🔧 Hysteria 2 Config Fix - Remove obfs"
echo "========================================"

if [ "$EUID" -ne 0 ]; then
    echo "Error: root user ဖြင့်သာ run ရပါမည်။"
    exit 1
fi

CONFIG="/etc/hysteria/config.yaml"

if [ ! -f "$CONFIG" ]; then
    echo "Error: $CONFIG မတွေ့ဘူး!"
    exit 1
fi

# Backup
cp "$CONFIG" "$CONFIG.bak"
echo "✅ Backup saved: $CONFIG.bak"

# Remove obfs block
python3 -c "
import re
content = open('$CONFIG').read()
# Remove obfs block (all variations)
content = re.sub(r'obfs:\n  type: salamander\n  salamander:\n    password: \".*?\"\n\n', '', content)
content = re.sub(r'obfs:\n  type: salamander\n  salamander:\n    password: .*?\n\n', '', content)
open('$CONFIG', 'w').write(content)
print('obfs removed!')
"

# Verify
echo ""
echo "📋 Config after fix:"
cat "$CONFIG"

echo ""
if grep -q "obfs" "$CONFIG"; then
    echo "⚠️  obfs ဆိုတာ ကျန်နေသေးတယ် - manual ပြင်ပါ"
else
    echo "✅ obfs ဖြုတ်ပြီးပြီ!"
fi

# Restart hysteria
echo ""
echo "🔄 Restarting hysteria-server..."
systemctl restart hysteria-server.service
sleep 2
systemctl status hysteria-server.service --no-pager | head -15

echo ""
echo "========================================"
echo "✅ Done! App အားလုံးမှာ key ထည့်လို့ရပြီ"
echo "========================================"
