#!/bin/bash
set -euo pipefail

echo "Removing Timeshift..."

sudo apt-get remove -y timeshift 2>/dev/null || true

echo "Timeshift removed"
echo "Note: Existing snapshots were preserved"
