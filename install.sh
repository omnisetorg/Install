#!/bin/bash

# OmniSet - Enhanced Installation Script with Progress Bars and Better UX
set -euo pipefail

# Get script directory for sourcing utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source the enhanced systems
if [ -f "$SCRIPT_DIR/utils/error-handling.sh" ]; then
    source "$SCRIPT_DIR/utils/error-handling.sh"
else
    echo "Error: Enhanced error handling system not found!"
    exit 1
fi

if [ -f "$SCRIPT_DIR/utils/progress-ux.sh" ]; then
    source "$SCRIPT_DIR/utils/progress-ux.sh"
else
    echo "Error: Progress and UX system not found!"
    exit 1
fi

# Command line options
DRY_RUN=false
FORCE_INSTALL=false
SKIP_CHECKS=false

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --skip-checks)
                SKIP_CHECKS=true
                shift
                ;;
            --help|-h)
                show_usage
                exit 0
                ;;
            *)
                PERSONALITY="$1"
                shift
                ;;
        esac
    done
}

show_usage() {
    cat << EOF
OmniSet - System Environment Setup

Usage: $0 [OPTIONS] [PERSONALITY]

Options:
    --dry-run       Preview what would be installed without making changes
    --force         Force installation even if applications already exist
    --skip-checks   Skip system validation checks (not recommended)
    --help, -h      Show this help message

Personalities:
    minimalist      Essential development tools only
    fullstack       Complete web development environment
    content_creator Media creation and development tools
    cloud_native    Cloud and container focused
    gamer          Gaming and communication tools
    student        Academic and productivity tools
    designer       Design and creative tools
    data_scientist Data analysis and machine learning tools

Examples:
    $0 fullstack          # Install fullstack personality
    $0 --dry-run student  # Preview student installation
    $0 --force gamer      # Force install gamer setup

EOF
}

# Personalities and their default tools
declare -A PERSONALITIES=(
    ["minimalist"]="essentials,cli-tools,vicinae,vlc,thunderbird"
    ["fullstack"]="essentials,cli-tools,vicinae,vscode,chrome,docker,dev-language,dev-storage"
    ["content_creator"]="essentials,cli-tools,vicinae,vscode,chrome,davinci-resolve,discord,vlc"
    ["cloud_native"]="essentials,cli-tools,vicinae,docker,vscode,dev-language,dev-storage"
    ["gamer"]="essentials,cli-tools,vicinae,steam,discord,chrome,vlc"
    ["student"]="essentials,cli-tools,vicinae,chrome,vscode,thunderbird,vlc"
    ["designer"]="essentials,cli-tools,vicinae,chrome,vscode,davinci-resolve,discord"
    ["data_scientist"]="essentials,cli-tools,vicinae,vscode,chrome,docker,dev-language,dev-storage,virtualbox"
)

# Application disk space requirements (in MB)
declare -A APP_DISK_REQUIREMENTS=(
    ["essentials"]="100"
    ["cli-tools"]="150"
    ["vscode"]="200"
    ["chrome"]="150"
    ["docker"]="500"
    ["dev-language"]="300"
    ["dev-storage"]="200"
    ["davinci-resolve"]="1500"
    ["discord"]="100"
    ["vlc"]="50"
    ["steam"]="1000"
    ["thunderbird"]="100"
    ["virtualbox"]="200"
)

# Application architecture requirements
declare -A APP_ARCH_REQUIREMENTS=(
    ["cli-tools"]="amd64,arm64,armhf"
    ["davinci-resolve"]="amd64"
    ["steam"]="amd64"
    ["virtualbox"]="amd64,arm64"
)

print_banner() {
    clear
    print_header "OmniSet - System Environment Setup"
    
    echo -e "${GREEN}"
    echo "███████╗ ███╗   ███╗ ███╗   ██╗ ██╗ ███████╗ ███████╗ ████████╗"
    echo "██╔═══██╗████╗ ████║ ████╗  ██║ ██║ ██╔════╝ ██╔════╝ ╚══██╔══╝"
    echo "██║   ██║██╔████╔██║ ██╔██╗ ██║ ██║ ███████╗ █████╗      ██║   "
    echo "██║   ██║██║╚██╔╝██║ ██║╚██╗██║ ██║ ╚════██║ ██╔══╝      ██║   "
    echo "╚██████╔╝██║ ╚═╝ ██║ ██║ ╚████║ ██║ ███████║ ███████╗    ██║   "
    echo " ╚═════╝ ╚═╝     ╚═╝ ╚═╝  ╚═══╝ ╚═╝ ╚══════╝ ╚══════╝    ╚═╝   "
    echo -e "${NC}"
    
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}${BOLD}   >>> DRY RUN MODE - No changes will be made <<<${NC}"
    fi
    
    echo ""
    log_action "OmniSet installation started"
}

