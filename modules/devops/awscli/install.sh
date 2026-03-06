#!/bin/bash
set -euo pipefail

ARCH="${1:-amd64}"

if command -v aws &>/dev/null; then
    echo "AWS CLI is already installed ($(aws --version))"
    exit 0
fi

echo "Installing AWS CLI..."

case "$ARCH" in
    amd64)
        curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
        ;;
    arm64)
        curl -sSL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o /tmp/awscliv2.zip
        ;;
    *)
        echo "AWS CLI installer not available for $ARCH, trying pip..."
        pip3 install --user awscli
        echo "AWS CLI installed via pip"
        exit 0
        ;;
esac

cd /tmp
unzip -qo awscliv2.zip
sudo ./aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "AWS CLI installed successfully ($(aws --version))"
echo "Run 'aws configure' to set up credentials"
