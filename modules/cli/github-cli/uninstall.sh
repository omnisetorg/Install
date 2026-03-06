#!/bin/bash
set -euo pipefail

echo "Removing GitHub CLI..."

sudo apt-get remove -y gh 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/github-cli.list
sudo rm -f /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "GitHub CLI removed"
