#!/bin/bash
# Node.js Installation
set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-lts}"

# Parse version from options
VERSION="lts"
if [[ "$OPTIONS" =~ ^[0-9]+$ ]]; then
    VERSION="$OPTIONS"
elif [[ "$OPTIONS" == "current" ]]; then
    VERSION="current"
fi

echo "Installing Node.js ($VERSION)..."

if command -v node &>/dev/null; then
    echo "Node.js is already installed: $(node --version)"
    read -p "Reinstall? [y/N] " confirm
    [[ ! "$confirm" =~ ^[Yy]$ ]] && exit 0
fi

# Determine NodeSource URL
case "$VERSION" in
    lts|20)
        SETUP_URL="https://deb.nodesource.com/setup_20.x"
        ;;
    current|22)
        SETUP_URL="https://deb.nodesource.com/setup_22.x"
        ;;
    18)
        SETUP_URL="https://deb.nodesource.com/setup_18.x"
        ;;
    *)
        SETUP_URL="https://deb.nodesource.com/setup_lts.x"
        ;;
esac

# Install Node.js via NodeSource
curl -fsSL "$SETUP_URL" | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
echo "Node.js $(node --version) installed"
echo "npm $(npm --version)"

# Install global packages if requested
GLOBAL_PACKAGES=""
[[ "$OPTIONS" == *"yarn"* ]] && GLOBAL_PACKAGES="$GLOBAL_PACKAGES yarn"
[[ "$OPTIONS" == *"pnpm"* ]] && GLOBAL_PACKAGES="$GLOBAL_PACKAGES pnpm"
[[ "$OPTIONS" == *"typescript"* ]] && GLOBAL_PACKAGES="$GLOBAL_PACKAGES typescript"
[[ "$OPTIONS" == *"nodemon"* ]] && GLOBAL_PACKAGES="$GLOBAL_PACKAGES nodemon"
[[ "$OPTIONS" == *"pm2"* ]] && GLOBAL_PACKAGES="$GLOBAL_PACKAGES pm2"

if [[ -n "$GLOBAL_PACKAGES" ]]; then
    echo "Installing global packages:$GLOBAL_PACKAGES"
    sudo npm install -g $GLOBAL_PACKAGES
fi

echo "Node.js installation complete"
