#!/bin/bash
# Modern CLI Tools Installation
# modules/cli/modern-cli/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    # Fallback print functions
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_bullet() { echo "  • $1"; }
fi

# ═══════════════════════════════════════════════════════════════
# Tool Installation Functions
# ═══════════════════════════════════════════════════════════════

install_fzf() {
    print_step "Installing fzf (fuzzy finder)..."

    if command -v fzf &>/dev/null; then
        print_warning "fzf is already installed"
        return 0
    fi

    # Try apt first
    if apt-cache policy fzf 2>/dev/null | grep -q "Candidate: [0-9]"; then
        sudo apt-get install -y fzf
    else
        # Manual installation
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all --no-update-rc
    fi

    # Shell configuration
    if [[ -f ~/.bashrc ]] && ! grep -q "source.*fzf.bash" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# fzf configuration
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
EOF
    fi

    print_success "fzf installed"
}

install_zoxide() {
    print_step "Installing zoxide (smart cd)..."

    if command -v zoxide &>/dev/null; then
        print_warning "zoxide is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64|arm64)
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        armhf)
            if command -v cargo &>/dev/null; then
                cargo install zoxide --locked
            else
                print_warning "zoxide requires Cargo for armhf - skipping"
                return 1
            fi
            ;;
    esac

    # Shell configuration
    if [[ -f ~/.bashrc ]] && ! grep -q "zoxide init" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# zoxide configuration
eval "$(zoxide init bash)"
EOF
    fi

    print_success "zoxide installed"
}

install_ripgrep() {
    print_step "Installing ripgrep (fast search)..."

    if command -v rg &>/dev/null; then
        print_warning "ripgrep is already installed"
        return 0
    fi

    sudo apt-get install -y ripgrep
    print_success "ripgrep installed"
}

install_eza() {
    print_step "Installing eza (modern ls)..."

    if command -v eza &>/dev/null; then
        print_warning "eza is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64)
            # Try apt first (Ubuntu 24.04+)
            if apt-cache policy eza 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get install -y eza
            else
                # Download from GitHub
                local version
                version=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                wget -qO /tmp/eza.tar.gz "https://github.com/eza-community/eza/releases/download/${version}/eza_x86_64-unknown-linux-gnu.tar.gz"
                tar -xzf /tmp/eza.tar.gz -C /tmp
                sudo mv /tmp/eza /usr/local/bin/
                rm /tmp/eza.tar.gz
            fi
            ;;
        arm64|armhf)
            # Install exa as fallback
            if apt-cache policy exa 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get install -y exa
                echo "alias eza='exa'" >> ~/.bashrc
            elif command -v cargo &>/dev/null; then
                cargo install eza
            fi
            ;;
    esac

    # Aliases
    if [[ -f ~/.bashrc ]] && ! grep -q "alias ls='eza" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# eza aliases
alias ls='eza --color=auto'
alias ll='eza -la --color=auto'
alias la='eza -a --color=auto'
alias lt='eza --tree --color=auto'
EOF
    fi

    print_success "eza installed"
}

install_fd() {
    print_step "Installing fd (user-friendly find)..."

    if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
        print_warning "fd is already installed"
        return 0
    fi

    sudo apt-get install -y fd-find

    # Create alias if installed as fdfind
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        echo "alias fd='fdfind'" >> ~/.bashrc
    fi

    print_success "fd installed"
}

install_bat() {
    print_step "Installing bat (cat with syntax highlighting)..."

    if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
        print_warning "bat is already installed"
        return 0
    fi

    sudo apt-get install -y bat

    # Create alias if installed as batcat
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        echo "alias bat='batcat'" >> ~/.bashrc
    fi

    print_success "bat installed"
}

install_btop() {
    print_step "Installing btop (system monitor)..."

    if command -v btop &>/dev/null; then
        print_warning "btop is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64)
            if apt-cache policy btop 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get install -y btop
            else
                # Download from GitHub
                local version
                version=$(curl -s "https://api.github.com/repos/aristocratos/btop/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                wget -qO /tmp/btop.tbz "https://github.com/aristocratos/btop/releases/download/${version}/btop-x86_64-linux-musl.tbz"
                tar -xjf /tmp/btop.tbz -C /tmp
                sudo mv /tmp/btop/bin/btop /usr/local/bin/
                rm -rf /tmp/btop /tmp/btop.tbz
            fi
            ;;
        arm64|armhf)
            if apt-cache policy btop 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get install -y btop
            else
                sudo apt-get install -y htop
                echo "alias btop='htop'" >> ~/.bashrc
                print_warning "Installed htop as btop alternative"
            fi
            ;;
    esac

    print_success "btop installed"
}

install_fastfetch() {
    print_step "Installing fastfetch (system info)..."

    if command -v fastfetch &>/dev/null; then
        print_warning "fastfetch is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64)
            if apt-cache policy fastfetch 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get install -y fastfetch
            else
                local version
                version=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                wget -qO /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${version}/fastfetch-linux-amd64.deb"
                sudo dpkg -i /tmp/fastfetch.deb || sudo apt-get install -f -y
                rm /tmp/fastfetch.deb
            fi
            ;;
        arm64)
            if apt-cache policy fastfetch 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get install -y fastfetch
            else
                sudo apt-get install -y neofetch
                echo "alias fastfetch='neofetch'" >> ~/.bashrc
            fi
            ;;
        armhf)
            sudo apt-get install -y neofetch
            echo "alias fastfetch='neofetch'" >> ~/.bashrc
            ;;
    esac

    print_success "fastfetch installed"
}

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    print_step "Installing Modern CLI Tools for $ARCH"

    # Install dependencies
    sudo apt-get update
    sudo apt-get install -y curl wget git tar

    # Track failures
    local failed=()

    install_fzf || failed+=("fzf")
    install_zoxide || failed+=("zoxide")
    install_ripgrep || failed+=("ripgrep")
    install_eza || failed+=("eza")
    install_fd || failed+=("fd")
    install_bat || failed+=("bat")
    install_btop || failed+=("btop")
    install_fastfetch || failed+=("fastfetch")

    echo ""
    echo "════════════════════════════════════════════"
    echo "Modern CLI Tools Installation Complete"
    echo "════════════════════════════════════════════"

    if [[ ${#failed[@]} -eq 0 ]]; then
        print_success "All tools installed successfully!"
    else
        print_warning "Some tools failed: ${failed[*]}"
    fi

    echo ""
    echo "Quick Reference:"
    print_bullet "fzf: Ctrl+R (history), Ctrl+T (files)"
    print_bullet "zoxide: z <dir> (smart jump)"
    print_bullet "ripgrep: rg <pattern> (fast search)"
    print_bullet "eza: ls replacement with colors"
    print_bullet "fd: find replacement"
    print_bullet "bat: cat with syntax highlighting"
    print_bullet "btop: system monitor"
    print_bullet "fastfetch: system info"
    echo ""
    echo "Run 'source ~/.bashrc' to activate aliases"
}

main "$@"
