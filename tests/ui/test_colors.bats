#!/usr/bin/env bats
# Tests for lib/ui/colors.sh

load "../helpers/test_helper"

setup() {
    setup_temp_dir
    setup_mock_bin
    # Don't call disable_colors here — we need to test color init behavior
    source_lib "ui/colors.sh"
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# _detect_color_support
# ═══════════════════════════════════════════════════════════════

@test "_detect_color_support: returns 1 when not a tty" {
    # In test context stdout is typically not a terminal
    run _detect_color_support
    assert_failure
}

@test "_detect_color_support: returns 1 for dumb terminal" {
    export TERM="dumb"
    run _detect_color_support
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# _detect_unicode_support
# ═══════════════════════════════════════════════════════════════

@test "_detect_unicode_support: detects UTF-8 in LANG" {
    LANG="en_US.UTF-8" LC_ALL="" LC_CTYPE="" run _detect_unicode_support
    assert_success
}

@test "_detect_unicode_support: detects UTF-8 in LC_ALL" {
    LANG="" LC_ALL="en_US.UTF-8" LC_CTYPE="" run _detect_unicode_support
    assert_success
}

@test "_detect_unicode_support: detects UTF-8 in LC_CTYPE" {
    LANG="" LC_ALL="" LC_CTYPE="en_US.UTF-8" run _detect_unicode_support
    assert_success
}

@test "_detect_unicode_support: fails when no UTF-8" {
    LANG="C" LC_ALL="C" LC_CTYPE="C" run _detect_unicode_support
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# init_colors
# ═══════════════════════════════════════════════════════════════

@test "init_colors: sets HAS_COLORS=false when no terminal" {
    export TERM="dumb"
    init_colors
    [[ "$HAS_COLORS" == "false" ]]
}

@test "init_colors: sets empty color vars when no terminal" {
    export TERM="dumb"
    init_colors
    [[ -z "$RED" ]]
    [[ -z "$GREEN" ]]
    [[ -z "$BOLD" ]]
    [[ -z "$NC" ]]
}

# ═══════════════════════════════════════════════════════════════
# init_symbols
# ═══════════════════════════════════════════════════════════════

@test "init_symbols: sets ASCII fallbacks when no unicode" {
    LANG="C" LC_ALL="C" LC_CTYPE="C" init_symbols
    [[ "$HAS_UNICODE" == "false" ]]
    [[ "$SYM_CHECK" == "+" ]]
    [[ "$SYM_CROSS" == "x" ]]
    [[ "$SYM_ARROW" == ">" ]]
}

@test "init_symbols: sets unicode symbols when UTF-8 available" {
    LANG="en_US.UTF-8" init_symbols
    [[ "$HAS_UNICODE" == "true" ]]
    [[ "$SYM_CHECK" == "✓" ]]
    [[ "$SYM_CROSS" == "✗" ]]
}

# ═══════════════════════════════════════════════════════════════
# get_terminal_size
# ═══════════════════════════════════════════════════════════════

@test "get_terminal_size: sets TERM_WIDTH and TERM_HEIGHT" {
    get_terminal_size
    [[ -n "$TERM_WIDTH" ]]
    [[ -n "$TERM_HEIGHT" ]]
    [[ "$TERM_WIDTH" -gt 0 ]]
    [[ "$TERM_HEIGHT" -gt 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# init_ui
# ═══════════════════════════════════════════════════════════════

@test "init_ui: initializes all UI components" {
    export TERM="dumb"
    LANG="C" LC_ALL="C" LC_CTYPE="C" init_ui
    [[ -n "$HAS_COLORS" ]]
    [[ -n "$HAS_UNICODE" ]]
    [[ -n "$TERM_WIDTH" ]]
}
