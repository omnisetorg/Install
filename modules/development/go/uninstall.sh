#!/bin/bash
# Go Uninstallation
# modules/development/go/uninstall.sh

set -euo pipefail

echo "Removing Go..."

# Remove via apt
sudo apt-get remove -y golang golang-go 2>/dev/null || true

# Remove manual installation
sudo rm -rf /usr/local/go

# Remove Go workspace
rm -rf ~/go

# Clean bashrc
sed -i '/GOPATH/d' ~/.bashrc 2>/dev/null || true
sed -i '/GOROOT/d' ~/.bashrc 2>/dev/null || true
sed -i '/go\/bin/d' ~/.bashrc 2>/dev/null || true

echo "Go removed"
