#!/bin/bash
set -euo pipefail

echo "Installing MySQL via Docker..."

if ! command -v docker &>/dev/null; then
    echo "Docker is required. Install docker module first."
    exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q "^mysql$"; then
    echo "MySQL container already exists"
    docker start mysql 2>/dev/null || true
else
    read -sp "Enter MySQL root password (leave empty for 'mysql'): " MYSQL_PASSWORD
    echo ""
    MYSQL_PASSWORD="${MYSQL_PASSWORD:-mysql}"

    docker run -d \
        --name mysql \
        -e MYSQL_ROOT_PASSWORD="$MYSQL_PASSWORD" \
        -p 127.0.0.1:3306:3306 \
        -v mysql_data:/var/lib/mysql \
        --restart unless-stopped \
        mysql:8.4
fi

echo ""
echo "MySQL running on localhost:3306"
echo "Connect: mysql -h 127.0.0.1 -u root -p"
