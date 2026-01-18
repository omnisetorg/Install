#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v go &>/dev/null; then
    echo "Go is already installed: $(go version)"
    exit 0
fi

echo "Installing Go..."

# Get latest version
GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)

# Map architecture
case "$ARCH" in
    amd64) GO_ARCH="amd64" ;;
    arm64) GO_ARCH="arm64" ;;
    armhf) GO_ARCH="armv6l" ;;
    *) echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Download and install
wget -qO /tmp/go.tar.gz "https://go.dev/dl/${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz
rm /tmp/go.tar.gz

# Add to PATH
if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# Go configuration
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
EOF
fi

# Create workspace
mkdir -p ~/go/{bin,src,pkg}

echo "Go installed: $(/usr/local/go/bin/go version)"
echo "Run 'source ~/.bashrc' to update PATH"
