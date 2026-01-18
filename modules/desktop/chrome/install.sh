#!/bin/bash
# Google Chrome Installation
# modules/desktop/chrome/install.sh

set -euo pipefail

ARCH="${1:-amd64}"

print_step() { echo "==> $1"; }
print_success() { echo "✓ $1"; }
print_warning() { echo "⚠ $1"; }
print_error() { echo "✗ $1" >&2; }

main() {
    print_step "Installing Google Chrome..."

    if command -v google-chrome &>/dev/null; then
        print_warning "Google Chrome is already installed"
        google-chrome --version
        return 0
    fi

    case "$ARCH" in
        amd64)
            wget -qO /tmp/chrome.deb "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
            sudo dpkg -i /tmp/chrome.deb || sudo apt-get install -f -y
            rm /tmp/chrome.deb
            print_success "Google Chrome installed"
            ;;
        arm64|armhf)
            print_warning "Google Chrome is not available for $ARCH"
            print_step "Installing Chromium as alternative..."
            sudo apt-get update
            sudo apt-get install -y chromium-browser || sudo apt-get install -y chromium
            print_success "Chromium installed as Chrome alternative"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac
}

main "$@"
