#!/bin/bash
# VS Code Installation Script
# modules/desktop/vscode/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

install_vscode_apt_repo() {
    print_bullet "Adding Microsoft repository..."

    # Add GPG key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/microsoft.gpg /usr/share/keyrings/microsoft.gpg
    rm /tmp/microsoft.gpg

    # Add repository
    echo "deb [arch=${ARCH},arm64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
        sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    # Install
    sudo apt-get update
    sudo apt-get install -y code
}

install_vscode_deb() {
    local deb_url

    case "$ARCH" in
        amd64)
            deb_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
            ;;
        arm64)
            deb_url="https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-arm64"
            ;;
        *)
            return 1
            ;;
    esac

    print_bullet "Downloading VS Code..."
    wget -q -O /tmp/vscode.deb "$deb_url"

    print_bullet "Installing..."
    sudo dpkg -i /tmp/vscode.deb || sudo apt-get install -f -y
    rm /tmp/vscode.deb
}

install_extensions() {
    local extensions="$1"

    if [[ -z "$extensions" ]]; then
        return 0
    fi

    print_bullet "Installing extensions..."

    IFS=',' read -ra ext_array <<< "$extensions"
    for ext in "${ext_array[@]}"; do
        code --install-extension "$ext" --force 2>/dev/null || true
    done
}

main() {
    # Check if already installed
    if command -v code &>/dev/null; then
        print_info "VS Code is already installed"
        local version=$(code --version 2>/dev/null | head -1)
        print_bullet "Version: $version"
    else
        # Try apt repo first, then direct deb
        if ! install_vscode_apt_repo; then
            print_warning "Repository method failed, trying direct download..."
            install_vscode_deb
        fi
    fi

    # Install requested extensions
    if [[ -n "${OPTIONS:-}" ]]; then
        install_extensions "$OPTIONS"
    fi

    print_success "VS Code installation complete"
}

main
