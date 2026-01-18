#!/bin/bash
# MariaDB Installation (Docker)
# modules/databases/mariadb/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Parse options
MARIADB_VERSION="${OPTIONS:-11.6}"
MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-mariadb}"
MARIADB_PORT="${MARIADB_PORT:-3307}"

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

install_mariadb() {
    print_step "Installing MariaDB ${MARIADB_VERSION} via Docker..."

    # Check if container exists
    if docker ps -a --format '{{.Names}}' | grep -q "^omniset-mariadb$"; then
        print_warning "MariaDB container already exists"

        if docker ps --format '{{.Names}}' | grep -q "^omniset-mariadb$"; then
            print_bullet "Container is running"
        else
            print_bullet "Starting existing container..."
            docker start omniset-mariadb
        fi
        return 0
    fi

    # Create data directory
    mkdir -p ~/.local/share/omniset/mariadb/data

    # Run MariaDB container
    docker run -d \
        --name omniset-mariadb \
        --restart unless-stopped \
        -e MARIADB_ROOT_PASSWORD="$MARIADB_ROOT_PASSWORD" \
        -e MARIADB_DATABASE=dev \
        -v ~/.local/share/omniset/mariadb/data:/var/lib/mysql \
        -p "${MARIADB_PORT}:3306" \
        "mariadb:${MARIADB_VERSION}"

    # Wait for MariaDB to be ready
    print_bullet "Waiting for MariaDB to be ready..."
    local retries=30
    while ! docker exec omniset-mariadb mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "SELECT 1" &>/dev/null; do
        retries=$((retries - 1))
        if [[ $retries -eq 0 ]]; then
            print_warning "Timeout waiting for MariaDB"
            break
        fi
        sleep 1
    done

    print_success "MariaDB installed"
}

install_client() {
    print_step "Installing MariaDB client..."

    if command -v mariadb &>/dev/null; then
        print_warning "MariaDB client already installed"
        return 0
    fi

    sudo apt-get update
    sudo apt-get install -y mariadb-client

    print_success "MariaDB client installed"
}

main() {
    print_step "Installing MariaDB for $ARCH"

    check_docker
    install_mariadb
    install_client

    echo ""
    echo "════════════════════════════════════════════"
    echo "MariaDB Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "MariaDB ${MARIADB_VERSION} running in Docker"

    echo ""
    print_bullet "Host: localhost"
    print_bullet "Port: ${MARIADB_PORT}"
    print_bullet "Root password: ${MARIADB_ROOT_PASSWORD}"
    print_bullet "Default database: dev"
    echo ""
    print_bullet "Connect: mariadb -h 127.0.0.1 -P ${MARIADB_PORT} -u root -p"
    print_bullet "Stop: docker stop omniset-mariadb"
    print_bullet "Start: docker start omniset-mariadb"
    print_bullet "Logs: docker logs omniset-mariadb"
}

main "$@"
