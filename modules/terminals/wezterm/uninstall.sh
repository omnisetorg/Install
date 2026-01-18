#!/bin/bash
# WezTerm Uninstallation
# modules/terminals/wezterm/uninstall.sh

set -euo pipefail

echo "Removing WezTerm..."

# Remove via apt
sudo apt-get remove -y wezterm 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/wezterm.list
sudo rm -f /usr/share/keyrings/wezterm-fury.gpg

# Remove via flatpak
flatpak uninstall -y org.wezfurlong.wezterm 2>/dev/null || true

# Remove AppImage
sudo rm -f /usr/local/bin/wezterm

# Remove config
rm -rf ~/.config/wezterm

sudo apt-get autoremove -y

echo "WezTerm removed"
