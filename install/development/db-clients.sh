#!/bin/bash

arch=$(dpkg --print-architecture)

AVAILABLE_APPS=(
    "DBeaver"
    "pgAdmin4"
    "MySQL-Workbench"
    "MongoDB-Compass"
    "Redis-Desktop"
    "SQLite-Browser"
    "Beekeeper-Studio"
    "TablePlus"
)

apps=$(gum choose "${AVAILABLE_APPS[@]}" --no-limit --height 10 --header "Select database clients to install")

if [[ -n "$apps" ]]; then
    for app in $apps; do
        case $app in
        DBeaver)
            case $arch in
                amd64|arm64)
                    wget -O - https://dbeaver.io/debs/dbeaver.gpg.key | sudo apt-key add -
                    echo "deb https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list
                    sudo apt update && sudo apt install -y dbeaver-ce
                    ;;
                *)
                    echo "DBeaver not available for $arch"
                    continue
                    ;;
            esac
            ;;
        pgAdmin4)
            case $arch in
                amd64|arm64)
                    curl -fsS https://www.pgadmin.org/static/packages_pgadmin_org.pub | sudo gpg --dearmor -o /usr/share/keyrings/packages-pgadmin-org.gpg
                    sudo sh -c 'echo "deb [signed-by=/usr/share/keyrings/packages-pgadmin-org.gpg] https://ftp.postgresql.org/pub/pgadmin/pgadmin4/apt/$(lsb_release -cs) pgadmin4 main" > /etc/apt/sources.list.d/pgadmin4.list'
                    sudo apt update && sudo apt install -y pgadmin4-desktop
                    ;;
                *)
                    echo "pgAdmin4 not available for $arch"
                    continue
                    ;;
            esac
            ;;
        MySQL-Workbench)
            case $arch in
                amd64)
                    wget https://dev.mysql.com/get/mysql-apt-config_0.8.24-1_all.deb
                    sudo dpkg -i mysql-apt-config*
                    sudo apt update && sudo apt install -y mysql-workbench-community
                    rm mysql-apt-config*
                    ;;
                *)
                    echo "MySQL Workbench not available for $arch"
                    continue
                    ;;
            esac
            ;;
        MongoDB-Compass)
            case $arch in
                amd64)
                    wget https://downloads.mongodb.com/compass/mongodb-compass_1.40.4_amd64.deb
                    sudo dpkg -i mongodb-compass*.deb
                    sudo apt-get install -f -y
                    rm mongodb-compass*.deb
                    ;;
                *)
                    echo "MongoDB Compass not available for $arch"
                    continue
                    ;;
            esac
            ;;
        Redis-Desktop)
            case $arch in
                amd64)
                    wget https://github.com/RedisInsight/RedisInsight/releases/download/v2.30.0/RedisInsight-v2.30.0.deb
                    sudo dpkg -i RedisInsight*.deb
                    sudo apt-get install -f -y
                    rm RedisInsight*.deb
                    ;;
                *)
                    echo "Redis Desktop not available for $arch"
                    continue
                    ;;
            esac
            ;;
        SQLite-Browser)
            sudo apt install -y sqlitebrowser
            ;;
        Beekeeper-Studio)
            case $arch in
                amd64|arm64)
                    wget --quiet -O - https://deb.beekeeperstudio.io/beekeeper.key | sudo apt-key add -
                    echo "deb https://deb.beekeeperstudio.io stable main" | sudo tee /etc/apt/sources.list.d/beekeeper-studio-app.list
                    sudo apt update && sudo apt install -y beekeeper-studio
                    ;;
                *)
                    echo "Beekeeper Studio not available for $arch"
                    continue
                    ;;
            esac
            ;;
        TablePlus)
            case $arch in
                amd64)
                    wget -O - https://deb.tableplus.com/apt.tableplus.com.gpg.key | sudo apt-key add -
                    sudo add-apt-repository "deb [arch=amd64] https://deb.tableplus.com/debian/22 tableplus main"
                    sudo apt update && sudo apt install -y tableplus
                    ;;
                *)
                    echo "TablePlus not available for $arch"
                    continue
                    ;;
            esac
            ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo "✓ Successfully installed $app"
        else
            echo "✗ Failed to install $app"
        fi
    done
fi

# Install common database CLI tools
echo "Would you like to install CLI database tools? (y/N)"
read -r install_cli

if [[ "$install_cli" =~ ^[Yy]$ ]]; then
    sudo apt install -y \
        postgresql-client \
        mysql-client \
        redis-tools \
        mongodb-clients \
        sqlite3
fi