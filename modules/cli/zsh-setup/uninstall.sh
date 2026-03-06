#!/bin/bash
set -euo pipefail

echo "Removing Zsh + Oh My Zsh..."

# Remove Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    rm -rf "$HOME/.oh-my-zsh"
    echo "Oh My Zsh removed"
fi

# Remove zsh package
sudo apt-get remove -y zsh 2>/dev/null || true

# Switch back to bash if zsh was default
if [[ "$(getent passwd "$USER" | cut -d: -f7)" == *"zsh"* ]]; then
    chsh -s /bin/bash 2>/dev/null || true
fi

echo "Zsh removed. Note: ~/.zshrc was preserved."
