#!/bin/bash

# Snap Disable Utility for Ubuntu 22.04/24.04 LTS
# Location: scripts/disable-snap.sh
# Safely disables Snap services without removing packages

set -euo pipefail

# Get script directory for relative imports
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source existing utility systems if available
if [ -f "$PROJECT_ROOT/utils/progress-ux.sh" ]; then
    source "$PROJECT_ROOT/utils/progress-ux.sh"
else
    # Fallback color definitions
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
    
    print_header() { echo -e "\n${BOLD}${BLUE}=== $1 ===${NC}\n"; }
    print_step() { echo -e "${CYAN}→${NC} ${BOLD}$1${NC}"; }
    print_success() { echo -e "${GREEN}✓${NC} $1"; }
    print_error() { echo -e "${RED}✗${NC} $1" >&2; }
    print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
    print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
fi

if [ -f "$PROJECT_ROOT/utils/error-handling.sh" ]; then
    source "$PROJECT_ROOT/utils/error-handling.sh"
else
    # Fallback logging
    LOG_FILE="/tmp/omniset-snap-disable.log"
    log_action() {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    }
fi

# Global variables
UBUNTU_VERSION=""
SNAP_STATUS=""

# System detection and validation
detect_ubuntu_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "ubuntu" ]]; then
            UBUNTU_VERSION="$VERSION_ID"
            print_success "Ubuntu $UBUNTU_VERSION detected"
            return 0
        fi
    fi
    
    print_error "This script is designed for Ubuntu systems only"
    return 1
}

check_snap_status() {
    if command -v snap >/dev/null 2>&1; then
        if systemctl is-active --quiet snapd.service 2>/dev/null; then
            SNAP_STATUS="active"
            print_info "Snap is currently active and running"
        elif systemctl is-enabled --quiet snapd.service 2>/dev/null; then
            SNAP_STATUS="disabled"
            print_info "Snap is installed but services are disabled"
        elif systemctl is-masked --quiet snapd.service 2>/dev/null; then
            SNAP_STATUS="masked"
            print_info "Snap services are already masked"
        else
            SNAP_STATUS="stopped"
            print_info "Snap services are stopped"
        fi
    else
        SNAP_STATUS="not_installed"
        print_info "Snap is not installed"
    fi
}

list_installed_snaps() {
    print_step "Checking installed snap packages..."
    
    if command -v snap >/dev/null 2>&1; then
        local snap_list=$(snap list 2>/dev/null || echo "")
        local snap_count=$(echo "$snap_list" | wc -l)
        
        if [ $snap_count -gt 1 ] && [ -n "$snap_list" ]; then
            echo -e "\n${BOLD}Installed snap packages:${NC}"
            echo "$snap_list" | grep -v "^Name" | while read -r line; do
                if [ -n "$line" ]; then
                    local name=$(echo "$line" | awk '{print $1}')
                    local version=$(echo "$line" | awk '{print $2}')
                    echo -e "  • ${YELLOW}$name${NC} ($version)"
                fi
            done
            echo ""
            print_warning "$(($snap_count - 1)) snap packages are currently installed"
            print_info "These will become inaccessible but remain on disk"
        else
            print_info "No snap packages are currently installed"
        fi
    else
        print_info "Snap is not available"
    fi
}

show_disable_explanation() {
    print_header "Snap Disable Information"
    
    cat << EOF
${BOLD}What happens when you disable Snap:${NC}

${GREEN}✓ Benefits:${NC}
  • Prevents snap from running and consuming resources
  • Stops automatic snap updates
  • Preserves system package integrity
  • Easily reversible if needed later
  • No risk of breaking Ubuntu system dependencies

${YELLOW}⚠ What becomes unavailable:${NC}
  • Snap-installed applications won't launch
  • Ubuntu Software Center (if snap-based)
  • Snap command-line tools
  • Automatic security updates for snap apps

${CYAN}ℹ Applications that may be affected:${NC}
EOF

    case "$UBUNTU_VERSION" in
        "22.04")
            echo "  • Firefox (default snap version)"
            echo "  • Ubuntu Software Center"
            echo "  • Any manually installed snap applications"
            ;;
        "24.04")
            echo "  • Firefox (snap version)"
            echo "  • Thunderbird (snap version)"
            echo "  • Ubuntu App Center"
            echo "  • Any manually installed snap applications"
            ;;
        *)
            echo "  • Default snap applications for your Ubuntu version"
            ;;
    esac

    cat << EOF

${BOLD}How to get alternatives:${NC}
  • Firefox: Install from Mozilla PPA or Flatpak
  • Thunderbird: Available via apt or Flatpak  
  • Other apps: Check APT repositories or Flatpak

