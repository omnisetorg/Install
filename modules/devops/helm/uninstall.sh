#!/bin/bash
# Helm Uninstallation
# modules/devops/helm/uninstall.sh

set -euo pipefail

echo "Removing Helm..."

# Remove binary
sudo rm -f /usr/local/bin/helm

# Remove cache and config
rm -rf ~/.cache/helm
rm -rf ~/.config/helm
rm -rf ~/.local/share/helm

# Clean bashrc
sed -i '/helm completion/d' ~/.bashrc 2>/dev/null || true

echo "Helm removed"
