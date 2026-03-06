#!/bin/bash
set -euo pipefail

echo "Removing ngrok..."

sudo snap remove ngrok 2>/dev/null || true
sudo apt-get remove -y ngrok 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/ngrok.list
sudo rm -f /etc/apt/trusted.gpg.d/ngrok.asc

echo "ngrok removed"
