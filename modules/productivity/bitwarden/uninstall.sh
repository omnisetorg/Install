#!/bin/bash
# Bitwarden Uninstallation
# modules/productivity/bitwarden/uninstall.sh

set -euo pipefail

echo "Removing Bitwarden..."

# Remove via snap
sudo snap remove bitwarden 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y com.bitwarden.desktop 2>/dev/null || true

# Remove AppImage installation
sudo rm -rf /opt/Bitwarden
sudo rm -f /usr/local/bin/bitwarden
sudo rm -f /usr/share/applications/bitwarden.desktop

# Remove CLI
sudo npm uninstall -g @bitwarden/cli 2>/dev/null || true
sudo snap remove bw 2>/dev/null || true

# Remove config
rm -rf ~/.config/Bitwarden

echo "Bitwarden removed"
