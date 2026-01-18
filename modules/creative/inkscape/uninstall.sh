#!/bin/bash
# Inkscape Uninstallation
# modules/creative/inkscape/uninstall.sh

set -euo pipefail

echo "Removing Inkscape..."

# Remove via apt
sudo apt-get remove -y inkscape 2>/dev/null || true

# Remove via snap
sudo snap remove inkscape 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y org.inkscape.Inkscape 2>/dev/null || true

# Remove config
rm -rf ~/.config/inkscape

sudo apt-get autoremove -y

echo "Inkscape removed"
