#!/bin/bash

# Exit immediately if a command fails
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored message
print_message() {
    echo -e "${BLUE}==> ${NC}$1"
}

# Function to print error
print_error() {
    echo -e "${RED}==> Error: ${NC}$1"
}

# Function to print success
print_success() {
    echo -e "${GREEN}==> Success: ${NC}$1"
}

# Get the script's directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Arrays to store file paths and names
software_files=()
software_names=()

# Function to extract software name from file path
get_software_name() {
    local filename=$(basename "$1" .sh)
    case "$filename" in
        "vscode") echo "Visual Studio Code";;
        "chrome") echo "Google Chrome";;
        "davinci-resolve") echo "DaVinci Resolve";;
        "discord") echo "Discord";;
        "docker") echo "Docker";;
        "virtualbox") echo "VirtualBox";;
        "vlc") echo "VLC Media Player";;
        "steam") echo "Steam";;
        "thunderbird") echo "Thunderbird";;
        *) echo "${filename^}";;  # Capitalize first letter for others
    esac
}

# Find all .sh files in the uninstall directory
print_message "Scanning for uninstallable software..."
index=1
while IFS= read -r file; do
    software_files+=("$file")
    software_name=$(get_software_name "$file")
    software_names+=("$software_name")
    echo "[$index] $software_name"
    ((index++))
done < <(find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -type f | sort)

if [ ${#software_files[@]} -eq 0 ]; then
    print_error "No uninstall scripts found"
    exit 1
fi

# Prompt user for selection
echo
print_message "Enter the numbers of software you want to uninstall (space-separated) or 'all' for everything:"
read -r selection

# Convert selection to array
if [[ "$selection" == "all" ]]; then
    selected_indices=( $(seq 1 ${#software_files[@]}) )
else
    selected_indices=( $selection )
fi

# Validate selections
for idx in "${selected_indices[@]}"; do
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt ${#software_files[@]} ]; then
        print_error "Invalid selection: $idx"
        exit 1
    fi
done

# Confirm uninstallation
echo
print_message "You selected:"
for idx in "${selected_indices[@]}"; do
    echo "- ${software_names[$((idx-1))]}"
done

echo
print_message "Are you sure you want to uninstall these software? (y/N)"
read -r confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    print_message "Uninstallation cancelled"
    exit 0
fi

# Perform uninstallation
echo
for idx in "${selected_indices[@]}"; do
    script_path="${software_files[$((idx-1))]}"
    software_name="${software_names[$((idx-1))]}"
    
    print_message "Uninstalling $software_name..."
    if bash "$script_path" "$(dpkg --print-architecture)"; then
        print_success "$software_name uninstalled successfully"
    else
        print_error "Failed to uninstall $software_name"
    fi
done

print_success "Uninstallation process completed"