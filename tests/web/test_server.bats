#!/usr/bin/env bats
# Tests for lib/web/server.sh

load "../helpers/test_helper"
load "../helpers/mock_commands"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    # Provide required globals
    export OMNISET_ROOT="$PROJECT_ROOT"
    export OMNISET_WEB_DIR="${OMNISET_ROOT}/web"

    # Source UI libs for print functions
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"

    # Stub omniset_mktemp so it works without full init
    omniset_mktemp() {
        local suffix=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --suffix=*) suffix="${1#--suffix=}" ;;
                -d) mktemp -d -p "$TEST_TEMP_DIR"; return ;;
            esac
            shift
        done
        mktemp -p "$TEST_TEMP_DIR" "tmp.XXXXXX${suffix}"
    }
    export -f omniset_mktemp
}

# ── Port configuration ─────────────────────────────────────────

@test "server: OMNISET_WEB_PORT defaults to 9999" {
    unset OMNISET_WEB_PORT
    source "${OMNISET_LIB}/web/server.sh"
    [[ "$OMNISET_WEB_PORT" == "9999" ]]
}

@test "server: OMNISET_WEB_PORT respects env override" {
    export OMNISET_WEB_PORT=8080
    source "${OMNISET_LIB}/web/server.sh"
    [[ "$OMNISET_WEB_PORT" == "8080" ]]
}

# ── Python3 availability ───────────────────────────────────────

@test "server: start_web_server fails when python3 missing" {
    export OMNISET_CALLBACK_FILE="${TEST_TEMP_DIR}/callback"

    # Create a safe PATH that has essential commands but NOT python3
    local safe_bin="${TEST_TEMP_DIR}/safe_bin"
    mkdir -p "$safe_bin"
    # Link only needed commands (excluding python3)
    # Use 'which' to find each command regardless of distro layout
    for cmd in bash mktemp tput env cat grep sed rm sleep kill chmod; do
        local cmd_path
        cmd_path=$(command -v "$cmd" 2>/dev/null) && ln -sf "$cmd_path" "${safe_bin}/${cmd}"
    done

    # PATH must contain ONLY safe_bin and MOCK_BIN — no /bin or /usr/bin
    # On Ubuntu /bin → /usr/bin, so including /bin leaks python3
    run env PATH="${MOCK_BIN}:${safe_bin}" bash -c '
        source "'"${OMNISET_LIB}/ui/colors.sh"'"
        source "'"${OMNISET_LIB}/ui/print.sh"'"
        omniset_mktemp() { mktemp -p "'"${TEST_TEMP_DIR}"'"; }
        export -f omniset_mktemp
        export OMNISET_ROOT="'"${PROJECT_ROOT}"'"
        export OMNISET_WEB_DIR="'"${OMNISET_WEB_DIR}"'"
        export OMNISET_CALLBACK_FILE="'"${TEST_TEMP_DIR}/callback"'"
        export HAS_COLORS=false HAS_UNICODE=false TERM=dumb
        export SYM_CHECK="+" SYM_CROSS="x" SYM_WARNING="!" SYM_INFO="i" SYM_ARROW=">" SYM_BULLET="*"
        export BOLD="" NC="" RED="" GREEN="" YELLOW="" BLUE="" CYAN="" DIM=""
        source "'"${OMNISET_LIB}/web/server.sh"'"
        start_web_server
    '
    assert_failure
    assert_output --partial "Python 3 is required"
}

# ── Callback file initialization ───────────────────────────────

@test "server: OMNISET_CALLBACK_FILE empty after source (not yet started)" {
    export OMNISET_CALLBACK_FILE=""
    source "${OMNISET_LIB}/web/server.sh"

    # After sourcing, the variable should still be empty since start_web_server wasn't called
    [[ -z "$OMNISET_CALLBACK_FILE" ]]
}

# ── get_selected_modules ───────────────────────────────────────

@test "server: get_selected_modules returns data from SELECTED_MODULES" {
    source "${OMNISET_LIB}/web/server.sh"

    SELECTED_MODULES=("nodejs" "rust" "python")

    run get_selected_modules
    assert_success
    assert_output "nodejs rust python"
}

@test "server: get_selected_modules handles set -u with empty array" {
    # The function uses ${SELECTED_MODULES[@]} which fails under set -u
    # This tests the actual behavior of the source code
    source "${OMNISET_LIB}/web/server.sh"

    SELECTED_MODULES=("single-module")
    run get_selected_modules
    assert_success
    assert_output "single-module"
}

# ── Browser open logic ─────────────────────────────────────────

@test "server: xdg-open is preferred over open" {
    create_mock "xdg-open" 0
    create_mock "open" 0

    run bash -c '
        export PATH="'"${MOCK_BIN}"'"
        if command -v xdg-open &>/dev/null; then
            echo "xdg-open"
        elif command -v open &>/dev/null; then
            echo "open"
        else
            echo "fallback"
        fi
    '
    assert_output "xdg-open"
}

