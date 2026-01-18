#!/bin/bash
# Obsidian Uninstallation
# modules/productivity/obsidian/uninstall.sh

set -euo pipefail

echo "Removing Obsidian..."

# Remove via snap
sudo snap remove obsidian 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y md.obsidian.Obsidian 2>/dev/null || true

# Remove AppImage installation
sudo rm -rf /opt/Obsidian
sudo rm -f /usr/local/bin/obsidian
sudo rm -f /usr/share/applications/obsidian.desktop

# Remove config (preserves vaults)
rm -rf ~/.config/obsidian

echo "Obsidian removed"
echo "Note: Your vaults (notes) were preserved"
