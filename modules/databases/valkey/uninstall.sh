#!/bin/bash
# Valkey Uninstallation (Docker)
# modules/databases/valkey/uninstall.sh

set -euo pipefail

echo "Removing Valkey..."

# Stop and remove container
docker stop omniset-valkey 2>/dev/null || true
docker rm omniset-valkey 2>/dev/null || true

# Remove client
sudo apt-get remove -y redis-tools 2>/dev/null || true

echo "Valkey container removed"
echo "Note: Data in ~/.local/share/omniset/valkey was preserved"
echo "Run 'rm -rf ~/.local/share/omniset/valkey' to remove data"
