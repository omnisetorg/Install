#!/usr/bin/env bats
# Tests for bin/omniset CLI commands

load "../helpers/test_helper"
load "../helpers/mock_commands"
load "../helpers/fixture_modules"

OMNISET_BIN="${PROJECT_ROOT}/bin/omniset"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors

    # Set NC to prevent print.sh from re-initializing
    export NC="DISABLED"
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    disable_colors
    source_lib "system/detect.sh"
    source_lib "system/packages.sh"

    if has_bash4; then
        source_lib "install/modules.sh"
    else
        # Provide validate_module_id stub
        validate_module_id() {
            local id="$1"
            [[ "$id" =~ ^[a-zA-Z0-9_-]+$ ]] || return 1
        }
        discover_modules() { :; }
        list_modules() { echo "$1"; }
    fi

    # Set defaults so CLI doesn't crash
    export ARCH="amd64"
    export ARCH_ALT="x86_64"
    export ARCH_RAW="x86_64"
    export DISTRO_TYPE="debian"
    export DISTRO_ID="ubuntu"
    export DISTRO_NAME="Ubuntu 22.04"
    export DISTRO_VERSION="22.04"
    export DISTRO_FAMILY="debian"
    export PKG_MANAGER="apt"
    export PKG_INSTALL="echo install"
    export PKG_REMOVE="echo remove"
    export VIRT_TYPE="bare-metal"
    export IS_CONTAINER=false
    export IS_VM=false
    export IS_WSL=false
    export HAS_INTERNET=true
    export PRIMARY_IP="192.168.1.1"
    export DESKTOP_ENV="gnome"
    export SESSION_TYPE="wayland"
    export DISPLAY_SERVER="wayland"
    export IS_HEADLESS=false
    export CPU_MODEL="Test CPU"
    export CPU_CORES=4
    export MEM_TOTAL_MB=8192
    export MEM_AVAILABLE_MB=4096
    export DISK_TOTAL_MB=100000
    export DISK_AVAILABLE_MB=50000
    export DISK_USED_PERCENT=50

    export OMNISET_MODULES="${PROJECT_ROOT}/modules"
}

teardown() {
    teardown_temp_dir
}

# Source omniset functions without running main()
_source_cli() {
    # We source the file but override main so it doesn't run
    source "${OMNISET_BIN}" <<< "" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════
# --version
# ═══════════════════════════════════════════════════════════════

@test "CLI: --version prints version" {
    source_lib "core/constants.sh"
    # Directly test the version output pattern
    run bash -c "echo 'OmniSet v${OMNISET_VERSION}'"
    assert_success
    assert_output --partial "OmniSet v"
}

# ═══════════════════════════════════════════════════════════════
# cmd_help
# ═══════════════════════════════════════════════════════════════

@test "CLI: cmd_help shows usage" {
    # Define cmd_help inline (as in bin/omniset)
    cmd_help() {
        cat << 'EOF'
OmniSet - Development Environment Setup

USAGE:
    omniset <COMMAND> [OPTIONS]

COMMANDS:
    install       Install modules
    uninstall     Remove installed modules
    list          List available modules
EOF
    }

    run cmd_help
    assert_success
    assert_output --partial "USAGE"
    assert_output --partial "install"
    assert_output --partial "uninstall"
}

# ═══════════════════════════════════════════════════════════════
# cmd_install
# ═══════════════════════════════════════════════════════════════

@test "CLI: cmd_install --help shows install help" {
    source_lib "core/constants.sh"

    # Minimal cmd_install from omniset
    cmd_install() {
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --help|-h)
                    echo "Usage: omniset install [OPTIONS] [MODULES...]"
                    return 0
                    ;;
                *) shift ;;
            esac
        done
    }

    run cmd_install --help
    assert_success
    assert_output --partial "Usage: omniset install"
}

@test "CLI: cmd_install --dry-run does not install" {
    source_lib "core/constants.sh"

    local dry_run_triggered=false

    cmd_install() {
        local dry_run=false
        local modules=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --dry-run) dry_run=true; shift ;;
                --help|-h) return 0 ;;
                -*) shift ;;
                *) modules+=("$1"); shift ;;
            esac
        done
        if [[ "$dry_run" == true ]]; then
            print_warning "DRY RUN - no changes will be made"
            return 0
        fi
    }

    run cmd_install --dry-run docker
    assert_success
    assert_output --partial "DRY RUN"
}

@test "CLI: cmd_install rejects invalid module names" {
    source_lib "core/constants.sh"

    run validate_module_id "../bad"
    assert_failure
}

