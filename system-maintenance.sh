#!/bin/bash

# System Updates
function update_system() {
    sudo apt update
    sudo apt upgrade -y
    sudo apt autoremove -y
    sudo apt autoclean
}

# Disk Space Management
function check_disk_space() {
    echo "Disk Space Usage:"
    df -h /
    
    # Alert if disk usage is over 90%
    use=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$use" -gt 90 ]; then
        echo "WARNING: Disk usage is over 90%"
    fi
}

# Cache Cleanup
function clean_cache() {
    sudo rm -rf /var/cache/apt/archives/*.deb
    sudo rm -rf ~/.cache/thumbnails/*
}

# System Health Check
function check_system_health() {
    echo "Memory Usage:"
    free -h
    
    echo "CPU Load:"
    uptime
    
    echo "System Temperature:"
    if command -v sensors &> /dev/null; then
        sensors
    else
        echo "sensors command not found. Installing..."
        sudo apt install -y lm-sensors
        sensors
    fi
}

# Docker Cleanup (if installed)
function clean_docker() {
    if command -v docker &> /dev/null; then
        echo "Cleaning unused Docker resources..."
        docker system prune -af --volumes
    fi
}

# Log Rotation
function rotate_logs() {
    sudo journalctl --vacuum-time=7d
}

# Main menu
while true; do
    echo "
System Maintenance Menu:
1. Run System Updates
2. Check Disk Space
3. Clean System Cache
4. Check System Health
5. Clean Docker (if installed)
6. Rotate System Logs
7. Run All Maintenance Tasks
8. Exit
"
    read -p "Select an option (1-8): " choice
    
    case $choice in
        1) update_system ;;
        2) check_disk_space ;;
        3) clean_cache ;;
        4) check_system_health ;;
        5) clean_docker ;;
        6) rotate_logs ;;
        7)
            update_system
            check_disk_space
            clean_cache
            check_system_health
            clean_docker
            rotate_logs
            ;;
        8) exit 0 ;;
        *) echo "Invalid option" ;;
    esac
    
    read -p "Press enter to continue..."
done