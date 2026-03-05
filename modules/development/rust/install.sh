#!/bin/bash
set -euo pipefail

if command -v rustc &>/dev/null; then
    echo "Rust is already installed: $(rustc --version)"
    exit 0
fi

echo "Installing Rust via rustup..."

# Install rustup
local installer
installer=$(mktemp)
curl --proto '=https' --tlsv1.2 -sSf --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 https://sh.rustup.rs -o "$installer"
chmod +x "$installer"
sh "$installer" -y
rm -f "$installer"

# Source cargo env
source "$HOME/.cargo/env"

echo "Rust installed: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Run 'source ~/.cargo/env' to update PATH"
