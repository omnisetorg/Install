#!/bin/bash

# Progress Bars and Enhanced UX System for OmniSet
# utils/progress-ux.sh

# Terminal capabilities detection
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)
HAS_UNICODE=false

# Check for Unicode support
if [[ "$LANG" =~ UTF-8 ]] || [[ "$LC_ALL" =~ UTF-8 ]]; then
    HAS_UNICODE=true
fi

# Unicode characters for better UX
if [ "$HAS_UNICODE" = true ]; then
    CHECKMARK="✓"
    CROSSMARK="✗"
    WARNING="⚠"
    INFO="ℹ"
    ARROW="→"
    BULLET="•"
    SPINNER_CHARS=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    PROGRESS_FULL="█"
    PROGRESS_EMPTY="░"
    PROGRESS_PARTIAL=("▏" "▎" "▍" "▌" "▋" "▊" "▉")
else
    CHECKMARK="✓"
    CROSSMARK="✗"
    WARNING="!"
    INFO="i"
    ARROW=">"
    BULLET="*"
    SPINNER_CHARS=("|" "/" "-" "\\")
    PROGRESS_FULL="="
    PROGRESS_EMPTY="-"
    PROGRESS_PARTIAL=("=" "=" "=" "=" "=" "=" "=")
fi

# Enhanced color definitions
if [ -t 1 ]; then
    # Standard colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    PURPLE='\033[0;35m'
    CYAN='\033[0;36m'
    WHITE='\033[1;37m'
    
    # Bright colors
    BRIGHT_RED='\033[1;31m'
    BRIGHT_GREEN='\033[1;32m'
    BRIGHT_YELLOW='\033[1;33m'
    BRIGHT_BLUE='\033[1;34m'
    
    # Background colors
    BG_RED='\033[41m'
    BG_GREEN='\033[42m'
    BG_YELLOW='\033[43m'
    
    # Text formatting
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    NC='\033[0m'
else
    # No color for non-terminals
    RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BRIGHT_RED='' BRIGHT_GREEN='' BRIGHT_YELLOW='' BRIGHT_BLUE=''
    BG_RED='' BG_GREEN='' BG_YELLOW=''
    BOLD='' DIM='' UNDERLINE='' BLINK='' REVERSE='' NC=''
fi

# Global progress tracking
declare -A PROGRESS_STATE
CURRENT_STEP=0
TOTAL_STEPS=0
CURRENT_APP=""
START_TIME=$(date +%s)

# Enhanced messaging functions
print_header() {
    local message="$1"
    local width=$((TERM_WIDTH - 4))
    
    echo ""
    echo -e "${BOLD}${BLUE}╭$(printf '─%.0s' $(seq 1 $width))╮${NC}"
    printf "${BOLD}${BLUE}│${NC} %-*s ${BOLD}${BLUE}│${NC}\n" $((width-2)) "$message"
    echo -e "${BOLD}${BLUE}╰$(printf '─%.0s' $(seq 1 $width))╯${NC}"
    echo ""
}

print_step() {
    local message="$1"
    local step_num="$2"
    
    if [ -n "$step_num" ]; then
        echo -e "${BLUE}${ARROW}${NC} ${BOLD}[$step_num/$TOTAL_STEPS]${NC} $message"
    else
        echo -e "${BLUE}${ARROW}${NC} ${BOLD}$message${NC}"
    fi
}

print_success() {
    local message="$1"
    echo -e "${GREEN}${CHECKMARK}${NC} ${BRIGHT_GREEN}$message${NC}"
}

print_error() {
    local message="$1"
    echo -e "${RED}${CROSSMARK}${NC} ${BRIGHT_RED}$message${NC}" >&2
}

print_warning() {
    local message="$1"
    echo -e "${YELLOW}${WARNING}${NC} ${BRIGHT_YELLOW}$message${NC}"
}

print_info() {
    local message="$1"
    echo -e "${CYAN}${INFO}${NC} ${message}"
}

print_bullet() {
    local message="$1"
    echo -e "  ${DIM}${BULLET}${NC} $message"
}

