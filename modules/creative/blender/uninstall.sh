#!/bin/bash
# Blender Uninstallation
# modules/creative/blender/uninstall.sh

set -euo pipefail

echo "Removing Blender..."

# Remove via apt
sudo apt-get remove -y blender 2>/dev/null || true

# Remove via snap
sudo snap remove blender 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y org.blender.Blender 2>/dev/null || true

# Remove config
rm -rf ~/.config/blender

sudo apt-get autoremove -y

echo "Blender removed"