show_personalities() {
    echo ""
    print_header "Available Personalities"
    
    for personality in "${!PERSONALITIES[@]}"; do
        local apps="${PERSONALITIES[$personality]}"
        local app_count=$(echo "$apps" | tr ',' '\n' | wc -l)
        
        case "$personality" in
            "minimalist")
                print_bullet "${BOLD}$personality${NC} - Essential development tools ($app_count apps)"
                ;;
            "fullstack")
                print_bullet "${BOLD}$personality${NC} - Complete web development environment($app_count apps)"
                ;;
            "content_creator")
                print_bullet "${BOLD}$personality${NC} - Media creation and development tools ($app_count apps)"
                ;;
            "cloud_native")
                print_bullet "${BOLD}$personality${NC} - Cloud and container focused($app_count apps)"
                ;;
            "gamer")
                print_bullet "${BOLD}$personality${NC} - Gaming and communication tools ($app_count apps)"
                ;;
            "student")
                print_bullet "${BOLD}$personality${NC} - Academic and productivity tools($app_count apps)"
                ;;
            "designer")
                print_bullet "${BOLD}$personality${NC} - Design and creative tools ($app_count apps)"
                ;;
            "data_scientist")
                print_bullet "${BOLD}$personality${NC} - Data analysis and ML tools($app_count apps)"
                ;;
        esac
    done
    echo ""
    print_info "All personalities now include modern CLI tools: fzf, zoxide, ripgrep, eza, fd, fastfetch, btop"
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

comprehensive_system_check() {
    if [ "$SKIP_CHECKS" = true ]; then
        print_warning "Skipping system checks as requested"
        return 0
    fi
    
    print_header "System Validation"
    
    local check_passed=true
    
    # 1. Basic system compatibility
    print_step "Checking system compatibility..."
    if ! command -v apt-get >/dev/null; then
        print_error "This script requires a Debian-based Linux distribution"
        check_passed=false
    else
        print_success "Debian-based system detected"
    fi
    
    # 2. Architecture detection and validation
    print_step "Detecting system architecture..."
    local arch=$(get_arch)
    print_success "Architecture: $arch"
    
    # 3. Collect system information
    collect_system_info "/tmp/omniset-system-info.txt"
    
    # 4. Check available disk space (require 3GB minimum for safety)
    check_available_space 3072 "/" "installation"
    if [ $? -ne 0 ]; then
        check_passed=false
    fi
    
    # 5. Check internet connectivity
    print_step "Testing internet connectivity..."
    if ping -c 1 -W 5 google.com >/dev/null 2>&1; then
        print_success "Internet connectivity verified"
    else
        print_error "No internet connection detected"
        check_passed=false
    fi
    
    # 6. Check user permissions
    print_step "Validating user permissions..."
    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run this script as root"
        check_passed=false
    elif sudo -n true 2>/dev/null; then
        print_success "Sudo access confirmed"
    else
        print_warning "Sudo access not configured - you'll be prompted for password"
    fi
    
    # 7. Check for required dependencies
    print_step "Checking system dependencies..."
    local deps=("curl" "wget" "git" "sudo" "bc")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null; then
            missing+=("$dep")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        print_warning "Missing dependencies: ${missing[*]}"
        print_info "Installing missing dependencies..."
        if [ "$DRY_RUN" = false ]; then
            sudo apt update && sudo apt install -y "${missing[@]}"
        else
            print_info "DRY RUN: Would install ${missing[*]}"
        fi
    else
        print_success "All dependencies satisfied"
    fi
    
    # 8. Check system resources
    print_step "Checking system resources..."
    local load_avg=$(uptime | grep -o 'load average:.*' | cut -d: -f2 | cut -d, -f1 | xargs)
    local cpu_cores=$(nproc)
    local load_per_core=$(echo "scale=2; $load_avg / $cpu_cores" | bc -l)
    
    if (( $(echo "$load_per_core > 2.0" | bc -l) )); then
        print_warning "High system load detected ($load_avg). Installation may be slower."
    else
        print_success "System load is acceptable ($load_avg)"
    fi
    
    if [ "$check_passed" = false ]; then
        print_error "System checks failed. Please resolve the issues above."
        if [ "$FORCE_INSTALL" = true ]; then
            print_warning "Continuing due to --force flag"
        else
            print_info "Use --force to continue anyway (not recommended)"
            cleanup_and_exit 1
        fi
    else
        print_success "All system checks passed"
    fi
    
    return 0
}

