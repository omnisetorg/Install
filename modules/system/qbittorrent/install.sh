#!/bin/bash
# qBittorrent Installation
# modules/system/qbittorrent/install.sh

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

install_qbittorrent() {
    print_step "Installing qBittorrent..."

    if command -v qbittorrent &>/dev/null; then
        print_warning "qBittorrent is already installed"
        return 0
    fi

    # Add qBittorrent PPA for latest version
    sudo add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable 2>/dev/null || true

    sudo apt-get update
    sudo apt-get install -y qbittorrent

    print_success "qBittorrent installed"
}

install_qbittorrent_nox() {
    print_step "Installing qBittorrent-nox (headless)..."

    if command -v qbittorrent-nox &>/dev/null; then
        print_warning "qBittorrent-nox already installed"
        return 0
    fi

    sudo apt-get install -y qbittorrent-nox

    print_success "qBittorrent-nox installed"
}

main() {
    print_step "Installing qBittorrent for $ARCH"

    install_qbittorrent
    install_qbittorrent_nox

    echo ""
    echo "════════════════════════════════════════════"
    echo "qBittorrent Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "qBittorrent BitTorrent client installed"

    echo ""
    print_bullet "GUI: Run 'qbittorrent' to start"
    print_bullet "Headless: Run 'qbittorrent-nox'"
    print_bullet "Web UI (headless): http://localhost:8080"
    print_bullet "Default credentials: admin/adminadmin"
}

main "$@"
