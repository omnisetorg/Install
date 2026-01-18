#!/bin/bash
# Python Uninstallation
# modules/development/python/uninstall.sh

set -euo pipefail

echo "Removing Python development tools..."

# Note: We don't remove system Python as it may break the system
# Only remove additional tools

# Remove pyenv
if [[ -d "$HOME/.pyenv" ]]; then
    rm -rf "$HOME/.pyenv"
fi

# Remove uv
rm -f ~/.cargo/bin/uv 2>/dev/null || true
rm -rf ~/.local/share/uv 2>/dev/null || true

# Remove pipx
pipx uninstall-all 2>/dev/null || true
rm -rf ~/.local/pipx

# Clean bashrc
sed -i '/PYENV_ROOT/d' ~/.bashrc 2>/dev/null || true
sed -i '/pyenv init/d' ~/.bashrc 2>/dev/null || true

echo "Python development tools removed"
echo "Note: System Python was preserved"
