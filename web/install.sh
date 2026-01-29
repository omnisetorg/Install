#!/bin/bash
# OmniSet Quick Start
# Usage: curl -sL https://omniset.org/install | bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔═══════════════════════════════════════╗"
echo "  ║         OmniSet Quick Start           ║"
echo "  ╚═══════════════════════════════════════╝"
echo -e "${NC}"

# Check requirements
check_requirements() {
    local missing=()

    command -v curl &>/dev/null || missing+=("curl")
    command -v python3 &>/dev/null || missing+=("python3")

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}Missing required tools: ${missing[*]}${NC}"
        echo "Please install them first."
        exit 1
    fi
}

# Create temp directory
OMNISET_TMP=$(mktemp -d)
trap "rm -rf $OMNISET_TMP" EXIT

PORT=9999
CALLBACK_FILE="$OMNISET_TMP/selection"
WEB_DIR="$OMNISET_TMP/web"
BASE_URL="${OMNISET_URL:-https://raw.githubusercontent.com/omnisetorg/omniset/main}"
GIT_URL="https://github.com/omnisetorg/omniset.git"

echo -e "${BLUE}▸${NC} Checking requirements..."
check_requirements
echo -e "${GREEN}✓${NC} Requirements OK"

echo -e "${BLUE}▸${NC} Downloading web interface..."
mkdir -p "$WEB_DIR/api" "$WEB_DIR/assets/css" "$WEB_DIR/assets/js" "$WEB_DIR/assets/icons"

# Download web files (parallel)
curl -sL "$BASE_URL/web/index.html" -o "$WEB_DIR/index.html" &
curl -sL "$BASE_URL/web/api/modules.json" -o "$WEB_DIR/api/modules.json" &
curl -sL "$BASE_URL/web/assets/css/style.css" -o "$WEB_DIR/assets/css/style.css" &
curl -sL "$BASE_URL/web/assets/js/app.js" -o "$WEB_DIR/assets/js/app.js" &
curl -sL "$BASE_URL/web/assets/js/icons.js" -o "$WEB_DIR/assets/js/icons.js" &
wait

# Download icons (parallel)
ICONS="docker nodejs python go rust php vscode chrome firefox postgresql mysql redis mongodb discord slack telegram zoom signal thunderbird gimp inkscape blender obs kdenlive audacity steam lutris vlc virtualbox git essentials modern-cli"
for icon in $ICONS; do
    curl -sL "$BASE_URL/web/assets/icons/${icon}.svg" -o "$WEB_DIR/assets/icons/${icon}.svg" &
done
wait

echo -e "${GREEN}✓${NC} Downloaded"

# Create Python server
cat > "$OMNISET_TMP/server.py" << 'PYEOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import sys

PORT = int(sys.argv[1])
WEB_DIR = sys.argv[2]
CALLBACK_FILE = sys.argv[3]

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_POST(self):
        if self.path == '/api/install':
            length = int(self.headers['Content-Length'])
            data = json.loads(self.rfile.read(length).decode())

            with open(CALLBACK_FILE, 'w') as f:
                f.write('\n'.join(data.get('modules', [])))

            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def log_message(self, *args):
        pass

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    httpd.handle_request()
    while not os.path.exists(CALLBACK_FILE):
        httpd.handle_request()
PYEOF

echo -e "${BLUE}▸${NC} Starting local server on port $PORT..."
python3 "$OMNISET_TMP/server.py" "$PORT" "$WEB_DIR" "$CALLBACK_FILE" &
SERVER_PID=$!
sleep 1

# Open browser
URL="http://localhost:${PORT}?mode=local"
echo -e "${BLUE}▸${NC} Opening browser..."

if command -v xdg-open &>/dev/null; then
    xdg-open "$URL" 2>/dev/null &
elif command -v open &>/dev/null; then
    open "$URL" 2>/dev/null &
elif command -v wslview &>/dev/null; then
    wslview "$URL" 2>/dev/null &
else
    echo -e "${YELLOW}Please open in browser:${NC} $URL"
fi

echo ""
echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   ${BOLD}Browser opened!${NC}                                         ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   1. Select the modules you want to install               ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   2. Click ${GREEN}'Install Selected'${NC}                             ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   3. Return here to continue                              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}   ${YELLOW}Waiting for your selection...${NC}                          ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                            ${CYAN}║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Wait for selection (5 min timeout)
TIMEOUT=300
ELAPSED=0
while [[ ! -f "$CALLBACK_FILE" ]] && [[ $ELAPSED -lt $TIMEOUT ]]; do
    sleep 1
    ((ELAPSED++))
done

kill $SERVER_PID 2>/dev/null || true

if [[ ! -f "$CALLBACK_FILE" ]]; then
    echo -e "${RED}Timeout waiting for selection${NC}"
    exit 1
fi

# Read selected modules
mapfile -t MODULES < "$CALLBACK_FILE"

if [[ ${#MODULES[@]} -eq 0 ]]; then
    echo -e "${YELLOW}No modules selected${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}✓${NC} Received ${#MODULES[@]} modules:"
for mod in "${MODULES[@]}"; do
    echo -e "  ${CYAN}•${NC} $mod"
done
echo ""

# Confirm
echo -e -n "${YELLOW}Continue with installation? [Y/n]${NC} "
read -r confirm
if [[ "$confirm" =~ ^[Nn]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Clone full repo and install
echo ""
echo -e "${BLUE}▸${NC} Downloading OmniSet..."

INSTALL_DIR="$HOME/.omniset"
if [[ -d "$INSTALL_DIR" ]]; then
    cd "$INSTALL_DIR"
    git pull -q 2>/dev/null || true
else
    git clone -q "$GIT_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
fi

echo -e "${GREEN}✓${NC} Ready"
echo ""

# Run installation
exec ./bin/omniset install "${MODULES[@]}"
