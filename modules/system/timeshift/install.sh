#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v timeshift &>/dev/null; then
    echo "Timeshift is already installed"
    exit 0
fi

echo "Installing Timeshift..."

sudo apt-get update
sudo apt-get install -y timeshift

echo "Timeshift installed successfully"
echo "Run 'sudo timeshift-gtk' to configure backups"
