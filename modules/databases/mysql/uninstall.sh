#!/bin/bash
# MySQL Uninstallation (Docker)
# modules/databases/mysql/uninstall.sh

set -euo pipefail

echo "Removing MySQL..."

# Stop and remove container
docker stop omniset-mysql 2>/dev/null || true
docker rm omniset-mysql 2>/dev/null || true

# Remove client
sudo apt-get remove -y mysql-client 2>/dev/null || true

echo "MySQL container removed"
echo "Note: Data in ~/.local/share/omniset/mysql was preserved"
echo "Run 'rm -rf ~/.local/share/omniset/mysql' to remove data"
