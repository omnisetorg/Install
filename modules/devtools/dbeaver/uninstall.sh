#!/bin/bash
# DBeaver Uninstallation
# modules/devtools/dbeaver/uninstall.sh

set -euo pipefail

echo "Removing DBeaver..."

# Remove via apt
sudo apt-get remove -y dbeaver-ce 2>/dev/null || true

# Remove config
rm -rf ~/.dbeaver4
rm -rf ~/.local/share/DBeaverData

sudo apt-get autoremove -y

echo "DBeaver removed"
