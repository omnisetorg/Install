#!/bin/bash
# Cursor (AI Code Editor) Installation
# modules/editors/cursor/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_bullet() { echo "  • $1"; }
fi

install_cursor() {
    print_step "Installing Cursor..."

    if command -v cursor &>/dev/null || [[ -f /opt/Cursor/cursor ]]; then
        print_warning "Cursor is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64)
            local url="https://downloader.cursor.sh/linux/appImage/x64"
            ;;
        arm64)
            local url="https://downloader.cursor.sh/linux/appImage/arm64"
            ;;
        *)
            print_error "Cursor not available for $ARCH"
            return 1
            ;;
    esac

    print_bullet "Downloading Cursor AppImage..."
    wget -qO /tmp/cursor.AppImage "$url"
    chmod +x /tmp/cursor.AppImage

    # Install to /opt
    sudo mkdir -p /opt/Cursor
    sudo mv /tmp/cursor.AppImage /opt/Cursor/cursor.AppImage

    # Create wrapper script
    sudo tee /usr/local/bin/cursor > /dev/null << 'EOF'
#!/bin/bash
/opt/Cursor/cursor.AppImage --no-sandbox "$@"
EOF
    sudo chmod +x /usr/local/bin/cursor

    # Create desktop entry
    sudo tee /usr/share/applications/cursor.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Cursor
Comment=AI-powered Code Editor
Exec=/opt/Cursor/cursor.AppImage --no-sandbox %F
Icon=cursor
Type=Application
Categories=Development;IDE;TextEditor;
MimeType=text/plain;
StartupWMClass=Cursor
EOF

    print_success "Cursor installed"
}

main() {
    print_step "Installing Cursor for $ARCH"

    install_cursor

    echo ""
    echo "════════════════════════════════════════════"
    echo "Cursor Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Cursor AI Editor installed"

    echo ""
    print_bullet "Run 'cursor' to start"
    print_bullet "VS Code fork with built-in AI assistance"
    print_bullet "Your VS Code extensions are compatible"
}

main "$@"
