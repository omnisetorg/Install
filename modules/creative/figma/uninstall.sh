#!/bin/bash
# Figma Uninstallation
# modules/creative/figma/uninstall.sh

set -euo pipefail

echo "Removing Figma..."

# Remove via snap
sudo snap remove figma-linux 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y io.github.nicolo_figma.figma-linux 2>/dev/null || true

# Remove AppImage installation
sudo rm -rf /opt/figma-linux
sudo rm -f /usr/local/bin/figma-linux
sudo rm -f /usr/share/applications/figma-linux.desktop

# Remove config
rm -rf ~/.config/figma-linux

echo "Figma removed"
