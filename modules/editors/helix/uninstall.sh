#!/bin/bash
# Helix Uninstallation
# modules/editors/helix/uninstall.sh

set -euo pipefail

echo "Removing Helix..."

# Remove via apt
sudo apt-get remove -y helix 2>/dev/null || true

# Remove via snap
sudo snap remove helix 2>/dev/null || true

# Remove manual installation
sudo rm -f /usr/local/bin/hx
sudo rm -rf /opt/helix-*

# Remove config and runtime
rm -rf ~/.config/helix
rm -rf ~/.local/share/helix

# Clean bashrc
sed -i '/HELIX_RUNTIME/d' ~/.bashrc 2>/dev/null || true

echo "Helix removed"
