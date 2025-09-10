#!/bin/bash

# Vicinae Launcher Installation Script
# High-performance, native launcher for Linux - Raycast compatible

arch=$1

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

# Function to get the latest Vicinae version
get_latest_version() {
    curl -s "https://api.github.com/repos/vicinaehq/vicinae/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
}

# Function to install Vicinae
install_vicinae() {
    print_status "Installing Vicinae launcher for architecture: $arch"
    
    # Check if already installed
    if command -v vicinae >/dev/null 2>&1; then
        print_warning "Vicinae is already installed"
        vicinae --version 2>/dev/null || echo "Version check failed"
        echo "Continue with reinstallation? (y/N)"
        read -r reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            print_status "Skipping Vicinae installation"
            return 0
        fi
    fi
    
    case $arch in
        amd64)
            print_status "Getting latest Vicinae version..."
            local version=$(get_latest_version)
            if [ -z "$version" ]; then
                print_error "Failed to get latest version information"
                return 1
            fi
            
            print_status "Downloading Vicinae $version for x86_64..."
            local download_url="https://github.com/vicinaehq/vicinae/releases/download/${version}/vicinae-linux-x86_64-${version}.tar.gz"
            
            if ! wget -O vicinae.tar.gz "$download_url" 2>/dev/null; then
                print_error "Failed to download Vicinae"
                return 1
            fi
            
            print_status "Extracting Vicinae..."
            tar -xzf vicinae.tar.gz
            
            # Find the extracted directory (should be vicinae-linux-x86_64-version)
            local extracted_dir=$(tar -tzf vicinae.tar.gz | head -1 | cut -f1 -d"/")
            if [ ! -d "$extracted_dir" ]; then
                print_error "Failed to find extracted Vicinae directory"
                rm -f vicinae.tar.gz
                return 1
            fi
            
            print_status "Installing Vicinae binary..."
            sudo mkdir -p /opt/vicinae
            sudo cp -r "$extracted_dir"/* /opt/vicinae/
            sudo chmod +x /opt/vicinae/vicinae
            
            # Create symlink to make it available in PATH
            sudo ln -sf /opt/vicinae/vicinae /usr/local/bin/vicinae
            
            # Cleanup
            rm -f vicinae.tar.gz
            rm -rf "$extracted_dir"
            ;;
        arm64)
            print_warning "Vicinae binary builds are not available for ARM64"
            print_info "You can try building from source or using an alternative launcher"
            print_info "Visit: https://github.com/vicinaehq/vicinae for build instructions"
            return 1
            ;;
        armhf)
            print_warning "Vicinae is not supported on ARMv7 (armhf) architecture"
            print_info "Consider using an alternative launcher for ARM devices"
            return 1
            ;;
        *)
            print_error "Unsupported architecture: $arch"
            return 1
            ;;
    esac
    
    return 0
}

# Function to create desktop entry
create_desktop_entry() {
    print_status "Creating desktop entry..."
    
    local desktop_entry="[Desktop Entry]
Name=Vicinae
Comment=A focused launcher for your desktop — native, fast, extensible
Exec=vicinae
Icon=vicinae
Terminal=false
Type=Application
Categories=Utility;
StartupNotify=true
Keywords=launcher;search;application;raycast;"

    echo "$desktop_entry" > ~/.local/share/applications/vicinae.desktop
    chmod +x ~/.local/share/applications/vicinae.desktop
    
    print_success "Desktop entry created"
}

# Function to set up systemd user service
setup_systemd_service() {
    print_status "Setting up systemd user service..."
    
    # Create user systemd directory if it doesn't exist
    mkdir -p ~/.config/systemd/user
    
    # Download the official systemd service file
    local service_url="https://raw.githubusercontent.com/vicinaehq/vicinae/refs/heads/main/extra/vicinae.service"
    
    if wget -O ~/.config/systemd/user/vicinae.service "$service_url" 2>/dev/null; then
        print_success "Systemd service file downloaded"
    else
        print_warning "Failed to download official service file, creating custom one..."
        
        # Create a custom service file
        cat > ~/.config/systemd/user/vicinae.service << EOF
[Unit]
Description=Vicinae launcher - A focused launcher for your desktop
After=graphical-session.target
BindsTo=graphical-session.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/local/bin/vicinae --daemon
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF
        print_success "Custom systemd service created"
    fi
    
    # Reload systemd user daemon
    systemctl --user daemon-reload
    
    # Ask user if they want to enable auto-start
    echo ""
    print_status "Enable Vicinae to start automatically with your desktop session? (Y/n)"
    read -r enable_autostart
    
    if [[ ! "$enable_autostart" =~ ^[Nn]$ ]]; then
        if systemctl --user enable vicinae.service; then
            print_success "Vicinae auto-start enabled"
            
            echo "Start Vicinae now? (Y/n)"
            read -r start_now
            if [[ ! "$start_now" =~ ^[Nn]$ ]]; then
                if systemctl --user start vicinae.service; then
                    print_success "Vicinae started successfully"
                else
                    print_warning "Failed to start Vicinae service - you can start it manually"
                fi
            fi
        else
            print_warning "Failed to enable auto-start - you can enable it manually with:"
            print_warning "systemctl --user enable vicinae.service"
        fi
    else
        print_status "Auto-start disabled - you can enable it later with:"
        print_status "systemctl --user enable vicinae.service"
    fi
}

# Function to download icon if available
setup_icon() {
    print_status "Setting up application icon..."
    
    local icon_url="https://raw.githubusercontent.com/vicinaehq/vicinae/refs/heads/main/vicinae/icons/vicinae.svg"
    local icon_dir="$HOME/.local/share/icons/hicolor/scalable/apps"
    
    mkdir -p "$icon_dir"
    
    if wget -O "$icon_dir/vicinae.svg" "$icon_url" 2>/dev/null; then
        print_success "Application icon installed"
        
        # Update icon cache if available
        if command -v gtk-update-icon-cache >/dev/null 2>&1; then
            gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor/ 2>/dev/null || true
        fi
    else
        print_warning "Failed to download application icon"
    fi
}

# Function to show post-installation info
show_usage_info() {
    print_success "Vicinae installation completed!"
    echo ""
    echo "🚀 Getting Started with Vicinae:"
    echo ""
    echo "• Launch with: vicinae"
    echo "• Or press your configured hotkey (default varies by desktop environment)"
    echo "• Type to search applications, files, and more"
    echo "• Use Tab to navigate between modules"
    echo ""
    echo "📖 Key Features:"
    echo "• Application launcher with smart search"
    echo "• File search and indexing"
    echo "• Calculator with history"
    echo "• Clipboard history tracker"
    echo "• Emoji picker"
    echo "• System shortcuts"
    echo "• Extensible with React/TypeScript"
    echo ""
    echo "⚙️ Configuration:"
    echo "• Configuration files: ~/.config/vicinae/"
    echo "• Documentation: https://docs.vicinae.com/"
    echo "• Extensions: Available via the launcher itself"
    echo ""
    echo "🔧 Systemd Service:"
    if systemctl --user is-enabled vicinae.service >/dev/null 2>&1; then
        echo "• Status: Enabled for auto-start"
        if systemctl --user is-active vicinae.service >/dev/null 2>&1; then
            echo "• Currently: Running"
        else
            echo "• Currently: Stopped"
        fi
    else
        echo "• Status: Disabled (manual start)"
    fi
    echo "• Control: systemctl --user [start|stop|enable|disable] vicinae.service"
    echo ""
    echo "💡 Tip: Vicinae runs in the background for instant access. Configure your"
    echo "   desktop environment to bind a hotkey (like Super+Space) to 'vicinae' for"
    echo "   quick access!"
}

# Main installation function
main() {
    print_status "Vicinae Launcher Installation"
    echo "============================================="
    echo ""
    
    # Check for required dependencies
    print_status "Checking system dependencies..."
    local missing_deps=()
    
    for dep in curl wget tar systemctl; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Installing missing dependencies..."
        sudo apt update && sudo apt install -y "${missing_deps[@]}"
    fi
    
    # Install Vicinae
    if install_vicinae; then
        print_success "Vicinae binary installed successfully"
        
        # Set up desktop integration
        create_desktop_entry
        setup_icon
        setup_systemd_service
        
        # Show usage information
        show_usage_info
        
        return 0
    else
        print_error "Vicinae installation failed"
        return 1
    fi
}

# Run main function
main