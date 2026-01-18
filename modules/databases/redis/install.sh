#!/bin/bash
# Redis Installation (via Docker)
set -euo pipefail

INSTALL_TYPE="${2:-docker}"

echo "Installing Redis..."

if [[ "$INSTALL_TYPE" == "docker" ]] && command -v docker &>/dev/null; then
    if docker ps -a --format '{{.Names}}' | grep -q "^redis$"; then
        echo "Redis container already exists"
        docker start redis 2>/dev/null || true
    else
        echo "Creating Redis container..."
        docker run -d \
            --name redis \
            -p 6379:6379 \
            -v redis_data:/data \
            --restart unless-stopped \
            redis:latest
    fi

    echo ""
    echo "Redis running in Docker on port 6379"
    echo ""
    echo "Commands:"
    echo "  docker exec -it redis redis-cli"
    echo "  docker stop redis"
    echo "  docker start redis"

else
    echo "Installing Redis via apt..."
    sudo apt-get update
    sudo apt-get install -y redis-server

    sudo systemctl enable redis-server
    sudo systemctl start redis-server

    echo "Redis installed and running on port 6379"
fi
