#!/bin/bash
# Slack Uninstallation
# modules/communication/slack/uninstall.sh

set -euo pipefail

echo "Removing Slack..."

# Remove via snap
sudo snap remove slack 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y slack-desktop 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y com.slack.Slack 2>/dev/null || true

# Remove config
rm -rf ~/.config/Slack

sudo apt-get autoremove -y

echo "Slack removed"
