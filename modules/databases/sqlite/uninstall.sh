#!/bin/bash
# SQLite Uninstallation
# modules/databases/sqlite/uninstall.sh

set -euo pipefail

echo "Removing SQLite tools..."

# Remove via apt
sudo apt-get remove -y sqlite3 sqlitebrowser 2>/dev/null || true

# Remove litecli
pipx uninstall litecli 2>/dev/null || true
pip3 uninstall -y litecli 2>/dev/null || true

sudo apt-get autoremove -y

echo "SQLite tools removed"
echo "Note: Your .db files were not removed"
