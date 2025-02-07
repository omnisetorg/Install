#!/bin/bash

arch=$(dpkg --print-architecture)

AVAILABLE_APPS=(
    "GIMP"
    "Inkscape"
    "Blender"
    "Kdenlive"
    "Krita"
    "Audacity"
    "OBS"
    "Darktable"
    "Shotcut"
    "FontManager"
)

apps=$(gum choose "${AVAILABLE_APPS[@]}" --no-limit --height 10 --header "Select creative apps to install")

if [[ -n "$apps" ]]; then
    for app in $apps; do
        case $app in
        GIMP)
            sudo add-apt-repository -y ppa:ubuntuhandbook1/gimp
            sudo apt update && sudo apt install -y gimp
            ;;
        Inkscape)
            sudo add-apt-repository -y ppa:inkscape.dev/stable
            sudo apt update && sudo apt install -y inkscape
            ;;
        Blender)
            case $arch in
                amd64|arm64)
                    sudo add-apt-repository -y ppa:savoury1/blender
                    sudo apt update && sudo apt install -y blender
                    ;;
                *)
                    echo "Blender not available for $arch"
                    continue
                    ;;
            esac
            ;;
        Kdenlive)
            sudo add-apt-repository -y ppa:kdenlive/kdenlive-stable
            sudo apt update && sudo apt install -y kdenlive
            ;;
        Krita)
            sudo add-apt-repository -y ppa:kritalime/ppa
            sudo apt update && sudo apt install -y krita
            ;;
        Audacity)
            sudo apt install -y audacity
            ;;
        OBS)
            case $arch in
                amd64|arm64)
                    sudo add-apt-repository -y ppa:obsproject/obs-studio
                    sudo apt update && sudo apt install -y obs-studio
                    ;;
                *)
                    echo "OBS not available for $arch"
                    continue
                    ;;
            esac
            ;;
        Darktable)
            sudo add-apt-repository -y ppa:pmjdebruijn/darktable-release
            sudo apt update && sudo apt install -y darktable
            ;;
        Shotcut)
            case $arch in
                amd64)
                    wget -O shotcut.deb "https://github.com/mltframework/shotcut/releases/download/v22.12/shotcut-linux-x86_64-221201.deb"
                    sudo dpkg -i shotcut.deb
                    sudo apt-get install -f -y
                    rm shotcut.deb
                    ;;
                *)
                    echo "Shotcut not available for $arch"
                    continue
                    ;;
            esac
            ;;
        FontManager)
            sudo apt install -y font-manager
            ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully installed $app"
        else
            echo "✗ Failed to install $app"
        fi
    done
fi

# Install common dependencies and assets
echo "Would you like to install additional creative assets? (y/N)"
read -r install_assets

if [[ "$install_assets" =~ ^[Yy]$ ]]; then
    # Common fonts
    sudo apt install -y \
        fonts-liberation \
        fonts-noto \
        fonts-roboto
        
    # Color management
    sudo apt install -y \
        argyll \
        colorhug-client
        
    # Asset management
    sudo apt install -y \
        rapid-photo-downloader \
        digikam
fi