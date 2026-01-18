#!/bin/bash
# VS Code Uninstallation
# modules/desktop/vscode/uninstall.sh

set -euo pipefail

echo "Removing VS Code..."

# Remove via apt
sudo apt-get remove -y code 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/vscode.list
sudo rm -f /usr/share/keyrings/microsoft.gpg

# Remove via snap
sudo snap remove code 2>/dev/null || true

# Remove config (preserves settings)
# rm -rf ~/.config/Code
# rm -rf ~/.vscode

sudo apt-get autoremove -y

echo "VS Code removed"
echo "Note: Settings in ~/.config/Code were preserved"
