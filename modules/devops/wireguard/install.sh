#!/bin/bash
# WireGuard Installation
# modules/devops/wireguard/install.sh

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

install_wireguard() {
    print_step "Installing WireGuard..."

    if command -v wg &>/dev/null; then
        print_warning "WireGuard is already installed"
        return 0
    fi

    sudo apt-get update
    sudo apt-get install -y wireguard wireguard-tools

    print_success "WireGuard installed"
}

configure_wireguard() {
    print_step "Configuring WireGuard..."

    # Create config directory
    sudo mkdir -p /etc/wireguard
    sudo chmod 700 /etc/wireguard

    # Generate keys if requested
    if [[ ! -f /etc/wireguard/privatekey ]]; then
        print_bullet "Generating WireGuard keys..."
        wg genkey | sudo tee /etc/wireguard/privatekey | wg pubkey | sudo tee /etc/wireguard/publickey
        sudo chmod 600 /etc/wireguard/privatekey
        print_success "Keys generated"
    fi

    # Create example config
    if [[ ! -f /etc/wireguard/wg0.conf.example ]]; then
        local private_key
        private_key=$(sudo cat /etc/wireguard/privatekey)

        sudo tee /etc/wireguard/wg0.conf.example > /dev/null << EOF
# WireGuard configuration example
# Copy to wg0.conf and edit as needed

[Interface]
PrivateKey = ${private_key}
Address = 10.0.0.1/24
ListenPort = 51820
# PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
# PostDown = iptables -D FORWARD -i wg0 -j ACCEPT

# [Peer]
# PublicKey = <peer-public-key>
# AllowedIPs = 10.0.0.2/32
# Endpoint = peer.example.com:51820
# PersistentKeepalive = 25
EOF
        print_success "Example configuration created"
    fi
}

main() {
    print_step "Installing WireGuard for $ARCH"

    install_wireguard
    configure_wireguard

    echo ""
    echo "════════════════════════════════════════════"
    echo "WireGuard Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "WireGuard installed"

    echo ""
    print_bullet "Public key: $(sudo cat /etc/wireguard/publickey 2>/dev/null || echo 'Not generated')"
    echo ""
    print_bullet "Example config: /etc/wireguard/wg0.conf.example"
    print_bullet "Start: sudo wg-quick up wg0"
    print_bullet "Stop: sudo wg-quick down wg0"
    print_bullet "Status: sudo wg show"
}

main "$@"
