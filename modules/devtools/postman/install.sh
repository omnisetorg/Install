#!/bin/bash
# Postman Installation
# modules/devtools/postman/install.sh

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

install_postman() {
    print_step "Installing Postman..."

    if command -v postman &>/dev/null || [[ -f /opt/Postman/Postman ]]; then
        print_warning "Postman is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64)
            local url="https://dl.pstmn.io/download/latest/linux_64"
            ;;
        arm64)
            local url="https://dl.pstmn.io/download/latest/linux_arm64"
            ;;
        *)
            print_error "Postman not available for $ARCH"
            return 1
            ;;
    esac

    print_bullet "Downloading Postman..."
    wget -qO /tmp/postman.tar.gz "$url"

    # Extract to /opt
    sudo rm -rf /opt/Postman
    sudo tar -xzf /tmp/postman.tar.gz -C /opt
    rm /tmp/postman.tar.gz

    # Create symlink
    sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman

    # Create desktop entry
    sudo tee /usr/share/applications/postman.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Postman
Comment=API Development Environment
Exec=/opt/Postman/Postman %U
Icon=/opt/Postman/app/resources/app/assets/icon.png
Type=Application
Categories=Development;Network;
StartupWMClass=postman
EOF

    print_success "Postman installed"
}

main() {
    print_step "Installing Postman for $ARCH"

    install_postman

    echo ""
    echo "════════════════════════════════════════════"
    echo "Postman Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Postman API Platform installed"

    echo ""
    print_bullet "Run 'postman' to start"
    print_bullet "Test REST, GraphQL, WebSocket APIs"
    print_bullet "Create and share API collections"
}

main "$@"
