#!/bin/bash
# Joplin MCP Doctor - Diagnostic script

INSTALL_DIR="$HOME/.joplin-mcp"
CONFIG_DIR="$HOME/.config/opencode"
JOPLIN_CONFIG_DIR="$HOME/.config/joplin-desktop"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detect OS for macOS compatibility
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
else
    OS="linux"
fi

echo "========================================"
echo "  Joplin MCP Doctor v2.1.1"
echo "========================================"
echo ""

# Check if installed
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}✗${NC} Joplin MCP is not installed in $INSTALL_DIR"
    echo ""
    echo "Run the installer first:"
    echo "  ./install.sh"
    exit 1
fi

echo -e "${GREEN}✓${NC} Installation found: $INSTALL_DIR"
echo ""

# Get version if available
if [ -f "$INSTALL_DIR/VERSION" ]; then
    echo "Installed version: $(cat $INSTALL_DIR/VERSION)"
    echo ""
fi

# Check core files
echo -e "${BLUE}Checking files:${NC}"
[ -f "$INSTALL_DIR/server.py" ] && echo -e "  ${GREEN}✓${NC} server.py" || echo -e "  ${RED}✗${NC} server.py not found"
[ -f "$INSTALL_DIR/run_mcp.sh" ] && echo -e "  ${GREEN}✓${NC} run_mcp.sh" || echo -e "  ${RED}✗${NC} run_mcp.sh not found"
[ -f "$INSTALL_DIR/requirements.txt" ] && echo -e "  ${GREEN}✓${NC} requirements.txt" || echo -e "  ${RED}✗${NC} requirements.txt not found"
[ -f "$INSTALL_DIR/venv/bin/python" ] && echo -e "  ${GREEN}✓${NC} Virtual environment" || echo -e "  ${RED}✗${NC} Virtual environment not found"

# Check token
echo ""
echo -e "${BLUE}Checking token:${NC}"
if [ -f "$INSTALL_DIR/run_mcp.sh" ]; then
    # Source the script to get variables
    JOPLIN_TOKEN=$(grep "export JOPLIN_TOKEN" "$INSTALL_DIR/run_mcp.sh" | cut -d'"' -f2)
    JOPLIN_PORT=$(grep "export JOPLIN_PORT" "$INSTALL_DIR/run_mcp.sh" | cut -d'"' -f2)
    
    if [ -n "$JOPLIN_TOKEN" ] && [ "$JOPLIN_TOKEN" != "TOKEN_JOPLIN" ]; then
        echo -e "  ${GREEN}✓${NC} Token configured (${#JOPLIN_TOKEN} characters)"
        echo -e "  ${GREEN}✓${NC} Port configured: ${JOPLIN_PORT:-41184}"
    else
        echo -e "  ${RED}✗${NC} Token not configured or is placeholder"
        echo "     Run ./install.sh to configure"
    fi
fi

# Check Joplin
echo ""
echo -e "${BLUE}Checking Joplin:${NC}"
port="${JOPLIN_PORT:-41184}"

# Check if Joplin process is running
if [ "$OS" = "macos" ]; then
    # macOS: use ps aux since pgrep -f is not supported
    if ps aux | grep -i "[j]oplin" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Joplin process detected"
    else
        echo -e "  ${YELLOW}⚠${NC} Joplin process not detected"
    fi
else
    # Linux: use pgrep -f
    if pgrep -f "joplin" > /dev/null 2>&1 || pgrep -f "Joplin" > /dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Joplin process detected"
    else
        echo -e "  ${YELLOW}⚠${NC} Joplin process not detected"
    fi
fi

# Check if port is listening
if command -v lsof &> /dev/null; then
    # macOS-compatible lsof check (without -sTCP:LISTEN)
    if lsof -i :$port 2>/dev/null | grep -i listen >/dev/null 2>&1; then
        echo -e "  ${GREEN}✓${NC} Port $port is listening"
    else
        echo -e "  ${YELLOW}⚠${NC} Port $port is not listening"
    fi
elif command -v netstat &> /dev/null; then
    # OS-specific netstat check
    if [ "$OS" = "macos" ]; then
        if netstat -an 2>/dev/null | grep -q "\.$port.*LISTEN"; then
            echo -e "  ${GREEN}✓${NC} Port $port is listening"
        else
            echo -e "  ${YELLOW}⚠${NC} Port $port is not listening"
        fi
    else
        if netstat -tuln 2>/dev/null | grep -q ":$port"; then
            echo -e "  ${GREEN}✓${NC} Port $port is listening"
        else
            echo -e "  ${YELLOW}⚠${NC} Port $port is not listening"
        fi
    fi