# Advanced progress bar with multiple styles
draw_progress_bar() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local style=${4:-"standard"}
    local label="$5"
    
    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))
    
    case "$style" in
        "standard")
            printf "\r${label} ["
            printf "%*s" $completed | tr ' ' "$PROGRESS_FULL"
            printf "%*s" $remaining | tr ' ' "$PROGRESS_EMPTY"
            printf "] %3d%% (%d/%d)" $percentage $current $total
            ;;
        "fancy")
            printf "\r${BOLD}${label}${NC} ${BLUE}["
            printf "${GREEN}%*s" $completed | tr ' ' "$PROGRESS_FULL"
            printf "${DIM}%*s" $remaining | tr ' ' "$PROGRESS_EMPTY"
            printf "${BLUE}]${NC} ${BOLD}%3d%%${NC} ${DIM}(%d/%d)${NC}" $percentage $current $total
            ;;
        "minimal")
            printf "\r%s: %d%%" "$label" $percentage
            ;;
        "percentage")
            local blocks=$((percentage / 2))
            printf "\r${label} "
            printf "${GREEN}%*s" $blocks | tr ' ' '█'
            printf "${DIM}%*s" $((50 - blocks)) | tr ' ' '░'
            printf "${NC} %3d%%" $percentage
            ;;
    esac
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# Animated spinner
show_spinner() {
    local pid=$1
    local message="$2"
    local delay=0.1
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "\r${message} ${SPINNER_CHARS[i]} "
        i=$(( (i + 1) % ${#SPINNER_CHARS[@]} ))
        sleep $delay
    done
    printf "\r${message} ${GREEN}${CHECKMARK}${NC}\n"
}

# System information collection
collect_system_info() {
    local info_file="${1:-/tmp/omniset-system-info.txt}"
    
    print_step "Collecting system information..."
    
    {
        echo "System Information for OmniSet"
        echo "=============================="
        echo "Collection Date: $(date)"
        echo "Collection Time: $(date +%s)"
        echo ""
        
        echo "=== Basic System Info ==="
        echo "Hostname: $(hostname)"
        echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")"
        echo "OS Release: $(lsb_release -r 2>/dev/null | cut -f2 || echo "Unknown")"
        echo "OS Codename: $(lsb_release -c 2>/dev/null | cut -f2 || echo "Unknown")"
        echo "Kernel: $(uname -r)"
        echo "Architecture: $(dpkg --print-architecture 2>/dev/null || uname -m)"
        echo "Platform: $(uname -p)"
        echo "Shell: $SHELL"
        echo "User: $USER"
        echo "Home: $HOME"
        echo "Language: $LANG"
        echo "Timezone: $(timedatectl show -p Timezone --value 2>/dev/null || echo "Unknown")"
        echo ""
        
        echo "=== Hardware Info ==="
        echo "CPU Model: $(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
        echo "CPU Cores: $(nproc)"
        echo "Total Memory: $(free -h | awk 'NR==2{print $2}')"
        echo "Available Memory: $(free -h | awk 'NR==2{print $7}')"
        echo "Swap: $(free -h | awk 'NR==3{print $2}')"
        echo ""
        
        echo "=== Storage Info ==="
        echo "Root Filesystem:"
        df -h / | tail -1
        echo ""
        echo "All Mounted Filesystems:"
        df -h
        echo ""
        
        echo "=== Network Info ==="
        echo "Primary IP: $(ip route get 8.8.8.8 2>/dev/null | grep -Po 'src \K\S+' || echo "Unknown")"
        echo "Network Interfaces:"
        ip -brief addr show 2>/dev/null || ifconfig -a 2>/dev/null | grep -E '^[a-z]'
        echo ""
        
        echo "=== Desktop Environment ==="
        echo "Desktop Session: ${XDG_CURRENT_DESKTOP:-Unknown}"
        echo "Display Server: ${XDG_SESSION_TYPE:-Unknown}"
        echo "Window Manager: ${DESKTOP_SESSION:-Unknown}"
        echo "Display: ${DISPLAY:-Unknown}"
        echo ""
        
        echo "=== Virtualization ==="
        detect_virtualization
        echo ""
        
        echo "=== Package Managers ==="
        command -v apt >/dev/null && echo "APT: $(apt --version | head -1)"
        command -v snap >/dev/null && echo "Snap: $(snap version | head -1)"
        command -v flatpak >/dev/null && echo "Flatpak: $(flatpak --version)"
        command -v docker >/dev/null && echo "Docker: $(docker --version)"
        echo ""
        
        echo "=== Development Tools ==="
        command -v git >/dev/null && echo "Git: $(git --version)"
        command -v python3 >/dev/null && echo "Python3: $(python3 --version)"
        command -v node >/dev/null && echo "Node.js: $(node --version)"
        command -v code >/dev/null && echo "VS Code: $(code --version | head -1)"
        echo ""
        
        echo "=== System Load ==="
        echo "Uptime: $(uptime)"
        echo "Load Average: $(uptime | grep -o 'load average:.*')"
        echo "Running Processes: $(ps aux | wc -l)"
        echo ""
        
        echo "=== Recent System Logs ==="
        echo "Last 5 system errors:"
        journalctl -p err -n 5 --no-pager 2>/dev/null || echo "Unable to access system logs"
        
    } > "$info_file"
    
    print_success "System information collected: $info_file"
    return 0
}

# Architecture validation
validate_architecture() {
    local app="$1"
    local required_arch="$2"
    local current_arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
    
    # If no specific architecture required, allow any
    if [ -z "$required_arch" ] || [ "$required_arch" = "any" ] || [ "$required_arch" = "all" ]; then
        return 0
    fi
    
    # Normalize architecture names
    case "$current_arch" in
        "x86_64") current_arch="amd64" ;;
        "aarch64") current_arch="arm64" ;;
        "armv7l") current_arch="armhf" ;;
    esac
    
    case "$required_arch" in
        "x86_64") required_arch="amd64" ;;
        "aarch64") required_arch="arm64" ;;
        "armv7l") required_arch="armhf" ;;
    esac
    
    if [ "$required_arch" != "$current_arch" ]; then
        print_warning "$app requires $required_arch architecture but system is $current_arch"
        echo "Continue anyway? (y/N)"
        read -r continue_anyway
        if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
            return 1
        fi
    fi
    
    return 0
}

