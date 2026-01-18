#!/bin/bash
set -euo pipefail

if command -v lutris &>/dev/null; then
    echo "Lutris is already installed"
    exit 0
fi

echo "Installing Lutris..."
sudo add-apt-repository -y ppa:lutris-team/lutris
sudo apt-get update
sudo apt-get install -y lutris

echo "Lutris installed successfully"
