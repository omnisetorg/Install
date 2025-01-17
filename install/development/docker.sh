#!/bin/bash

# Define architecture
arch=$(dpkg --print-architecture)

# Install Docker based on architecture
echo "Installing Docker for architecture: $arch"

# Add the official Docker repository
sudo install -m 0755 -d /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/docker.asc https://download.docker.com/linux/ubuntu/gpg
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update

# Check architecture-specific requirements
case $arch in
    amd64|arm64)
        # Install Docker engine, CLI, and standard plugins
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
        ;;
    armhf)
        # Note: Docker may have limited support for armhf
        echo "Installing Docker for armhf..."
        sudo apt install -y docker.io
        echo "Docker for armhf installed using docker.io package."
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac

# Give user privileged Docker access
sudo usermod -aG docker ${USER}

# Limit Docker log size to prevent disk space issues
echo '{"log-driver":"json-file","log-opts":{"max-size":"50m","max-file":"5"}}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker

# Install Docker Desktop if applicable (amd64 and arm64 only)
if [[ "$arch" == "amd64" || "$arch" == "arm64" ]]; then
    echo "Installing Docker Desktop for $arch..."
    curl -fsSL https://desktop.docker.com/linux/main/amd64/docker-desktop-4.0.0-linux-x86_64.deb -o docker-desktop.deb
    sudo dpkg -i docker-desktop.deb || sudo apt-get install -f -y
    rm docker-desktop.deb
    echo "Docker Desktop installation completed."
else
    echo "Docker Desktop is not supported for architecture: $arch"
fi

echo "Docker installation complete. Please restart your session or run 'newgrp docker' to enable Docker access without re-login."