#!/bin/bash
set -euo pipefail

if command -v rustc &>/dev/null; then
    echo "Rust is already installed: $(rustc --version)"
    exit 0
fi

echo "Installing Rust via rustup..."

# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Source cargo env
source "$HOME/.cargo/env"

echo "Rust installed: $(rustc --version)"
echo "Cargo: $(cargo --version)"
echo "Run 'source ~/.cargo/env' to update PATH"
