#!/bin/bash

# Enhanced CLI Tools Installation Script
# Installs modern terminal tools: fzf, zoxide, ripgrep, eza, fd, fastfetch, btop

arch=$1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to install fzf (fuzzy finder)
install_fzf() {
    print_status "Installing fzf (fuzzy finder)..."
    
    if command -v fzf >/dev/null 2>&1; then
        print_warning "fzf is already installed"
        return 0
    fi
    
    case $arch in
        amd64|arm64|armhf)
            # Install via apt first (available in Ubuntu 20.04+)
            if apt-cache policy fzf | grep -q "Candidate: [0-9]"; then
                sudo apt install -y fzf
            else
                # Fallback to manual installation
                git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
                ~/.fzf/install --all --no-update-rc
            fi
            
            # Configure shell integration
            if ! grep -q "source ~/.fzf.bash" ~/.bashrc 2>/dev/null; then
                echo "# fzf configuration" >> ~/.bashrc
                echo "source ~/.fzf.bash" >> ~/.bashrc
                echo "export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'" >> ~/.bashrc
            fi
            ;;
        *)
            print_error "fzf installation not supported for architecture: $arch"
            return 1
            ;;
    esac
    
    print_success "fzf installed successfully"
}

# Function to install zoxide (smart cd)
install_zoxide() {
    print_status "Installing zoxide (smart cd replacement)..."
    
    if command -v zoxide >/dev/null 2>&1; then
        print_warning "zoxide is already installed"
        return 0
    fi
    
    case $arch in
        amd64)
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        arm64)
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        armhf)
            # Try to install via cargo if available, otherwise skip
            if command -v cargo >/dev/null 2>&1; then
                cargo install zoxide --locked
            else
                print_warning "zoxide requires Rust/Cargo for armhf. Skipping."
                return 1
            fi
            ;;
        *)
            print_error "zoxide installation not supported for architecture: $arch"
            return 1
            ;;
    esac
    
    # Add to shell configuration
    if ! grep -q "eval.*zoxide init" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# zoxide configuration" >> ~/.bashrc
        echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
    fi
    
    print_success "zoxide installed successfully"
}

# Function to install ripgrep (fast grep)
install_ripgrep() {
    print_status "Installing ripgrep (fast grep replacement)..."
    
    if command -v rg >/dev/null 2>&1; then
        print_warning "ripgrep is already installed"
        return 0
    fi
    
    case $arch in
        amd64|arm64|armhf)
            # Install via apt (available as 'ripgrep')
            sudo apt install -y ripgrep
            ;;
        *)
            print_error "ripgrep installation not supported for architecture: $arch"
            return 1
            ;;
    esac
    
    print_success "ripgrep installed successfully"
}

# Function to install eza (modern ls)
install_eza() {
    print_status "Installing eza (modern ls replacement)..."
    
    if command -v eza >/dev/null 2>&1; then
        print_warning "eza is already installed"
        return 0
    fi
    
    case $arch in
        amd64)
            # Download latest release
            EZA_VERSION=$(curl -s "https://api.github.com/repos/eza-community/eza/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            wget -O eza.tar.gz "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_x86_64-unknown-linux-gnu.tar.gz"
            tar -xzf eza.tar.gz
            sudo mv eza /usr/local/bin/
            rm eza.tar.gz
            ;;
        arm64)
            # Try to install via cargo if available
            if command -v cargo >/dev/null 2>&1; then
                cargo install eza
            else
                print_warning "eza requires Rust/Cargo for arm64. Installing via apt as exa fallback."
                sudo apt install -y exa
                # Create alias for eza -> exa
                echo "alias eza='exa'" >> ~/.bashrc
            fi
            ;;
        armhf)
            # Install exa as fallback
            sudo apt install -y exa
            echo "alias eza='exa'" >> ~/.bashrc
            ;;
        *)
            print_error "eza installation not supported for architecture: $arch"
            return 1
            ;;
    esac
    
    # Add useful aliases
    if ! grep -q "alias ls.*eza" ~/.bashrc 2>/dev/null; then
        echo "" >> ~/.bashrc
        echo "# eza aliases" >> ~/.bashrc
        echo "alias ls='eza --color=auto'" >> ~/.bashrc
        echo "alias ll='eza -la --color=auto'" >> ~/.bashrc
        echo "alias la='eza -a --color=auto'" >> ~/.bashrc
        echo "alias lt='eza --tree --color=auto'" >> ~/.bashrc
    fi
    
    print_success "eza installed successfully"
}

# Function to install fd (user-friendly find)
install_fd() {
    print_status "Installing fd (user-friendly find replacement)..."
    
    if command -v fd >/dev/null 2>&1 || command -v fdfind >/dev/null 2>&1; then
        print_warning "fd is already installed"
        return 0
    fi
    
    case $arch in
        amd64|arm64|armhf)
            # Install via apt (available as 'fd-find')
            sudo apt install -y fd-find
            
            # Create fd alias if it's installed as fdfind
            if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
                echo "alias fd='fdfind'" >> ~/.bashrc
            fi
            ;;
        *)
            print_error "fd installation not supported for architecture: $arch"
            return 1
            ;;
    esac
    
    print_success "fd installed successfully"
}

