#!/bin/bash
set -euo pipefail

echo "Removing mpv..."

sudo apt-get remove -y mpv 2>/dev/null || true

echo "mpv removed"
