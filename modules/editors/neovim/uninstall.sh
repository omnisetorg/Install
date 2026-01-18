#!/bin/bash
# Neovim Uninstallation
# modules/editors/neovim/uninstall.sh

set -euo pipefail

echo "Removing Neovim..."

# Remove via apt
sudo apt-get remove -y neovim 2>/dev/null || true

# Remove manual installation
sudo rm -rf /opt/nvim
sudo rm -f /usr/local/bin/nvim
sudo rm -f /usr/local/bin/nvim.appimage

# Remove config and data
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

sudo apt-get autoremove -y

echo "Neovim removed"
