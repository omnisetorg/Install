#!/bin/bash
# Cursor Uninstallation
# modules/editors/cursor/uninstall.sh

set -euo pipefail

echo "Removing Cursor..."

# Remove installation
sudo rm -rf /opt/Cursor
sudo rm -f /usr/local/bin/cursor

# Remove desktop entry
sudo rm -f /usr/share/applications/cursor.desktop

# Remove config (optional - preserves user settings)
# rm -rf ~/.config/Cursor

echo "Cursor removed"
echo "Note: User config in ~/.config/Cursor was preserved"
