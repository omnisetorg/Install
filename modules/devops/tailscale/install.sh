#!/bin/bash
# Tailscale Installation
# modules/devops/tailscale/install.sh

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

install_tailscale() {
    print_step "Installing Tailscale..."

    if command -v tailscale &>/dev/null; then
        print_warning "Tailscale is already installed"
        tailscale version
        return 0
    fi

    # Use official install script
    curl -fsSL https://tailscale.com/install.sh | sh

    print_success "Tailscale installed"
}

configure_tailscale() {
    print_step "Configuring Tailscale..."

    # Enable and start tailscaled
    sudo systemctl enable --now tailscaled

    print_success "Tailscale daemon started"
}

main() {
    print_step "Installing Tailscale for $ARCH"

    install_tailscale
    configure_tailscale

    echo ""
    echo "════════════════════════════════════════════"
    echo "Tailscale Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v tailscale &>/dev/null; then
        print_success "Tailscale version: $(tailscale version | head -1)"
    fi

    echo ""
    print_bullet "Run 'sudo tailscale up' to connect"
    print_bullet "Run 'tailscale status' to see network"
    print_bullet "Run 'tailscale ip' to see your IP"
    echo ""
    print_warning "You'll need to authenticate via browser"
}

main "$@"
