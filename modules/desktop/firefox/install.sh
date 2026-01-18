#!/bin/bash
set -euo pipefail

if command -v firefox &>/dev/null; then
    echo "Firefox is already installed"
    exit 0
fi

echo "Installing Firefox..."
sudo apt-get update
sudo apt-get install -y firefox
echo "Firefox installed successfully"
