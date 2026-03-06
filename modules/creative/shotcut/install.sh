#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v shotcut &>/dev/null; then
    echo "Shotcut is already installed"
    exit 0
fi

echo "Installing Shotcut..."

if command -v snap &>/dev/null; then
    sudo snap install shotcut --classic
elif command -v flatpak &>/dev/null; then
    flatpak install -y flathub org.shotcut.Shotcut
else
    sudo apt-get update
    sudo apt-get install -y shotcut
fi

echo "Shotcut installed successfully"
