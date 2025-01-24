#!/bin/bash

arch=$1

case $arch in
    amd64)
        sudo apt remove --purge -y code
        ;;
    armhf)
        sudo apt remove --purge -y code code-oss
        ;;
    arm64)
        sudo apt remove --purge -y code code-oss
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac