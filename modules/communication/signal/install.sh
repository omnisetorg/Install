#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v signal-desktop &>/dev/null; then
    echo "Signal is already installed"
    exit 0
fi

case "$ARCH" in
    amd64|arm64)
        echo "Installing Signal..."

        # Add repository key
        wget -qO- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null

        # Add repository
        echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal.list

        sudo apt-get update
        sudo apt-get install -y signal-desktop

        echo "Signal installed successfully"
        ;;
    *)
        echo "Signal is not available for $ARCH"
        exit 1
        ;;
esac
