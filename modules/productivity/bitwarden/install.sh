#!/bin/bash
# Bitwarden Installation
# modules/productivity/bitwarden/install.sh

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

install_bitwarden() {
    print_step "Installing Bitwarden..."

    if command -v bitwarden &>/dev/null || [[ -f /opt/Bitwarden/bitwarden ]]; then
        print_warning "Bitwarden is already installed"
        return 0
    fi

    # Try snap (official)
    if command -v snap &>/dev/null; then
        sudo snap install bitwarden
        print_success "Bitwarden installed via snap"
        return 0
    fi

    # Try flatpak
    if command -v flatpak &>/dev/null; then
        flatpak install -y flathub com.bitwarden.desktop
        print_success "Bitwarden installed via Flatpak"
        return 0
    fi

    # Manual installation (AppImage)
    case "$ARCH" in
        amd64)
            local url="https://vault.bitwarden.com/download/?app=desktop&platform=linux"

            wget -qO /tmp/bitwarden.AppImage "$url"
            chmod +x /tmp/bitwarden.AppImage

            sudo mkdir -p /opt/Bitwarden
            sudo mv /tmp/bitwarden.AppImage /opt/Bitwarden/bitwarden.AppImage

            # Create wrapper
            sudo tee /usr/local/bin/bitwarden > /dev/null << 'EOF'
#!/bin/bash
/opt/Bitwarden/bitwarden.AppImage --no-sandbox "$@"
EOF
            sudo chmod +x /usr/local/bin/bitwarden

            # Desktop entry
            sudo tee /usr/share/applications/bitwarden.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Bitwarden
Comment=Password Manager
Exec=/opt/Bitwarden/bitwarden.AppImage --no-sandbox %U
Icon=bitwarden
Type=Application
Categories=Utility;Security;
EOF
            ;;
        *)
            print_error "Bitwarden desktop not available for $ARCH"
            print_bullet "Use browser extension or web vault: https://vault.bitwarden.com"
            return 1
            ;;
    esac

    print_success "Bitwarden installed"
}

install_cli() {
    print_step "Installing Bitwarden CLI..."

    if command -v bw &>/dev/null; then
        print_warning "Bitwarden CLI already installed"
        return 0
    fi

    # Try npm
    if command -v npm &>/dev/null; then
        sudo npm install -g @bitwarden/cli
        print_success "Bitwarden CLI installed via npm"
        return 0
    fi

    # Try snap
    if command -v snap &>/dev/null; then
        sudo snap install bw
        print_success "Bitwarden CLI installed via snap"
        return 0
    fi

    print_warning "Could not install CLI (requires npm or snap)"
}

main() {
    print_step "Installing Bitwarden for $ARCH"

    install_bitwarden
    install_cli

    echo ""
    echo "════════════════════════════════════════════"
    echo "Bitwarden Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Bitwarden password manager installed"

    echo ""
    print_bullet "Desktop: Run 'bitwarden' to start"
    print_bullet "CLI: Run 'bw login' to authenticate"
    print_bullet "Web vault: https://vault.bitwarden.com"
    print_bullet "Browser extensions available for all browsers"
}

main "$@"
