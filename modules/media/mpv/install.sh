#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v mpv &>/dev/null; then
    echo "mpv is already installed"
    exit 0
fi

echo "Installing mpv..."

sudo apt-get update
sudo apt-get install -y mpv

echo "mpv installed successfully"
