#!/bin/bash
# Audacity Uninstallation
# modules/creative/audacity/uninstall.sh

set -euo pipefail

echo "Removing Audacity..."

# Remove via apt
sudo apt-get remove -y audacity 2>/dev/null || true

# Remove via snap
sudo snap remove audacity 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y org.audacityteam.Audacity 2>/dev/null || true

# Remove config
rm -rf ~/.config/audacity
rm -rf ~/.audacity-data

sudo apt-get autoremove -y

echo "Audacity removed"
