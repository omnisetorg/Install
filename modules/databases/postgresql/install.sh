#!/bin/bash
# PostgreSQL Installation (via Docker)
set -euo pipefail

INSTALL_TYPE="${2:-docker}"

echo "Installing PostgreSQL..."

if [[ "$INSTALL_TYPE" == "docker" ]] && command -v docker &>/dev/null; then
    # Check if container exists
    if docker ps -a --format '{{.Names}}' | grep -q "^postgres$"; then
        echo "PostgreSQL container already exists"
        docker start postgres 2>/dev/null || true
    else
        echo "Creating PostgreSQL container..."
        docker run -d \
            --name postgres \
            -e POSTGRES_PASSWORD=postgres \
            -e POSTGRES_USER=postgres \
            -e POSTGRES_DB=postgres \
            -p 5432:5432 \
            -v postgres_data:/var/lib/postgresql/data \
            --restart unless-stopped \
            postgres:latest
    fi

    echo ""
    echo "PostgreSQL running in Docker"
    echo "Connection: postgresql://postgres:postgres@localhost:5432/postgres"
    echo ""
    echo "Commands:"
    echo "  docker exec -it postgres psql -U postgres"
    echo "  docker stop postgres"
    echo "  docker start postgres"

else
    # Install via apt
    echo "Installing PostgreSQL via apt..."
    sudo apt-get update
    sudo apt-get install -y postgresql postgresql-contrib

    sudo systemctl enable postgresql
    sudo systemctl start postgresql

    echo "PostgreSQL installed and running"
    echo "Default user: postgres"
    echo "Connect: sudo -u postgres psql"
fi
