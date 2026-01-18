#!/bin/bash
# Firefox Uninstallation
# modules/desktop/firefox/uninstall.sh

set -euo pipefail

echo "Removing Firefox..."

# Remove via apt
sudo apt-get remove -y firefox 2>/dev/null || true

# Remove via snap
sudo snap remove firefox 2>/dev/null || true

# Remove Mozilla repo
sudo rm -f /etc/apt/sources.list.d/mozilla.list
sudo rm -f /etc/apt/keyrings/packages.mozilla.org.asc

# Remove config (preserves profile)
# rm -rf ~/.mozilla/firefox

sudo apt-get autoremove -y

echo "Firefox removed"
echo "Note: Profile in ~/.mozilla/firefox was preserved"