# Disk space checking with detailed information
check_available_space() {
    local required_mb=${1:-2048}  # Default 2GB
    local target_path=${2:-"/"}   # Default root filesystem
    local app_name="$3"
    
    print_step "Checking disk space requirements..."
    
    # Get disk usage information
    local df_output=$(df "$target_path" | tail -1)
    local available_kb=$(echo "$df_output" | awk '{print $4}')
    local available_mb=$((available_kb / 1024))
    local total_kb=$(echo "$df_output" | awk '{print $2}')
    local total_gb=$((total_kb / 1024 / 1024))
    local used_kb=$(echo "$df_output" | awk '{print $3}')
    local used_percent=$(echo "$df_output" | awk '{print $5}' | sed 's/%//')
    
    # Display current disk usage
    print_info "Disk usage for $target_path:"
    print_bullet "Total space: ${total_gb}GB"
    print_bullet "Used space: ${used_percent}% ($(( used_kb / 1024 / 1024 ))GB)"
    print_bullet "Available space: ${available_mb}MB"
    print_bullet "Required space: ${required_mb}MB"
    
    # Visual representation of disk usage
    local bar_width=40
    local used_blocks=$((used_percent * bar_width / 100))
    local free_blocks=$((bar_width - used_blocks))
    
    printf "    Usage: ["
    printf "${RED}%*s" $used_blocks | tr ' ' '█'
    printf "${GREEN}%*s" $free_blocks | tr ' ' '░'
    printf "${NC}] %d%%\n" $used_percent
    
    # Check if we have enough space
    if [ $available_mb -lt $required_mb ]; then
        print_error "Insufficient disk space for ${app_name:-installation}"
        print_error "Required: ${required_mb}MB, Available: ${available_mb}MB"
        print_error "Please free up $((required_mb - available_mb))MB of space"
        
        # Suggest cleanup options
        echo ""
        print_info "Space cleanup suggestions:"
        print_bullet "Run: sudo apt autoremove && sudo apt autoclean"
        print_bullet "Clear browser cache and downloads"
        print_bullet "Remove old log files: sudo journalctl --vacuum-time=7d"
        print_bullet "Check large files: du -h ~ | sort -hr | head -20"
        
        return 1
    fi
    
    # Warn if space is getting low (less than 1GB remaining after installation)
    local remaining_after=$((available_mb - required_mb))
    if [ $remaining_after -lt 1024 ]; then
        print_warning "Disk space will be low after installation (${remaining_after}MB remaining)"
        print_warning "Consider freeing up additional space"
    else
        print_success "Sufficient disk space available"
    fi
    
    return 0
}

