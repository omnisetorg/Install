#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v keepassxc &>/dev/null; then
    echo "KeePassXC is already installed"
    exit 0
fi

echo "Installing KeePassXC..."

sudo apt-get update
sudo apt-get install -y keepassxc

echo "KeePassXC installed successfully"
