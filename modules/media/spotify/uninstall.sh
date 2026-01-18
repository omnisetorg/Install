#!/bin/bash
# Spotify Uninstallation
# modules/media/spotify/uninstall.sh

set -euo pipefail

echo "Removing Spotify..."

# Remove via snap
sudo snap remove spotify 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y com.spotify.Client 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y spotify-client 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/spotify.list
sudo rm -f /etc/apt/trusted.gpg.d/spotify.gpg

# Remove config
rm -rf ~/.config/spotify
rm -rf ~/.cache/spotify

sudo apt-get autoremove -y

echo "Spotify removed"
