#!/bin/bash
# OBS Studio Uninstallation
# modules/creative/obs/uninstall.sh

set -euo pipefail

echo "Removing OBS Studio..."

# Remove via apt
sudo apt-get remove -y obs-studio 2>/dev/null || true

# Remove PPA
sudo add-apt-repository --remove -y ppa:obsproject/obs-studio 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y com.obsproject.Studio 2>/dev/null || true

# Remove config
rm -rf ~/.config/obs-studio

sudo apt-get autoremove -y

echo "OBS Studio removed"
