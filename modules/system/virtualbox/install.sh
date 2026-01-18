#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if [[ "$ARCH" != "amd64" ]]; then
    echo "VirtualBox is only available for amd64"
    exit 1
fi

if command -v virtualbox &>/dev/null; then
    echo "VirtualBox is already installed"
    exit 0
fi

echo "Installing VirtualBox..."
sudo apt-get update
sudo apt-get install -y virtualbox virtualbox-ext-pack

echo "VirtualBox installed successfully"