# Enhanced installation progress tracking
start_installation_progress() {
    local personality="$1"
    local apps_list="$2"
    
    IFS=',' read -ra APP_ARRAY <<< "$apps_list"
    TOTAL_STEPS=${#APP_ARRAY[@]}
    CURRENT_STEP=0
    START_TIME=$(date +%s)
    
    print_header "Installing $personality personality ($TOTAL_STEPS applications)"
    
    # Initialize progress state
    for app in "${APP_ARRAY[@]}"; do
        PROGRESS_STATE["$app"]="pending"
    done
}

# Update progress for current app
update_app_progress() {
    local app="$1"
    local status="$2"  # starting, downloading, installing, configuring, completed, failed
    local progress="$3" # 0-100
    
    CURRENT_APP="$app"
    PROGRESS_STATE["$app"]="$status"
    
    case "$status" in
        "starting")
            CURRENT_STEP=$((CURRENT_STEP + 1))
            print_step "Starting installation of $app" "$CURRENT_STEP"
            ;;
        "downloading")
            printf "\r  ${CYAN}${ARROW}${NC} Downloading $app... "
            if [ -n "$progress" ]; then
                draw_progress_bar "$progress" 100 30 "fancy" ""
            fi
            ;;
        "installing")
            printf "\r  ${BLUE}${ARROW}${NC} Installing $app... "
            ;;
        "configuring")
            printf "\r  ${PURPLE}${ARROW}${NC} Configuring $app... "
            ;;
        "completed")
            printf "\r  ${GREEN}${CHECKMARK}${NC} $app installed successfully\n"
            ;;
        "failed")
            printf "\r  ${RED}${CROSSMARK}${NC} $app installation failed\n"
            ;;
    esac
}

# Show overall installation progress
show_overall_progress() {
    local completed=0
    local failed=0
    
    for app in "${!PROGRESS_STATE[@]}"; do
        case "${PROGRESS_STATE[$app]}" in
            "completed") completed=$((completed + 1)) ;;
            "failed") failed=$((failed + 1)) ;;
        esac
    done
    
    local total_processed=$((completed + failed))
    
    if [ $total_processed -gt 0 ]; then
        echo ""
        draw_progress_bar "$total_processed" "$TOTAL_STEPS" 50 "fancy" "Overall Progress"
        
        # Show time estimates
        local elapsed=$(($(date +%s) - START_TIME))
        local rate=$(echo "scale=2; $total_processed / $elapsed" | bc -l 2>/dev/null || echo "0")
        local remaining_apps=$((TOTAL_STEPS - total_processed))
        
        if [ "$rate" != "0" ] && [ $remaining_apps -gt 0 ]; then
            local eta=$(echo "scale=0; $remaining_apps / $rate" | bc -l 2>/dev/null || echo "0")
            local eta_min=$((eta / 60))
            local eta_sec=$((eta % 60))
            
            printf "  ETA: %dm %ds | " $eta_min $eta_sec
        fi
        
        printf "Completed: ${GREEN}%d${NC} | Failed: ${RED}%d${NC} | Remaining: %d\n" \
               $completed $failed $remaining_apps
    fi
}

