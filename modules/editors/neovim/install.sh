#!/bin/bash
# Neovim Installation
# modules/editors/neovim/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Parse options
INSTALL_KICKSTART=false
[[ "${OPTIONS:-}" == *"kickstart"* ]] && INSTALL_KICKSTART=true

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_bullet() { echo "  • $1"; }
fi

install_neovim() {
    print_step "Installing Neovim..."

    if command -v nvim &>/dev/null; then
        local version
        version=$(nvim --version | head -1)
        print_warning "Neovim is already installed: $version"

        # Check if version is recent enough (0.9+)
        if nvim --version | grep -qE "v0\.[0-8]\."; then
            print_step "Upgrading to latest version..."
        else
            return 0
        fi
    fi

    case "$ARCH" in
        amd64)
            # Download latest stable release
            local url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
            wget -qO /tmp/nvim.tar.gz "$url"
            sudo rm -rf /opt/nvim
            sudo tar -xzf /tmp/nvim.tar.gz -C /opt
            sudo mv /opt/nvim-linux64 /opt/nvim
            sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
            rm /tmp/nvim.tar.gz
            ;;
        arm64)
            # Build from source or use AppImage
            if apt-cache policy neovim 2>/dev/null | grep -q "Candidate: 0\.[9]"; then
                sudo apt-get update
                sudo apt-get install -y neovim
            else
                # Use AppImage
                local url="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"
                wget -qO /tmp/nvim.appimage "$url"
                chmod +x /tmp/nvim.appimage
                sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
            fi
            ;;
        armhf)
            # Install from apt (may be older version)
            sudo apt-get update
            sudo apt-get install -y neovim
            ;;
    esac

    print_success "Neovim installed"
}

install_dependencies() {
    print_step "Installing dependencies..."

    sudo apt-get update
    sudo apt-get install -y \
        git \
        curl \
        unzip \
        ripgrep \
        fd-find \
        xclip

    # Node.js for LSP servers (if not present)
    if ! command -v node &>/dev/null; then
        print_bullet "Installing Node.js for LSP support..."
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    print_success "Dependencies installed"
}

install_kickstart() {
    if [[ "$INSTALL_KICKSTART" != true ]]; then
        return 0
    fi

    print_step "Installing Kickstart.nvim..."

    local config_dir="$HOME/.config/nvim"

    if [[ -d "$config_dir" ]]; then
        print_warning "Existing config found, backing up..."
        mv "$config_dir" "$config_dir.backup.$(date +%s)"
    fi

    git clone https://github.com/nvim-lua/kickstart.nvim.git "$config_dir"

    print_success "Kickstart.nvim installed"
}

configure_basic() {
    if [[ "$INSTALL_KICKSTART" == true ]]; then
        return 0
    fi

    print_step "Creating basic configuration..."

    local config_dir="$HOME/.config/nvim"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/init.lua" ]]; then
        cat > "$config_dir/init.lua" << 'EOF'
-- Basic Neovim configuration
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.clipboard = 'unnamedplus'

-- Leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Basic keymaps
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Save file' })
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
vim.keymap.set('n', '<Esc>', ':nohlsearch<CR>', { silent = true })

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git', 'clone', '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugins
require('lazy').setup({
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
  { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' },
  { 'nvim-telescope/telescope.nvim', dependencies = { 'nvim-lua/plenary.nvim' } },
})

-- Colorscheme
vim.cmd.colorscheme('catppuccin-mocha')
EOF
        print_success "Basic configuration created"
    fi
}

main() {
    print_step "Installing Neovim for $ARCH"

    install_dependencies
    install_neovim
    install_kickstart
    configure_basic

    echo ""
    echo "════════════════════════════════════════════"
    echo "Neovim Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v nvim &>/dev/null; then
        print_success "Neovim version: $(nvim --version | head -1)"
    fi

    echo ""
    print_bullet "Run 'nvim' to start"
    print_bullet "Config: ~/.config/nvim/init.lua"
    print_bullet "First launch will install plugins"
    if [[ "$INSTALL_KICKSTART" == true ]]; then
        print_bullet "Kickstart.nvim provides a great starting point"
    fi
}

main "$@"