# Function to install fastfetch (system info)
install_fastfetch() {
    print_status "Installing fastfetch (system information tool)..."
    
    if command -v fastfetch >/dev/null 2>&1; then
        print_warning "fastfetch is already installed"
        return 0
    fi
    
    case $arch in
        amd64)
            # Check if available via apt
            if apt-cache policy fastfetch | grep -q "Candidate: [0-9]"; then
                sudo apt install -y fastfetch
            else
                # Install from GitHub releases
                FASTFETCH_VERSION=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                wget -O fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb"
                sudo dpkg -i fastfetch.deb
                sudo apt-get install -f -y
                rm fastfetch.deb
            fi
            ;;
        arm64)
            # Try apt first, fallback to manual build
            if apt-cache policy fastfetch | grep -q "Candidate: [0-9]"; then
                sudo apt install -y fastfetch
            else
                print_warning "fastfetch may not be available for arm64 via packages"
                # Could try building from source here
                return 1
            fi
            ;;
        armhf)
            # Install neofetch as fallback
            sudo apt install -y neofetch
            echo "alias fastfetch='neofetch'" >> ~/.bashrc
            print_warning "Installed neofetch as fastfetch alternative for armhf"
            ;;
        *)
            print_error "fastfetch installation not supported for architecture: $arch"
            return 1
            ;;
    esac
    
    print_success "fastfetch installed successfully"
}

# Function to install btop (system monitor)
install_btop() {
    print_status "Installing btop (system monitor)..."
    
    if command -v btop >/dev/null 2>&1; then
        print_warning "btop is already installed"
        return 0
    fi
    
    case $arch in
        amd64)
            # Check if available via apt (Ubuntu 22.04+)
            if apt-cache policy btop | grep -q "Candidate: [0-9]"; then
                sudo apt install -y btop
            else
                # Install from GitHub releases
                BTOP_VERSION=$(curl -s "https://api.github.com/repos/aristocratos/btop/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
                wget -O btop.tbz "https://github.com/aristocratos/btop/releases/download/${BTOP_VERSION}/btop-x86_64-linux-musl.tbz"
                tar -xjf btop.tbz
                sudo mv btop/bin/btop /usr/local/bin/
                sudo chmod +x /usr/local/bin/btop
                rm -rf btop btop.tbz
            fi
            ;;
        arm64)
            # Try apt first
            if apt-cache policy btop | grep -q "Candidate: [0-9]"; then
                sudo apt install -y btop
            else
                # Install htop as fallback
                sudo apt install -y htop
                echo "alias btop='htop'" >> ~/.bashrc
                print_warning "Installed htop as btop alternative for arm64"
            fi
            ;;
        armhf)
            # Install htop as fallback
            sudo apt install -y htop
            echo "alias btop='htop'" >> ~/.bashrc
            print_warning "Installed htop as btop alternative for armhf"
            ;;
        *)
            print_error "btop installation not supported for architecture: $arch"
            return 1
            ;;
    esac
    
    print_success "btop installed successfully"
}

# Main installation function
main() {
    print_status "Installing enhanced CLI tools for architecture: $arch"
    echo ""
    
    # Update package lists
    print_status "Updating package lists..."
    sudo apt update
    
    # Install dependencies
    print_status "Installing dependencies..."
    sudo apt install -y curl wget git tar
    
    # Install each tool
    local failed_tools=()
    
    echo ""
    install_fzf || failed_tools+=("fzf")
    echo ""
    install_zoxide || failed_tools+=("zoxide")
    echo ""
    install_ripgrep || failed_tools+=("ripgrep")
    echo ""
    install_eza || failed_tools+=("eza")
    echo ""
    install_fd || failed_tools+=("fd")
    echo ""
    install_fastfetch || failed_tools+=("fastfetch")
    echo ""
    install_btop || failed_tools+=("btop")
    
    echo ""
    echo "============================================"
    echo "CLI Tools Installation Summary"
    echo "============================================"
    
    if [ ${#failed_tools[@]} -eq 0 ]; then
        print_success "All CLI tools installed successfully!"
    else
        print_warning "Some tools failed to install: ${failed_tools[*]}"
    fi
    
    echo ""
    print_status "Setting up shell configuration..."
    
    # Source the updated bashrc to make tools available immediately
    echo "# CLI Tools - Enhanced terminal experience" >> ~/.bashrc
    echo "# Restart your shell or run 'source ~/.bashrc' to activate" >> ~/.bashrc
    
    echo ""
    print_success "Installation completed!"
    echo ""
    echo "📝 Quick usage guide:"
    echo "  • fzf: Use Ctrl+R for command history, Ctrl+T for file search"
    echo "  • zoxide: Use 'z <dir>' to jump to frequently used directories"
    echo "  • ripgrep: Use 'rg <pattern>' for fast text search"
    echo "  • eza: Enhanced 'ls' with colors and icons"
    echo "  • fd: Use 'fd <name>' for user-friendly file finding"
    echo "  • fastfetch: Run 'fastfetch' for beautiful system info"
    echo "  • btop: Run 'btop' for advanced system monitoring"
    echo ""
    echo "🔄 Restart your shell or run 'source ~/.bashrc' to activate all features"
}

# Run main function
main