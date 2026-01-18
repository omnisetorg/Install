#!/bin/bash
# MariaDB Uninstallation (Docker)
# modules/databases/mariadb/uninstall.sh

set -euo pipefail

echo "Removing MariaDB..."

# Stop and remove container
docker stop omniset-mariadb 2>/dev/null || true
docker rm omniset-mariadb 2>/dev/null || true

# Remove client
sudo apt-get remove -y mariadb-client 2>/dev/null || true

# Data is preserved by default
echo "MariaDB container removed"
echo "Note: Data in ~/.local/share/omniset/mariadb was preserved"
echo "Run 'rm -rf ~/.local/share/omniset/mariadb' to remove data"
