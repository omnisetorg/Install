#!/bin/bash
# GIMP Uninstallation
# modules/creative/gimp/uninstall.sh

set -euo pipefail

echo "Removing GIMP..."

# Remove via apt
sudo apt-get remove -y gimp 2>/dev/null || true

# Remove via snap
sudo snap remove gimp 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y org.gimp.GIMP 2>/dev/null || true

# Remove config
rm -rf ~/.config/GIMP
rm -rf ~/.gimp-*

sudo apt-get autoremove -y

echo "GIMP removed"
