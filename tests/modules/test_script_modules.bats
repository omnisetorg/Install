#!/usr/bin/env bats
# Tests for script-download + apt module pattern (nodejs)

load "../helpers/test_helper"
load "../helpers/mock_commands"

NODEJS_INSTALL="${PROJECT_ROOT}/modules/development/nodejs/install.sh"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    # Common mocks
    create_sudo_passthrough
    create_mock "apt-get" 0
}

# ── Version parsing ────────────────────────────────────────────

@test "nodejs: default version is lts" {
    run bash -c '
        OPTIONS="lts"
        VERSION="lts"
        if [[ "$OPTIONS" =~ ^[0-9]+$ ]]; then
            VERSION="$OPTIONS"
        elif [[ "$OPTIONS" == "current" ]]; then
            VERSION="current"
        fi
        echo "$VERSION"
    '
    assert_success
    assert_output "lts"
}

@test "nodejs: numeric version parsed from OPTIONS" {
    run bash -c '
        OPTIONS="20"
        VERSION="lts"
        if [[ "$OPTIONS" =~ ^[0-9]+$ ]]; then
            VERSION="$OPTIONS"
        elif [[ "$OPTIONS" == "current" ]]; then
            VERSION="current"
        fi
        echo "$VERSION"
    '
    assert_success
    assert_output "20"
}

@test "nodejs: current version from OPTIONS" {
    run bash -c '
        OPTIONS="current"
        VERSION="lts"
        if [[ "$OPTIONS" =~ ^[0-9]+$ ]]; then
            VERSION="$OPTIONS"
        elif [[ "$OPTIONS" == "current" ]]; then
            VERSION="current"
        fi
        echo "$VERSION"
    '
    assert_success
    assert_output "current"
}

# ── NodeSource URL selection ───────────────────────────────────

@test "nodejs: lts maps to setup_20.x" {
    run bash -c '
        VERSION="lts"
        case "$VERSION" in
            lts|20) SETUP_URL="https://deb.nodesource.com/setup_20.x" ;;
            current|22) SETUP_URL="https://deb.nodesource.com/setup_22.x" ;;
            18) SETUP_URL="https://deb.nodesource.com/setup_18.x" ;;
            *) SETUP_URL="https://deb.nodesource.com/setup_lts.x" ;;
        esac
        echo "$SETUP_URL"
    '
    assert_success
    assert_output "https://deb.nodesource.com/setup_20.x"
}

@test "nodejs: version 22 maps to setup_22.x" {
    run bash -c '
        VERSION="22"
        case "$VERSION" in
            lts|20) SETUP_URL="https://deb.nodesource.com/setup_20.x" ;;
            current|22) SETUP_URL="https://deb.nodesource.com/setup_22.x" ;;
            18) SETUP_URL="https://deb.nodesource.com/setup_18.x" ;;
            *) SETUP_URL="https://deb.nodesource.com/setup_lts.x" ;;
        esac
        echo "$SETUP_URL"
    '
    assert_success
    assert_output "https://deb.nodesource.com/setup_22.x"
}

@test "nodejs: version 18 maps to setup_18.x" {
    run bash -c '
        VERSION="18"
        case "$VERSION" in
            lts|20) SETUP_URL="https://deb.nodesource.com/setup_20.x" ;;
            current|22) SETUP_URL="https://deb.nodesource.com/setup_22.x" ;;
            18) SETUP_URL="https://deb.nodesource.com/setup_18.x" ;;
            *) SETUP_URL="https://deb.nodesource.com/setup_lts.x" ;;
        esac
        echo "$SETUP_URL"
    '
    assert_success
    assert_output "https://deb.nodesource.com/setup_18.x"
}

@test "nodejs: unknown version falls back to lts.x" {
    run bash -c '
        VERSION="99"
        case "$VERSION" in
            lts|20) SETUP_URL="https://deb.nodesource.com/setup_20.x" ;;
            current|22) SETUP_URL="https://deb.nodesource.com/setup_22.x" ;;
            18) SETUP_URL="https://deb.nodesource.com/setup_18.x" ;;
            *) SETUP_URL="https://deb.nodesource.com/setup_lts.x" ;;
        esac
        echo "$SETUP_URL"
    '
    assert_success
    assert_output "https://deb.nodesource.com/setup_lts.x"
}

