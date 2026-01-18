#!/bin/bash
# OmniSet v2 - Global Constants
# lib/core/constants.sh

# Version
readonly OMNISET_VERSION="2.0.0"
readonly OMNISET_MIN_BASH_VERSION="4.0"

# Directories
readonly OMNISET_ROOT="${OMNISET_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
readonly OMNISET_LIB="${OMNISET_ROOT}/lib"
readonly OMNISET_MODULES="${OMNISET_ROOT}/modules"
readonly OMNISET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omniset"
readonly OMNISET_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/omniset"
readonly OMNISET_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/omniset"

# Remote
readonly OMNISET_REPO_URL="https://raw.githubusercontent.com/user/omniset/main"
readonly OMNISET_WEB_URL="https://omniset.io"
readonly OMNISET_API_URL="${OMNISET_WEB_URL}/api"

# Logging
readonly OMNISET_LOG_FILE="${OMNISET_DATA_DIR}/install.log"

# Installation
readonly OMNISET_TEMP_DIR="/tmp/omniset-$$"
readonly OMNISET_CHECKPOINT_DIR="${OMNISET_TEMP_DIR}/checkpoints"

# Module categories
readonly -a OMNISET_CATEGORIES=(
    "base"
    "desktop"
    "development"
    "cli"
    "creative"
    "gaming"
    "communication"
    "system"
)

# Supported architectures
readonly -a OMNISET_SUPPORTED_ARCH=(
    "amd64"
    "arm64"
    "armhf"
)

# Supported distro families
readonly -a OMNISET_SUPPORTED_DISTROS=(
    "debian"    # Ubuntu, Debian, Mint, Pop, Elementary
    "rhel"      # Fedora, CentOS, Rocky, Alma
    "arch"      # Arch, Manjaro, EndeavourOS
    "suse"      # openSUSE
)

# Exit codes
readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1
readonly EXIT_INVALID_ARGS=2
readonly EXIT_MISSING_DEPS=3
readonly EXIT_UNSUPPORTED_OS=4
readonly EXIT_UNSUPPORTED_ARCH=5
readonly EXIT_USER_CANCELLED=130
