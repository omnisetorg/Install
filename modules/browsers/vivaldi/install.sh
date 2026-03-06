#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v vivaldi &>/dev/null || command -v vivaldi-stable &>/dev/null; then
    echo "Vivaldi is already installed"
    exit 0
fi

echo "Installing Vivaldi..."

case "$ARCH" in
    amd64)
        wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/vivaldi-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vivaldi-archive-keyring.gpg] https://repo.vivaldi.com/archive/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y vivaldi-stable
        ;;
    arm64)
        wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/vivaldi-archive-keyring.gpg
        echo "deb [arch=arm64 signed-by=/usr/share/keyrings/vivaldi-archive-keyring.gpg] https://repo.vivaldi.com/archive/deb/ stable main" | sudo tee /etc/apt/sources.list.d/vivaldi.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y vivaldi-stable
        ;;
    *)
        echo "Vivaldi is not available for $ARCH"
        exit 1
        ;;
esac

echo "Vivaldi installed successfully"
