#!/bin/bash

# Exit immediately if a command fails, treat unset variables as an error and ensure all parts of pipelines fail properly
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Developer personalities and their default tools
declare -A PERSONALITIES=(
    ["minimalist"]="essentials,vscode,dev-language"
    ["fullstack"]="essentials,vscode,chrome,docker,dev-language,dev-storage"
    ["content_creator"]="essentials,vscode,chrome,davinci-resolve,discord,vlc"
    ["cloud_native"]="essentials,docker,vscode,dev-language,dev-storage"
)

# Function to print banner
print_banner() {
    echo -e "${GREEN}"
    echo "██████╗ ███████╗██╗   ██╗███████╗███╗   ██╗██╗   ██╗"
    echo "██╔══██╗██╔════╝██║   ██║██╔════╝████╗  ██║██║   ██║"
    echo "██║  ██║█████╗  ██║   ██║█████╗  ██╔██╗ ██║██║   ██║"
    echo "██║  ██║██╔══╝  ╚██╗ ██╔╝██╔══╝  ██║╚██╗██║╚██╗ ██╔╝"
    echo "██████╔╝███████╗ ╚████╔╝ ███████╗██║ ╚████║ ╚████╔╝ "
    echo "╚═════╝ ╚══════╝  ╚═══╝  ╚══════╝╚═╝  ╚═══╝  ╚═══╝  "
    echo -e "${NC}"
    echo -e "${BOLD}Modern Development Environment Setup${NC}"
    echo ""
}

# Function to print step
print_step() {
    echo -e "${BLUE}==> ${NC}${BOLD}$1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}==> Success:${NC} $1"
}

# Function to print error
print_error() {
    echo -e "${RED}==> Error:${NC} $1"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}==> Warning:${NC} $1"
}

# Function to display available personalities
show_personalities() {
    echo -e "\nAvailable developer personalities:"
    echo -e "${BOLD}minimalist${NC} - Lightweight setup with essential tools only"
    echo -e "${BOLD}fullstack${NC} - Complete web development environment"
    echo -e "${BOLD}content_creator${NC} - Development + content creation tools"
    echo -e "${BOLD}cloud_native${NC} - Cloud development and containerization focus"
    echo ""
}

# Function to determine CPU architecture
get_arch() {
    local arch
    case $(uname -m) in
        x86_64) arch="amd64" ;;
        armv7l) arch="armhf" ;;
        aarch64) arch="arm64" ;;
        *) print_error "Unknown architecture"; exit 1 ;;
    esac
    echo "$arch"
}

# Function to check system compatibility
check_system() {
    if ! command -v apt-get >/dev/null; then
        print_error "This script requires a Debian-based Linux distribution"
        exit 1
    fi
}

# Function to get selected personality
get_selected_personality() {
    local personality="fullstack"  # Default personality
    
    # Check if personality is provided as argument
    if [ $# -gt 0 ]; then
        if [[ -n "${PERSONALITIES[$1]}" ]]; then
            personality="$1"
        else
            print_error "Invalid personality: $1"
            show_personalities
            exit 1
        fi
    else
        # Interactive personality selection
        show_personalities
        echo "Select a developer personality (default: fullstack):"
        read -r selected_personality
        
        if [ -n "$selected_personality" ]; then
            if [[ -n "${PERSONALITIES[$selected_personality]}" ]]; then
                personality="$selected_personality"
            else
                print_error "Invalid personality selected, using default: fullstack"
            fi
        fi
    fi
    
    echo "$personality"
}

# Function to validate and prepare app script
prepare_app_script() {
    local app=$1
    local script_path="apps/${app}.sh"
    
    if [ ! -f "$script_path" ]; then
        print_error "Installation script for ${app} not found"
        return 1
    fi
    
    chmod +x "$script_path"
}

# Function to install selected apps
install_apps() {
    local arch
    arch=$(get_arch)
    local personality="$1"
    local apps="${PERSONALITIES[$personality]}"
    
    print_step "Setting up environment for ${BOLD}${personality}${NC} personality..."
    print_step "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    
    print_step "Installing selected applications..."
    
    # Convert comma-separated string to array
    IFS=',' read -ra APP_ARRAY <<< "$apps"
    
    for app in "${APP_ARRAY[@]}"; do
        if prepare_app_script "$app"; then
            print_step "Installing ${app}..."
            if "./apps/${app}.sh" "$arch"; then
                print_success "${app} installed successfully"
            else
                print_error "Failed to install ${app}"
            fi
        fi
    done
}

# Function to configure development environment
configure_environment() {
    local personality="$1"
    
    print_step "Configuring development environment..."
    
    # Additional configuration based on personality
    case "$personality" in
        "minimalist")
            # Minimal configuration
            ;;
        "fullstack")
            # Configure additional dev tools
            if command -v docker >/dev/null; then
                print_step "Setting up default Docker containers..."
            fi
            ;;
        "content_creator")
            # Configure media tools
            ;;
        "cloud_native")
            # Configure cloud tools
            if command -v docker >/dev/null; then
                print_step "Setting up cloud-native tools..."
            fi
            ;;
    esac
}

# Main installation function
main() {
    print_banner
    check_system
    
    local personality
    personality=$(get_selected_personality "$@")
    
    install_apps "$personality"
    configure_environment "$personality"
    
    # Clean up
    print_step "Cleaning up..."
    sudo apt autoremove -y
    sudo apt autoclean -y
    
    print_success "Installation complete! Your ${personality} development environment is ready."
    echo "Please log out and log back in to complete the setup."
}

# Execute main function with all arguments
main "$@"