# Exit immediately if a command fails, treat unset variables as an error and ensure all parts of pipelines fail properly
set -euo pipefail

#!/bin/bash

# Function to determine CPU architecture
get_arch() {
    local arch
    case $(uname -m) in
        x86_64) arch="amd64" ;;
        armv7l) arch="armhf" ;;
        aarch64) arch="arm64" ;;
        *) echo "Unknown architecture"; exit 1 ;;
    esac
    echo "$arch"
}

# Get the CPU architecture
arch=$(get_arch)

# Update system packages
sudo apt update
sudo apt upgrade -y

# Load and execute each app script based on architecture
for app in apps/*.sh; do
    chmod +x "$app"
    ./"$app" "$arch"
done

# Clean up
sudo apt autoremove -y
sudo apt autoclean -y

echo "Setup complete! Enjoy your modern web development environment."