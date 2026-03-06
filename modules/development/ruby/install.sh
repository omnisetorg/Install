#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v ruby &>/dev/null; then
    echo "Ruby is already installed ($(ruby --version))"
    exit 0
fi

echo "Installing Ruby..."

sudo apt-get update
sudo apt-get install -y ruby-full build-essential

# Install bundler
sudo gem install bundler

echo "Ruby installed successfully ($(ruby --version))"