else
    echo -e "  ${YELLOW}⚠${NC} Cannot verify port (install lsof or netstat)"
fi

# Test connection to Joplin
echo ""
echo -e "${BLUE}Testing connection to Joplin:${NC}"
if curl -s "http://localhost:$port/ping" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Joplin responds on port $port"
else
    echo -e "  ${YELLOW}⚠${NC} Joplin does not respond on port $port"
    echo "     Make sure that:"
    echo "     1. Joplin is running"
    echo "     2. Web Clipper is enabled (Options > Web Clipper)"
fi

# Test token validity
if [ -n "$JOPLIN_TOKEN" ] && [ "$JOPLIN_TOKEN" != "TOKEN_JOPLIN" ]; then
    echo ""
    echo -e "${BLUE}Validating token:${NC}"
    if curl -s "http://localhost:$port/notes?token=$JOPLIN_TOKEN&limit=1" 2>/dev/null | grep -q '"items"'; then
        echo -e "  ${GREEN}✓${NC} Valid token - Successful connection"
    else
        echo -e "  ${RED}✗${NC} Invalid or rejected token"
        echo "     Possible causes:"
        echo "     - The token has changed"
        echo "     - Web Clipper is not enabled"
        echo "     - Run ./install.sh to reconfigure"
    fi
fi

# Test MCP server
echo ""
echo -e "${BLUE}Testing MCP server:${NC}"
if [ -f "$INSTALL_DIR/run_mcp.sh" ]; then
    response=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' | "$INSTALL_DIR/run_mcp.sh" 2>/dev/null | head -1)
    
    if [ -n "$response" ] && echo "$response" | grep -q '"jsonrpc"'; then
        echo -e "  ${GREEN}✓${NC} MCP server responds"
        
        # Test tools/list
        tools_response=$(echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | "$INSTALL_DIR/run_mcp.sh" 2>/dev/null | head -1)
        if echo "$tools_response" | grep -q '"tools"'; then
            tool_count=$(echo "$tools_response" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('result',{}).get('tools',[])))" 2>/dev/null || echo "?")
            echo -e "  ${GREEN}✓${NC} Tools available: $tool_count"
        fi
    else
        echo -e "  ${RED}✗${NC} MCP server does not respond correctly"
        echo "     Check the log: $INSTALL_DIR/logs/install.log"
    fi
else
    echo -e "  ${RED}✗${NC} run_mcp.sh not found"
fi

# Check OpenCode config
echo ""
echo -e "${BLUE}Checking OpenCode configuration:${NC}"
if [ -f "$CONFIG_DIR/opencode.jsonc" ]; then
    if grep -q '"joplin_mcp"' "$CONFIG_DIR/opencode.jsonc"; then
        echo -e "  ${GREEN}✓${NC} Joplin configuration found in opencode.jsonc"
    else
        echo -e "  ${YELLOW}⚠${NC} Joplin configuration not found"
        echo "     Run ./install.sh to configure"
    fi
elif [ -f "$CONFIG_DIR/opencode.json" ]; then
    if grep -q '"joplin_mcp"' "$CONFIG_DIR/opencode.json"; then
        echo -e "  ${GREEN}✓${NC} Joplin configuration found in opencode.json"
    else
        echo -e "  ${YELLOW}⚠${NC} Joplin configuration not found"
        echo "     Run ./install.sh to configure"
    fi
else
    echo -e "  ${YELLOW}⚠${NC} OpenCode config not found"
    echo "     Typical configuration at: $CONFIG_DIR/opencode.json or $CONFIG_DIR/opencode.jsonc"
fi

# Show backup info
echo ""
echo -e "${BLUE}Available backups:${NC}"
latest_backup=$(cat "$INSTALL_DIR/LATEST_BACKUP" 2>/dev/null || echo "")
if [ -n "$latest_backup" ] && [ -d "$latest_backup" ]; then
    echo -e "  ${GREEN}✓${NC} Latest backup: $latest_backup"
else
    echo "  ℹ No recent backup information"
fi

echo ""
echo "========================================"
echo -e "  ${GREEN}Diagnostics completed${NC}"
echo "========================================"
echo ""
echo "If you encounter issues:"
echo "  1. Check the log: $INSTALL_DIR/logs/install.log"
echo "  2. Reinstall: ./install.sh"
echo "  3. Uninstall and reinstall: ./uninstall.sh && ./install.sh"
echo ""
echo "========================================"
