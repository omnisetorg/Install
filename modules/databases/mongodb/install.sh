#!/bin/bash
set -euo pipefail

echo "Installing MongoDB via Docker..."

if ! command -v docker &>/dev/null; then
    echo "Docker is required. Install docker module first."
    exit 1
fi

if docker ps -a --format '{{.Names}}' | grep -q "^mongodb$"; then
    echo "MongoDB container already exists"
    docker start mongodb 2>/dev/null || true
else
    docker run -d \
        --name mongodb \
        -p 127.0.0.1:27017:27017 \
        -v mongodb_data:/data/db \
        --restart unless-stopped \
        mongo:7
fi

echo ""
echo "MongoDB running on localhost:27017"
echo "Connect: docker exec -it mongodb mongosh"
