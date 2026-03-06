#!/bin/bash
set -euo pipefail

if command -v rustc &>/dev/null; then
    echo "Rust is already installed: $(rustc --version)"
    exit 0
fi

echo "Installing Rust via rustup..."

# Install rustup
_installer=$(mktemp)
curl --proto '=https' --tlsv1.2 -sSf --connect-timeout 15 --max-time 300 --retry 3 --retry-delay 2 https://sh.rustup.rs -o "$_installer"
chmod +x "$_installer"
sh "$_installer" -y
rm -f "$_installer"

# Source cargo env
source "$HOME/.cargo/env"

echo "Rust installed: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Run 'source ~/.cargo/env' to update PATH"
