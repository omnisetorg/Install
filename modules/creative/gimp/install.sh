#!/bin/bash
set -euo pipefail

if command -v gimp &>/dev/null; then
    echo "GIMP is already installed"
    exit 0
fi

echo "Installing GIMP..."

# Try PPA for latest version
if sudo add-apt-repository -y ppa:ubuntuhandbook1/gimp 2>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y gimp
else
    # Fallback to standard apt
    sudo apt-get update
    sudo apt-get install -y gimp
fi

echo "GIMP installed successfully"
