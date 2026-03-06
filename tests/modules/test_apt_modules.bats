#!/usr/bin/env bats
# Tests for simple apt module pattern (gimp)

load "../helpers/test_helper"
load "../helpers/mock_commands"

GIMP_INSTALL="${PROJECT_ROOT}/modules/creative/gimp/install.sh"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    create_sudo_passthrough
    create_mock "apt-get" 0
}

# ── Already-installed check ────────────────────────────────────

@test "gimp: skips when already installed" {
    create_mock "gimp" 0 "GNU Image Manipulation Program"

    run bash -c '
        export PATH="'"${MOCK_BIN}:${PATH}"'"
        source "'"$GIMP_INSTALL"'"
    '
    assert_success
    assert_output --partial "already installed"
}

@test "gimp: proceeds with install when not installed" {
    mock_command_not_exists gimp
    create_mock "add-apt-repository" 0

    run bash -c '
        export PATH="'"${MOCK_BIN}:${PATH}"'"
        source "'"$GIMP_INSTALL"'"
    '
    assert_success
    assert_output --partial "installed successfully"
}

# ── PPA fallback ───────────────────────────────────────────────

@test "gimp: tries PPA first for latest version" {
    mock_command_not_exists gimp
    create_mock "add-apt-repository" 0

    run bash -c '
        export PATH="'"${MOCK_BIN}:${PATH}"'"
        source "'"$GIMP_INSTALL"'"
    '
    assert_success
    assert_mock_called "add-apt-repository"
}

@test "gimp: falls back to standard apt when PPA fails" {
    mock_command_not_exists gimp
    create_mock "add-apt-repository" 1

    run bash -c '
        export PATH="'"${MOCK_BIN}:${PATH}"'"
        source "'"$GIMP_INSTALL"'"
    '
    assert_success
    assert_mock_called "apt-get"
    assert_output --partial "installed successfully"
}

# ── apt-get calls ──────────────────────────────────────────────

@test "gimp: calls apt-get install with gimp package" {
    mock_command_not_exists gimp
    create_mock "add-apt-repository" 0

    run bash -c '
        export PATH="'"${MOCK_BIN}:${PATH}"'"
        source "'"$GIMP_INSTALL"'"
    '
    assert_success
    assert_mock_called_with "apt-get" "install"
    assert_mock_called_with "apt-get" "gimp"
}

@test "gimp: calls apt-get update before install" {
    mock_command_not_exists gimp
    create_mock "add-apt-repository" 0

    run bash -c '
        export PATH="'"${MOCK_BIN}:${PATH}"'"
        source "'"$GIMP_INSTALL"'"
    '
    assert_success
    assert_mock_called_with "apt-get" "update"
}

# ── Script validity ────────────────────────────────────────────

@test "gimp: install.sh is valid bash" {
    run bash -n "$GIMP_INSTALL"
    assert_success
}

@test "gimp: has set -euo pipefail" {
    run grep "set -euo pipefail" "$GIMP_INSTALL"
    assert_success
}

@test "gimp: uses sudo for system package operations" {
    run grep "sudo" "$GIMP_INSTALL"
    assert_success
}
