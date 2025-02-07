#!/bin/bash

# Get system architecture
arch=$(dpkg --print-architecture)

AVAILABLE_APPS=(
    "Discord"
    "Slack"
    "Telegram"
    "Signal"
    "Teams"
    "Zoom"
    "Skype"
    "Thunderbird"
    "RocketChat"
)

# Let user select apps
apps=$(gum choose "${AVAILABLE_APPS[@]}" --no-limit --height 10 --header "Select communication apps to install")

if [[ -n "$apps" ]]; then
    for app in $apps; do
        case $app in
        Discord)
            case $arch in
                amd64)
                    wget -O discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                    ;;
                arm64)
                    wget -O discord.deb "https://discord.com/api/download/arm?platform=linux&format=deb"
                    ;;
                *)
                    echo "Discord not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i discord.deb
            sudo apt-get install -f -y
            rm discord.deb
            ;;
        Slack)
            case $arch in
                amd64)
                    wget -O slack.deb "https://downloads.slack-edge.com/releases/linux/4.35.126/prod/x64/slack-desktop-4.35.126-amd64.deb"
                    ;;
                arm64)
                    wget -O slack.deb "https://downloads.slack-edge.com/releases/linux/4.35.126/prod/arm64/slack-desktop-4.35.126-arm64.deb"
                    ;;
                *)
                    echo "Slack not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i slack.deb
            sudo apt-get install -f -y
            rm slack.deb
            ;;
        Telegram)
            sudo add-apt-repository -y ppa:atareao/telegram
            sudo apt update && sudo apt install -y telegram
            ;;
        Signal)
            case $arch in
                amd64|arm64)
                    wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
                    echo "deb [arch=$arch signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main" | sudo tee /etc/apt/sources.list.d/signal.list
                    sudo apt update && sudo apt install -y signal-desktop
                    ;;
                *)
                    echo "Signal not available for $arch"
                    continue
                    ;;
            esac
            ;;
        Teams)
            case $arch in
                amd64)
                    wget -O teams.deb "https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.5.00.23861_amd64.deb"
                    ;;
                arm64)
                    wget -O teams.deb "https://packages.microsoft.com/repos/ms-teams/pool/main/t/teams/teams_1.5.00.23861_arm64.deb"
                    ;;
                *)
                    echo "Teams not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i teams.deb
            sudo apt-get install -f -y
            rm teams.deb
            ;;
        Zoom)
            case $arch in
                amd64)
                    wget https://zoom.us/client/latest/zoom_amd64.deb
                    ;;
                arm64)
                    wget https://zoom.us/client/latest/zoom_arm64.deb
                    ;;
                *)
                    echo "Zoom not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i zoom_*.deb
            sudo apt-get install -f -y
            rm zoom_*.deb
            ;;
        Skype)
            case $arch in
                amd64)
                    wget -O skype.deb "https://repo.skype.com/latest/skypeforlinux-64.deb"
                    ;;
                arm64)
                    wget -O skype.deb "https://repo.skype.com/latest/skypeforlinux-arm64.deb"
                    ;;
                *)
                    echo "Skype not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i skype.deb
            sudo apt-get install -f -y
            rm skype.deb
            ;;
        Thunderbird)
            sudo apt install -y thunderbird
            ;;
        RocketChat)
            case $arch in
                amd64)
                    wget -O rocketchat.deb "https://github.com/RocketChat/Rocket.Chat.Electron/releases/latest/download/rocketchat-desktop_amd64.deb"
                    ;;
                arm64)
                    wget -O rocketchat.deb "https://github.com/RocketChat/Rocket.Chat.Electron/releases/latest/download/rocketchat-desktop_arm64.deb"
                    ;;
                *)
                    echo "RocketChat not available for $arch"
                    continue
                    ;;
            esac
            sudo dpkg -i rocketchat.deb
            sudo apt-get install -f -y
            rm rocketchat.deb
            ;;
        *)
            echo "Unknown app: $app"
            ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully installed $app"
        else
            echo "✗ Failed to install $app"
        fi
    done
fi