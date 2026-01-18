#!/bin/bash
# Obsidian Installation
# modules/productivity/obsidian/install.sh

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

install_obsidian() {
    print_step "Installing Obsidian..."

    if command -v obsidian &>/dev/null || [[ -f /opt/Obsidian/obsidian ]]; then
        print_warning "Obsidian is already installed"
        return 0
    fi

    # Try snap first
    if command -v snap &>/dev/null; then
        sudo snap install obsidian --classic
        print_success "Obsidian installed via snap"
        return 0
    fi

    # Try flatpak
    if command -v flatpak &>/dev/null; then
        flatpak install -y flathub md.obsidian.Obsidian
        print_success "Obsidian installed via Flatpak"
        return 0
    fi

    # Manual AppImage installation
    case "$ARCH" in
        amd64)
            local version
            version=$(curl -s "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

            wget -qO /tmp/obsidian.AppImage "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage"
            chmod +x /tmp/obsidian.AppImage

            sudo mkdir -p /opt/Obsidian
            sudo mv /tmp/obsidian.AppImage /opt/Obsidian/obsidian.AppImage

            # Create wrapper
            sudo tee /usr/local/bin/obsidian > /dev/null << 'EOF'
#!/bin/bash
/opt/Obsidian/obsidian.AppImage --no-sandbox "$@"
EOF
            sudo chmod +x /usr/local/bin/obsidian

            # Desktop entry
            sudo tee /usr/share/applications/obsidian.desktop > /dev/null << 'EOF'
[Desktop Entry]
Name=Obsidian
Comment=Knowledge base and note-taking
Exec=/opt/Obsidian/obsidian.AppImage --no-sandbox %U
Icon=obsidian
Type=Application
Categories=Office;TextEditor;
MimeType=x-scheme-handler/obsidian;
EOF
            ;;
        arm64)
            print_error "Obsidian AppImage not available for arm64"
            print_bullet "Try: flatpak install flathub md.obsidian.Obsidian"
            return 1
            ;;
    esac

    print_success "Obsidian installed"
}

main() {
    print_step "Installing Obsidian for $ARCH"

    install_obsidian

    echo ""
    echo "════════════════════════════════════════════"
    echo "Obsidian Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Obsidian knowledge base installed"

    echo ""
    print_bullet "Run 'obsidian' to start"
    print_bullet "Create vaults for different projects"
    print_bullet "Markdown-based note-taking"
    print_bullet "Graph view for connections"
}

main "$@"
