#!/bin/bash
# Docker Installation
# modules/development/docker/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Parse options
INSTALL_COMPOSE=true
INSTALL_DESKTOP=false
NON_ROOT=true

if [[ -n "$OPTIONS" ]]; then
    [[ "$OPTIONS" == *"no-compose"* ]] && INSTALL_COMPOSE=false
    [[ "$OPTIONS" == *"desktop"* ]] && INSTALL_DESKTOP=true
    [[ "$OPTIONS" == *"no-nonroot"* ]] && NON_ROOT=false
fi

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_bullet() { echo "  • $1"; }
fi

# ═══════════════════════════════════════════════════════════════
# Installation
# ═══════════════════════════════════════════════════════════════

install_docker_engine() {
    print_step "Installing Docker Engine..."

    if command -v docker &>/dev/null; then
        print_warning "Docker is already installed"
        docker --version
        return 0
    fi

    # Remove old versions
    sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

    # Install prerequisites
    sudo apt-get update
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Detect distro
    local distro
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="${ID}"
    else
        distro="ubuntu"
    fi

    # Get version codename
    local codename
    codename=$(lsb_release -cs 2>/dev/null || echo "jammy")

    # Add repository
    echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro} ${codename} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt-get update

    case "$ARCH" in
        amd64|arm64)
            sudo apt-get install -y \
                docker-ce \
                docker-ce-cli \
                containerd.io \
                docker-buildx-plugin \
                docker-compose-plugin
            ;;
        armhf)
            # Limited support for armhf
            sudo apt-get install -y docker.io
            print_warning "Using docker.io package for armhf (limited features)"
            ;;
    esac

    print_success "Docker Engine installed"
}

configure_docker() {
    print_step "Configuring Docker..."

    # Add user to docker group for non-root access
    if [[ "$NON_ROOT" == true ]]; then
        sudo usermod -aG docker "${USER}"
        print_success "Added ${USER} to docker group"
    fi

    # Configure log rotation
    sudo mkdir -p /etc/docker
    cat << 'EOF' | sudo tee /etc/docker/daemon.json > /dev/null
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "50m",
        "max-file": "5"
    }
}
EOF

    # Enable and start Docker
    sudo systemctl enable docker
    sudo systemctl start docker

    print_success "Docker configured"
}

install_docker_desktop() {
    if [[ "$INSTALL_DESKTOP" != true ]]; then
        return 0
    fi

    print_step "Installing Docker Desktop..."

    case "$ARCH" in
        amd64)
            local url="https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb"
            ;;
        arm64)
            local url="https://desktop.docker.com/linux/main/arm64/docker-desktop-arm64.deb"
            ;;
        *)
            print_warning "Docker Desktop not available for $ARCH"
            return 0
            ;;
    esac

    wget -qO /tmp/docker-desktop.deb "$url"
    sudo dpkg -i /tmp/docker-desktop.deb || sudo apt-get install -f -y
    rm /tmp/docker-desktop.deb

    print_success "Docker Desktop installed"
}

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    print_step "Installing Docker for $ARCH"

    install_docker_engine
    configure_docker
    install_docker_desktop

    echo ""
    echo "════════════════════════════════════════════"
    echo "Docker Installation Complete"
    echo "════════════════════════════════════════════"

    # Verify installation
    if command -v docker &>/dev/null; then
        print_success "Docker version: $(docker --version)"

        if [[ "$INSTALL_COMPOSE" == true ]]; then
            print_success "Docker Compose version: $(docker compose version 2>/dev/null || echo 'N/A')"
        fi
    fi

    echo ""
    print_warning "IMPORTANT: Log out and back in for docker group to take effect"
    print_bullet "Or run: newgrp docker"
    echo ""
    print_bullet "Test with: docker run hello-world"
}

main "$@"