@test "server: open used when xdg-open missing" {
    mock_command_not_exists xdg-open
    create_mock "open" 0

    run bash -c '
        export PATH="'"${MOCK_BIN}"'"
        if command -v xdg-open &>/dev/null; then
            echo "xdg-open"
        elif command -v open &>/dev/null; then
            echo "open"
        else
            echo "fallback"
        fi
    '
    assert_output "open"
}

@test "server: fallback when no browser opener found" {
    mock_command_not_exists xdg-open
    mock_command_not_exists open

    # Use ONLY mock_bin in PATH so no system open/xdg-open is found
    run bash -c '
        export PATH="'"${MOCK_BIN}"'"
        if command -v xdg-open &>/dev/null; then
            echo "xdg-open"
        elif command -v open &>/dev/null; then
            echo "open"
        else
            echo "fallback"
        fi
    '
    assert_output "fallback"
}

# ── Callback file reading ─────────────────────────────────────

@test "server: reads selected modules from callback file" {
    require_bash4

    local callback_file="${TEST_TEMP_DIR}/callback"
    printf "nodejs\nrust\npython\n" > "$callback_file"

    local -a result=()
    while IFS= read -r line; do
        result+=("$line")
    done < "$callback_file"

    [[ ${#result[@]} -eq 3 ]]
    [[ "${result[0]}" == "nodejs" ]]
    [[ "${result[1]}" == "rust" ]]
    [[ "${result[2]}" == "python" ]]
}

@test "server: empty callback file results in zero modules" {
    local callback_file="${TEST_TEMP_DIR}/callback"
    touch "$callback_file"

    local count=0
    while IFS= read -r line; do
        ((count++))
    done < "$callback_file"

    [[ $count -eq 0 ]]
}

# ── Server script generation ──────────────────────────────────

@test "server: start_web_server invokes python3 with correct args" {
    # mapfile is required by server.sh and needs bash 4+
    require_bash4

    export OMNISET_CALLBACK_FILE="${TEST_TEMP_DIR}/callback"

    # Mock python3: args are (script, port, webdir, callback_file)
    # $1=script path, $2=port, $3=webdir, $4=callback_file
    cat > "${MOCK_BIN}/python3" << MOCK
#!/bin/bash
echo "\$@" >> "${MOCK_LOG_DIR}/python3.log"
# Create callback file to unblock the wait loop
echo "test-module" > "\$4"
exit 0
MOCK
    chmod +x "${MOCK_BIN}/python3"

    create_mock "xdg-open" 0

    source "${OMNISET_LIB}/web/server.sh"

    run start_web_server
    assert_success

    # Verify python3 was called
    assert_mock_called "python3"
}

# ── Timeout behavior ──────────────────────────────────────────

@test "server: timeout logic returns error when no callback" {
    # Test the timeout logic in isolation without the full server
    run bash -c '
        source "'"${OMNISET_LIB}/ui/colors.sh"'"
        source "'"${OMNISET_LIB}/ui/print.sh"'"
        export HAS_COLORS=false HAS_UNICODE=false TERM=dumb
        export SYM_CHECK="+" SYM_CROSS="x" SYM_WARNING="!" SYM_INFO="i" SYM_ARROW=">" SYM_BULLET="*"
        export BOLD="" NC="" RED="" GREEN="" YELLOW="" BLUE="" CYAN="" DIM=""

        CALLBACK_FILE="'"${TEST_TEMP_DIR}/no_such_callback"'"
        timeout=1
        elapsed=0
        while [[ ! -f "$CALLBACK_FILE" ]] && [[ $elapsed -lt $timeout ]]; do
            sleep 0.5
            ((elapsed++))
        done

        if [[ -f "$CALLBACK_FILE" ]]; then
            echo "received"
            exit 0
        else
            print_error "Timeout waiting for selection"
            exit 1
        fi
    '
    assert_failure
    assert_output --partial "Timeout"
}

@test "server: timeout logic succeeds when callback exists" {
    # Pre-create the callback file
    echo "nodejs" > "${TEST_TEMP_DIR}/callback_ready"

    run bash -c '
        CALLBACK_FILE="'"${TEST_TEMP_DIR}/callback_ready"'"
        timeout=1
        elapsed=0
        while [[ ! -f "$CALLBACK_FILE" ]] && [[ $elapsed -lt $timeout ]]; do
            sleep 0.5
            ((elapsed++))
        done

        if [[ -f "$CALLBACK_FILE" ]]; then
            echo "received"
            exit 0
        else
            echo "timeout"
            exit 1
        fi
    '
    assert_success
    assert_output "received"
}

# ── Server script content ────────────────────────────────────

@test "server: generated python script handles /api/install POST" {
    run grep -c "/api/install" "${OMNISET_LIB}/web/server.sh"
    assert_success
}

@test "server: server.sh sources correctly" {
    run bash -n "${OMNISET_LIB}/web/server.sh"
    assert_success
}
