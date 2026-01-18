#!/bin/bash
# Kdenlive Uninstallation
# modules/creative/kdenlive/uninstall.sh

set -euo pipefail

echo "Removing Kdenlive..."

# Remove via apt
sudo apt-get remove -y kdenlive 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y org.kde.kdenlive 2>/dev/null || true

# Remove config
rm -rf ~/.config/kdenlive*
rm -rf ~/.local/share/kdenlive

sudo apt-get autoremove -y

echo "Kdenlive removed"
