#!/bin/bash
# Essential System Tools Installation
set -euo pipefail

echo "Installing Essential System Tools..."

sudo apt-get update

sudo apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    zip \
    tar \
    gzip \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    nano \
    vim \
    tree \
    htop \
    net-tools \
    iputils-ping \
    dnsutils \
    jq \
    bc

echo "Essential tools installed successfully"
