#!/bin/bash

arch=$1

case $arch in
    amd64)
        wget https://www.blackmagicdesign.com/products/davinciresolve/ -O DaVinci_Resolve_Linux.zip
        unzip DaVinci_Resolve_Linux.zip -d davinci_resolve_installer
        cd davinci_resolve_installer
        sudo ./DaVinci_Resolve_Installer.run
        cd ..
        rm -rf DaVinci_Resolve_Linux.zip davinci_resolve_installer
        echo "DaVinci Resolve installation completed!"
        ;;
    *)
        echo "Unsupported architecture: $arch. DaVinci Resolve supports only amd64 (x86_64)."
        exit 1
        ;;
esac