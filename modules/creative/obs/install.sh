#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v obs &>/dev/null; then
    echo "OBS Studio is already installed"
    exit 0
fi

case "$ARCH" in
    amd64|arm64)
        echo "Installing OBS Studio..."
        sudo add-apt-repository -y ppa:obsproject/obs-studio 2>/dev/null || true
        sudo apt-get update
        sudo apt-get install -y obs-studio
        echo "OBS Studio installed successfully"
        ;;
    *)
        echo "OBS Studio is not available for $ARCH"
        exit 1
        ;;
esac
