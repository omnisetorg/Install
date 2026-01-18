#!/bin/bash
set -euo pipefail

if command -v kdenlive &>/dev/null; then
    echo "Kdenlive is already installed"
    exit 0
fi

echo "Installing Kdenlive..."
sudo add-apt-repository -y ppa:kdenlive/kdenlive-stable 2>/dev/null || true
sudo apt-get update
sudo apt-get install -y kdenlive

echo "Kdenlive installed successfully"
