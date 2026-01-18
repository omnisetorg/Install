#!/bin/bash
# Thunderbird Uninstallation
# modules/communication/thunderbird/uninstall.sh

set -euo pipefail

echo "Removing Thunderbird..."

# Remove via apt
sudo apt-get remove -y thunderbird 2>/dev/null || true

# Remove via snap
sudo snap remove thunderbird 2>/dev/null || true

# Remove config (preserves email data)
# rm -rf ~/.thunderbird

sudo apt-get autoremove -y

echo "Thunderbird removed"
echo "Note: Email data in ~/.thunderbird was preserved"
