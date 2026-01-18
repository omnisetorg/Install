#!/bin/bash
set -euo pipefail

if command -v audacity &>/dev/null; then
    echo "Audacity is already installed"
    exit 0
fi

echo "Installing Audacity..."
sudo apt-get update
sudo apt-get install -y audacity

echo "Audacity installed successfully"
