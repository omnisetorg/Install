#!/bin/bash
# Insomnia Installation
# modules/devtools/insomnia/install.sh

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

install_insomnia() {
    print_step "Installing Insomnia..."

    if command -v insomnia &>/dev/null; then
        print_warning "Insomnia is already installed"
        return 0
    fi

    # Try snap first (recommended by Insomnia)
    if command -v snap &>/dev/null; then
        sudo snap install insomnia
        print_success "Insomnia installed via snap"
        return 0
    fi

    # Manual installation
    case "$ARCH" in
        amd64)
            local version
            version=$(curl -s "https://api.github.com/repos/Kong/insomnia/releases/latest" | grep '"tag_name":' | sed -E 's/.*"core@([^"]+)".*/\1/')

            local url="https://github.com/Kong/insomnia/releases/download/core%40${version}/Insomnia.Core-${version}.deb"
            wget -qO /tmp/insomnia.deb "$url"

            sudo dpkg -i /tmp/insomnia.deb || sudo apt-get install -f -y
            rm /tmp/insomnia.deb
            ;;
        arm64)
            # Try flatpak
            if command -v flatpak &>/dev/null; then
                flatpak install -y flathub rest.insomnia.Insomnia
                print_success "Insomnia installed via Flatpak"
                return 0
            fi
            print_error "Insomnia not available for arm64 without snap/flatpak"
            return 1
            ;;
        *)
            print_error "Insomnia not available for $ARCH"
            return 1
            ;;
    esac

    print_success "Insomnia installed"
}

main() {
    print_step "Installing Insomnia for $ARCH"

    install_insomnia

    echo ""
    echo "════════════════════════════════════════════"
    echo "Insomnia Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Insomnia API Client installed"

    echo ""
    print_bullet "Run 'insomnia' to start"
    print_bullet "REST, GraphQL, gRPC, WebSocket support"
    print_bullet "Open-source API development platform"
}

main "$@"
