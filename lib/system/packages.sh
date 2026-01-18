#!/bin/bash
# OmniSet v2 - Package Manager Abstraction
# lib/system/packages.sh

# Package manager variables (set by detect_package_manager)
export PKG_MANAGER=""
export PKG_INSTALL=""
export PKG_REMOVE=""
export PKG_UPDATE=""
export PKG_UPGRADE=""
export PKG_SEARCH=""
export PKG_INFO=""
export PKG_LIST_INSTALLED=""

# ═══════════════════════════════════════════════════════════════
# Package Manager Detection
# ═══════════════════════════════════════════════════════════════

detect_package_manager() {
    # Detect based on distro type if available
    case "${DISTRO_TYPE:-}" in
        debian)
            _setup_apt
            return
            ;;
        rhel)
            if command -v dnf &>/dev/null; then
                _setup_dnf
            else
                _setup_yum
            fi
            return
            ;;
        arch)
            _setup_pacman
            return
            ;;
        suse)
            _setup_zypper
            return
            ;;
        alpine)
            _setup_apk
            return
            ;;
    esac

    # Fallback: detect by available command
    if command -v apt-get &>/dev/null; then
        _setup_apt
    elif command -v dnf &>/dev/null; then
        _setup_dnf
    elif command -v yum &>/dev/null; then
        _setup_yum
    elif command -v pacman &>/dev/null; then
        _setup_pacman
    elif command -v zypper &>/dev/null; then
        _setup_zypper
    elif command -v apk &>/dev/null; then
        _setup_apk
    else
        print_error "No supported package manager found"
        return 1
    fi
}

# Package manager setup functions
_setup_apt() {
    PKG_MANAGER="apt"
    PKG_INSTALL="sudo apt-get install -y"
    PKG_REMOVE="sudo apt-get remove -y"
    PKG_PURGE="sudo apt-get purge -y"
    PKG_UPDATE="sudo apt-get update"
    PKG_UPGRADE="sudo apt-get upgrade -y"
    PKG_SEARCH="apt-cache search"
    PKG_INFO="apt-cache show"
    PKG_LIST_INSTALLED="dpkg -l"
    PKG_AUTOREMOVE="sudo apt-get autoremove -y"
    PKG_CLEAN="sudo apt-get autoclean"
}

_setup_dnf() {
    PKG_MANAGER="dnf"
    PKG_INSTALL="sudo dnf install -y"
    PKG_REMOVE="sudo dnf remove -y"
    PKG_PURGE="sudo dnf remove -y"
    PKG_UPDATE="sudo dnf check-update"
    PKG_UPGRADE="sudo dnf upgrade -y"
    PKG_SEARCH="dnf search"
    PKG_INFO="dnf info"
    PKG_LIST_INSTALLED="dnf list installed"
    PKG_AUTOREMOVE="sudo dnf autoremove -y"
    PKG_CLEAN="sudo dnf clean all"
}

_setup_yum() {
    PKG_MANAGER="yum"
    PKG_INSTALL="sudo yum install -y"
    PKG_REMOVE="sudo yum remove -y"
    PKG_PURGE="sudo yum remove -y"
    PKG_UPDATE="sudo yum check-update"
    PKG_UPGRADE="sudo yum upgrade -y"
    PKG_SEARCH="yum search"
    PKG_INFO="yum info"
    PKG_LIST_INSTALLED="yum list installed"
    PKG_AUTOREMOVE="sudo yum autoremove -y"
    PKG_CLEAN="sudo yum clean all"
}

_setup_pacman() {
    PKG_MANAGER="pacman"
    PKG_INSTALL="sudo pacman -S --noconfirm"
    PKG_REMOVE="sudo pacman -R --noconfirm"
    PKG_PURGE="sudo pacman -Rns --noconfirm"
    PKG_UPDATE="sudo pacman -Sy"
    PKG_UPGRADE="sudo pacman -Syu --noconfirm"
    PKG_SEARCH="pacman -Ss"
    PKG_INFO="pacman -Si"
    PKG_LIST_INSTALLED="pacman -Q"
    PKG_AUTOREMOVE="sudo pacman -Qdtq | sudo pacman -Rs --noconfirm - 2>/dev/null || true"
    PKG_CLEAN="sudo pacman -Sc --noconfirm"
}

_setup_zypper() {
    PKG_MANAGER="zypper"
    PKG_INSTALL="sudo zypper install -y"
    PKG_REMOVE="sudo zypper remove -y"
    PKG_PURGE="sudo zypper remove -y --clean-deps"
    PKG_UPDATE="sudo zypper refresh"
    PKG_UPGRADE="sudo zypper update -y"
    PKG_SEARCH="zypper search"
    PKG_INFO="zypper info"
    PKG_LIST_INSTALLED="zypper packages --installed"
    PKG_AUTOREMOVE="sudo zypper remove -y --clean-deps \$(zypper packages --unneeded | tail -n +5 | awk '{print \$3}') 2>/dev/null || true"
    PKG_CLEAN="sudo zypper clean"
}

_setup_apk() {
    PKG_MANAGER="apk"
    PKG_INSTALL="sudo apk add"
    PKG_REMOVE="sudo apk del"
    PKG_PURGE="sudo apk del --purge"
    PKG_UPDATE="sudo apk update"
    PKG_UPGRADE="sudo apk upgrade"
    PKG_SEARCH="apk search"
    PKG_INFO="apk info"
    PKG_LIST_INSTALLED="apk list --installed"
    PKG_AUTOREMOVE="sudo apk cache clean"
    PKG_CLEAN="sudo apk cache clean"
}

# ═══════════════════════════════════════════════════════════════
# Universal Package Operations
# ═══════════════════════════════════════════════════════════════

