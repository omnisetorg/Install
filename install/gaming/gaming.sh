#!/bin/bash

arch=$(dpkg --print-architecture)

AVAILABLE_APPS=(
    "Steam"
    "Lutris"
    "Wine"
    "GameMode"
    "MangoHud"
    "ProtonGE"
    "RetroArch"
    "PCSX2"
    "Dolphin"
    "OpenRazer"
)

apps=$(gum choose "${AVAILABLE_APPS[@]}" --no-limit --height 10 --header "Select gaming apps to install")

if [[ -n "$apps" ]]; then
    for app in $apps; do
        case $app in
        Steam)
            case $arch in
                amd64)
                    wget -O steam.deb "https://cdn.akamai.steamstatic.com/client/installer/steam.deb"
                    sudo dpkg -i steam.deb
                    sudo apt-get install -f -y
                    rm steam.deb
                    ;;
                *)
                    echo "Steam not available for $arch"
                    continue
                    ;;
            esac
            ;;
        Lutris)
            sudo add-apt-repository -y ppa:lutris-team/lutris
            sudo apt update && sudo apt install -y lutris
            ;;
        Wine)
            sudo dpkg --add-architecture i386
            sudo mkdir -pm755 /etc/apt/keyrings
            sudo wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
            sudo wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources
            sudo apt update
            sudo apt install -y --install-recommends winehq-stable
            ;;
        GameMode)
            sudo apt install -y gamemode
            ;;
        MangoHud)
            sudo apt install -y mangohud
            ;;
        ProtonGE)
            mkdir -p ~/.steam/root/compatibilitytools.d/
            wget -O proton.tar.gz "https://github.com/GloriousEggroll/proton-ge-custom/releases/latest/download/GE-Proton7-55.tar.gz"
            tar -xzf proton.tar.gz -C ~/.steam/root/compatibilitytools.d/
            rm proton.tar.gz
            ;;
        RetroArch)
            sudo add-apt-repository -y ppa:libretro/stable
            sudo apt update && sudo apt install -y retroarch*
            ;;
        PCSX2)
            case $arch in
                amd64)
                    sudo add-apt-repository -y ppa:pcsx2-team/pcsx2-daily
                    sudo apt update && sudo apt install -y pcsx2
                    ;;
                *)
                    echo "PCSX2 not available for $arch"
                    continue
                    ;;
            esac
            ;;
        Dolphin)
            sudo add-apt-repository -y ppa:dolphin-emu/ppa
            sudo apt update && sudo apt install -y dolphin-emu
            ;;
        OpenRazer)
            sudo add-apt-repository -y ppa:openrazer/stable
            sudo apt update
            sudo apt install -y openrazer-meta
            ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully installed $app"
        else
            echo "✗ Failed to install $app"
        fi
    done
fi

# Gaming optimizations
echo "Would you like to apply gaming optimizations? (y/N)"
read -r apply_optimizations

if [[ "$apply_optimizations" =~ ^[Yy]$ ]]; then
    # CPU Governor
    sudo apt install -y cpupower-gui
    sudo systemctl enable cpupower
    
    # GPU optimizations
    if lspci | grep -i nvidia > /dev/null; then
        sudo apt install -y nvidia-settings
    fi
    
    # Install performance monitoring tools
    sudo apt install -y htop iotop
    
    # Configure CPU for performance
    sudo bash -c 'echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor'
    
    # Optimize memory management
    sudo bash -c 'echo "vm.swappiness=10" >> /etc/sysctl.conf'
    
    # Enable esync support
    sudo bash -c 'echo "$USER hard nofile 524288" >> /etc/security/limits.conf'
    
    # Optional: Install additional drivers
    ubuntu-drivers devices
    echo "Would you like to install recommended drivers? (y/N)"
    read -r install_drivers
    if [[ "$install_drivers" =~ ^[Yy]$ ]]; then
        sudo ubuntu-drivers autoinstall
    fi
fi