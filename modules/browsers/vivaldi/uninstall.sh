#!/bin/bash
set -euo pipefail

echo "Removing Vivaldi..."

sudo apt-get remove -y vivaldi-stable 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/vivaldi.list
sudo rm -f /usr/share/keyrings/vivaldi-archive-keyring.gpg

echo "Vivaldi removed"
