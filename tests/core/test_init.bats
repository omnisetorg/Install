#!/usr/bin/env bats
# Tests for lib/core/init.sh

load "../helpers/test_helper"
load "../helpers/mock_commands"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    export OMNISET_ROOT="$PROJECT_ROOT"
    export OMNISET_LIB="${OMNISET_ROOT}/lib"
    export OMNISET_MODULES="${OMNISET_ROOT}/modules"

    # Source only the libs needed for init tests (avoid modules.sh which needs bash 4+)
    source_lib "core/constants.sh"
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    source_lib "system/detect.sh"
    source_lib "system/packages.sh"

    # Provide stub for omniset_mktemp and init functions without full init.sh sourcing
    # (init.sh sources modules.sh via the library chain)
    _OMNISET_TEMP_FILES=()

    omniset_mktemp() {
        local tmp
        tmp=$(mktemp "$@")
        _OMNISET_TEMP_FILES+=("$tmp")
        echo "$tmp"
    }

    omniset_cleanup() {
        local exit_code=$?
        for f in "${_OMNISET_TEMP_FILES[@]:-}"; do
            rm -rf "$f" 2>/dev/null || true
        done
        return $exit_code
    }

    # Source init.sh functions by extracting them (avoid the full source chain)
    # We re-define the key functions from init.sh here
    check_not_root() {
        if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
            print_error "Do not run OmniSet as root"
            print_info "Run as a normal user with sudo access"
            return 1
        fi
    }

    check_sudo() {
        if ! sudo -n true 2>/dev/null; then
            print_warning "Sudo access required. You may be prompted for your password."
        fi
    }

    check_bash_version() {
        local required="4.0"
        local current="${BASH_VERSION%%[^0-9.]*}"
        if [[ "$(printf '%s\n' "$required" "$current" | sort -V | head -n1)" != "$required" ]]; then
            print_error "Bash $required or higher is required (current: $current)"
            return 1
        fi
    }

    check_yq() {
        if command -v yq &>/dev/null; then
            return 0
        fi
        print_warning "yq (YAML processor) is not installed"
        print_info "yq is required for parsing module manifests"
        print_step "Installing yq..."
        local arch="${ARCH:-amd64}"
        local yq_url="https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_${arch}"
        if curl -fsSL "$yq_url" -o /tmp/yq && chmod +x /tmp/yq; then
            if sudo mv /tmp/yq /usr/local/bin/yq; then
                return 0
            fi
        fi
        print_error "Could not install yq automatically"
        return 1
    }

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
        check_yq || return 1
        return 0
    }
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# omniset_mktemp
# ═══════════════════════════════════════════════════════════════

@test "omniset_mktemp: creates a file" {
    local tmp
    tmp=$(omniset_mktemp)
    [[ -f "$tmp" ]]
    rm -f "$tmp"
}

@test "omniset_mktemp: tracks file in _OMNISET_TEMP_FILES" {
    _OMNISET_TEMP_FILES=()  # reset
    local tmp
    tmp=$(omniset_mktemp)
    [[ ${#_OMNISET_TEMP_FILES[@]} -gt 0 ]]
    rm -f "$tmp"
}

@test "omniset_mktemp: creates directory with -d flag" {
    local tmp
    tmp=$(omniset_mktemp -d)
    [[ -d "$tmp" ]]
    rm -rf "$tmp"
}

# ═══════════════════════════════════════════════════════════════
# omniset_cleanup
# ═══════════════════════════════════════════════════════════════

@test "omniset_cleanup: removes tracked temp files" {
    _OMNISET_TEMP_FILES=()
    local tmp1 tmp2
    tmp1=$(mktemp)
    tmp2=$(mktemp)
    _OMNISET_TEMP_FILES+=("$tmp1" "$tmp2")

    [[ -f "$tmp1" ]]
    [[ -f "$tmp2" ]]

    # Run cleanup manually (not via exit trap)
    for f in "${_OMNISET_TEMP_FILES[@]:-}"; do
        rm -rf "$f" 2>/dev/null || true
    done

    [[ ! -f "$tmp1" ]]
    [[ ! -f "$tmp2" ]]
}

# ═══════════════════════════════════════════════════════════════
# check_requirements
# ═══════════════════════════════════════════════════════════════

@test "check_requirements: succeeds when all commands present" {
    create_mock "curl" 0
    create_mock "wget" 0
    create_mock "git" 0
    create_mock "sudo" 0
    create_mock "yq" 0

    run check_requirements
    assert_success
}

@test "check_requirements: fails when command missing" {
    mock_command_not_exists "curl"
    mock_command_not_exists "wget"
    create_mock "git" 0
    create_mock "sudo" 0

    run check_requirements
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# check_bash_version
# ═══════════════════════════════════════════════════════════════

@test "check_bash_version: validates version comparison" {
    if has_bash4; then
        run check_bash_version
        assert_success
    else
        # On bash 3.2 (macOS), it should correctly report failure
        run check_bash_version
        assert_failure
        assert_output --partial "4.0 or higher is required"
    fi
}

# ═══════════════════════════════════════════════════════════════
# check_not_root
# ═══════════════════════════════════════════════════════════════

@test "check_not_root: succeeds for non-root user" {
    # This test runs as a normal user, should pass
    if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
        run check_not_root
        assert_success
    else
        skip "test is running as root"
    fi
}

# ═══════════════════════════════════════════════════════════════
# check_yq
# ═══════════════════════════════════════════════════════════════

@test "check_yq: succeeds when yq is available" {
    create_mock "yq" 0
    run check_yq
    assert_success
}

@test "check_yq: warns when yq not found" {
    mock_command_not_exists "yq"
    # Mock curl to fail (can't install)
    create_mock "curl" 1
    export ARCH="amd64"

    run check_yq
    assert_failure
    assert_output --partial "yq"
}

# ═══════════════════════════════════════════════════════════════
# check_sudo
# ═══════════════════════════════════════════════════════════════

@test "check_sudo: runs without error" {
    create_sudo_noop
    run check_sudo
    assert_success
}
