#!/bin/bash
set -euo pipefail

echo "Removing GitKraken..."

sudo apt-get remove -y gitkraken 2>/dev/null || true

echo "GitKraken removed"
