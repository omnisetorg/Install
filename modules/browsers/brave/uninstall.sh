#!/bin/bash
# Brave Browser Uninstallation
# modules/browsers/brave/uninstall.sh

set -euo pipefail

echo "Removing Brave Browser..."

# Remove via apt
sudo apt-get remove -y brave-browser 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/brave-browser-release.list
sudo rm -f /usr/share/keyrings/brave-browser-archive-keyring.gpg

# Remove config (optional)
# rm -rf ~/.config/BraveSoftware

sudo apt-get autoremove -y

echo "Brave Browser removed"
echo "Note: User profile in ~/.config/BraveSoftware was preserved"
