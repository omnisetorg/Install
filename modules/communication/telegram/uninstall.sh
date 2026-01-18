#!/bin/bash
# Telegram Uninstallation
# modules/communication/telegram/uninstall.sh

set -euo pipefail

echo "Removing Telegram..."

# Remove via snap
sudo snap remove telegram-desktop 2>/dev/null || true

# Remove via flatpak
flatpak uninstall -y org.telegram.desktop 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y telegram-desktop 2>/dev/null || true

# Remove manual installation
rm -rf ~/Applications/Telegram
rm -f ~/.local/share/applications/telegramdesktop.desktop

# Remove config
rm -rf ~/.local/share/TelegramDesktop

sudo apt-get autoremove -y

echo "Telegram removed"
