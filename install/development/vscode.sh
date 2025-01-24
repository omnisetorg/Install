#!/bin/bash

arch=$1

case $arch in
    amd64)
        wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
        sudo apt update
        sudo apt install -y code
        ;;
    armhf)
        sudo apt install -y code-oss
        ;;
    arm64)
        sudo apt install -y code-oss
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac