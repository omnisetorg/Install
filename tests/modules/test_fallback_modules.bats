#!/usr/bin/env bats
# Tests for multi-method fallback module pattern (ansible)

load "../helpers/test_helper"
load "../helpers/mock_commands"

ANSIBLE_INSTALL="${PROJECT_ROOT}/modules/devops/ansible/install.sh"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    export OMNISET_LIB="$PROJECT_ROOT/lib"
    export HOME="$TEST_TEMP_DIR"

    create_sudo_noop

    # Create a .bashrc for tests that check it
    touch "${HOME}/.bashrc"

    # Build isolated PATH with essential commands only
    SAFE_BIN="${TEST_TEMP_DIR}/safe_bin"
    mkdir -p "$SAFE_BIN"
    local essential_cmds=(bash cat grep sed awk tr head tail wc mkdir rm cp mv mktemp chmod sleep tput env sort cut dirname basename find)
    for cmd in "${essential_cmds[@]}"; do
        local real_path
        real_path=$(command -v "$cmd" 2>/dev/null) || true
        if [[ -n "$real_path" ]]; then
            ln -sf "$real_path" "${SAFE_BIN}/${cmd}"
        fi
    done
    export ISOLATED_PATH="${MOCK_BIN}:${SAFE_BIN}"
}

# Helper: run a function from ansible's install.sh in a subshell
# Sources the script with `main "$@"` stripped out, then calls the given function
run_ansible_fn() {
    local fn="$1"
    shift
    run bash -c '
        set -euo pipefail
        export PATH="'"${ISOLATED_PATH}"'"
        export MOCK_LOG_DIR="'"${MOCK_LOG_DIR}"'"
        export HOME="'"${TEST_TEMP_DIR}"'"
        export OMNISET_LIB="'"${PROJECT_ROOT}/lib"'"
        export HAS_COLORS=false TERM=dumb
        ARCH="amd64"
        OPTIONS=""

        # Source the script without running main
        eval "$(sed "/^main \"\\\$@\"/d" "'"$ANSIBLE_INSTALL"'")"

        '"$fn"' "$@"
    ' -- "$@"
}

# ── Already-installed detection ────────────────────────────────

@test "ansible: detects already installed ansible" {
    create_mock "ansible" 0 "ansible [core 2.16.0]"

    run_ansible_fn install_ansible
    assert_success
    assert_output --partial "already installed"
}

# ── Installation chain: pipx → pip → apt ──────────────────────

@test "ansible: prefers pipx when available" {
    mock_command_not_exists ansible
    create_mock "pipx" 0

    run_ansible_fn install_ansible
    assert_success
    assert_mock_called "pipx"
    assert_output --partial "pipx"
}

@test "ansible: falls back to pip3 when pipx missing" {
    mock_command_not_exists ansible
    mock_command_not_exists pipx
    create_mock "pip3" 0

    run_ansible_fn install_ansible
    assert_success
    assert_mock_called "pip3"
    assert_output --partial "pip"
}

@test "ansible: falls back to apt when pipx and pip3 missing" {
    mock_command_not_exists ansible
    mock_command_not_exists pipx
    mock_command_not_exists pip3
    create_mock "apt-get" 0
    create_sudo_passthrough

    run_ansible_fn install_ansible
    assert_success
    assert_mock_called "apt-get"
    assert_output --partial "apt"
}

# ── Config generation ─────────────────────────────────────────

@test "ansible: creates default ansible.cfg when missing" {
    [[ ! -f "${HOME}/.ansible.cfg" ]]

    run_ansible_fn configure_ansible
    assert_success

    assert_file_exists "${HOME}/.ansible.cfg"
    run grep "inventory" "${HOME}/.ansible.cfg"
    assert_success
}

@test "ansible: does not overwrite existing ansible.cfg" {
    echo "# custom config" > "${HOME}/.ansible.cfg"

    run_ansible_fn configure_ansible
    assert_success

    run cat "${HOME}/.ansible.cfg"
    assert_output --partial "# custom config"
}

@test "ansible: creates inventory file" {
    mkdir -p "${HOME}/.ansible"

    run_ansible_fn configure_ansible
    assert_success

    assert_file_exists "${HOME}/.ansible/hosts"
    run grep "localhost" "${HOME}/.ansible/hosts"
    assert_success
}

@test "ansible: does not overwrite existing inventory" {
    mkdir -p "${HOME}/.ansible"
    echo "# my hosts" > "${HOME}/.ansible/hosts"

    run_ansible_fn configure_ansible
    assert_success

    run cat "${HOME}/.ansible/hosts"
    assert_output "# my hosts"
}

# ── Dependencies ───────────────────────────────────────────────

@test "ansible: install_dependencies calls apt-get for python3 packages" {
    create_mock "apt-get" 0
    create_mock "pip3" 0
    create_mock "pipx" 0
    create_sudo_passthrough

    run_ansible_fn install_dependencies
    assert_success
    assert_mock_called_with "apt-get" "python3"
}

# ── Fallback print functions ──────────────────────────────────

@test "ansible: defines fallback print functions when OMNISET_LIB unavailable" {
    run bash -c '
        set -euo pipefail
        unset OMNISET_LIB
        ARCH="amd64"
        OPTIONS=""
        eval "$(sed "/^main \"\\\$@\"/d" "'"$ANSIBLE_INSTALL"'")"
        print_step "test message"
    '
    assert_success
    assert_output "==> test message"
}

@test "ansible: sources print.sh when OMNISET_LIB available" {
    run grep 'source.*print.sh' "$ANSIBLE_INSTALL"
    assert_success
}

# ── Script validity ────────────────────────────────────────────

@test "ansible: install.sh is valid bash" {
    run bash -n "$ANSIBLE_INSTALL"
    assert_success
}

@test "ansible: has set -euo pipefail" {
    run grep "set -euo pipefail" "$ANSIBLE_INSTALL"
    assert_success
}
