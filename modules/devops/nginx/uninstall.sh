#!/bin/bash
# Nginx Uninstallation (Docker)
# modules/devops/nginx/uninstall.sh

set -euo pipefail

echo "Removing Nginx..."

# Stop and remove container
docker stop omniset-nginx 2>/dev/null || true
docker rm omniset-nginx 2>/dev/null || true

# Data is preserved by default
echo "Nginx container removed"
echo "Note: Config and data in ~/.local/share/omniset/nginx was preserved"
echo "Run 'rm -rf ~/.local/share/omniset/nginx' to remove all data"
