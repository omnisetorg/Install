#!/bin/bash
set -euo pipefail

if command -v thunderbird &>/dev/null; then
    echo "Thunderbird is already installed"
    exit 0
fi

echo "Installing Thunderbird..."
sudo apt-get update
sudo apt-get install -y thunderbird

echo "Thunderbird installed successfully"
