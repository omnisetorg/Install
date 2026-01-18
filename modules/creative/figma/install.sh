#!/bin/bash
# Figma Installation (Unofficial Desktop App)
# modules/creative/figma/install.sh

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

install_figma() {
    print_step "Installing Figma..."

    if command -v figma-linux &>/dev/null || [[ -f /opt/figma-linux/figma-linux ]]; then
        print_warning "Figma is already installed"
        return 0
    fi

    # Try snap (unofficial but well-maintained)
    if command -v snap &>/dev/null; then
        sudo snap install figma-linux
        print_success "Figma installed via snap"
        return 0
    fi

    # Try flatpak
    if command -v flatpak &>/dev/null; then
        flatpak install -y flathub io.github.nicolo_figma.figma-linux
        print_success "Figma installed via Flatpak"
        return 0
    fi

    # Manual installation
    case "$ARCH" in
        amd64)
            local version
            version=$(curl -s "https://api.github.com/repos/nicolo-ribaudo/nicolo-figma.figma-linux/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/' || echo "")

            if [[ -z "$version" ]]; then
                # Try figma-linux repo
                version=$(curl -s "https://api.github.com/repos/nicolo-ribaudo/nicolo-figma.figma-linux/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            fi

            # Download AppImage
            wget -qO /tmp/figma.AppImage "https://github.com/nicolo-ribaudo/nicolo-figma.figma-linux/releases/latest/download/figma-linux.AppImage" || \
            wget -qO /tmp/figma.AppImage "https://github.com/nicolo-ribaudo/nicolo-figma.figma-linux/releases/download/${version}/figma-linux_${version}_linux_x86_64.AppImage"

            chmod +x /tmp/figma.AppImage

            sudo mkdir -p /opt/figma-linux
            sudo mv /tmp/figma.AppImage /opt/figma-linux/figma-linux.AppImage

            # Create wrapper
            sudo tee /usr/local/bin/figma-linux > /dev/null << 'EOF'
#!/bin/bash
/opt/figma-linux/figma-linux.AppImage --no-sandbox "$@"
EOF
            sudo chmod +x /usr/local/bin/figma-linux

            # Desktop entry
            sudo tee /usr/share/applications/figma-linux.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Figma
Comment=Collaborative Design Tool
Exec=/opt/figma-linux/figma-linux.AppImage --no-sandbox %U
Icon=figma
Type=Application
Categories=Graphics;Design;
MimeType=x-scheme-handler/figma;
EOF
            ;;
        *)
            print_error "Figma desktop not available for $ARCH"
            print_bullet "Use web version: https://figma.com"
            return 1
            ;;
    esac

    print_success "Figma installed"
}

main() {
    print_step "Installing Figma for $ARCH"

    install_figma

    echo ""
    echo "════════════════════════════════════════════"
    echo "Figma Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Figma desktop app installed"

    echo ""
    print_bullet "Run 'figma-linux' to start"
    print_bullet "Unofficial Linux client"
    print_bullet "Web version: https://figma.com"
    print_bullet "Full feature parity with web"
}

main "$@"
