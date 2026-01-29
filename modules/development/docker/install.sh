#!/bin/bash
# Docker Installation - Multi-distro support
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

# Detect distro
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-}"
        DISTRO_CODENAME="${VERSION_CODENAME:-}"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        DISTRO_ID="${DISTRIB_ID,,}"
        DISTRO_VERSION="${DISTRIB_RELEASE:-}"
        DISTRO_CODENAME="${DISTRIB_CODENAME:-}"
    else
        DISTRO_ID="unknown"
    fi

    # Normalize distro type
    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian)
            DISTRO_TYPE="debian"
            ;;
        fedora|rhel|centos|rocky|alma|oracle)
            DISTRO_TYPE="rhel"
            ;;
        arch|manjaro|endeavouros|garuda)
            DISTRO_TYPE="arch"
            ;;
        opensuse*|suse*|sles)
            DISTRO_TYPE="suse"
            ;;
        *)
            DISTRO_TYPE="unknown"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
# Debian/Ubuntu Installation
# ═══════════════════════════════════════════════════════════════

install_docker_debian() {
    print_step "Installing Docker on Debian/Ubuntu..."

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

    # Determine the correct Docker repo based on distro
    local docker_distro="$DISTRO_ID"
    case "$DISTRO_ID" in
        linuxmint|pop|elementary|zorin|kali)
            docker_distro="ubuntu"
            ;;
        raspbian)
            docker_distro="debian"
            ;;
    esac

    curl -fsSL "https://download.docker.com/linux/${docker_distro}/gpg" | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Get codename (fallback for derivatives)
    local codename="$DISTRO_CODENAME"
    if [[ -z "$codename" ]]; then
        codename=$(lsb_release -cs 2>/dev/null || echo "jammy")
    fi

    # Add repository
    echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${docker_distro} ${codename} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
}

# ═══════════════════════════════════════════════════════════════
# Fedora/RHEL Installation
# ═══════════════════════════════════════════════════════════════

install_docker_rhel() {
    print_step "Installing Docker on Fedora/RHEL..."

    # Remove old versions
    sudo dnf remove -y docker docker-client docker-client-latest \
        docker-common docker-latest docker-latest-logrotate \
        docker-logrotate docker-selinux docker-engine-selinux docker-engine 2>/dev/null || true

    # Install prerequisites
    sudo dnf install -y dnf-plugins-core

    # Add Docker repository
    local repo_url="https://download.docker.com/linux/fedora/docker-ce.repo"
    if [[ "$DISTRO_ID" == "centos" ]] || [[ "$DISTRO_ID" == "rhel" ]] || \
       [[ "$DISTRO_ID" == "rocky" ]] || [[ "$DISTRO_ID" == "alma" ]]; then
        repo_url="https://download.docker.com/linux/centos/docker-ce.repo"
    fi

    sudo dnf config-manager --add-repo "$repo_url"

    # Install Docker
    sudo dnf install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin
}

# ═══════════════════════════════════════════════════════════════
# Arch Linux Installation
# ═══════════════════════════════════════════════════════════════

install_docker_arch() {
    print_step "Installing Docker on Arch Linux..."

    # Install Docker from official repos
    sudo pacman -S --noconfirm docker docker-compose

    # docker-buildx is in community repo
    sudo pacman -S --noconfirm docker-buildx 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════
# openSUSE Installation
# ═══════════════════════════════════════════════════════════════

install_docker_suse() {
    print_step "Installing Docker on openSUSE..."

    # Install Docker
    sudo zypper install -y docker docker-compose

    # Or use official Docker repo
    # sudo zypper addrepo https://download.docker.com/linux/sles/docker-ce.repo
    # sudo zypper install -y docker-ce docker-ce-cli containerd.io
}

# ═══════════════════════════════════════════════════════════════
# Common Configuration
# ═══════════════════════════════════════════════════════════════

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

    case "$DISTRO_TYPE" in
        debian)
            wget -qO /tmp/docker-desktop.deb "$url"
            sudo dpkg -i /tmp/docker-desktop.deb || sudo apt-get install -f -y
            rm /tmp/docker-desktop.deb
            ;;
        rhel)
            # Docker Desktop for Fedora
            local rpm_url="https://desktop.docker.com/linux/main/amd64/docker-desktop-x86_64.rpm"
            wget -qO /tmp/docker-desktop.rpm "$rpm_url"
            sudo dnf install -y /tmp/docker-desktop.rpm
            rm /tmp/docker-desktop.rpm
            ;;
        *)
            print_warning "Docker Desktop installation not supported for $DISTRO_TYPE"
            return 0
            ;;
    esac

    print_success "Docker Desktop installed"
}

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    detect_distro

    print_step "Installing Docker for $DISTRO_ID ($DISTRO_TYPE) on $ARCH"

    if command -v docker &>/dev/null; then
        print_warning "Docker is already installed"
        docker --version
        print_info "Use --force to reinstall"
        configure_docker
        return 0
    fi

    # Install based on distro type
    case "$DISTRO_TYPE" in
        debian)
            install_docker_debian
            ;;
        rhel)
            install_docker_rhel
            ;;
        arch)
            install_docker_arch
            ;;
        suse)
            install_docker_suse
            ;;
        *)
            print_error "Unsupported distribution: $DISTRO_ID"
            print_info "Please install Docker manually: https://docs.docker.com/engine/install/"
            return 1
            ;;
    esac

    configure_docker
    install_docker_desktop

    echo ""
    echo "════════════════════════════════════════════"
    echo "Docker Installation Complete"
    echo "════════════════════════════════════════════"

    # Verify installation
    if command -v docker &>/dev/null; then
        print_success "Docker version: $(docker --version)"

        if command -v docker-compose &>/dev/null || docker compose version &>/dev/null 2>&1; then
            print_success "Docker Compose: $(docker compose version 2>/dev/null || docker-compose --version)"
        fi
    fi

    echo ""
    print_warning "IMPORTANT: Log out and back in for docker group to take effect"
    print_bullet "Or run: newgrp docker"
    echo ""
    print_bullet "Test with: docker run hello-world"
}

main "$@"
