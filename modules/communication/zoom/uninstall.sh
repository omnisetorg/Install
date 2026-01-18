#!/bin/bash
# Zoom Uninstallation
# modules/communication/zoom/uninstall.sh

set -euo pipefail

echo "Removing Zoom..."

# Remove via apt
sudo apt-get remove -y zoom 2>/dev/null || true

# Remove via snap
sudo snap remove zoom-client 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y us.zoom.Zoom 2>/dev/null || true

# Remove config
rm -rf ~/.zoom
rm -rf ~/.config/zoomus.conf

sudo apt-get autoremove -y

echo "Zoom removed"