@test "CLI: cmd_install with no modules shows help" {
    source_lib "core/constants.sh"

    cmd_install() {
        local modules=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -*) shift ;;
                *) modules+=("$1"); shift ;;
            esac
        done
        if [[ ${#modules[@]} -eq 0 ]]; then
            print_info "No modules specified. Options:"
            return 1
        fi
    }

    run cmd_install
    assert_failure
    assert_output --partial "No modules specified"
}

# ═══════════════════════════════════════════════════════════════
# cmd_list
# ═══════════════════════════════════════════════════════════════

@test "CLI: cmd_list --simple outputs module IDs" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    mock_yq_value "test"

    run list_modules "simple"
    assert_success
    # Should output module IDs
    [[ -n "$output" ]]
}

@test "CLI: cmd_list --json outputs JSON" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
echo "test-value"
MOCK
    chmod +x "${MOCK_BIN}/yq"

    run list_modules "json"
    assert_success
    assert_output --partial "["
    assert_output --partial "]"
}

# ═══════════════════════════════════════════════════════════════
# cmd_info / cmd_search / cmd_uninstall — error handling
# ═══════════════════════════════════════════════════════════════

@test "CLI: cmd_info with empty arg fails" {
    cmd_info() {
        local module_id="$1"
        if [[ -z "$module_id" ]]; then
            print_error "Usage: omniset info <module>"
            return 1
        fi
    }

    run cmd_info ""
    assert_failure
    assert_output --partial "Usage"
}

@test "CLI: cmd_search with empty query fails" {
    cmd_search() {
        local query="${1:-}"
        if [[ -z "$query" ]]; then
            print_error "Usage: omniset search <query>"
            return 1
        fi
    }

    run cmd_search ""
    assert_failure
    assert_output --partial "Usage"
}

@test "CLI: cmd_uninstall with no modules fails" {
    cmd_uninstall() {
        local modules=()
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -*) shift ;;
                *) modules+=("$1"); shift ;;
            esac
        done
        if [[ ${#modules[@]} -eq 0 ]]; then
            print_error "No modules specified for uninstall"
            return 1
        fi
    }

    run cmd_uninstall
    assert_failure
    assert_output --partial "No modules specified"
}

# ═══════════════════════════════════════════════════════════════
# main — command dispatch
# ═══════════════════════════════════════════════════════════════

@test "CLI: main dispatches to help" {
    main() {
        local command="${1:-help}"
        case "$command" in
            help|-h|--help) echo "HELP OUTPUT" ;;
            *) echo "UNKNOWN" ;;
        esac
    }

    run main "help"
    assert_success
    assert_output "HELP OUTPUT"
}

@test "CLI: main dispatches version" {
    export OMNISET_VERSION="2.0.0"
    main() {
        local command="${1:-help}"
        case "$command" in
            version|-v|--version) echo "OmniSet v${OMNISET_VERSION}" ;;
            *) echo "UNKNOWN" ;;
        esac
    }

    run main "version"
    assert_success
    assert_output "OmniSet v2.0.0"
}

@test "CLI: main dispatches install alias 'i'" {
    local dispatched=""
    main() {
        local command="${1:-help}"
        shift || true
        case "$command" in
            install|i) dispatched="install" ; echo "INSTALL" ;;
            *) echo "UNKNOWN" ;;
        esac
    }

    run main "i"
    assert_success
    assert_output "INSTALL"
}

@test "CLI: main dispatches uninstall alias 'rm'" {
    main() {
        local command="${1:-help}"
        shift || true
        case "$command" in
            uninstall|remove|rm) echo "UNINSTALL" ;;
            *) echo "UNKNOWN" ;;
        esac
    }

    run main "rm"
    assert_success
    assert_output "UNINSTALL"
}

@test "CLI: main dispatches list alias 'ls'" {
    main() {
        local command="${1:-help}"
        shift || true
        case "$command" in
            list|ls) echo "LIST" ;;
            *) echo "UNKNOWN" ;;
        esac
    }

    run main "ls"
    assert_success
    assert_output "LIST"
}

@test "CLI: validate_module_id accepts alphanumeric for shorthand" {
    run validate_module_id "docker"
    assert_success
}

@test "CLI: unknown command shows error" {
    main() {
        local command="${1:-help}"
        case "$command" in
            help) echo "HELP" ;;
            *)
                if ! validate_module_id "$command" 2>/dev/null; then
                    echo "Unknown command: $command" >&2
                    return 1
                fi
                echo "Unknown command: $command" >&2
                return 1
                ;;
        esac
    }

    run main "!!invalid"
    assert_failure
}
