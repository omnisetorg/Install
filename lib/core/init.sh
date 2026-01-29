#!/bin/bash
# OmniSet v2 - Initialization
# lib/core/init.sh
#
# This file bootstraps the OmniSet environment.
# Source this file to load all necessary libraries.

set -euo pipefail

# Determine OMNISET_ROOT if not set
if [[ -z "${OMNISET_ROOT:-}" ]]; then
    OMNISET_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi

export OMNISET_ROOT
export OMNISET_LIB="${OMNISET_ROOT}/lib"
export OMNISET_MODULES="${OMNISET_ROOT}/modules"

# ═══════════════════════════════════════════════════════════════
# Load Core Libraries
# ═══════════════════════════════════════════════════════════════

# Constants (must be first)
source "${OMNISET_LIB}/core/constants.sh"

# UI components
source "${OMNISET_LIB}/ui/colors.sh"
source "${OMNISET_LIB}/ui/print.sh"

# System detection
source "${OMNISET_LIB}/system/detect.sh"
source "${OMNISET_LIB}/system/packages.sh"

# Install system
source "${OMNISET_LIB}/install/modules.sh"

# ═══════════════════════════════════════════════════════════════
# Initialization Functions
# ═══════════════════════════════════════════════════════════════

# Full initialization
omniset_init() {
    # Initialize UI (colors, symbols, terminal size)
    init_ui

    # Detect system information
    detect_system

    # Detect package manager
    detect_package_manager

    # Check for required dependencies (including yq)
    check_requirements || {
        print_error "Missing required dependencies. Please install them and try again."
        exit 1
    }

    # Create necessary directories
    mkdir -p "${OMNISET_DATA_DIR}" "${OMNISET_CACHE_DIR}" "${OMNISET_CONFIG_DIR}"

    # Discover available modules
    discover_modules
}

# Quick initialization (skip expensive operations)
omniset_init_quick() {
    init_ui
    detect_distro
    detect_arch
    detect_package_manager
}

# Check if running as root
check_not_root() {
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        print_error "Do not run OmniSet as root"
        print_info "Run as a normal user with sudo access"
        exit 1
    fi
}

# Check sudo access
check_sudo() {
    if ! sudo -n true 2>/dev/null; then
        print_warning "Sudo access required. You may be prompted for your password."
    fi
}

# Check bash version
check_bash_version() {
    local required="4.0"
    local current="${BASH_VERSION%%[^0-9.]*}"

    if [[ "$(printf '%s\n' "$required" "$current" | sort -V | head -n1)" != "$required" ]]; then
        print_error "Bash $required or higher is required (current: $current)"
        exit 1
    fi
}

# Check for required commands
check_requirements() {
    local missing=()
    local required_cmds=("curl" "wget" "git" "sudo")

    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_warning "Missing required commands: ${missing[*]}"
        return 1
    fi

    # Check for yq (required for YAML parsing)
    check_yq || return 1

    return 0
}

# Check and install yq if missing
check_yq() {
    if command -v yq &>/dev/null; then
        return 0
    fi

    print_warning "yq (YAML processor) is not installed"
    print_info "yq is required for parsing module manifests"

    # Try to install yq
    print_step "Installing yq..."

    local arch="${ARCH:-amd64}"
    local yq_version="v4.40.5"
    local yq_binary="yq_linux_${arch}"
    local yq_url="https://github.com/mikefarah/yq/releases/download/${yq_version}/${yq_binary}"

    # Try to download and install yq
    if curl -fsSL "$yq_url" -o /tmp/yq && chmod +x /tmp/yq; then
        if sudo mv /tmp/yq /usr/local/bin/yq; then
            print_success "yq installed successfully"
            return 0
        fi
    fi

    # Fallback: try package managers
    case "${DISTRO_TYPE:-}" in
        debian)
            if sudo apt-get update && sudo apt-get install -y yq 2>/dev/null; then
                print_success "yq installed via apt"
                return 0
            fi
            ;;
        arch)
            if sudo pacman -S --noconfirm yq 2>/dev/null; then
                print_success "yq installed via pacman"
                return 0
            fi
            ;;
    esac

    # If snap is available
    if command -v snap &>/dev/null; then
        if sudo snap install yq 2>/dev/null; then
            print_success "yq installed via snap"
            return 0
        fi
    fi

    print_error "Could not install yq automatically"
    print_info "Please install yq manually:"
    print_bullet "Debian/Ubuntu: sudo apt install yq"
    print_bullet "Or: sudo snap install yq"
    print_bullet "Or: https://github.com/mikefarah/yq#install"
    return 1
}

# ═══════════════════════════════════════════════════════════════
# Cleanup
# ═══════════════════════════════════════════════════════════════

# Cleanup function for exit
omniset_cleanup() {
    local exit_code=$?

    # Remove temp directory if exists
    if [[ -d "${OMNISET_TEMP_DIR:-}" ]]; then
        rm -rf "${OMNISET_TEMP_DIR}"
    fi

    exit $exit_code
}

# Set up cleanup trap
trap omniset_cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Auto-init if sourced directly
# ═══════════════════════════════════════════════════════════════

# Only auto-init if this is the main script being run
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    omniset_init
fi