# Install packages
pkg_install() {
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        print_warning "No packages specified for installation"
        return 0
    fi

    print_step "Installing packages: ${packages[*]}"
    $PKG_INSTALL "${packages[@]}"
}

# Remove packages
pkg_remove() {
    local packages=("$@")

    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi

    print_step "Removing packages: ${packages[*]}"
    $PKG_REMOVE "${packages[@]}"
}

# Update package lists
pkg_update() {
    print_step "Updating package lists..."
    $PKG_UPDATE
}

# Upgrade all packages
pkg_upgrade() {
    print_step "Upgrading packages..."
    $PKG_UPGRADE
}

# Check if package is installed
pkg_is_installed() {
    local package="$1"

    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$package" 2>/dev/null | grep -q "^ii"
            ;;
        dnf|yum)
            rpm -q "$package" &>/dev/null
            ;;
        pacman)
            pacman -Q "$package" &>/dev/null
            ;;
        zypper)
            rpm -q "$package" &>/dev/null
            ;;
        apk)
            apk info -e "$package" &>/dev/null
            ;;
        *)
            return 1
            ;;
    esac
}

# Install from .deb file
install_deb() {
    local deb_path="$1"

    case "$PKG_MANAGER" in
        apt)
            sudo dpkg -i "$deb_path" || sudo apt-get install -f -y
            ;;
        dnf|yum)
            # Convert using alien if available
            if command -v alien &>/dev/null; then
                local rpm_path="${deb_path%.deb}.rpm"
                sudo alien -r "$deb_path" -o "$rpm_path"
                sudo $PKG_MANAGER install -y "$rpm_path"
                rm -f "$rpm_path"
            else
                print_error "Cannot install .deb on $PKG_MANAGER without 'alien'"
                return 1
            fi
            ;;
        *)
            print_error "Cannot install .deb on $PKG_MANAGER"
            return 1
            ;;
    esac
}

# Install from .rpm file
install_rpm() {
    local rpm_path="$1"

    case "$PKG_MANAGER" in
        dnf)
            sudo dnf install -y "$rpm_path"
            ;;
        yum)
            sudo yum install -y "$rpm_path"
            ;;
        zypper)
            sudo zypper install -y "$rpm_path"
            ;;
        apt)
            if command -v alien &>/dev/null; then
                local deb_path="${rpm_path%.rpm}.deb"
                sudo alien -d "$rpm_path" -o "$deb_path"
                sudo dpkg -i "$deb_path" || sudo apt-get install -f -y
                rm -f "$deb_path"
            else
                print_error "Cannot install .rpm on apt without 'alien'"
                return 1
            fi
            ;;
        *)
            print_error "Cannot install .rpm on $PKG_MANAGER"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════
# Repository Management
# ═══════════════════════════════════════════════════════════════

# Add APT repository
add_apt_repo() {
    local repo="$1"
    local key_url="${2:-}"
    local key_name="${3:-}"

    if [[ "$PKG_MANAGER" != "apt" ]]; then
        print_warning "add_apt_repo only works on Debian-based systems"
        return 1
    fi

    # Ensure prerequisites
    pkg_install software-properties-common apt-transport-https ca-certificates gnupg

    # Add GPG key if provided
    if [[ -n "$key_url" ]]; then
        local key_dir="/usr/share/keyrings"
        local key_file="${key_dir}/${key_name:-custom}.gpg"

        if [[ "$key_url" == *.asc ]] || [[ "$key_url" == *"gpg"* ]]; then
            curl -fsSL "$key_url" | sudo gpg --dearmor -o "$key_file"
        else
            curl -fsSL "$key_url" | sudo tee "$key_file" > /dev/null
        fi
    fi

    # Add repository
    echo "$repo" | sudo tee /etc/apt/sources.list.d/"${key_name:-custom}".list > /dev/null
    pkg_update
}

# ═══════════════════════════════════════════════════════════════
# Alternative Package Managers
# ═══════════════════════════════════════════════════════════════

# Install via Flatpak
install_flatpak() {
    local app_id="$1"
    local remote="${2:-flathub}"

    if ! command -v flatpak &>/dev/null; then
        print_info "Installing Flatpak..."
        pkg_install flatpak
    fi

    # Add Flathub if not present
    if [[ "$remote" == "flathub" ]]; then
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
    fi

    print_step "Installing $app_id via Flatpak..."
    flatpak install -y "$remote" "$app_id"
}

# Install via Snap
install_snap() {
    local package="$1"
    local flags="${2:-}"

    if ! command -v snap &>/dev/null; then
        print_info "Installing Snapd..."
        pkg_install snapd
        sudo systemctl enable --now snapd.socket 2>/dev/null || true
    fi

    print_step "Installing $package via Snap..."
    if [[ -n "$flags" ]]; then
        sudo snap install $flags "$package"
    else
        sudo snap install "$package"
    fi
}

# Install via Cargo (Rust)
install_cargo() {
    local package="$1"

    if ! command -v cargo &>/dev/null; then
        print_info "Installing Rust toolchain..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    print_step "Installing $package via Cargo..."
    cargo install "$package"
}

# Install via npm
install_npm_global() {
    local package="$1"

    if ! command -v npm &>/dev/null; then
        print_error "npm is not installed"
        return 1
    fi

    print_step "Installing $package via npm..."
    sudo npm install -g "$package"
}

# Install via pip
install_pip() {
    local package="$1"
    local python="${2:-python3}"

    if ! command -v "$python" &>/dev/null; then
        print_error "$python is not installed"
        return 1
    fi

    print_step "Installing $package via pip..."
    "$python" -m pip install --user "$package"
}
