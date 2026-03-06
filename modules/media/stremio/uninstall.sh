#!/bin/bash
set -euo pipefail

echo "Removing Stremio..."

sudo apt-get remove -y stremio 2>/dev/null || true

echo "Stremio removed"
