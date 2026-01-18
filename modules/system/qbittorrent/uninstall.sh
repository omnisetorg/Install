#!/bin/bash
# qBittorrent Uninstallation
# modules/system/qbittorrent/uninstall.sh

set -euo pipefail

echo "Removing qBittorrent..."

# Remove via apt
sudo apt-get remove -y qbittorrent qbittorrent-nox 2>/dev/null || true

# Remove PPA
sudo add-apt-repository --remove -y ppa:qbittorrent-team/qbittorrent-stable 2>/dev/null || true

# Remove config
rm -rf ~/.config/qBittorrent
rm -rf ~/.local/share/qBittorrent

sudo apt-get autoremove -y

echo "qBittorrent removed"
