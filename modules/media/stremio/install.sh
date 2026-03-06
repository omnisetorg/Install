#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v stremio &>/dev/null || dpkg -l stremio &>/dev/null 2>&1; then
    echo "Stremio is already installed"
    exit 0
fi

echo "Installing Stremio..."

case "$ARCH" in
    amd64)
        wget -qO /tmp/stremio.deb "https://dl.strem.io/server/v4.20.8/desktop/linux/stremio_4.20-1_amd64.deb" 2>/dev/null || \
            wget -qO /tmp/stremio.deb "https://dl.strem.io/shell-linux/v4.4.168/stremio_4.4.168-1_amd64.deb"
        sudo apt-get install -y /tmp/stremio.deb
        rm -f /tmp/stremio.deb
        ;;
    *)
        echo "Stremio is not available for $ARCH"
        exit 1
        ;;
esac

echo "Stremio installed successfully"
