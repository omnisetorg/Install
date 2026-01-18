#!/bin/bash
# VLC Media Player Installation
set -euo pipefail

if command -v vlc &>/dev/null; then
    echo "VLC is already installed"
    exit 0
fi

echo "Installing VLC Media Player..."
sudo apt-get update
sudo apt-get install -y vlc
echo "VLC installed successfully"
