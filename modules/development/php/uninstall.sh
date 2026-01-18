#!/bin/bash
# PHP Uninstallation
# modules/development/php/uninstall.sh

set -euo pipefail

echo "Removing PHP..."

# Remove PHP packages
sudo apt-get remove -y php* 2>/dev/null || true

# Remove Composer
sudo rm -f /usr/local/bin/composer
rm -rf ~/.composer
rm -rf ~/.config/composer

# Remove Ondrej PPA
sudo add-apt-repository --remove -y ppa:ondrej/php 2>/dev/null || true

sudo apt-get autoremove -y

echo "PHP removed"
