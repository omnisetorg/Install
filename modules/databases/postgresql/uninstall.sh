#!/bin/bash
# PostgreSQL Uninstallation (Docker)
# modules/databases/postgresql/uninstall.sh

set -euo pipefail

echo "Removing PostgreSQL..."

# Stop and remove container
docker stop omniset-postgres 2>/dev/null || true
docker rm omniset-postgres 2>/dev/null || true

# Remove client
sudo apt-get remove -y postgresql-client 2>/dev/null || true

echo "PostgreSQL container removed"
echo "Note: Data in ~/.local/share/omniset/postgres was preserved"
echo "Run 'rm -rf ~/.local/share/omniset/postgres' to remove data"
