#!/usr/bin/env bats
# Tests for lib/install/state.sh

load "../helpers/test_helper"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    # Set state dir BEFORE sourcing constants (which declares it readonly)
    export OMNISET_DATA_DIR="${TEST_TEMP_DIR}/data"
    export OMNISET_STATE_DIR="${TEST_TEMP_DIR}/data/installed"
    export ARCH="amd64"

    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"

    # Provide validate_module_id (normally from modules.sh)
    validate_module_id() {
        local id="$1"
        [[ "$id" =~ ^[a-zA-Z0-9_-]+$ ]] || return 1
    }

    source_lib "install/state.sh"
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# state_init
# ═══════════════════════════════════════════════════════════════

@test "state_init: creates state directory" {
    [[ ! -d "$OMNISET_STATE_DIR" ]]
    state_init
    [[ -d "$OMNISET_STATE_DIR" ]]
}

@test "state_init: idempotent when dir exists" {
    mkdir -p "$OMNISET_STATE_DIR"
    run state_init
    assert_success
    [[ -d "$OMNISET_STATE_DIR" ]]
}

# ═══════════════════════════════════════════════════════════════
# state_record_install
# ═══════════════════════════════════════════════════════════════

@test "state_record_install: creates state file with correct fields" {
    state_init
    state_record_install "docker" "development" "Docker" "script"

    local state_file="${OMNISET_STATE_DIR}/docker"
    [[ -f "$state_file" ]]

    run grep '^MODULE_ID="docker"$' "$state_file"
    assert_success

    run grep '^CATEGORY="development"$' "$state_file"
    assert_success

    run grep '^DISPLAY_NAME="Docker"$' "$state_file"
    assert_success

    run grep '^INSTALL_METHOD="script"$' "$state_file"
    assert_success

    run grep '^ARCH="amd64"$' "$state_file"
    assert_success

    run grep '^INSTALLED_AT=' "$state_file"
    assert_success
}

@test "state_record_install: uses defaults for optional params" {
    state_init
    state_record_install "test-mod"

    local state_file="${OMNISET_STATE_DIR}/test-mod"
    [[ -f "$state_file" ]]

    run grep '^CATEGORY="unknown"$' "$state_file"
    assert_success

    run grep '^INSTALL_METHOD="script"$' "$state_file"
    assert_success
}

@test "state_record_install: rejects invalid module ID" {
    state_init
    run state_record_install "../etc/passwd" "dev" "Bad" "apt"
    assert_failure
}

@test "state_record_install: overwrites existing state file" {
    state_init
    state_record_install "docker" "development" "Docker" "apt"
    state_record_install "docker" "development" "Docker" "snap"

    run grep '^INSTALL_METHOD="snap"$' "${OMNISET_STATE_DIR}/docker"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# state_record_uninstall
# ═══════════════════════════════════════════════════════════════

@test "state_record_uninstall: removes state file" {
    state_init
    state_record_install "docker" "development" "Docker" "script"
    [[ -f "${OMNISET_STATE_DIR}/docker" ]]

    state_record_uninstall "docker"
    [[ ! -f "${OMNISET_STATE_DIR}/docker" ]]
}

@test "state_record_uninstall: succeeds when file does not exist" {
    state_init
    run state_record_uninstall "nonexistent"
    assert_success
}

@test "state_record_uninstall: rejects invalid module ID" {
    state_init
    run state_record_uninstall "../etc/passwd"
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# state_is_installed
# ═══════════════════════════════════════════════════════════════

@test "state_is_installed: returns 0 for recorded module" {
    state_init
    state_record_install "docker" "development" "Docker" "script"

    run state_is_installed "docker"
    assert_success
}

@test "state_is_installed: returns 1 for unrecorded module" {
    state_init

    run state_is_installed "nonexistent"
    assert_failure
}

@test "state_is_installed: returns 1 after uninstall" {
    state_init
    state_record_install "docker" "development" "Docker" "script"
    state_record_uninstall "docker"

    run state_is_installed "docker"
    assert_failure
}

@test "state_is_installed: rejects invalid module ID" {
    state_init
    run state_is_installed "../etc/passwd"
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# state_list_installed
# ═══════════════════════════════════════════════════════════════

@test "state_list_installed: returns all recorded modules" {
    state_init
    state_record_install "docker" "development" "Docker" "script"
    state_record_install "nodejs" "development" "Node.js" "apt"
    state_record_install "python" "development" "Python" "apt"

    run state_list_installed
    assert_success
    assert_output --partial "docker"
    assert_output --partial "nodejs"
    assert_output --partial "python"
}

@test "state_list_installed: returns empty when no modules installed" {
    state_init

    run state_list_installed
    assert_success
    assert_output ""
}

@test "state_list_installed: excludes uninstalled modules" {
    state_init
    state_record_install "docker" "development" "Docker" "script"
    state_record_install "nodejs" "development" "Node.js" "apt"
    state_record_uninstall "docker"

    run state_list_installed
    assert_success
    refute_output --partial "docker"
    assert_output --partial "nodejs"
}

# ═══════════════════════════════════════════════════════════════
# state_get_field
# ═══════════════════════════════════════════════════════════════

@test "state_get_field: returns correct value" {
    state_init
    state_record_install "docker" "development" "Docker" "apt"

    run state_get_field "docker" "CATEGORY"
    assert_success
    assert_output "development"

    run state_get_field "docker" "INSTALL_METHOD"
    assert_success
    assert_output "apt"

    run state_get_field "docker" "DISPLAY_NAME"
    assert_success
    assert_output "Docker"
}

@test "state_get_field: fails for nonexistent module" {
    state_init

    run state_get_field "nonexistent" "CATEGORY"
    assert_failure
}

@test "state_get_field: fails for nonexistent field" {
    state_init
    state_record_install "docker" "development" "Docker" "apt"

    run state_get_field "docker" "NONEXISTENT_FIELD"
    assert_failure
}

@test "state_get_field: rejects invalid module ID" {
    state_init
    run state_get_field "../etc/passwd" "CATEGORY"
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# State file integrity
# ═══════════════════════════════════════════════════════════════

@test "state files are shell-sourceable" {
    state_init
    state_record_install "docker" "development" "Docker" "script"

    # Sourcing the state file should not fail
    run bash -c "source '${OMNISET_STATE_DIR}/docker' && echo \"\$MODULE_ID\""
    assert_success
    assert_output "docker"
}

@test "state_record_install: sanitizes values with special characters" {
    state_init
    # Try to inject shell metacharacters in display_name
    state_record_install "test-mod" "development" 'Test $(whoami) Module' "apt"

    # The file should exist and be sourceable without executing injected commands
    local state_file="${OMNISET_STATE_DIR}/test-mod"
    [[ -f "$state_file" ]]

    # Verify the $ was stripped (making command substitution harmless)
    run grep '\\$' "$state_file"
    assert_failure
}

@test "module ID validation prevents path traversal in state operations" {
    state_init

    run state_record_install "../../etc/cron.d/evil" "dev" "Evil" "apt"
    assert_failure

    run state_is_installed "../../etc/cron.d/evil"
    assert_failure

    run state_get_field "../../etc/cron.d/evil" "CATEGORY"
    assert_failure
}
