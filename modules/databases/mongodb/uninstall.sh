#!/bin/bash
# MongoDB Uninstallation (Docker)
# modules/databases/mongodb/uninstall.sh

set -euo pipefail

echo "Removing MongoDB..."

# Stop and remove container
docker stop omniset-mongodb 2>/dev/null || true
docker rm omniset-mongodb 2>/dev/null || true

# Remove mongosh client
sudo apt-get remove -y mongodb-mongosh 2>/dev/null || true

echo "MongoDB container removed"
echo "Note: Data in ~/.local/share/omniset/mongodb was preserved"
echo "Run 'rm -rf ~/.local/share/omniset/mongodb' to remove data"
