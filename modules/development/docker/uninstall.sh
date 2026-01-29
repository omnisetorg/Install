#!/bin/bash
# Docker Uninstall Script - Multi-distro support
set -euo pipefail

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_info() { echo "ℹ $1"; }
    print_error() { echo "✗ $1" >&2; }
fi

REMOVE_DATA="${1:-false}"

print_step "Uninstalling Docker..."

# Stop Docker service
print_info "Stopping Docker service..."
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl stop docker.socket 2>/dev/null || true
sudo systemctl stop containerd 2>/dev/null || true

# Remove Docker packages (Debian/Ubuntu)
if command -v apt-get &>/dev/null; then
    sudo apt-get remove -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true

    # Remove APT repo
    sudo rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
    sudo rm -f /etc/apt/keyrings/docker.gpg 2>/dev/null || true
    sudo rm -f /usr/share/keyrings/docker.gpg 2>/dev/null || true
fi

# Remove Docker packages (Fedora/RHEL)
if command -v dnf &>/dev/null; then
    sudo dnf remove -y docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras 2>/dev/null || true
    sudo dnf autoremove -y 2>/dev/null || true
fi

# Remove Docker packages (Arch)
if command -v pacman &>/dev/null; then
    sudo pacman -Rs --noconfirm docker docker-compose docker-buildx 2>/dev/null || true
fi

# Remove Docker packages (openSUSE)
if command -v zypper &>/dev/null; then
    sudo zypper remove -y docker docker-compose 2>/dev/null || true
fi

# Remove Snap version
if command -v snap &>/dev/null; then
    sudo snap remove docker 2>/dev/null || true
fi

# Remove user from docker group
sudo gpasswd -d "$USER" docker 2>/dev/null || true

# Remove Docker Desktop if installed
if command -v apt-get &>/dev/null; then
    sudo apt-get remove -y docker-desktop 2>/dev/null || true
fi

print_success "Docker packages removed"

# Remove data if requested
if [[ "$REMOVE_DATA" == "true" ]] || [[ "$REMOVE_DATA" == "--purge" ]]; then
    print_warning "Removing all Docker data (containers, images, volumes)..."

    sudo rm -rf /var/lib/docker 2>/dev/null || true
    sudo rm -rf /var/lib/containerd 2>/dev/null || true
    sudo rm -rf /etc/docker 2>/dev/null || true
    rm -rf "$HOME/.docker" 2>/dev/null || true
    rm -rf "$HOME/.local/share/docker-desktop" 2>/dev/null || true

    print_success "All Docker data removed"
else
    print_info "Docker data preserved at /var/lib/docker"
    print_info "Use --purge to remove all containers, images, and volumes"
fi

print_success "Docker uninstalled"
print_warning "Log out and back in for group changes to take effect"