get_selected_personality() {
    local personality="${PERSONALITY:-}"
    
    if [ -n "$personality" ]; then
        if [[ -n "${PERSONALITIES[$personality]}" ]]; then
            log_action "Using personality from command line: $personality"
        else
            print_error "Invalid personality: $personality"
            show_personalities
            cleanup_and_exit 1
        fi
    else
        show_personalities
        echo "Select a personality (default: fullstack):"
        printf "${BOLD}Choice:${NC} "
        read -r selected_personality
        
        if [ -n "$selected_personality" ]; then
            if [[ -n "${PERSONALITIES[$selected_personality]}" ]]; then
                personality="$selected_personality"
                log_action "User selected personality: $personality"
            else
                print_error "Invalid personality selected, using default: fullstack"
                personality="fullstack"
            fi
        else
            personality="fullstack"
            log_action "Using default personality: fullstack"
        fi
    fi
    
    echo "$personality"
}

validate_app_requirements() {
    local app="$1"
    local arch=$(get_arch)
    
    # Check architecture requirements
    local required_arch="${APP_ARCH_REQUIREMENTS[$app]:-any}"
    if ! validate_architecture "$app" "$required_arch"; then
        return 1
    fi
    
    # Check disk space requirements
    local required_space="${APP_DISK_REQUIREMENTS[$app]:-100}"
    if ! check_available_space "$required_space" "/" "$app"; then
        if [ "$FORCE_INSTALL" = false ]; then
            return 1
        else
            print_warning "Continuing installation of $app despite disk space warning"
        fi
    fi
    
    return 0
}

