#!/bin/bash
# Redis Uninstallation (Docker)
# modules/databases/redis/uninstall.sh

set -euo pipefail

echo "Removing Redis..."

# Stop and remove container
docker stop omniset-redis 2>/dev/null || true
docker rm omniset-redis 2>/dev/null || true

# Remove client
sudo apt-get remove -y redis-tools 2>/dev/null || true

echo "Redis container removed"
echo "Note: Data in ~/.local/share/omniset/redis was preserved"
echo "Run 'rm -rf ~/.local/share/omniset/redis' to remove data"
