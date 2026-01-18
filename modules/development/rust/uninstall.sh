#!/bin/bash
# Rust Uninstallation
# modules/development/rust/uninstall.sh

set -euo pipefail

echo "Removing Rust..."

# Use rustup to uninstall
if command -v rustup &>/dev/null; then
    rustup self uninstall -y
fi

# Remove manually if rustup not available
rm -rf ~/.rustup
rm -rf ~/.cargo

# Clean bashrc
sed -i '/\.cargo\/env/d' ~/.bashrc 2>/dev/null || true
sed -i '/CARGO_HOME/d' ~/.bashrc 2>/dev/null || true
sed -i '/RUSTUP_HOME/d' ~/.bashrc 2>/dev/null || true

echo "Rust removed"
