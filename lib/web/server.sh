#!/bin/bash
# Local web server for module selection
# Uses Python's built-in HTTP server with custom handler

OMNISET_WEB_PORT="${OMNISET_WEB_PORT:-9999}"
OMNISET_WEB_DIR="${OMNISET_ROOT}/web"
OMNISET_CALLBACK_FILE="/tmp/omniset-selection-$$"

start_web_server() {
    local port="$OMNISET_WEB_PORT"

    # Check if Python is available
    if ! command -v python3 &>/dev/null; then
        print_error "Python 3 is required for web mode"
        return 1
    fi

    # Clean up old callback file
    rm -f "$OMNISET_CALLBACK_FILE"

    # Create the Python server script
    local server_script="/tmp/omniset-server-$$.py"
    cat > "$server_script" << 'PYTHON_EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import json
import os
import sys
import urllib.parse
from pathlib import Path

PORT = int(sys.argv[1])
WEB_DIR = sys.argv[2]
CALLBACK_FILE = sys.argv[3]

class OmniSetHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=WEB_DIR, **kwargs)

    def do_POST(self):
        if self.path == '/api/install':
            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length)

            try:
                data = json.loads(post_data.decode('utf-8'))
                modules = data.get('modules', [])

                # Write selection to callback file
                with open(CALLBACK_FILE, 'w') as f:
                    f.write('\n'.join(modules))

                # Send success response
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(json.dumps({'status': 'ok', 'message': 'Selection received'}).encode())

                # Signal to shutdown after response
                print("SELECTION_RECEIVED", flush=True)

            except Exception as e:
                self.send_response(500)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                self.wfile.write(json.dumps({'error': str(e)}).encode())
        else:
            self.send_response(404)
            self.end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.end_headers()

    def log_message(self, format, *args):
        # Suppress default logging
        pass

print(f"Starting server on port {PORT}...", flush=True)
with socketserver.TCPServer(("", PORT), OmniSetHandler) as httpd:
    print(f"READY", flush=True)
    httpd.handle_request()  # Handle requests until selection received
    while not os.path.exists(CALLBACK_FILE):
        httpd.handle_request()
PYTHON_EOF

    print_info "Starting local web server on port $port..."

    # Start server in background and capture output
    python3 "$server_script" "$port" "$OMNISET_WEB_DIR" "$OMNISET_CALLBACK_FILE" 2>&1 &
    local server_pid=$!

    # Wait for server to be ready
    sleep 1

    # Open browser
    local url="http://localhost:${port}?mode=local"
    print_info "Opening browser: $url"

    if command -v xdg-open &>/dev/null; then
        xdg-open "$url" 2>/dev/null &
    elif command -v open &>/dev/null; then
        open "$url" 2>/dev/null &
    else
        print_warning "Please open in browser: $url"
    fi

    print_info "Waiting for module selection..."
    print_info "(Select modules in browser and click 'Install')"
    echo ""

    # Wait for selection file to appear
    local timeout=300  # 5 minutes
    local elapsed=0
    while [[ ! -f "$OMNISET_CALLBACK_FILE" ]] && [[ $elapsed -lt $timeout ]]; do
        sleep 1
        ((elapsed++))
    done

    # Kill server
    kill $server_pid 2>/dev/null || true
    rm -f "$server_script"

    if [[ -f "$OMNISET_CALLBACK_FILE" ]]; then
        # Read selected modules
        mapfile -t SELECTED_MODULES < "$OMNISET_CALLBACK_FILE"
        rm -f "$OMNISET_CALLBACK_FILE"

        if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
            print_info "No modules selected"
            return 1
        fi

        print_success "Received ${#SELECTED_MODULES[@]} modules"
        return 0
    else
        print_error "Timeout waiting for selection"
        return 1
    fi
}

get_selected_modules() {
    echo "${SELECTED_MODULES[@]}"
}
