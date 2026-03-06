#!/bin/bash
# OmniSet Test Helper — loaded by every test file
# Provides isolated temp dirs, mock PATH, color reset, and source helpers

# Project paths
export PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export OMNISET_ROOT="$PROJECT_ROOT"
export OMNISET_LIB="${OMNISET_ROOT}/lib"
export OMNISET_MODULES="${OMNISET_ROOT}/modules"

# BATS helper libraries
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
load "${TESTS_DIR}/bats/bats-support/load"
load "${TESTS_DIR}/bats/bats-assert/load"
load "${TESTS_DIR}/bats/bats-file/load"

# ── Per-test isolated temp directory ────────────────────────────
setup_temp_dir() {
    export TEST_TEMP_DIR
    TEST_TEMP_DIR="$(mktemp -d)"
}

teardown_temp_dir() {
    if [[ -d "${TEST_TEMP_DIR:-}" ]]; then
        rm -rf "$TEST_TEMP_DIR"
    fi
}

# Default setup/teardown (tests can override by defining their own)
setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors
}

teardown() {
    teardown_temp_dir
}

# ── Mock binary directory ───────────────────────────────────────
setup_mock_bin() {
    export MOCK_BIN="${TEST_TEMP_DIR}/mock_bin"
    export MOCK_LOG_DIR="${TEST_TEMP_DIR}/mock_logs"
    mkdir -p "$MOCK_BIN" "$MOCK_LOG_DIR"
    export PATH="${MOCK_BIN}:${PATH}"
}

# ── Disable ANSI colors for deterministic output assertions ─────
disable_colors() {
    export HAS_COLORS=false
    export HAS_UNICODE=false
    export TERM=dumb

    # Empty all color variables
    export BLACK='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    export BRIGHT_BLACK='' BRIGHT_RED='' BRIGHT_GREEN='' BRIGHT_YELLOW=''
    export BRIGHT_BLUE='' BRIGHT_PURPLE='' BRIGHT_CYAN='' BRIGHT_WHITE=''
    export BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE=''
    export BOLD='' DIM='' ITALIC='' UNDERLINE='' BLINK='' REVERSE='' HIDDEN='' STRIKETHROUGH=''
    export NC='' RESET=''

    # ASCII fallback symbols
    export SYM_CHECK="+"
    export SYM_CROSS="x"
    export SYM_WARNING="!"
    export SYM_INFO="i"
    export SYM_ARROW=">"
    export SYM_BULLET="*"
    export SYM_STAR="*"
    export SYM_CIRCLE="o"
    export SYM_SQUARE="#"
    export SYM_DIAMOND="+"
    export SYM_PROG_FULL="="
    export SYM_PROG_EMPTY="-"
    export SYM_PROG_HALF="+"
    export SYM_BOX_TL="+"
    export SYM_BOX_TR="+"
    export SYM_BOX_BL="+"
    export SYM_BOX_BR="+"
    export SYM_BOX_H="-"
    export SYM_BOX_V="|"

    export TERM_WIDTH=80
    export TERM_HEIGHT=24
}

# ── Bash version check ──────────────────────────────────────────
# Returns 0 if bash >= 4.0 (needed for associative arrays)
has_bash4() {
    [[ "${BASH_VERSINFO[0]}" -ge 4 ]]
}

# Skip test if bash < 4 (used by tests needing associative arrays)
require_bash4() {
    if ! has_bash4; then
        skip "requires bash 4+ (associative arrays)"
    fi
}

# ── Source helper ────────────────────────────────────────────────
# Source a single lib file without triggering full init
source_lib() {
    local lib_file="$1"
    source "${OMNISET_LIB}/${lib_file}"
}

# Source lib files needed for most tests (ui + detect + packages + modules)
source_all_libs() {
    source_lib "core/constants.sh"
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    source_lib "system/detect.sh"
    source_lib "system/packages.sh"
    source_lib "install/modules.sh"
}
