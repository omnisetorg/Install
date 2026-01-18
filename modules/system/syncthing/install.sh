#!/bin/bash
# Syncthing Installation
# modules/system/syncthing/install.sh

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

install_syncthing() {
    print_step "Installing Syncthing..."

    if command -v syncthing &>/dev/null; then
        print_warning "Syncthing is already installed"
        syncthing --version
        return 0
    fi

    # Add Syncthing repository
    sudo mkdir -p /etc/apt/keyrings
    curl -L -o /tmp/syncthing-release-key.asc https://syncthing.net/release-key.txt
    sudo gpg --dearmor -o /etc/apt/keyrings/syncthing-archive-keyring.gpg /tmp/syncthing-release-key.asc
    rm /tmp/syncthing-release-key.asc

    echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable" | \
        sudo tee /etc/apt/sources.list.d/syncthing.list

    sudo apt-get update
    sudo apt-get install -y syncthing

    print_success "Syncthing installed"
}

configure_syncthing() {
    print_step "Configuring Syncthing..."

    # Enable user service
    systemctl --user enable syncthing.service
    systemctl --user start syncthing.service

    print_success "Syncthing service started"
}

main() {
    print_step "Installing Syncthing for $ARCH"

    install_syncthing
    configure_syncthing

    echo ""
    echo "════════════════════════════════════════════"
    echo "Syncthing Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v syncthing &>/dev/null; then
        print_success "Syncthing version: $(syncthing --version | head -1)"
    fi

    echo ""
    print_bullet "Web UI: http://localhost:8384"
    print_bullet "Service: systemctl --user status syncthing"
    print_bullet "Continuous file synchronization"
    print_bullet "No cloud required, peer-to-peer"
}

main "$@"
