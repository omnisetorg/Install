#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v teams-for-linux &>/dev/null || snap list teams-for-linux &>/dev/null 2>&1; then
    echo "Teams for Linux is already installed"
    exit 0
fi

echo "Installing Teams for Linux..."

# Microsoft discontinued the official Teams client for Linux.
# Install the community-maintained "Teams for Linux" via snap.
if command -v snap &>/dev/null; then
    sudo snap install teams-for-linux
else
    echo "Snap is required to install Teams for Linux"
    echo "Install snapd first: sudo apt install snapd"
    exit 1
fi

echo "Teams for Linux installed successfully"
