#!/bin/bash
set -euo pipefail

if command -v telegram-desktop &>/dev/null; then
    echo "Telegram is already installed"
    exit 0
fi

echo "Installing Telegram..."
sudo apt-get update
sudo apt-get install -y telegram-desktop

echo "Telegram installed successfully"
