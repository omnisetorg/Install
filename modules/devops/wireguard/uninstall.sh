#!/bin/bash
# WireGuard Uninstallation
# modules/devops/wireguard/uninstall.sh

set -euo pipefail

echo "Removing WireGuard..."

# Stop all WireGuard interfaces
for iface in $(sudo wg show interfaces 2>/dev/null); do
    sudo wg-quick down "$iface" 2>/dev/null || true
done

# Remove via apt
sudo apt-get remove -y wireguard wireguard-tools 2>/dev/null || true

# Remove config (contains private keys!)
echo "WireGuard config in /etc/wireguard was preserved for safety"
echo "Run 'sudo rm -rf /etc/wireguard' to remove keys"

sudo apt-get autoremove -y

echo "WireGuard removed"
