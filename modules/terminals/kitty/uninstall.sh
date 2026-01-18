#!/bin/bash
# Kitty Uninstallation
# modules/terminals/kitty/uninstall.sh

set -euo pipefail

echo "Removing Kitty..."

# Remove official installation
rm -rf ~/.local/kitty.app
rm -f ~/.local/bin/kitty
rm -f ~/.local/bin/kitten

# Remove desktop entries
rm -f ~/.local/share/applications/kitty.desktop
rm -f ~/.local/share/applications/kitty-open.desktop

# Remove via apt
sudo apt-get remove -y kitty 2>/dev/null || true

# Remove config
rm -rf ~/.config/kitty

echo "Kitty removed"
