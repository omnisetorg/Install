#!/bin/bash

# Vicinae Launcher Uninstall Script

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

# Function to stop and disable systemd service
remove_systemd_service() {
    print_status "Removing systemd user service..."
    
    # Stop the service if it's running
    if systemctl --user is-active vicinae.service >/dev/null 2>&1; then
        print_status "Stopping Vicinae service..."
        systemctl --user stop vicinae.service
        print_success "Vicinae service stopped"
    fi
    
    # Disable the service if it's enabled
    if systemctl --user is-enabled vicinae.service >/dev/null 2>&1; then
        print_status "Disabling Vicinae auto-start..."
        systemctl --user disable vicinae.service
        print_success "Vicinae auto-start disabled"
    fi
    
    # Remove service file
    if [ -f ~/.config/systemd/user/vicinae.service ]; then
        rm ~/.config/systemd/user/vicinae.service
        print_success "Systemd service file removed"
    fi
    
    # Reload systemd user daemon
    systemctl --user daemon-reload
}

# Function to remove desktop entry
remove_desktop_entry() {
    print_status "Removing desktop entry..."
    
    if [ -f ~/.local/share/applications/vicinae.desktop ]; then
        rm ~/.local/share/applications/vicinae.desktop
        print_success "Desktop entry removed"
    else
        print_warning "Desktop entry not found"
    fi
}

# Function to remove application icon
remove_icon() {
    print_status "Removing application icon..."
    
    local icon_path="$HOME/.local/share/icons/hicolor/scalable/apps/vicinae.svg"
    
    if [ -f "$icon_path" ]; then
        rm "$icon_path"
        print_success "Application icon removed"
        
        # Update icon cache if available
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
            gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/ 2>/dev/null || true
        fi
    else
        print_warning "Application icon not found"
    fi
}

# Function to remove Vicinae binary and installation
remove_vicinae_binary() {
    print_status "Removing Vicinae binary and installation..."
    
    # Remove symlink from PATH
    if [ -L /usr/local/bin/vicinae ]; then
        sudo rm /usr/local/bin/vicinae
        print_success "Removed Vicinae from PATH"
    elif [ -f /usr/local/bin/vicinae ]; then
        sudo rm /usr/local/bin/vicinae
        print_success "Removed Vicinae from PATH"
    fi
    
    # Remove installation directory
    if [ -d /opt/vicinae ]; then
        sudo rm -rf /opt/vicinae
        print_success "Removed Vicinae installation directory"
    fi
    
    # Check if vicinae command is still available
    if command -v vicinae >/dev/null 2>&1; then
        print_warning "Vicinae binary still found in PATH - may be installed elsewhere"
        print_warning "Location: $(which vicinae)"
    else
        print_success "Vicinae binary completely removed"
    fi
}

# Function to remove configuration files
remove_configuration() {
    print_status "Configuration and data cleanup..."
    
    local config_dir="$HOME/.config/vicinae"
    local data_dir="$HOME/.local/share/vicinae"
    local cache_dir="$HOME/.cache/vicinae"
    
    echo "Remove Vicinae configuration and data? This will delete:"
    echo "• Configuration files (~/.config/vicinae/)"
    echo "• User data and extensions (~/.local/share/vicinae/)"
    echo "• Cache files (~/.cache/vicinae/)"
    echo ""
    echo "Remove user data? (y/N)"
    read -r remove_data
    
    if [[ "$remove_data" =~ ^[Yy]$ ]]; then
        # Remove configuration
        if [ -d "$config_dir" ]; then
            rm -rf "$config_dir"
            print_success "Configuration files removed"
        fi
        
        # Remove user data
        if [ -d "$data_dir" ]; then
            rm -rf "$data_dir"
            print_success "User data removed"
        fi
        
        # Remove cache
        if [ -d "$cache_dir" ]; then
            rm -rf "$cache_dir"
            print_success "Cache files removed"
        fi
        
        print_success "All user data removed"
    else
        print_status "User configuration and data preserved"
        echo "To remove later:"
        echo "  rm -rf ~/.config/vicinae"
        echo "  rm -rf ~/.local/share/vicinae"
        echo "  rm -rf ~/.cache/vicinae"
    fi
}

# Function to check for running processes
check_running_processes() {
    print_status "Checking for running Vicinae processes..."
    
    local vicinae_pids=$(pgrep -f vicinae 2>/dev/null || true)
    
    if [ -n "$vicinae_pids" ]; then
        print_warning "Found running Vicinae processes: $vicinae_pids"
        echo "Terminate running Vicinae processes? (Y/n)"
        read -r kill_processes
        
        if [[ ! "$kill_processes" =~ ^[Nn]$ ]]; then
            print_status "Terminating Vicinae processes..."
            pkill -f vicinae 2>/dev/null || true
            sleep 2
            
            # Force kill if still running
            if pgrep -f vicinae >/dev/null 2>&1; then
                print_warning "Force killing remaining processes..."
                pkill -9 -f vicinae 2>/dev/null || true
            fi
            
            print_success "Vicinae processes terminated"
        else
            print_warning "Vicinae processes left running"
        fi
    else
        print_success "No running Vicinae processes found"
    fi
}

# Function to show uninstall summary
show_uninstall_summary() {
    echo ""
    print_success "Vicinae uninstallation completed!"
    echo ""
    echo "🗑️ What was removed:"
    echo "• Vicinae binary (/opt/vicinae, /usr/local/bin/vicinae)"
    echo "• Desktop entry (~/.local/share/applications/vicinae.desktop)"
    echo "• Application icon (~/.local/share/icons/...)"
    echo "• Systemd service (~/.config/systemd/user/vicinae.service)"
    
    if [ -d "$HOME/.config/vicinae" ] || [ -d "$HOME/.local/share/vicinae" ]; then
        echo ""
        echo "📁 Preserved files:"
        echo "• User configuration (~/.config/vicinae/)"
        echo "• User data (~/.local/share/vicinae/)"
        echo "• Cache files (~/.cache/vicinae/)"
    fi
    
    echo ""
    print_status "Vicinae has been successfully removed from your system."
}

# Main uninstall function
main() {
    echo ""
    print_status "Vicinae Launcher Uninstaller"
    echo "============================================="
    echo ""
    
    # Check if Vicinae is installed
    if ! command -v vicinae >/dev/null 2>&1 && [ ! -d /opt/vicinae ]; then
        print_warning "Vicinae does not appear to be installed"
        echo "Continue with cleanup anyway? (y/N)"
        read -r continue_cleanup
        if [[ ! "$continue_cleanup" =~ ^[Yy]$ ]]; then
            print_status "Uninstallation cancelled"
            exit 0
        fi
    fi
    
    print_warning "This will remove Vicinae and its components from your system."
    echo "Continue with uninstallation? (y/N)"
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "Uninstallation cancelled"
        exit 0
    fi
    
    echo ""
    print_status "Starting Vicinae uninstallation..."
    echo ""
    
    # Check and handle running processes
    check_running_processes
    
    # Remove systemd service
    remove_systemd_service
    
    # Remove desktop integration
    remove_desktop_entry
    remove_icon
    
    # Remove binary and installation
    remove_vicinae_binary
    
    # Handle user data
    remove_configuration
    
    # Show summary
    show_uninstall_summary
}

# Run main function
main