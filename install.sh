#!/bin/bash

# Exit immediately if a command fails, treat unset variables as an error and ensure all parts of pipelines fail properly
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

# Personalities and their default tools
declare -A PERSONALITIES=(
    ["minimalist"]="essentials,vlc,thunderbird"
    ["fullstack"]="essentials,vscode,chrome,docker,dev-language,dev-storage"
    ["content_creator"]="essentials,vscode,chrome,davinci-resolve,discord,vlc"
    ["cloud_native"]="essentials,docker,vscode,dev-language,dev-storage"
    ["gamer"]="essentials,steam,discord,chrome,vlc"
    ["student"]="essentials,chrome,vscode,thunderbird,vlc"
    ["designer"]="essentials,chrome,vscode,davinci-resolve,discord"
    ["data_scientist"]="essentials,vscode,chrome,docker,dev-language,dev-storage,virtualbox"
)

print_banner() {
    echo -e "${GREEN}"
    echo "███████╗ ███╗   ███╗ ███╗   ██╗ ██╗ ███████╗ ███████╗ ████████╗"
    echo "██╔═══██╗████╗ ████║ ████╗  ██║ ██║ ██╔════╝ ██╔════╝ ╚══██╔══╝"
    echo "██║   ██║██╔████╔██║ ██╔██╗ ██║ ██║ ███████╗ █████╗      ██║   "
    echo "██║   ██║██║╚██╔╝██║ ██║╚██╗██║ ██║ ╚════██║ ██╔══╝      ██║   "
    echo "╚██████╔╝██║ ╚═╝ ██║ ██║ ╚████║ ██║ ███████║ ███████╗    ██║   "
    echo " ╚═════╝ ╚═╝     ╚═╝ ╚═╝  ╚═══╝ ╚═╝ ╚══════╝ ╚══════╝    ╚═╝   "
    echo -e "${NC}"
    echo -e "${BOLD}System Environment Setup${NC}"
    echo ""
}

print_step() {
    echo -e "${BLUE}==> ${NC}${BOLD}$1${NC}"
}

print_success() {
    echo -e "${GREEN}==> Success:${NC} $1"
}

print_error() {
    echo -e "${RED}==> Error:${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}==> Warning:${NC} $1"
}

show_personalities() {
    echo -e "\nAvailable personalities:"
    echo -e "${BOLD}minimalist${NC} - Essential development tools only"
    echo -e "${BOLD}fullstack${NC} - Complete web development environment"
    echo -e "${BOLD}content_creator${NC} - Media creation and development tools"
    echo -e "${BOLD}cloud_native${NC} - Cloud and container focused"
    echo -e "${BOLD}gamer${NC} - Gaming and communication tools"
    echo -e "${BOLD}student${NC} - Academic and productivity tools"
    echo -e "${BOLD}designer${NC} - Design and creative tools"
    echo -e "${BOLD}data_scientist${NC} - Data analysis and machine learning tools"
    echo ""
}

get_arch() {
    case $(uname -m) in
        x86_64) echo "amd64" ;;
        armv7l) echo "armhf" ;;
        aarch64) echo "arm64" ;;
        *) print_error "Unknown architecture"; exit 1 ;;
    esac
}

check_system() {
    if ! command -v apt-get >/dev/null; then
        print_error "This script requires a Debian-based Linux distribution"
        exit 1
    fi
}

get_selected_personality() {
    local personality="fullstack"
    
    if [ $# -gt 0 ]; then
        if [[ -n "${PERSONALITIES[$1]}" ]]; then
            personality="$1"
        else
            print_error "Invalid personality: $1"
            show_personalities
            exit 1
        fi
    else
        show_personalities
        echo "Select a personality (default: fullstack):"
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

prepare_app_script() {
    local app=$1
    local script_path="apps/${app}.sh"
    
    if [ ! -f "$script_path" ]; then
        print_error "Installation script for ${app} not found"
        return 1
    fi
    
    chmod +x "$script_path"
}

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

configure_environment() {
    local personality="$1"
    
    print_step "Configuring environment..."
    
    case "$personality" in
        "minimalist"|"fullstack"|"cloud_native")
            if command -v docker >/dev/null; then
                print_step "Setting up development containers..."
            fi
            ;;
        "content_creator"|"designer")
            print_step "Configuring media tools..."
            ;;
        "gamer")
            print_step "Optimizing system for gaming..."
            ;;
        "student")
            print_step "Setting up academic tools..."
            ;;
        "data_scientist")
            if command -v docker >/dev/null; then
                print_step "Setting up data science containers..."
            fi
            ;;
    esac
}

main() {
    print_banner
    check_system
    
    local personality
    personality=$(get_selected_personality "$@")
    
    install_apps "$personality"
    configure_environment "$personality"
    
    print_step "Cleaning up..."
    sudo apt autoremove -y
    sudo apt autoclean -y
    
    print_success "Installation complete! Your ${personality} environment is ready."
    echo "Please log out and log back in to complete the setup."
}

main "$@"