#!/bin/bash
# Zed Uninstallation
# modules/editors/zed/uninstall.sh

set -euo pipefail

echo "Removing Zed..."

# Remove installation
rm -rf ~/.local/zed.app
rm -f ~/.local/bin/zed

# Remove desktop entry
rm -f ~/.local/share/applications/zed.desktop

# Remove config
rm -rf ~/.config/zed

echo "Zed removed"
