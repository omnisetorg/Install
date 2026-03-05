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
        # Generate a random password
        POSTGRES_PASSWORD=$(head -c 16 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9' | head -c 16)

        echo "Creating PostgreSQL container..."
        docker run -d \
            --name postgres \
            -e POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
            -e POSTGRES_USER=postgres \
            -e POSTGRES_DB=postgres \
            -p 5432:5432 \
            -v postgres_data:/var/lib/postgresql/data \
            --restart unless-stopped \
            postgres:latest

        echo ""
        echo "Generated password: $POSTGRES_PASSWORD"
        echo "Save this password - it cannot be recovered!"
    fi

    echo ""
    echo "PostgreSQL running in Docker"
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
