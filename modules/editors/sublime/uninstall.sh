#!/bin/bash
# Sublime Text Uninstallation
# modules/editors/sublime/uninstall.sh

set -euo pipefail

echo "Removing Sublime Text..."

# Remove via apt
sudo apt-get remove -y sublime-text 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/sublime-text.list
sudo rm -f /etc/apt/trusted.gpg.d/sublimehq-archive.gpg

# Remove config (optional)
# rm -rf ~/.config/sublime-text

sudo apt-get autoremove -y

echo "Sublime Text removed"
echo "Note: User config in ~/.config/sublime-text was preserved"
