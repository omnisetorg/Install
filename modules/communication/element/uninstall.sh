#!/bin/bash
set -euo pipefail

echo "Removing Element..."

sudo apt-get remove -y element-desktop 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/element-io.list
sudo rm -f /usr/share/keyrings/element-io-archive-keyring.gpg

echo "Element removed"
