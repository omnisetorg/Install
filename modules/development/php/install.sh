#!/bin/bash
set -euo pipefail

if command -v php &>/dev/null; then
    echo "PHP is already installed: $(php -v | head -1)"
    read -p "Continue with reinstall/upgrade? [y/N] " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0
fi

echo "Installing PHP 8.5..."

# Add Ondrej's PPA
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

# Install PHP and common extensions
sudo apt-get install -y \
    php8.5 \
    php8.5-cli \
    php8.5-common \
    php8.5-curl \
    php8.5-mbstring \
    php8.5-xml \
    php8.5-zip \
    php8.5-mysql \
    php8.5-pgsql \
    php8.5-sqlite3 \
    php8.5-gd \
    php8.5-intl \
    php8.5-bcmath \
    php8.5-fpm

# Install Composer
if ! command -v composer &>/dev/null; then
    echo "Installing Composer..."
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php --quiet
    sudo mv composer.phar /usr/local/bin/composer
    rm -f composer-setup.php
fi

echo "PHP installed: $(php -v | head -1)"
echo "Composer: $(composer --version 2>/dev/null || echo 'installed')"
