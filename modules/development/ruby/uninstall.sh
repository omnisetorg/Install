#!/bin/bash
set -euo pipefail

echo "Removing Ruby..."

sudo apt-get remove -y ruby-full 2>/dev/null || true
sudo apt-get autoremove -y 2>/dev/null || true

echo "Ruby removed"
