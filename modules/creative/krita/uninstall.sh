#!/bin/bash
set -euo pipefail

echo "Removing Krita..."

sudo apt-get remove -y krita 2>/dev/null || true

echo "Krita removed"
