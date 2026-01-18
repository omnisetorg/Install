#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v slack &>/dev/null; then
    echo "Slack is already installed"
    exit 0
fi

case "$ARCH" in
    amd64)
        URL="https://downloads.slack-edge.com/desktop-releases/linux/x64/4.36.140/slack-desktop-4.36.140-amd64.deb"
        ;;
    arm64)
        URL="https://downloads.slack-edge.com/desktop-releases/linux/arm64/4.36.140/slack-desktop-4.36.140-arm64.deb"
        ;;
    *)
        echo "Slack is not available for $ARCH"
        exit 1
        ;;
esac

echo "Installing Slack..."
wget -qO /tmp/slack.deb "$URL"
sudo dpkg -i /tmp/slack.deb || sudo apt-get install -f -y
rm /tmp/slack.deb

echo "Slack installed successfully"
