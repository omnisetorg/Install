#!/bin/bash
# Lutris Uninstallation
# modules/gaming/lutris/uninstall.sh

set -euo pipefail

echo "Removing Lutris..."

# Remove via apt
sudo apt-get remove -y lutris 2>/dev/null || true

# Remove PPA
sudo add-apt-repository --remove -y ppa:lutris-team/lutris 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y net.lutris.Lutris 2>/dev/null || true

# Remove config (preserves games)
# rm -rf ~/.config/lutris
# rm -rf ~/.local/share/lutris

sudo apt-get autoremove -y

echo "Lutris removed"
echo "Note: Games data was preserved"
