#!/bin/bash
# Ghostty Uninstallation
# modules/terminals/ghostty/uninstall.sh

set -euo pipefail

echo "Removing Ghostty..."

# Remove via apt
sudo apt-get remove -y ghostty 2>/dev/null || true

# Remove manual installation
sudo rm -f /usr/local/bin/ghostty
sudo rm -rf /opt/ghostty* 2>/dev/null || true

# Remove config
rm -rf ~/.config/ghostty

echo "Ghostty removed"
