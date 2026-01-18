#!/bin/bash
# Postman Uninstallation
# modules/devtools/postman/uninstall.sh

set -euo pipefail

echo "Removing Postman..."

# Remove installation
sudo rm -rf /opt/Postman
sudo rm -f /usr/local/bin/postman

# Remove desktop entry
sudo rm -f /usr/share/applications/postman.desktop

# Remove config
rm -rf ~/.config/Postman

echo "Postman removed"
