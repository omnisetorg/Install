#!/bin/bash

arch=$1

case $arch in
    amd64)
        echo "Downloading DaVinci Resolve installer for amd64 architecture..."
        wget https://www.blackmagicdesign.com/products/davinciresolve/ -O DaVinci_Resolve_Linux.zip
        echo "Extracting installer..."
        unzip DaVinci_Resolve_Linux.zip -d davinci_resolve_installer
        echo "Running installer..."
        cd davinci_resolve_installer
        sudo ./DaVinci_Resolve_Installer.run
        cd ..
        echo "Cleaning up..."
        rm -rf DaVinci_Resolve_Linux.zip davinci_resolve_installer
        echo "DaVinci Resolve installation completed!"
        ;;
    *)
        echo "Unsupported architecture: $arch. DaVinci Resolve supports only amd64 (x86_64)."
        exit 1
        ;;
esac