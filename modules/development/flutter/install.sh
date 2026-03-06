#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v flutter &>/dev/null; then
    echo "Flutter is already installed ($(flutter --version | head -1))"
    exit 0
fi

echo "Installing Flutter..."

# Install via snap (recommended for Linux)
if command -v snap &>/dev/null; then
    sudo snap install flutter --classic
else
    # Fallback: clone from git
    FLUTTER_DIR="$HOME/.flutter-sdk"
    if [[ ! -d "$FLUTTER_DIR" ]]; then
        git clone --depth=1 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
    fi

    # Add to PATH via profile
    if ! grep -q 'flutter-sdk/bin' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.flutter-sdk/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    export PATH="$FLUTTER_DIR/bin:$PATH"
fi

# Install dependencies
sudo apt-get update
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev 2>/dev/null || true

echo "Flutter installed successfully"
echo "Run 'flutter doctor' to verify your setup"
