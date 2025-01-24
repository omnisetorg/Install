#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() { echo -e "${BLUE}==> ${NC}$1"; }
print_error() { echo -e "${RED}==> Error: ${NC}$1"; }
print_success() { echo -e "${GREEN}==> Success: ${NC}$1"; }

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/uninstall"

if [ ! -d "$SCRIPT_DIR" ]; then
    print_error "Uninstall directory not found"
    exit 1
fi

software_files=()
software_names=()

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
        *) echo "$(tr '[:lower:]' '[:upper:]' <<< ${filename:0:1})${filename:1}";;
    esac
}

print_message "Scanning for uninstallable software..."
while IFS= read -r file; do
    software_files+=("$file")
    software_name=$(get_software_name "$file")
    software_names+=("$software_name")
    echo "[${#software_files[@]}] $software_name"
done < <(find "$SCRIPT_DIR" -name "*.sh" -type f | sort)

if [ ${#software_files[@]} -eq 0 ]; then
    print_error "No uninstall scripts found"
    exit 1
fi

echo
print_message "Enter the numbers of software you want to uninstall (space-separated) or 'all' for everything:"
read -r selection

if [[ "$selection" == "all" ]]; then
    selected_indices=( $(seq 1 ${#software_files[@]}) )
else
    selected_indices=( $selection )
fi

for idx in "${selected_indices[@]}"; do
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt ${#software_files[@]} ]; then
        print_error "Invalid selection: $idx"
        exit 1
    fi
done

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