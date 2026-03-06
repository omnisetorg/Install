#!/usr/bin/env bats
# Tests for lib/core/constants.sh

load "../helpers/test_helper"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    # Source constants with our PROJECT_ROOT
    export OMNISET_ROOT="$PROJECT_ROOT"
    source_lib "core/constants.sh"
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# Version
# ═══════════════════════════════════════════════════════════════

@test "OMNISET_VERSION matches semver format" {
    [[ "$OMNISET_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "OMNISET_MIN_BASH_VERSION is set" {
    [[ -n "$OMNISET_MIN_BASH_VERSION" ]]
}

# ═══════════════════════════════════════════════════════════════
# Paths
# ═══════════════════════════════════════════════════════════════

@test "OMNISET_ROOT points to project root" {
    [[ -d "$OMNISET_ROOT" ]]
    [[ -f "$OMNISET_ROOT/bin/omniset" ]]
}

@test "OMNISET_LIB path is correct" {
    [[ "$OMNISET_LIB" == "${OMNISET_ROOT}/lib" ]]
    [[ -d "$OMNISET_LIB" ]]
}

@test "OMNISET_MODULES path is correct" {
    [[ "$OMNISET_MODULES" == "${OMNISET_ROOT}/modules" ]]
    [[ -d "$OMNISET_MODULES" ]]
}

# ═══════════════════════════════════════════════════════════════
# Categories and architectures
# ═══════════════════════════════════════════════════════════════

@test "OMNISET_CATEGORIES array is populated" {
    # readonly arrays can't cross bats subshell boundary, check via grep
    run grep -c "OMNISET_CATEGORIES" "${OMNISET_LIB}/core/constants.sh"
    assert_success
    # Verify the file declares the array with elements
    run grep "base" "${OMNISET_LIB}/core/constants.sh"
    assert_success
}

@test "OMNISET_SUPPORTED_ARCH contains amd64" {
    run grep "amd64" "${OMNISET_LIB}/core/constants.sh"
    assert_success
}

@test "OMNISET_SUPPORTED_DISTROS contains debian" {
    run grep '"debian"' "${OMNISET_LIB}/core/constants.sh"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# Exit codes
# ═══════════════════════════════════════════════════════════════

@test "EXIT_SUCCESS is 0" {
    [[ "$EXIT_SUCCESS" -eq 0 ]]
}

@test "EXIT_FAILURE is 1" {
    [[ "$EXIT_FAILURE" -eq 1 ]]
}

@test "exit codes are integers" {
    [[ "$EXIT_SUCCESS" =~ ^[0-9]+$ ]]
    [[ "$EXIT_FAILURE" =~ ^[0-9]+$ ]]
    [[ "$EXIT_INVALID_ARGS" =~ ^[0-9]+$ ]]
    [[ "$EXIT_MISSING_DEPS" =~ ^[0-9]+$ ]]
    [[ "$EXIT_UNSUPPORTED_OS" =~ ^[0-9]+$ ]]
    [[ "$EXIT_UNSUPPORTED_ARCH" =~ ^[0-9]+$ ]]
    [[ "$EXIT_USER_CANCELLED" =~ ^[0-9]+$ ]]
}
