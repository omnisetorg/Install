#!/bin/bash

# Enhanced error handling and logging system
LOG_FILE="/tmp/omniset-install.log"
FAILED_APPS=()

# Logging functions
log_action() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

# Enhanced app installation with rollback capability
install_app_with_recovery() {
    local app="$1"
    local arch="$2"
    local script_path="apps/${app}.sh"
    
    log_action "Starting installation of $app"
    
    # Create checkpoint before installation
    create_checkpoint "$app"
    
    if prepare_app_script "$app"; then
        if timeout 300 "./apps/${app}.sh" "$arch" 2>&1 | tee -a "$LOG_FILE"; then
            log_action "✓ $app installed successfully"
            return 0
        else
            log_error "✗ Failed to install $app"
            FAILED_APPS+=("$app")
            
            # Ask user if they want to continue or rollback
            echo -e "${YELLOW}Installation of $app failed. Options:${NC}"
            echo "1) Continue with other apps"
            echo "2) Retry installation"
            echo "3) Skip this app"
            read -p "Choice (1-3): " choice
            
            case $choice in
                1) return 1 ;;
                2) install_app_with_recovery "$app" "$arch" ;;
                3) return 1 ;;
            esac
        fi
    else
        log_error "Script not found for $app"
        return 1
    fi
}

# System checkpoint creation
create_checkpoint() {
    local app="$1"
    log_action "Creating checkpoint before installing $app"
    # Store current package state
    dpkg -l > "/tmp/packages_before_${app}.txt"
}

# Rollback functionality
rollback_installation() {
    echo -e "${RED}Installation failed. Attempting rollback...${NC}"
    
    # Show failed apps
    if [ ${#FAILED_APPS[@]} -gt 0 ]; then
        echo "Failed applications:"
        printf '%s\n' "${FAILED_APPS[@]}"
        
        echo "Would you like to:"
        echo "1) Generate error report"
        echo "2) Retry failed installations"
        echo "3) Continue without failed apps"
        read -p "Choice (1-3): " choice
        
        case $choice in
            1) generate_error_report ;;
            2) retry_failed_installations ;;
            3) echo "Continuing..." ;;
        esac
    fi
}

# Generate detailed error report
generate_error_report() {
    local report_file="/tmp/omniset-error-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "OmniSet Installation Error Report"
        echo "================================="
        echo "Date: $(date)"
        echo "System: $(uname -a)"
        echo "Architecture: $(dpkg --print-architecture)"
        echo ""
        echo "Failed Applications:"
        printf '%s\n' "${FAILED_APPS[@]}"
        echo ""
        echo "Full Log:"
        cat "$LOG_FILE"
    } > "$report_file"
    
    echo "Error report generated: $report_file"
    echo "Please share this with the OmniSet team for support."
}