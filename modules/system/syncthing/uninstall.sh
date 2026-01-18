#!/bin/bash
# Syncthing Uninstallation
# modules/system/syncthing/uninstall.sh

set -euo pipefail

echo "Removing Syncthing..."

# Stop service
systemctl --user stop syncthing.service 2>/dev/null || true
systemctl --user disable syncthing.service 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y syncthing 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/syncthing.list
sudo rm -f /etc/apt/keyrings/syncthing-archive-keyring.gpg

# Remove config
rm -rf ~/.config/syncthing
rm -rf ~/.local/state/syncthing

sudo apt-get autoremove -y

echo "Syncthing removed"
echo "Note: Your synced folders were preserved"