# Installation summary with statistics
show_installation_summary() {
    local personality="$1"
    local end_time=$(date +%s)
    local total_time=$((end_time - START_TIME))
    local minutes=$((total_time / 60))
    local seconds=$((total_time % 60))
    
    local completed=0
    local failed=0
    local completed_apps=()
    local failed_apps=()
    
    for app in "${!PROGRESS_STATE[@]}"; do
        case "${PROGRESS_STATE[$app]}" in
            "completed") 
                completed=$((completed + 1))
                completed_apps+=("$app")
                ;;
            "failed") 
                failed=$((failed + 1))
                failed_apps+=("$app")
                ;;
        esac
    done
    
    echo ""
    print_header "Installation Summary"
    
    print_info "Personality: $personality"
    print_info "Total time: ${minutes}m ${seconds}s"
    print_info "Applications processed: $TOTAL_STEPS"
    
    if [ $completed -gt 0 ]; then
        print_success "Successfully installed: $completed applications"
        for app in "${completed_apps[@]}"; do
            print_bullet "${GREEN}$app${NC}"
        done
    fi
    
    if [ $failed -gt 0 ]; then
        echo ""
        print_error "Failed installations: $failed applications"
        for app in "${failed_apps[@]}"; do
            print_bullet "${RED}$app${NC}"
        done
    fi
    
    # Success rate
    local success_rate=$((completed * 100 / TOTAL_STEPS))
    echo ""
    printf "Success rate: "
    if [ $success_rate -ge 90 ]; then
        printf "${GREEN}%d%%${NC}\n" $success_rate
    elif [ $success_rate -ge 70 ]; then
        printf "${YELLOW}%d%%${NC}\n" $success_rate
    else
        printf "${RED}%d%%${NC}\n" $success_rate
    fi
    
    # Performance metrics
    if [ $total_time -gt 0 ]; then
        local apps_per_minute=$(echo "scale=1; $completed * 60 / $total_time" | bc -l 2>/dev/null || echo "0")
        print_info "Installation rate: $apps_per_minute apps/minute"
    fi
}

# Interactive confirmation with preview
confirm_installation() {
    local personality="$1"
    local apps_list="$2"
    
    print_header "Installation Preview"
    
    print_info "Selected personality: ${BOLD}$personality${NC}"
    print_info "Applications to install:"
    
    IFS=',' read -ra APP_ARRAY <<< "$apps_list"
    local app_count=${#APP_ARRAY[@]}
    
    for app in "${APP_ARRAY[@]}"; do
        print_bullet "$app"
    done
    
    echo ""
    print_info "Total applications: $app_count"
    print_info "Estimated time: $((app_count * 2-5)) minutes"
    print_info "Estimated disk usage: $((app_count * 100-200))MB"
    
    echo ""
    printf "Continue with installation? (${GREEN}y${NC}/${RED}N${NC}): "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Installation cancelled by user"
        return 1
    fi
    
    return 0
}

# Detect virtualization environment
detect_virtualization() {
    local virt_type="bare-metal"
    
    if [ -f /proc/xen/capabilities ] || [ -d /proc/xen ]; then
        virt_type="xen"
    elif [ -f /.dockerenv ]; then
        virt_type="docker"
    elif grep -q "QEMU" /proc/cpuinfo 2>/dev/null; then
        virt_type="qemu/kvm"
    elif [ -f /sys/hypervisor/uuid ] && head -c 3 /sys/hypervisor/uuid 2>/dev/null | grep -q "ec2"; then
        virt_type="aws-ec2"
    elif command -v systemd-detect-virt >/dev/null; then
        virt_type=$(systemd-detect-virt 2>/dev/null || echo "bare-metal")
    fi
    
    echo "Virtualization: $virt_type"
    
    # Adjust recommendations based on environment
    case "$virt_type" in
        "docker")
            print_info "Running in Docker container - some features may be limited"
            ;;
        "aws-ec2")
            print_info "Running on AWS EC2 - optimized for cloud environment"
            ;;
        "qemu/kvm")
            print_info "Running in virtual machine - performance may be reduced"
            ;;
    esac
}

# Initialize the UX system
initialize_ux_system() {
    # Check terminal capabilities
    if [ ! -t 1 ]; then
        print_warning "Not running in interactive terminal - some features disabled"
    fi
    
    # Check for required commands
    local missing_commands=()
    for cmd in "tput" "bc"; do
        if ! command -v "$cmd" >/dev/null; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        print_warning "Missing commands for enhanced UX: ${missing_commands[*]}"
        print_info "Install with: sudo apt install ${missing_commands[*]}"
    fi
    
    # Set up signal handlers for cleanup
    trap 'printf "\n"; print_warning "Installation interrupted by user"; exit 130' INT TERM
    
    print_success "Enhanced UX system initialized"
}