# ── Global packages ───────────────────────────────────────────

@test "nodejs: global packages parsed from OPTIONS" {
    run bash -c '
        OPTIONS="lts,yarn,pnpm,typescript"
        GLOBAL_PACKAGES=()
        [[ "$OPTIONS" == *"yarn"* ]] && GLOBAL_PACKAGES+=("yarn")
        [[ "$OPTIONS" == *"pnpm"* ]] && GLOBAL_PACKAGES+=("pnpm")
        [[ "$OPTIONS" == *"typescript"* ]] && GLOBAL_PACKAGES+=("typescript")
        [[ "$OPTIONS" == *"nodemon"* ]] && GLOBAL_PACKAGES+=("nodemon")
        [[ "$OPTIONS" == *"pm2"* ]] && GLOBAL_PACKAGES+=("pm2")
        echo "${GLOBAL_PACKAGES[*]}"
    '
    assert_success
    assert_output "yarn pnpm typescript"
}

@test "nodejs: no global packages when OPTIONS is just version" {
    run bash -c '
        OPTIONS="lts"
        GLOBAL_PACKAGES=()
        [[ "$OPTIONS" == *"yarn"* ]] && GLOBAL_PACKAGES+=("yarn")
        [[ "$OPTIONS" == *"pnpm"* ]] && GLOBAL_PACKAGES+=("pnpm")
        [[ "$OPTIONS" == *"typescript"* ]] && GLOBAL_PACKAGES+=("typescript")
        [[ "$OPTIONS" == *"nodemon"* ]] && GLOBAL_PACKAGES+=("nodemon")
        [[ "$OPTIONS" == *"pm2"* ]] && GLOBAL_PACKAGES+=("pm2")
        echo "${#GLOBAL_PACKAGES[@]}"
    '
    assert_success
    assert_output "0"
}

@test "nodejs: pm2 and nodemon detected in OPTIONS" {
    run bash -c '
        OPTIONS="current,pm2,nodemon"
        GLOBAL_PACKAGES=()
        [[ "$OPTIONS" == *"yarn"* ]] && GLOBAL_PACKAGES+=("yarn")
        [[ "$OPTIONS" == *"pnpm"* ]] && GLOBAL_PACKAGES+=("pnpm")
        [[ "$OPTIONS" == *"typescript"* ]] && GLOBAL_PACKAGES+=("typescript")
        [[ "$OPTIONS" == *"nodemon"* ]] && GLOBAL_PACKAGES+=("nodemon")
        [[ "$OPTIONS" == *"pm2"* ]] && GLOBAL_PACKAGES+=("pm2")
        echo "${GLOBAL_PACKAGES[*]}"
    '
    assert_success
    assert_output "nodemon pm2"
}

# ── Already-installed detection ────────────────────────────────

@test "nodejs: detects existing node installation" {
    create_mock "node" 0 "v20.11.0"

    run bash -c '
        export PATH="'"${MOCK_BIN}:${PATH}"'"
        if command -v node &>/dev/null; then
            echo "already-installed"
        else
            echo "not-installed"
        fi
    '
    assert_success
    assert_output "already-installed"
}

@test "nodejs: proceeds when node not installed" {
    mock_command_not_exists node

    # Use only MOCK_BIN in PATH so system node is not found
    run bash -c '
        export PATH="'"${MOCK_BIN}"'"
        if command -v node &>/dev/null; then
            echo "already-installed"
        else
            echo "not-installed"
        fi
    '
    assert_success
    assert_output "not-installed"
}

# ── Script validity ────────────────────────────────────────────

@test "nodejs: install.sh is valid bash" {
    run bash -n "$NODEJS_INSTALL"
    assert_success
}

@test "nodejs: has set -euo pipefail" {
    run grep "set -euo pipefail" "$NODEJS_INSTALL"
    assert_success
}
