#!/bin/bash
# OmniSet v2 - Uninstall Helper Functions
# lib/install/uninstall.sh

# ═══════════════════════════════════════════════════════════════
# Package Removal Functions
# ═══════════════════════════════════════════════════════════════

# Remove package via all package managers
remove_package() {
    local package="$1"

    # APT (Debian/Ubuntu)
    if command -v apt-get &>/dev/null; then
        sudo apt-get remove -y "$package" 2>/dev/null || true
    fi

    # DNF (Fedora)
    if command -v dnf &>/dev/null; then
        sudo dnf remove -y "$package" 2>/dev/null || true
    fi

    # YUM (RHEL/CentOS)
    if command -v yum &>/dev/null && ! command -v dnf &>/dev/null; then
        sudo yum remove -y "$package" 2>/dev/null || true
    fi

    # Pacman (Arch)
    if command -v pacman &>/dev/null; then
        sudo pacman -Rs --noconfirm "$package" 2>/dev/null || true
    fi

    # Zypper (openSUSE)
    if command -v zypper &>/dev/null; then
        sudo zypper remove -y "$package" 2>/dev/null || true
    fi

    # APK (Alpine)
    if command -v apk &>/dev/null; then
        sudo apk del "$package" 2>/dev/null || true
    fi
}

# Remove Flatpak application
remove_flatpak() {
    local app_id="$1"

    if command -v flatpak &>/dev/null; then
        flatpak uninstall -y "$app_id" 2>/dev/null || true
    fi
}

# Remove Snap package
remove_snap() {
    local package="$1"

    if command -v snap &>/dev/null; then
        sudo snap remove "$package" 2>/dev/null || true
    fi
}

# Remove Docker container and image
remove_docker() {
    local container_name="$1"
    local image_name="${2:-}"

    if command -v docker &>/dev/null; then
        # Stop and remove container
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true

        # Remove image if specified
        if [[ -n "$image_name" ]]; then
            docker rmi "$image_name" 2>/dev/null || true
        fi

        # Remove wrapper script
        sudo rm -f "/usr/local/bin/${container_name}-docker" 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════════════════════════
# Cleanup Functions
# ═══════════════════════════════════════════════════════════════

# Clean orphaned packages
cleanup_orphans() {
    if command -v apt-get &>/dev/null; then
        sudo apt-get autoremove -y 2>/dev/null || true
        sudo apt-get autoclean 2>/dev/null || true
    fi

    if command -v dnf &>/dev/null; then
        sudo dnf autoremove -y 2>/dev/null || true
    fi

    if command -v pacman &>/dev/null; then
        sudo pacman -Qdtq | sudo pacman -Rs --noconfirm - 2>/dev/null || true
    fi
}

# Remove user config directories
remove_config_dirs() {
    local app_name="$1"
    shift
    local extra_dirs=("$@")

    local dirs=(
        "$HOME/.config/$app_name"
        "$HOME/.local/share/$app_name"
        "$HOME/.cache/$app_name"
        "$HOME/.$app_name"
    )

    # Add extra directories
    for dir in "${extra_dirs[@]}"; do
        dirs+=("$dir")
    done

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            print_info "Removed: $dir"
        fi
    done
}

# Remove APT repository
remove_apt_repo() {
    local repo_name="$1"

    sudo rm -f "/etc/apt/sources.list.d/${repo_name}.list" 2>/dev/null || true
    sudo rm -f "/etc/apt/sources.list.d/${repo_name}.sources" 2>/dev/null || true
    sudo rm -f "/usr/share/keyrings/${repo_name}.gpg" 2>/dev/null || true
    sudo rm -f "/etc/apt/keyrings/${repo_name}.gpg" 2>/dev/null || true
}

# Remove systemd service
remove_service() {
    local service_name="$1"
    local user_service="${2:-false}"

    if [[ "$user_service" == "true" ]]; then
        systemctl --user stop "$service_name" 2>/dev/null || true
        systemctl --user disable "$service_name" 2>/dev/null || true
    else
        sudo systemctl stop "$service_name" 2>/dev/null || true
        sudo systemctl disable "$service_name" 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════════════════════════
# Complete Uninstall Helper
# ═══════════════════════════════════════════════════════════════

# Full uninstall with all options
full_uninstall() {
    local module_name="$1"
    local packages="$2"
    local flatpak_id="${3:-}"
    local snap_name="${4:-}"
    local docker_container="${5:-}"
    local remove_config="${6:-false}"

    print_step "Uninstalling $module_name..."

    # Remove packages
    for pkg in $packages; do
        remove_package "$pkg"
    done

    # Remove Flatpak
    if [[ -n "$flatpak_id" ]]; then
        remove_flatpak "$flatpak_id"
    fi

    # Remove Snap
    if [[ -n "$snap_name" ]]; then
        remove_snap "$snap_name"
    fi

    # Remove Docker container
    if [[ -n "$docker_container" ]]; then
        remove_docker "$docker_container"
    fi

    # Cleanup orphans
    cleanup_orphans

    # Remove config if requested
    if [[ "$remove_config" == "true" ]]; then
        remove_config_dirs "$module_name"
    fi

    print_success "$module_name uninstalled"
}
