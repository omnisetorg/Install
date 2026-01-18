#!/bin/bash
# Docker Uninstallation
# modules/development/docker/uninstall.sh

set -euo pipefail

echo "Removing Docker..."

# Stop Docker services
sudo systemctl stop docker.socket 2>/dev/null || true
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl stop containerd 2>/dev/null || true

# Remove packages
sudo apt-get purge -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin \
    docker-ce-rootless-extras \
    docker-desktop \
    docker.io \
    2>/dev/null || true

# Remove Docker data (optional - commented out for safety)
# sudo rm -rf /var/lib/docker
# sudo rm -rf /var/lib/containerd

# Remove configuration
sudo rm -f /etc/apt/sources.list.d/docker.list
sudo rm -f /etc/apt/keyrings/docker.gpg
sudo rm -f /etc/docker/daemon.json

# Remove user from docker group
sudo deluser "${USER}" docker 2>/dev/null || true

sudo apt-get autoremove -y

echo "Docker removed"
echo "Note: Docker data in /var/lib/docker was preserved"
echo "Run 'sudo rm -rf /var/lib/docker' to remove all data"
