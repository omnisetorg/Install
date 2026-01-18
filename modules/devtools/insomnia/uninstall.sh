#!/bin/bash
# Insomnia Uninstallation
# modules/devtools/insomnia/uninstall.sh

set -euo pipefail

echo "Removing Insomnia..."

# Remove via snap
sudo snap remove insomnia 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y insomnia 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y rest.insomnia.Insomnia 2>/dev/null || true

# Remove config
rm -rf ~/.config/Insomnia

echo "Insomnia removed"
