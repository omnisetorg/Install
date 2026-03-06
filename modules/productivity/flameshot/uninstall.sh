#!/bin/bash
set -euo pipefail

echo "Removing Flameshot..."

sudo apt-get remove -y flameshot 2>/dev/null || true

echo "Flameshot removed"
