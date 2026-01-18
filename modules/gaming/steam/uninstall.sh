#!/bin/bash
# Steam Uninstallation
# modules/gaming/steam/uninstall.sh

set -euo pipefail

echo "Removing Steam..."

# Remove via apt
sudo apt-get remove -y steam-installer steam-launcher 2>/dev/null || true

# Remove config (preserves games)
# rm -rf ~/.steam
# rm -rf ~/.local/share/Steam

sudo apt-get autoremove -y

echo "Steam removed"
echo "Note: Games in ~/.steam were preserved"
echo "Run 'rm -rf ~/.steam ~/.local/share/Steam' to remove all data"
