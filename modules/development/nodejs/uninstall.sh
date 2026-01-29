#!/bin/bash
# Node.js Uninstall Script
set -euo pipefail

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_info() { echo "ℹ $1"; }
fi

REMOVE_CONFIG="${1:-false}"

print_step "Uninstalling Node.js..."

# Remove NVM-installed Node.js
if [[ -d "$HOME/.nvm" ]]; then
    print_step "Removing NVM installation..."

    # Source nvm to get access to it
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Remove all installed Node versions
    if command -v nvm &>/dev/null; then
        for version in $(nvm ls --no-colors 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' || true); do
            nvm uninstall "$version" 2>/dev/null || true
        done
    fi

    if [[ "$REMOVE_CONFIG" == "true" ]] || [[ "$REMOVE_CONFIG" == "--purge" ]]; then
        rm -rf "$HOME/.nvm"
        # Remove NVM lines from shell config
        sed -i '/NVM_DIR/d' "$HOME/.bashrc" 2>/dev/null || true
        sed -i '/nvm.sh/d' "$HOME/.bashrc" 2>/dev/null || true
        sed -i '/NVM_DIR/d' "$HOME/.zshrc" 2>/dev/null || true
        sed -i '/nvm.sh/d' "$HOME/.zshrc" 2>/dev/null || true
        print_success "NVM removed completely"
    else
        print_info "NVM directory preserved at ~/.nvm"
    fi
fi

# Remove via package managers
if command -v apt-get &>/dev/null; then
    sudo apt-get remove -y nodejs npm 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true
    sudo rm -f /usr/share/keyrings/nodesource.gpg 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
fi

if command -v dnf &>/dev/null; then
    sudo dnf remove -y nodejs npm 2>/dev/null || true
fi

if command -v pacman &>/dev/null; then
    sudo pacman -Rs --noconfirm nodejs npm 2>/dev/null || true
fi

# Remove Snap version
if command -v snap &>/dev/null; then
    sudo snap remove node 2>/dev/null || true
fi

# Remove global npm packages location
if [[ "$REMOVE_CONFIG" == "true" ]] || [[ "$REMOVE_CONFIG" == "--purge" ]]; then
    print_step "Removing npm cache and global packages..."
    rm -rf "$HOME/.npm" 2>/dev/null || true
    rm -rf "$HOME/.node-gyp" 2>/dev/null || true
    rm -rf "$HOME/.npmrc" 2>/dev/null || true
    sudo rm -rf /usr/local/lib/node_modules 2>/dev/null || true
    print_success "npm data removed"
else
    print_info "npm cache preserved at ~/.npm"
    print_info "Use --purge to remove all data"
fi

print_success "Node.js uninstalled"
