#!/bin/bash
# Alacritty Uninstallation
# modules/terminals/alacritty/uninstall.sh

set -euo pipefail

echo "Removing Alacritty..."

# Remove via apt
sudo apt-get remove -y alacritty 2>/dev/null || true

# Remove via snap
sudo snap remove alacritty 2>/dev/null || true

# Remove cargo installation
rm -f ~/.cargo/bin/alacritty 2>/dev/null || true
sudo rm -f /usr/local/bin/alacritty 2>/dev/null || true

# Remove config
rm -rf ~/.config/alacritty

sudo apt-get autoremove -y

echo "Alacritty removed"
