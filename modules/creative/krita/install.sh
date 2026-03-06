#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v krita &>/dev/null; then
    echo "Krita is already installed"
    exit 0
fi

echo "Installing Krita..."

sudo apt-get update
sudo apt-get install -y krita

echo "Krita installed successfully"
