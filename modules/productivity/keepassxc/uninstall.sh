#!/bin/bash
set -euo pipefail

echo "Removing KeePassXC..."

sudo apt-get remove -y keepassxc 2>/dev/null || true

echo "KeePassXC removed"
echo "Note: Your database files were preserved"
