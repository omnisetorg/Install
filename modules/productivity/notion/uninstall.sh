#!/bin/bash
# Notion Uninstallation
# modules/productivity/notion/uninstall.sh

set -euo pipefail

echo "Removing Notion..."

# Remove via snap
sudo snap remove notion-snap-reborn 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y notion-app-enhanced notion-app 2>/dev/null || true

# Remove config
rm -rf ~/.config/notion-app-enhanced
rm -rf ~/.config/Notion

sudo apt-get autoremove -y

echo "Notion removed"
