#!/bin/bash
# Valkey Installation (Docker)
# modules/databases/valkey/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Parse options
VALKEY_VERSION="${OPTIONS:-8.0}"
VALKEY_PORT="${VALKEY_PORT:-6380}"

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

check_docker() {
    if ! command -v docker &>/dev/null; then
        print_error "Docker is required but not installed"
        print_bullet "Run: omniset install docker"
        exit 1
    fi
}

install_valkey() {
    print_step "Installing Valkey ${VALKEY_VERSION} via Docker..."

    # Check if container exists
    if docker ps -a --format '{{.Names}}' | grep -q "^omniset-valkey$"; then
        print_warning "Valkey container already exists"

        if docker ps --format '{{.Names}}' | grep -q "^omniset-valkey$"; then
            print_bullet "Container is running"
        else
            print_bullet "Starting existing container..."
            docker start omniset-valkey
        fi
        return 0
    fi

    # Create data directory
    mkdir -p ~/.local/share/omniset/valkey/data

    # Run Valkey container
    docker run -d \
        --name omniset-valkey \
        --restart unless-stopped \
        -v ~/.local/share/omniset/valkey/data:/data \
        -p "${VALKEY_PORT}:6379" \
        "valkey/valkey:${VALKEY_VERSION}"

    print_success "Valkey installed"
}

install_client() {
    print_step "Installing Redis CLI (compatible with Valkey)..."

    if command -v redis-cli &>/dev/null; then
        print_warning "Redis CLI already installed"
        return 0
    fi

    sudo apt-get update
    sudo apt-get install -y redis-tools

    print_success "Redis CLI installed"
}

main() {
    print_step "Installing Valkey for $ARCH"

    check_docker
    install_valkey
    install_client

    echo ""
    echo "════════════════════════════════════════════"
    echo "Valkey Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Valkey ${VALKEY_VERSION} running in Docker"

    echo ""
    print_bullet "Host: localhost"
    print_bullet "Port: ${VALKEY_PORT}"
    echo ""
    print_bullet "Connect: redis-cli -p ${VALKEY_PORT}"
    print_bullet "Stop: docker stop omniset-valkey"
    print_bullet "Start: docker start omniset-valkey"
    print_bullet "Logs: docker logs omniset-valkey"
    echo ""
    print_bullet "Valkey is an open-source Redis fork"
}

main "$@"
