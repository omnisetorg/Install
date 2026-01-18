#!/bin/bash
# Signal Uninstallation
# modules/communication/signal/uninstall.sh

set -euo pipefail

echo "Removing Signal..."

# Remove via apt
sudo apt-get remove -y signal-desktop 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/signal-xenial.list
sudo rm -f /usr/share/keyrings/signal-desktop-keyring.gpg

# Remove via flatpak
flatpak uninstall -y org.signal.Signal 2>/dev/null || true

# Remove config
rm -rf ~/.config/Signal

sudo apt-get autoremove -y

echo "Signal removed"
