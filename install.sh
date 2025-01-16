#!/bin/bash

# Exit immediately if a command fails, treat unset variables as an error and ensure all parts of pipelines fail properly
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Default apps to install
DEFAULT_APPS="essentials,node,vscode,chrome"

# Function to print banner
print_banner() {
    echo -e "${GREEN}"
    echo "██"
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

# Function to get selected apps from URL parameters
get_selected_apps() {
    if [ -n "${QUERY_STRING:-}" ] && [[ $QUERY_STRING == *"tools="* ]]; then
        echo "$QUERY_STRING" | grep -o 'tools=[^&]*' | cut -d= -f2
    else
        echo "$DEFAULT_APPS"
    fi
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
    local apps
    apps=$(get_selected_apps)
    
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

# Main installation function
main() {
    print_banner
    check_system
    install_apps
    
    # Clean up
    print_step "Cleaning up..."
    sudo apt autoremove -y
    sudo apt autoclean -y
    
    print_success "Installation complete! Your development environment is ready."
    echo "Please log out and log back in to complete the setup."
}

# Execute main function
main