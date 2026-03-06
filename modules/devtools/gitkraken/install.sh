#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v gitkraken &>/dev/null || dpkg -l gitkraken &>/dev/null 2>&1; then
    echo "GitKraken is already installed"
    exit 0
fi

echo "Installing GitKraken..."

case "$ARCH" in
    amd64)
        wget -qO /tmp/gitkraken.deb "https://release.gitkraken.com/linux/gitkraken-amd64.deb"
        ;;
    arm64)
        wget -qO /tmp/gitkraken.deb "https://release.gitkraken.com/linux/gitkraken-arm64.deb"
        ;;
    *)
        echo "GitKraken is not available for $ARCH"
        exit 1
        ;;
esac

sudo apt-get install -y /tmp/gitkraken.deb
rm -f /tmp/gitkraken.deb

echo "GitKraken installed successfully"
