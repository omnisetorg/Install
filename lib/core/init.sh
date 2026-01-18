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

    return 0
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