${BOLD}Re-enabling later:${NC}
  Run this script again or use:
  sudo systemctl unmask snapd.service
  sudo systemctl enable snapd.service snapd.socket snapd.seeded.service
  sudo systemctl start snapd.service
EOF
}

disable_snap_services() {
    print_header "Disabling Snap Services"
    
    if [ "$SNAP_STATUS" == "not_installed" ]; then
        print_info "Snap is not installed - nothing to disable"
        return 0
    fi
    
    if [ "$SNAP_STATUS" == "masked" ]; then
        print_success "Snap services are already disabled and masked"
        return 0
    fi
    
    local services=("snapd.service" "snapd.socket" "snapd.seeded.service")
    local success_count=0
    
    # Stop running services first
    print_step "Stopping running snap services..."
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            print_step "Stopping $service..."
            if sudo systemctl stop "$service" 2>/dev/null; then
                print_success "$service stopped"
            else
                print_warning "Could not stop $service"
            fi
        fi
    done
    
    # Disable services
    print_step "Disabling snap services..."
    for service in "${services[@]}"; do
        if systemctl is-enabled --quiet "$service" 2>/dev/null; then
            if sudo systemctl disable "$service" 2>/dev/null; then
                print_success "$service disabled"
                success_count=$((success_count + 1))
            else
                print_warning "Failed to disable $service"
            fi
        else
            print_info "$service was already disabled"
        fi
    done
    
    # Mask snapd.service to prevent accidental re-enabling
    print_step "Masking snapd.service to prevent automatic restart..."
    if sudo systemctl mask snapd.service 2>/dev/null; then
        print_success "snapd.service masked"
        success_count=$((success_count + 1))
    else
        print_error "Failed to mask snapd.service"
    fi
    
    # Verify the changes
    print_step "Verifying snap service status..."
    local masked=$(systemctl is-masked snapd.service 2>/dev/null || echo "not-masked")
    local active=$(systemctl is-active snapd.service 2>/dev/null || echo "inactive")
    
    if [ "$masked" == "masked" ] && [ "$active" == "inactive" ]; then
        print_success "Snap successfully disabled and secured"
        log_action "Snap services successfully disabled and masked"
    else
        print_warning "Snap disable may not be complete - check service status"
    fi
    
    return 0
}

enable_snap_services() {
    print_header "Re-enabling Snap Services"
    
    if [ "$SNAP_STATUS" == "not_installed" ]; then
        print_error "Snap is not installed - cannot re-enable"
        print_info "Install snapd first with: sudo apt install snapd"
        return 1
    fi
    
    if [ "$SNAP_STATUS" == "active" ]; then
        print_success "Snap is already active and running"
        return 0
    fi
    
    local services=("snapd.service" "snapd.socket" "snapd.seeded.service")
    
    # Unmask snapd.service if it's masked
    if systemctl is-masked --quiet snapd.service 2>/dev/null; then
        print_step "Unmasking snapd.service..."
        if sudo systemctl unmask snapd.service 2>/dev/null; then
            print_success "snapd.service unmasked"
        else
            print_error "Failed to unmask snapd.service"
            return 1
        fi
    fi
    
    # Enable services
    print_step "Enabling snap services..."
    for service in "${services[@]}"; do
        if sudo systemctl enable "$service" 2>/dev/null; then
            print_success "$service enabled"
        else
            print_warning "Failed to enable $service"
        fi
    done
    
    # Start snapd.service
    print_step "Starting snapd.service..."
    if sudo systemctl start snapd.service 2>/dev/null; then
        print_success "snapd.service started"
    else
        print_error "Failed to start snapd.service"
        return 1
    fi
    
    # Wait a moment and verify
    sleep 2
    print_step "Verifying snap functionality..."
    if snap version >/dev/null 2>&1; then
        print_success "Snap is now fully functional"
        log_action "Snap services successfully re-enabled"
    else
        print_warning "Snap may not be fully functional yet - try again in a few seconds"
    fi
    
    return 0
}

show_current_status() {
    print_header "Current Snap Status"
    
    echo -e "${BOLD}System Information:${NC}"
    echo -e "  Ubuntu Version: ${YELLOW}$UBUNTU_VERSION${NC}"
    echo -e "  Snap Status: ${YELLOW}$SNAP_STATUS${NC}"
    echo ""
    
    if [ "$SNAP_STATUS" != "not_installed" ]; then
        echo -e "${BOLD}Service Status:${NC}"
        local services=("snapd.service" "snapd.socket" "snapd.seeded.service")
        
        for service in "${services[@]}"; do
            local status=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
            local enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "unknown")
            local masked=$(systemctl is-masked "$service" 2>/dev/null || echo "not-masked")
            
            echo -e "  $service:"
            echo -e "    Active: ${status}"
            echo -e "    Enabled: ${enabled}"
            if [ "$masked" == "masked" ]; then
                echo -e "    Masked: ${RED}yes${NC}"
            fi
        done
        echo ""
    fi
    
    if command -v snap >/dev/null 2>&1; then
        echo -e "${BOLD}Snap Version:${NC}"
        snap version 2>/dev/null | head -3 || echo "  Unable to get snap version"
        echo ""
    fi
}

