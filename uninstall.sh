#!/bin/bash
# Joplin MCP Uninstaller

INSTALL_DIR="$HOME/.joplin-mcp"
CONFIG_DIR="$HOME/.config/opencode"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "  Joplin MCP Uninstaller"
echo "========================================"
echo ""

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}⚠${NC} Joplin MCP does not appear to be installed in $INSTALL_DIR"
    exit 0
fi

echo "Will be removed:"
echo "  - Directory: $INSTALL_DIR"
echo "  - Configuration at: $CONFIG_DIR/opencode.json or $CONFIG_DIR/opencode.jsonc"
echo ""

read -p "Continue? (y/n): " confirm
if [ "$confirm" != "y" ]; then
    echo "Cancelled"
    exit 0
fi

# Backup before removal
backup_dir="$HOME/.joplin-mcp-backup-$(date +%Y%m%d_%H%M%S)"
if [ -d "$INSTALL_DIR" ]; then
    cp -r "$INSTALL_DIR" "$backup_dir"
    echo -e "${GREEN}✓${NC} Backup created: $backup_dir"
fi

# Remove from OpenCode config
if [ -f "$CONFIG_DIR/opencode.jsonc" ]; then
    echo "Updating OpenCode configuration..."
    
    CONFIG_FILE="$CONFIG_DIR/opencode.jsonc" python3 <<'EOF'
import json
import os
import sys
import re

config_file = os.environ['CONFIG_FILE']

def strip_jsonc(text):
    cleaned = []
    in_string = False
    escape = False
    i = 0

    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ''

        if in_string:
            cleaned.append(ch)
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            cleaned.append(ch)
            i += 1
            continue

        if ch == '/' and nxt == '/':
            i += 2
            while i < len(text) and text[i] not in '\r\n':
                i += 1
            continue

        if ch == '/' and nxt == '*':
            i += 2
            while i + 1 < len(text) and text[i:i + 2] != '*/':
                i += 1
            i += 2
            continue

        cleaned.append(ch)
        i += 1

    text = ''.join(cleaned)
    cleaned = []
    in_string = False
    escape = False
    i = 0

    while i < len(text):
        ch = text[i]

        if in_string:
            cleaned.append(ch)
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            cleaned.append(ch)
            i += 1
            continue

        if ch == ',':
            j = i + 1
            while j < len(text) and text[j].isspace():
                j += 1
            if j < len(text) and text[j] in '}]':
                i += 1
                continue

        cleaned.append(ch)
        i += 1

    return ''.join(cleaned)

try:
    with open(config_file, 'r', encoding='utf-8') as f:
        raw = f.read()

    try:
        config = json.loads(raw)
    except json.JSONDecodeError:
        config = json.loads(strip_jsonc(raw))
    
    if 'mcp' in config and 'joplin_mcp' in config['mcp']:
        del config['mcp']['joplin_mcp']
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
            f.write("\n")
        print("✓ Joplin configuration removed from opencode.jsonc")
    else:
        print("ℹ Joplin configuration not found")
        
except Exception as e:
    print(f"⚠ Error updating opencode.jsonc: {e}", file=sys.stderr)
    sys.exit(1)
EOF
elif [ -f "$CONFIG_DIR/opencode.json" ]; then
    echo "Updating OpenCode configuration..."
    
    CONFIG_FILE="$CONFIG_DIR/opencode.json" python3 <<'EOF'
import json
import os
import sys
import re

config_file = os.environ['CONFIG_FILE']

def strip_jsonc(text):
    cleaned = []
    in_string = False
    escape = False
    i = 0

    while i < len(text):
        ch = text[i]
        nxt = text[i + 1] if i + 1 < len(text) else ''

        if in_string:
            cleaned.append(ch)
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            cleaned.append(ch)
            i += 1
            continue

        if ch == '/' and nxt == '/':
            i += 2
            while i < len(text) and text[i] not in '\r\n':
                i += 1
            continue

        if ch == '/' and nxt == '*':
            i += 2
            while i + 1 < len(text) and text[i:i + 2] != '*/':
                i += 1
            i += 2
            continue

        cleaned.append(ch)
        i += 1

    text = ''.join(cleaned)
    cleaned = []
    in_string = False
    escape = False
    i = 0

    while i < len(text):
        ch = text[i]

        if in_string:
            cleaned.append(ch)
            if escape:
                escape = False
            elif ch == '\\':
                escape = True
            elif ch == '"':
                in_string = False
            i += 1
            continue

        if ch == '"':
            in_string = True
            cleaned.append(ch)
            i += 1
            continue

        if ch == ',':
            j = i + 1
            while j < len(text) and text[j].isspace():
                j += 1
            if j < len(text) and text[j] in '}]':
                i += 1
                continue

        cleaned.append(ch)
        i += 1

    return ''.join(cleaned)

try:
    with open(config_file, 'r', encoding='utf-8') as f:
        raw = f.read()

    try:
        config = json.loads(raw)
    except json.JSONDecodeError:
        config = json.loads(strip_jsonc(raw))
    
    if 'mcp' in config and 'joplin_mcp' in config['mcp']:
        del config['mcp']['joplin_mcp']
        with open(config_file, 'w', encoding='utf-8') as f:
            json.dump(config, f, indent=2)
            f.write("\n")
        print("✓ Joplin configuration removed from opencode.json")
    else:
        print("ℹ Joplin configuration not found")
        
except Exception as e:
    print(f"⚠ Error updating opencode.json: {e}", file=sys.stderr)
    sys.exit(1)
EOF
fi

# Remove installation directory
echo "Removing $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"

echo ""
echo "========================================"
echo -e "  ${GREEN}Uninstallation complete${NC}"
echo "========================================"
echo ""
echo "Backup saved to:"
echo "  $backup_dir"
echo ""
echo "To reinstall, run:"
echo "  ./install.sh"
echo "========================================"
