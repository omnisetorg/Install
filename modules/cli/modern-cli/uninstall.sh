#!/bin/bash
# Modern CLI Tools Uninstallation
# modules/cli/modern-cli/uninstall.sh

set -euo pipefail

echo "Removing Modern CLI Tools..."

# Remove apt packages
sudo apt-get remove -y ripgrep fd-find bat btop fastfetch neofetch exa 2>/dev/null || true

# Remove fzf
if [[ -d ~/.fzf ]]; then
    ~/.fzf/uninstall --all 2>/dev/null || true
    rm -rf ~/.fzf
fi

# Remove zoxide
rm -f ~/.local/bin/zoxide 2>/dev/null || true

# Remove eza if manually installed
sudo rm -f /usr/local/bin/eza 2>/dev/null || true
sudo rm -f /usr/local/bin/btop 2>/dev/null || true

# Clean up bashrc entries
if [[ -f ~/.bashrc ]]; then
    sed -i '/# fzf configuration/,/FZF_DEFAULT_OPTS/d' ~/.bashrc 2>/dev/null || true
    sed -i '/# zoxide configuration/,/zoxide init/d' ~/.bashrc 2>/dev/null || true
    sed -i '/# eza aliases/,/alias lt=/d' ~/.bashrc 2>/dev/null || true
    sed -i "/alias fd='fdfind'/d" ~/.bashrc 2>/dev/null || true
    sed -i "/alias bat='batcat'/d" ~/.bashrc 2>/dev/null || true
    sed -i "/alias eza='exa'/d" ~/.bashrc 2>/dev/null || true
    sed -i "/alias btop='htop'/d" ~/.bashrc 2>/dev/null || true
    sed -i "/alias fastfetch='neofetch'/d" ~/.bashrc 2>/dev/null || true
fi

echo "Modern CLI Tools removed"
