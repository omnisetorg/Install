#!/bin/bash
set -euo pipefail

echo "Removing Flutter..."

# Remove snap version
sudo snap remove flutter 2>/dev/null || true

# Remove git-cloned version
if [[ -d "$HOME/.flutter-sdk" ]]; then
    rm -rf "$HOME/.flutter-sdk"
    echo "Removed Flutter SDK from ~/.flutter-sdk"
fi

# Clean PATH entry from .bashrc
sed -i '/flutter-sdk\/bin/d' "$HOME/.bashrc" 2>/dev/null || true

echo "Flutter removed"
