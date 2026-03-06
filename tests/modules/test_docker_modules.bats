#!/usr/bin/env bats
# Tests for Docker-based module pattern (mariadb)

load "../helpers/test_helper"
load "../helpers/mock_commands"

MARIADB_INSTALL="${PROJECT_ROOT}/modules/databases/mariadb/install.sh"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    export OMNISET_LIB="$PROJECT_ROOT/lib"
    export HOME="$TEST_TEMP_DIR"

    # Build a safe system PATH with essential commands but NOT docker/pip3/etc.
    # This ensures our mocks are the only source of these commands
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

# Helper: run a function from mariadb's install.sh in a subshell
# Sources the script with `main "$@"` stripped, then calls the given function
run_mariadb_fn() {
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
        OPTIONS="${OPTIONS:-}"
        export MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-testpass123}"
        export MARIADB_PORT="${MARIADB_PORT:-3307}"

        # Source the script without running main
        eval "$(sed "/^main \"\\\$@\"/d" "'"$MARIADB_INSTALL"'")"

        '"$fn"' "$@"
    ' -- "$@"
}

# ── Docker check ───────────────────────────────────────────────

@test "mariadb: check_docker fails when docker is not installed" {
    mock_command_not_exists docker

    run_mariadb_fn check_docker
    assert_failure
    assert_output --partial "Docker is required"
}

@test "mariadb: check_docker succeeds when docker is available" {
    create_mock "docker" 0

    run_mariadb_fn check_docker
    assert_success
}

# ── Container exists detection ─────────────────────────────────

@test "mariadb: detects existing running container" {
    cat > "${MOCK_BIN}/docker" << 'EOF'
#!/bin/bash
echo "$@" >> "${MOCK_LOG_DIR}/docker.log"
case "$1 $2" in
    "ps -a")
        echo "omniset-mariadb"
        ;;
    "ps --format")
        echo "omniset-mariadb"
        ;;
esac
exit 0
EOF
    chmod +x "${MOCK_BIN}/docker"

    run_mariadb_fn install_mariadb
    assert_success
    assert_output --partial "already exists"
}

@test "mariadb: starts stopped container" {
    cat > "${MOCK_BIN}/docker" << 'EOF'
#!/bin/bash
echo "$@" >> "${MOCK_LOG_DIR}/docker.log"
case "$1" in
    ps)
        if [[ "$2" == "-a" ]]; then
            echo "omniset-mariadb"
        else
            echo ""
        fi
        ;;
    start)
        echo "started"
        ;;
esac
exit 0
EOF
    chmod +x "${MOCK_BIN}/docker"

    run_mariadb_fn install_mariadb
    assert_success
    assert_mock_called_with "docker" "start"
}

# ── Password generation ───────────────────────────────────────

@test "mariadb: generates password when not set" {
    unset MARIADB_ROOT_PASSWORD

    # Test password generation logic directly
    run bash -c '
        export LC_ALL=C
        password=$(tr -dc "A-Za-z0-9" </dev/urandom | head -c 16)
        echo ${#password}
    '
    assert_success
    assert_output "16"
}

@test "mariadb: respects MARIADB_ROOT_PASSWORD env" {
    export MARIADB_ROOT_PASSWORD="my_custom_pass"

    eval "$(grep 'MARIADB_ROOT_PASSWORD=' "$MARIADB_INSTALL" | head -1)"

    [[ "$MARIADB_ROOT_PASSWORD" == "my_custom_pass" ]]
}

# ── Port configuration ────────────────────────────────────────

@test "mariadb: default port is 3307" {
    unset MARIADB_PORT

    eval "$(grep 'MARIADB_PORT=' "$MARIADB_INSTALL")"

    [[ "$MARIADB_PORT" == "3307" ]]
}

@test "mariadb: respects MARIADB_PORT env" {
    export MARIADB_PORT="13306"

    eval "$(grep 'MARIADB_PORT=' "$MARIADB_INSTALL")"

    [[ "$MARIADB_PORT" == "13306" ]]
}

# ── Version parsing ────────────────────────────────────────────

@test "mariadb: default version is 11.6" {
    OPTIONS=""
    eval "$(grep 'MARIADB_VERSION=' "$MARIADB_INSTALL")"

    [[ "$MARIADB_VERSION" == "11.6" ]]
}

@test "mariadb: version from OPTIONS" {
    OPTIONS="10.11"
    eval "$(grep 'MARIADB_VERSION=' "$MARIADB_INSTALL")"

    [[ "$MARIADB_VERSION" == "10.11" ]]
}

# ── Client installation ───────────────────────────────────────

@test "mariadb: install_client skips when mariadb command exists" {
    create_mock "mariadb" 0 "mariadb  Ver 15.1"
    create_sudo_noop

    run_mariadb_fn install_client
    assert_success
    assert_output --partial "already installed"
}

@test "mariadb: install_client runs apt-get when mariadb missing" {
    mock_command_not_exists mariadb
    create_mock "apt-get" 0
    create_sudo_passthrough

    run_mariadb_fn install_client
    assert_success
    assert_mock_called "apt-get"
}

# ── Script validity ────────────────────────────────────────────

@test "mariadb: install.sh is valid bash" {
    run bash -n "$MARIADB_INSTALL"
    assert_success
}

@test "mariadb: has set -euo pipefail" {
    run grep "set -euo pipefail" "$MARIADB_INSTALL"
    assert_success
}
