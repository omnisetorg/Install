#!/bin/bash

# Integration script for disable-snap functionality
# Location: install/system/disable-snap.sh

arch=$1
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Check if Ubuntu system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]]; then
        echo "Snap disable feature is only available on Ubuntu systems"
        exit 0
    fi
else
    echo "Cannot detect OS - skipping snap disable"
    exit 0
fi

echo "Snap Management: Offering to disable snap services..."
echo ""
echo "Ubuntu includes Snap package management by default."
echo "Some users prefer to disable it in favor of APT packages."
echo ""
echo "Would you like to disable Snap? (y/N)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    if [ -x "$PROJECT_ROOT/scripts/disable-snap.sh" ]; then
        "$PROJECT_ROOT/scripts/disable-snap.sh" disable
    else
        echo "Error: disable-snap.sh script not found or not executable"
        exit 1
    fi
else
    echo "Keeping Snap enabled - you can disable it later with:"
    echo "./scripts/disable-snap.sh"
fi