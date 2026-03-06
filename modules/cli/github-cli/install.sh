#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v gh &>/dev/null; then
    echo "GitHub CLI is already installed: $(gh --version | head -1)"
    exit 0
fi

echo "Installing GitHub CLI..."

# Add GitHub CLI apt repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

sudo apt-get update
sudo apt-get install -y gh

echo "GitHub CLI installed: $(gh --version | head -1)"
echo "Run 'gh auth login' to authenticate"
