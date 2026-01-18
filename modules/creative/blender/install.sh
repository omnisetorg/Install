#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v blender &>/dev/null; then
    echo "Blender is already installed"
    exit 0
fi

case "$ARCH" in
    amd64|arm64)
        echo "Installing Blender..."
        sudo add-apt-repository -y ppa:savoury1/blender 2>/dev/null || true
        sudo apt-get update
        sudo apt-get install -y blender
        echo "Blender installed successfully"
        ;;
    *)
        echo "Blender is not available for $ARCH"
        exit 1
        ;;
esac
