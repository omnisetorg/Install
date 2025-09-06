#!/bin/bash

# CLI Tools Uninstall Script
# Removes: fzf, zoxide, ripgrep, eza, fd, fastfetch, btop

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

# Function to remove fzf
remove_fzf() {
    print_status "Removing fzf..."
    
    # Remove apt installation
    if dpkg -l | grep -q "^ii.*fzf"; then
        sudo apt remove -y fzf
    fi
    
    # Remove manual installation
    if [ -d ~/.fzf ]; then
        ~/.fzf/uninstall
        rm -rf ~/.fzf
    fi
    
    # Remove shell configuration
    sed -i '/# fzf configuration/,+2d' ~/.bashrc 2>/dev/null
    sed -i '/source.*fzf/d' ~/.bashrc 2>/dev/null
    sed -i '/FZF_DEFAULT_OPTS/d' ~/.bashrc 2>/dev/null
    
    print_success "fzf removed"
}

# Function to remove zoxide
remove_zoxide() {
    print_status "Removing zoxide..."
    
    # Remove binary
    sudo rm -f /usr/local/bin/zoxide ~/.local/bin/zoxide
    
    # Remove shell configuration
    sed -i '/# zoxide configuration/,+1d' ~/.bashrc 2>/dev/null
    sed -i '/zoxide init/d' ~/.bashrc 2>/dev/null
    
    print_success "zoxide removed"
}

# Function to remove ripgrep
remove_ripgrep() {
    print_status "Removing ripgrep..."
    
    if dpkg -l | grep -q "^ii.*ripgrep"; then
        sudo apt remove -y ripgrep
    fi
    
    print_success "ripgrep removed"
}

# Function to remove eza
remove_eza() {
    print_status "Removing eza..."
    
    # Remove binary
    sudo rm -f /usr/local/bin/eza
    
    # Remove exa if installed as fallback
    if dpkg -l | grep -q "^ii.*exa"; then
        sudo apt remove -y exa
    fi
    
    # Remove aliases
    sed -i '/# eza aliases/,+4d' ~/.bashrc 2>/dev/null
    sed -i '/alias.*eza/d' ~/.bashrc 2>/dev/null
    sed -i '/alias.*exa/d' ~/.bashrc 2>/dev/null
    
    print_success "eza removed"
}

# Function to remove fd
remove_fd() {
    print_status "Removing fd..."
    
    if dpkg -l | grep -q "^ii.*fd-find"; then
        sudo apt remove -y fd-find
    fi
    
    # Remove alias
    sed -i '/alias fd=.fdfind./d' ~/.bashrc 2>/dev/null
    
    print_success "fd removed"
}

# Function to remove fastfetch
remove_fastfetch() {
    print_status "Removing fastfetch..."
    
    # Remove apt installation
    if dpkg -l | grep -q "^ii.*fastfetch"; then
        sudo apt remove -y fastfetch
    fi
    
    # Remove manual installation
    sudo rm -f /usr/local/bin/fastfetch
    
    # Remove neofetch if installed as fallback
    if dpkg -l | grep -q "^ii.*neofetch"; then
        echo "Remove neofetch (fastfetch fallback)? (y/N)"
        read -r remove_neofetch
        if [[ "$remove_neofetch" =~ ^[Yy]$ ]]; then
            sudo apt remove -y neofetch
        fi
    fi
    
    # Remove alias
    sed -i '/alias fastfetch=.neofetch./d' ~/.bashrc 2>/dev/null
    
    print_success "fastfetch removed"
}

# Function to remove btop
remove_btop() {
    print_status "Removing btop..."
    
    # Remove apt installation
    if dpkg -l | grep -q "^ii.*btop"; then
        sudo apt remove -y btop
    fi
    
    # Remove manual installation
    sudo rm -f /usr/local/bin/btop
    
    # Remove htop if installed as fallback
    if dpkg -l | grep -q "^ii.*htop"; then
        echo "Remove htop (btop fallback)? (y/N)"
        read -r remove_htop
        if [[ "$remove_htop" =~ ^[Yy]$ ]]; then
            sudo apt remove -y htop
        fi
    fi
    
    # Remove alias
    sed -i '/alias btop=.htop./d' ~/.bashrc 2>/dev/null
    
    print_success "btop removed"
}

# Main uninstall function
main() {
    echo ""
    print_status "CLI Tools Uninstaller"
    echo "============================================="
    echo ""
    print_warning "This will remove all enhanced CLI tools:"
    echo "  • fzf (fuzzy finder)"
    echo "  • zoxide (smart cd)"
    echo "  • ripgrep (fast grep)"
    echo "  • eza (modern ls)"
    echo "  • fd (user-friendly find)"
    echo "  • fastfetch (system info)"
    echo "  • btop (system monitor)"
    echo ""
    echo "Continue with removal? (y/N)"
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
    
    echo ""
    print_status "Starting CLI tools removal..."
    echo ""
    
    remove_fzf
    remove_zoxide
    remove_ripgrep
    remove_eza
    remove_fd
    remove_fastfetch
    remove_btop
    
    # Clean up shell configuration
    print_status "Cleaning up shell configuration..."
    
    # Remove CLI Tools section marker
    sed -i '/# CLI Tools - Enhanced terminal experience/,+1d' ~/.bashrc 2>/dev/null
    
    # Remove any empty lines that might be left
    sed -i '/^$/N;/^\n$/d' ~/.bashrc 2>/dev/null
    
    echo ""
    print_success "All CLI tools have been removed!"
    echo ""
    print_status "🔄 Restart your shell or run 'source ~/.bashrc' to apply changes"
    
    # Offer to run autoremove
    echo ""
    echo "Run 'sudo apt autoremove' to clean up unused dependencies? (y/N)"
    read -r cleanup
    if [[ "$cleanup" =~ ^[Yy]$ ]]; then
        sudo apt autoremove -y
    fi
}

# Run main function
main