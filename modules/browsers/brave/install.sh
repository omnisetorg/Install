#!/bin/bash
# Brave Browser Installation
# modules/browsers/brave/install.sh

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

install_brave() {
    print_step "Installing Brave Browser..."

    if command -v brave-browser &>/dev/null; then
        print_warning "Brave is already installed"
        brave-browser --version
        return 0
    fi

    # Add Brave repository
    sudo apt-get update
    sudo apt-get install -y curl

    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
        https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | \
        sudo tee /etc/apt/sources.list.d/brave-browser-release.list

    sudo apt-get update
    sudo apt-get install -y brave-browser

    print_success "Brave Browser installed"
}

main() {
    print_step "Installing Brave Browser for $ARCH"

    case "$ARCH" in
        amd64|arm64)
            install_brave
            ;;
        *)
            print_error "Brave not available for $ARCH"
            exit 1
            ;;
    esac

    echo ""
    echo "════════════════════════════════════════════"
    echo "Brave Browser Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v brave-browser &>/dev/null; then
        print_success "Brave version: $(brave-browser --version)"
    fi

    echo ""
    print_bullet "Run 'brave-browser' to start"
    print_bullet "Built-in ad and tracker blocking"
    print_bullet "Privacy-focused browsing"
}

main "$@"
