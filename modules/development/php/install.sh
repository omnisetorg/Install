#!/bin/bash
set -euo pipefail

if command -v php &>/dev/null; then
    echo "PHP is already installed: $(php -v | head -1)"
    read -p "Continue with reinstall/upgrade? [y/N] " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0
fi

echo "Installing PHP 8.4..."

# Add Ondrej's PPA
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

# Install PHP and common extensions
sudo apt-get install -y \
    php8.4 \
    php8.4-cli \
    php8.4-common \
    php8.4-curl \
    php8.4-mbstring \
    php8.4-xml \
    php8.4-zip \
    php8.4-mysql \
    php8.4-pgsql \
    php8.4-sqlite3 \
    php8.4-gd \
    php8.4-intl \
    php8.4-bcmath \
    php8.4-fpm

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
