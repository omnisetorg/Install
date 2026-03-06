#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v ngrok &>/dev/null; then
    echo "ngrok is already installed"
    exit 0
fi

echo "Installing ngrok..."

if command -v snap &>/dev/null; then
    sudo snap install ngrok
else
    # Fallback: install via apt repo
    curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y ngrok
fi

echo "ngrok installed successfully"
echo "Run 'ngrok config add-authtoken <token>' to authenticate"
