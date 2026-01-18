#!/bin/bash
# Base Essentials Uninstallation
# modules/base/essentials/uninstall.sh

set -euo pipefail

echo "Removing base essential packages..."

# Note: These are commonly needed system packages
# Removing them may break other software

echo "WARNING: Base essentials are commonly required by other software"
echo "Uninstalling may cause issues with other applications"
echo ""
read -p "Are you sure you want to continue? [y/N] " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Remove packages
sudo apt-get remove -y \
    build-essential \
    curl \
    wget \
    git \
    vim \
    htop \
    unzip \
    jq \
    tmux \
    2>/dev/null || true

sudo apt-get autoremove -y

echo "Base essentials removed"
