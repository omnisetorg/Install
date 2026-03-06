#!/bin/bash
set -euo pipefail

echo "Removing Teams for Linux..."

sudo snap remove teams-for-linux 2>/dev/null || true

echo "Teams for Linux removed"
