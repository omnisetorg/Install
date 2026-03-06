#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v flameshot &>/dev/null; then
    echo "Flameshot is already installed"
    exit 0
fi

echo "Installing Flameshot..."

sudo apt-get update
sudo apt-get install -y flameshot

echo "Flameshot installed successfully"
echo "Launch with 'flameshot gui' or bind it to Print Screen"
