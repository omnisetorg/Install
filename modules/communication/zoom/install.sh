#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v zoom &>/dev/null; then
    echo "Zoom is already installed"
    exit 0
fi

case "$ARCH" in
    amd64)
        URL="https://zoom.us/client/latest/zoom_amd64.deb"
        ;;
    arm64)
        URL="https://zoom.us/client/latest/zoom_arm64.deb"
        ;;
    *)
        echo "Zoom is not available for $ARCH"
        exit 1
        ;;
esac

echo "Installing Zoom..."
wget -qO /tmp/zoom.deb "$URL"
sudo dpkg -i /tmp/zoom.deb || sudo apt-get install -f -y
rm /tmp/zoom.deb

echo "Zoom installed successfully"
