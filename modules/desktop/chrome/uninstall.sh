#!/bin/bash
# Google Chrome Uninstallation

sudo apt-get remove -y google-chrome-stable chromium-browser chromium 2>/dev/null || true
sudo rm -f /etc/apt/sources.list.d/google-chrome.list
echo "Chrome removed"
