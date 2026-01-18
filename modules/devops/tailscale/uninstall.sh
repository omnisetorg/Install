#!/bin/bash
# Tailscale Uninstallation
# modules/devops/tailscale/uninstall.sh

set -euo pipefail

echo "Removing Tailscale..."

# Logout first
sudo tailscale logout 2>/dev/null || true

# Stop service
sudo systemctl stop tailscaled 2>/dev/null || true
sudo systemctl disable tailscaled 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y tailscale 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/tailscale.list
sudo rm -f /usr/share/keyrings/tailscale-archive-keyring.gpg

# Remove state
sudo rm -rf /var/lib/tailscale

sudo apt-get autoremove -y

echo "Tailscale removed"
