#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if [[ "$ARCH" != "amd64" ]]; then
    echo "Steam is only available for amd64 architecture"
    exit 1
fi

if command -v steam &>/dev/null; then
    echo "Steam is already installed"
    exit 0
fi

echo "Installing Steam..."

# Enable 32-bit architecture (required for Steam)
sudo dpkg --add-architecture i386
sudo apt-get update

# Download and install
wget -qO /tmp/steam.deb "https://cdn.akamai.steamstatic.com/client/installer/steam.deb"
sudo dpkg -i /tmp/steam.deb || sudo apt-get install -f -y
rm /tmp/steam.deb

echo "Steam installed successfully"
