#!/bin/bash

arch=$1

case $arch in
    amd64)
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
        sudo dpkg -i google-chrome-stable_current_amd64.deb
        rm google-chrome-stable_current_amd64.deb
        ;;
    armhf)
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_armhf.deb
        sudo dpkg -i google-chrome-stable_current_armhf.deb
        rm google-chrome-stable_current_armhf.deb
        ;;
    arm64)
        wget https://dl.google.com/linux/direct/google-chrome-stable_current_arm64.deb
        sudo dpkg -i google-chrome-stable_current_arm64.deb
        rm google-chrome-stable_current_arm64.deb
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac