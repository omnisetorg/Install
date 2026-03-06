#!/usr/bin/env bats
# Tests for lib/ui/print.sh

load "../helpers/test_helper"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors
    # Set NC to a non-empty sentinel to prevent print.sh from re-initializing colors
    export NC="DISABLED"
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    # Re-apply disable after sourcing (to ensure clean state)
    disable_colors
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# Basic print functions
# ═══════════════════════════════════════════════════════════════

@test "print: outputs text to stdout" {
    run print "hello world"
    assert_success
    assert_output "hello world"
}

@test "printn: outputs text without newline" {
    run printn "hello"
    assert_success
    assert_output "hello"
}

@test "printerr: outputs text to stderr" {
    run printerr "error message"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# Semantic print functions
# ═══════════════════════════════════════════════════════════════

@test "print_success: contains check symbol and message" {
    run print_success "Operation completed"
    assert_success
    assert_output --partial "+"
    assert_output --partial "Operation completed"
}

@test "print_error: contains cross symbol and message" {
    run print_error "Something failed"
    assert_success
    assert_output --partial "x"
    assert_output --partial "Something failed"
}

@test "print_warning: contains warning symbol and message" {
    run print_warning "Caution ahead"
    assert_success
    assert_output --partial "!"
    assert_output --partial "Caution ahead"
}

@test "print_info: contains info symbol and message" {
    run print_info "FYI note"
    assert_success
    assert_output --partial "i"
    assert_output --partial "FYI note"
}

@test "print_step: contains arrow symbol and message" {
    run print_step "Installing..."
    assert_success
    assert_output --partial ">"
    assert_output --partial "Installing..."
}

@test "print_step: with step numbers" {
    run print_step "Installing..." "1" "5"
    assert_success
    assert_output --partial "[1/5]"
    assert_output --partial "Installing..."
}

@test "print_bullet: outputs bullet with message" {
    run print_bullet "item one"
    assert_success
    assert_output --partial "*"
    assert_output --partial "item one"
}

@test "print_debug: silent when OMNISET_DEBUG not set" {
    export OMNISET_DEBUG=false
    run print_debug "debug info"
    assert_success
    assert_output ""
}

@test "print_debug: outputs when OMNISET_DEBUG=true" {
    export OMNISET_DEBUG=true
    run print_debug "debug info"
    assert_success
    assert_output --partial "DEBUG"
    assert_output --partial "debug info"
}

# ═══════════════════════════════════════════════════════════════
# Formatted print functions
# ═══════════════════════════════════════════════════════════════

@test "print_header: outputs boxed header" {
    run print_header "Test Header"
    assert_success
    assert_output --partial "Test Header"
    # Should contain box drawing characters (ASCII fallback)
    assert_output --partial "+"
    assert_output --partial "-"
}

@test "print_divider: outputs horizontal line" {
    run print_divider
    assert_success
    assert_output --partial "-"
}

@test "print_kv: outputs key-value pair" {
    run print_kv "Name" "OmniSet"
    assert_success
    assert_output --partial "Name"
    assert_output --partial "OmniSet"
}

@test "print_status: ok status" {
    run print_status "Docker" "ok"
    assert_success
    assert_output --partial "Docker"
    assert_output --partial "OK"
}

@test "print_status: fail status" {
    run print_status "Docker" "fail"
    assert_success
    assert_output --partial "Docker"
    assert_output --partial "FAIL"
}

@test "print_status: skip status" {
    run print_status "Docker" "skip"
    assert_success
    assert_output --partial "Docker"
    assert_output --partial "SKIP"
}

@test "print_columns: outputs items in columns" {
    run print_columns "item1" "item2" "item3" "item4"
    assert_success
    assert_output --partial "item1"
    assert_output --partial "item2"
    assert_output --partial "item3"
    assert_output --partial "item4"
}

# ═══════════════════════════════════════════════════════════════
# Banner
# ═══════════════════════════════════════════════════════════════

@test "print_banner: outputs OMNISET banner" {
    export OMNISET_VERSION="2.0.0"
    run print_banner
    assert_success
    assert_output --partial "2.0.0"
    assert_output --partial "Development Environment Setup"
}

@test "print_compact_banner: outputs single-line banner" {
    export OMNISET_VERSION="2.0.0"
    run print_compact_banner
    assert_success
    assert_output --partial "OmniSet"
    assert_output --partial "2.0.0"
}
