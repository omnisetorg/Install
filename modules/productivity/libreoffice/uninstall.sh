#!/bin/bash
# LibreOffice Uninstallation
# modules/productivity/libreoffice/uninstall.sh

set -euo pipefail

echo "Removing LibreOffice..."

# Remove via apt
sudo apt-get remove -y libreoffice* 2>/dev/null || true

# Remove config
rm -rf ~/.config/libreoffice

sudo apt-get autoremove -y

echo "LibreOffice removed"
