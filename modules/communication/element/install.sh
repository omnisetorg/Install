#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v element-desktop &>/dev/null || dpkg -l element-desktop &>/dev/null 2>&1; then
    echo "Element is already installed"
    exit 0
fi

echo "Installing Element..."

# Add Element repo
sudo wget -qO /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" | sudo tee /etc/apt/sources.list.d/element-io.list >/dev/null

sudo apt-get update
sudo apt-get install -y element-desktop

echo "Element installed successfully"