interactive_menu() {
    while true; do
        clear
        print_header "Snap Management for Ubuntu $UBUNTU_VERSION"
        
        show_current_status
        
        echo -e "${BOLD}Available Actions:${NC}"
        case "$SNAP_STATUS" in
            "active")
                echo "1) Disable Snap (Safe - Recommended)"
                echo "2) Show disable information"
                echo "3) List installed snap packages"
                ;;
            "disabled"|"stopped"|"masked")
                echo "1) Re-enable Snap"
                echo "2) Show current detailed status"
                echo "3) List installed snap packages (won't work while disabled)"
                ;;
            "not_installed")
                echo "1) Install Snap (run: sudo apt install snapd)"
                echo "2) Show system information"
                ;;
        esac
        
        echo "4) Exit"
        echo ""
        
        printf "Choose an option (1-4): "
        read -r choice
        
        case "$choice" in
            1)
                case "$SNAP_STATUS" in
                    "active")
                        echo ""
                        show_disable_explanation
                        echo ""
                        printf "Proceed with disabling Snap? (y/N): "
                        read -r confirm
                        if [[ "$confirm" =~ ^[Yy]$ ]]; then
                            disable_snap_services
                            echo ""
                            printf "Press Enter to continue..."
                            read -r
                            # Refresh status
                            check_snap_status
                        fi
                        ;;
                    "disabled"|"stopped"|"masked")
                        echo ""
                        enable_snap_services
                        echo ""
                        printf "Press Enter to continue..."
                        read -r
                        # Refresh status
                        check_snap_status
                        ;;
                    "not_installed")
                        echo ""
                        print_info "To install Snap, run: sudo apt install snapd"
                        printf "Press Enter to continue..."
                        read -r
                        ;;
                esac
                ;;
            2)
                echo ""
                case "$SNAP_STATUS" in
                    "active")
                        show_disable_explanation
                        ;;
                    *)
                        show_current_status
                        ;;
                esac
                echo ""
                printf "Press Enter to continue..."
                read -r
                ;;
            3)
                echo ""
                list_installed_snaps
                echo ""
                printf "Press Enter to continue..."
                read -r
                ;;
            4)
                print_info "Exiting snap management"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please choose 1-4."
                sleep 1
                ;;
        esac
    done
}

# Main execution
main() {
    # Check if we have sudo access
    if [ "$EUID" -eq 0 ]; then
        print_error "Please don't run this script as root"
        print_info "The script will request sudo access when needed"
        exit 1
    fi
    
    # Verify sudo access
    if ! sudo -n true 2>/dev/null; then
        print_info "This script requires sudo access for system modifications"
        if ! sudo true; then
            print_error "Sudo access required. Exiting."
            exit 1
        fi
    fi
    
    # Initialize logging
    log_action "Snap management script started"
    
    # Detect system
    if ! detect_ubuntu_version; then
        exit 1
    fi
    
    # Check current snap status
    check_snap_status
    
    # Handle command line arguments
    case "${1:-interactive}" in
        "disable"|"--disable")
            show_disable_explanation
            echo ""
            printf "Proceed with disabling Snap? (y/N): "
            read -r confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                disable_snap_services
            else
                print_info "Operation cancelled"
            fi
            ;;
        "enable"|"--enable")
            enable_snap_services
            ;;
        "status"|"--status")
            show_current_status
            list_installed_snaps
            ;;
        "help"|"--help")
            cat << EOF
Snap Disable Utility - Usage:

  $0                    # Interactive mode
  $0 disable            # Disable snap services
  $0 enable             # Re-enable snap services  
  $0 status             # Show current status
  $0 help               # Show this help

This utility safely disables Ubuntu's Snap package management
system without removing packages or breaking system integrity.

EOF
            ;;
        "interactive"|"")
            interactive_menu
            ;;
        *)
            print_error "Unknown option: $1"
            print_info "Use '$0 help' for usage information"
            exit 1
            ;;
    esac
    
    log_action "Snap management script completed"
}

# Run main function with all arguments
main "$@"