prepare_app_script() {
    local app=$1
    local script_path=""
    
    # Try multiple possible locations
    local possible_paths=(
        "install/${app}.sh"
        "install/desktop/${app}.sh"
        "install/development/${app}.sh"
        "install/gaming/${app}.sh"
        "install/video/${app}.sh"
        "install/terminal/${app}.sh"
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

# Enhanced app installation with progress tracking
install_app_with_progress() {
    local app="$1"
    local arch="$2"
    local script_path=""
    
    # Find the appropriate script
    local possible_paths=(
        "install/${app}.sh"
        "install/desktop/${app}.sh"
        "install/development/${app}.sh"
        "install/gaming/${app}.sh"
        "install/video/${app}.sh"
        "install/terminal/${app}.sh"
    )
    
    for path in "${possible_paths[@]}"; do
        if [ -f "$path" ]; then
            script_path="$path"
            break
        fi
    done
    
    if [ ! -f "$script_path" ]; then
        update_app_progress "$app" "failed"
        log_error "Installation script for ${app} not found"
        return 1
    fi
    
    # Validate requirements before starting
    update_app_progress "$app" "starting"
    if ! validate_app_requirements "$app"; then
        update_app_progress "$app" "failed"
        return 1
    fi
    
    # Create checkpoint
    create_checkpoint "$app"
    
    # Start installation
    chmod +x "$script_path"
    update_app_progress "$app" "installing"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "DRY RUN: Would execute $script_path with arch $arch"
        sleep 1  # Simulate installation time
        update_app_progress "$app" "completed"
        return 0
    fi
    
    # Execute installation with timeout and logging
    if timeout 600 "$script_path" "$arch" 2>&1 | tee -a "$LOG_FILE"; then
        update_app_progress "$app" "completed"
        INSTALLED_APPS+=("$app")
        return 0
    else
        local exit_code=$?
        update_app_progress "$app" "failed"
        FAILED_APPS+=("$app")
        
        if [ $exit_code -eq 124 ]; then
            log_error "$app installation timed out"
        else
            log_error "$app installation failed with exit code $exit_code"
        fi
        
        return 1
    fi
}

# Enhanced install_apps function with progress tracking
enhanced_install_apps() {
    local personality="$1"
    local apps="${PERSONALITIES[$personality]}"
    local arch=$(get_arch)
    
    # Calculate total disk space needed
    IFS=',' read -ra APP_ARRAY <<< "$apps"
    local total_space_needed=0
    for app in "${APP_ARRAY[@]}"; do
        local app_space="${APP_DISK_REQUIREMENTS[$app]:-100}"
        total_space_needed=$((total_space_needed + app_space))
    done
    
    print_info "Total estimated disk space needed: ${total_space_needed}MB"
    
    # Show installation preview and get confirmation
    if ! confirm_installation "$personality" "$apps"; then
        cleanup_and_exit 0
    fi
    
    # Start progress tracking
    start_installation_progress "$personality" "$apps"
    
    # Pre-installation system updates
    if [ "$DRY_RUN" = false ]; then
        print_step "Updating system packages..."
        if ! sudo apt update 2>&1 | tee -a "$LOG_FILE"; then
            log_error "Failed to update package lists"
            cleanup_and_exit 1
        fi
        
        print_step "Upgrading existing packages..."
        if ! sudo apt upgrade -y 2>&1 | tee -a "$LOG_FILE"; then
            log_warning "System upgrade had issues, continuing..."
        fi
    else
        print_info "DRY RUN: Would update and upgrade system packages"
    fi
    
    # Install applications
    for app in "${APP_ARRAY[@]}"; do
        install_app_with_progress "$app" "$arch"
        show_overall_progress
        sleep 0.5  # Brief pause for better UX
    done
    
    # Final system cleanup
    if [ "$DRY_RUN" = false ]; then
        print_step "Performing final system cleanup..."
        sudo apt autoremove -y 2>&1 | tee -a "$LOG_FILE"
        sudo apt autoclean 2>&1 | tee -a "$LOG_FILE"
    else
        print_info "DRY RUN: Would perform system cleanup"
    fi
    
    # Show final summary
    show_installation_summary "$personality"
}

# Enhanced configuration
configure_environment() {
    local personality="$1"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "DRY RUN: Would configure environment for $personality"
        return 0
    fi
    
    print_header "Environment Configuration"
    
    case "$personality" in
        "minimalist"|"fullstack"|"cloud_native")
            if command -v docker >/dev/null; then
                print_step "Configuring Docker environment..."
                if ! docker info >/dev/null 2>&1; then
                    print_warning "Docker is installed but not running properly"
                    print_info "Try: sudo systemctl start docker"
                else
                    print_success "Docker is running correctly"
                fi
            fi
            ;;
        "content_creator"|"designer")
            print_step "Setting up media project directories..."
            mkdir -p ~/Videos/Projects ~/Pictures/Projects ~/Audio/Projects
            print_success "Media project directories created"
            ;;
        "gamer")
            print_step "Applying gaming optimizations..."
            # Could add gaming-specific optimizations here
            print_success "Gaming environment configured"
            ;;
        "student")
            print_step "Setting up academic directories..."
            mkdir -p ~/Documents/School ~/Downloads/Academic ~/Projects/School
            print_success "Academic directories created"
            ;;
        "data_scientist")
            print_step "Setting up data science environment..."
            mkdir -p ~/DataScience/{datasets,notebooks,models,scripts}
            if command -v docker >/dev/null; then
                print_info "Consider using Jupyter Docker containers for isolated environments"
            fi
            print_success "Data science environment configured"
            ;;
    esac
    
    # CLI tools are now available in all personalities
    if command -v fzf >/dev/null 2>&1; then
        print_step "Enhanced CLI tools are ready!"
        print_info "Use 'fzf' for fuzzy finding, 'z <dir>' for smart directory jumping"
        print_info "Run 'fastfetch' for system info, 'btop' for system monitoring"
    fi
}

# Main function with enhanced flow
main() {
    # Parse command line arguments
    parse_args "$@"
    
    # Initialize systems
    initialize_ux_system
    initialize_error_handling
    
    # Show banner
    print_banner
    
    # Run comprehensive system checks
    comprehensive_system_check
    
    # Get personality selection
    local personality
    personality=$(get_selected_personality)
    
    # Start installation process
    log_action "Starting installation with personality: $personality"
    
    # Install applications with progress tracking
    enhanced_install_apps "$personality"
    
    # Configure environment
    configure_environment "$personality"
    
    # Final messages
    if [ ${#FAILED_APPS[@]} -eq 0 ]; then
        print_header "Installation Completed Successfully!"
        print_success "Your ${personality} environment is ready to use!"
        
        echo ""
        print_info "Next steps:"
        print_bullet "Log out and log back in to complete the setup"
        print_bullet "Check installed applications in your application menu"
        print_bullet "Review the installation log: $LOG_FILE"
        
        if [[ "$personality" == *"dev"* ]] || [ "$personality" = "fullstack" ]; then
            print_bullet "Consider configuring your development tools"
        fi
        
        print_bullet "Modern CLI tools are available: fzf, zoxide, ripgrep, eza, fd, fastfetch, btop"
    else
        print_header "Installation Completed with Issues"
        print_warning "Some applications failed to install"
        print_info "Check the error log for details: $LOG_FILE"
        print_info "You can retry failed installations or continue with what's working"
    fi
    
    # Clean exit
    cleanup_and_exit 0
}

# Run main function with all arguments
main "$@"