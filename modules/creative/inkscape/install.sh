#!/bin/bash
set -euo pipefail

if command -v inkscape &>/dev/null; then
    echo "Inkscape is already installed"
    exit 0
fi

echo "Installing Inkscape..."
sudo add-apt-repository -y ppa:inkscape.dev/stable 2>/dev/null || true
sudo apt-get update
sudo apt-get install -y inkscape

echo "Inkscape installed successfully"
