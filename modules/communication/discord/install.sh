#!/bin/bash
# Discord Installation
set -euo pipefail

ARCH="${1:-amd64}"

if command -v discord &>/dev/null; then
    echo "Discord is already installed"
    exit 0
fi

case "$ARCH" in
    amd64)
        echo "Installing Discord..."
        wget -qO /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
        sudo dpkg -i /tmp/discord.deb || sudo apt-get install -f -y
        rm /tmp/discord.deb
        echo "Discord installed successfully"
        ;;
    *)
        echo "Discord is not available for $ARCH"
        echo "Consider using Discord web: https://discord.com/app"
        exit 1
        ;;
esac
