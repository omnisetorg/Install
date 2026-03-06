#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

echo "Installing Zsh + Oh My Zsh..."

# Install zsh
if ! command -v zsh &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y zsh
else
    echo "Zsh is already installed"
fi

# Install Oh My Zsh (unattended)
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    echo "Oh My Zsh installed"
else
    echo "Oh My Zsh is already installed"
fi

# Install popular plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Enable plugins in .zshrc
if [[ -f "$HOME/.zshrc" ]]; then
    sed -i 's/^plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc" 2>/dev/null || true
fi

echo ""
echo "Zsh + Oh My Zsh installation complete"
echo "Run 'chsh -s \$(which zsh)' to set Zsh as your default shell"
