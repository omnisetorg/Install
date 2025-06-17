#!/bin/bash

# OmniSet 
set -euo pipefail

# Get script directory for sourcing utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the enhanced error handling system
if [ -f "$SCRIPT_DIR/utils/error-handling.sh" ]; then
    source "$SCRIPT_DIR/utils/error-handling.sh"
else
    echo "Error: Enhanced error handling system not found!"
    echo "Please ensure utils/error-handling.sh exists"
    exit 1
fi

# Colors for output (keeping original colors for consistency)
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
BOLD='\033[1m'

# Personalities and their default tools (unchanged)
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
    echo -e "${BOLD}System Environment Setup with Enhanced Error Handling${NC}"
    echo ""
    log_action "OmniSet installation started"
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
        *) 
            log_error "Unknown architecture: $(uname -m)"
            cleanup_and_exit 1
            ;;
    esac
}

check_system() {
    log_step "Checking system compatibility"
    
    if ! command -v apt-get >/dev/null; then
        log_error "This script requires a Debian-based Linux distribution"
        cleanup_and_exit 1
    fi
    
    # Check if system is up to date enough
    if ! lsb_release -d | grep -E "(Ubuntu|Debian|Mint|Elementary|Pop|Zorin)" >/dev/null; then
        log_warning "This system may not be fully supported"
        echo "Detected: $(lsb_release -d | cut -f2)"
        echo "Continue anyway? (y/N)"
        read -r continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            log_action "Installation cancelled by user"
            cleanup_and_exit 0
        fi
    fi
    
    log_success "System compatibility check passed"
}

get_selected_personality() {
    local personality="fullstack"
    
    if [ $# -gt 0 ]; then
        if [[ -n "${PERSONALITIES[$1]}" ]]; then
            personality="$1"
            log_action "Using personality from command line: $personality"
        else
            log_error "Invalid personality: $1"
            show_personalities
            cleanup_and_exit 1
        fi
    else
        show_personalities
        echo "Select a personality (default: fullstack):"
        read -r selected_personality
        
        if [ -n "$selected_personality" ]; then
            if [[ -n "${PERSONALITIES[$selected_personality]}" ]]; then
                personality="$selected_personality"
                log_action "User selected personality: $personality"
            else
                log_error "Invalid personality selected, using default: fullstack"
                personality="fullstack"
            fi
        else
            log_action "Using default personality: fullstack"
        fi
    fi
    
    echo "$personality"
}

prepare_app_script() {
    local app=$1
    local script_path="install/${app}.sh"
    
    # Try multiple possible locations
    local possible_paths=(
        "install/${app}.sh"
        "install/desktop/${app}.sh"
        "install/development/${app}.sh"
        "install/gaming/${app}.sh"
        "install/video/${app}.sh"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -f "$path" ]; then
            script_path="$path"
            break
        fi
    done
    
    if [ ! -f "$script_path" ]; then
        log_error "Installation script for ${app} not found in any expected location"
        return 1
    fi
    
    chmod +x "$script_path"
    log_action "Prepared script: $script_path"
    return 0
}

# Modified install_apps function that uses enhanced error handling
install_apps() {
    local personality="$1"
    
    # Use the enhanced install function
    enhanced_install_apps "$personality"
}

configure_environment() {
    local personality="$1"
    
    log_step "Configuring environment for $personality personality..."
    
    case "$personality" in
        "minimalist"|"fullstack"|"cloud_native")
            if command -v docker >/dev/null; then
                log_step "Setting up development containers..."
                # Test Docker installation
                if ! docker info >/dev/null 2>&1; then
                    log_warning "Docker is installed but not running properly"
                fi
            fi
            ;;
        "content_creator"|"designer")
            log_step "Configuring media tools..."
            # Set up media directories
            mkdir -p ~/Videos/Projects ~/Pictures/Projects ~/Audio/Projects
            log_success "Media project directories created"
            ;;
        "gamer")
            log_step "Optimizing system for gaming..."
            # Gaming optimizations can be added here
            ;;
        "student")
            log_step "Setting up academic tools..."
            mkdir -p ~/Documents/School ~/Downloads/Academic
            log_success "Academic directories created"
            ;;
        "data_scientist")
            if command -v docker >/dev/null; then
                log_step "Setting up data science containers..."
                # Could pull common data science Docker images
            fi
            ;;
    esac
    
    log_success "Environment configuration completed"
}

# Enhanced main function with better error handling
main() {
    print_banner
    
    # System checks
    check_system
    
    # Get personality selection
    local personality
    personality=$(get_selected_personality "$@")
    
    # Confirm installation
    echo ""
    echo -e "${YELLOW}You selected the '${personality}' personality.${NC}"
    echo "This will install: ${PERSONALITIES[$personality]}"
    echo ""
    echo "Continue with installation? (y/N)"
    read -r confirm_install
    
    if [[ ! "$confirm_install" =~ ^[Yy]$ ]]; then
        log_action "Installation cancelled by user"
        cleanup_and_exit 0
    fi
    
    # Start installation process
    log_action "Starting installation with personality: $personality"
    
    # Install applications (this now uses enhanced error handling)
    install_apps "$personality"
    
    # Configure environment
    configure_environment "$personality"
    
    # Final cleanup
    log_step "Performing final system maintenance..."
    sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE" || log_warning "Autoremove had issues"
    sudo apt autoclean 2>&1 | tee -a "$LOG_FILE" || log_warning "Autoclean had issues"
    
    # Success message
    log_success "Installation complete! Your ${personality} environment is ready."
    echo ""
    echo "Installation Summary:"
    echo "- Successfully installed: ${#INSTALLED_APPS[@]} applications"
    if [ ${#FAILED_APPS[@]} -gt 0 ]; then
        echo "- Failed installations: ${#FAILED_APPS[@]} applications"
        echo "- Check the error log for details: $LOG_FILE"
    fi
    echo ""
    echo "Please log out and log back in to complete the setup."
    
    # Clean exit
    cleanup_and_exit 0
}

# Run main function with all arguments
main "$@"