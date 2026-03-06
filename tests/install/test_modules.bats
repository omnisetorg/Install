#!/usr/bin/env bats
# Tests for lib/install/modules.sh

load "../helpers/test_helper"
load "../helpers/mock_commands"
load "../helpers/fixture_modules"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    source_lib "system/detect.sh"
    source_lib "system/packages.sh"

    # Set default architecture for tests
    export ARCH="amd64"
    export ARCH_ALT="x86_64"
    export ARCH_RAW="x86_64"

    # Set a large available disk to avoid disk space check failures
    export DISK_AVAILABLE_MB=99999

    # Default package manager
    export PKG_MANAGER="apt"
    export PKG_INSTALL="echo pkg_install"
    export PKG_REMOVE="echo pkg_remove"

    # Source modules.sh only if bash 4+ is available
    if has_bash4; then
        source_lib "install/modules.sh"
        declare -gA MODULE_REGISTRY=()
        INSTALLED_MODULES=()
        FAILED_MODULES=()
    else
        # Provide validate_module_id stub for bash 3
        validate_module_id() {
            local id="$1"
            [[ "$id" =~ ^[a-zA-Z0-9_-]+$ ]] || return 1
        }
    fi
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# validate_module_id
# ═══════════════════════════════════════════════════════════════

@test "validate_module_id: accepts alphanumeric" {
    run validate_module_id "docker"
    assert_success
}

@test "validate_module_id: accepts hyphens" {
    run validate_module_id "modern-cli"
    assert_success
}

@test "validate_module_id: accepts underscores" {
    run validate_module_id "my_module"
    assert_success
}

@test "validate_module_id: rejects empty string" {
    run validate_module_id ""
    assert_failure
}

@test "validate_module_id: rejects spaces" {
    run validate_module_id "my module"
    assert_failure
}

@test "validate_module_id: rejects dots" {
    run validate_module_id "my.module"
    assert_failure
}

@test "validate_module_id: rejects slashes (path traversal)" {
    run validate_module_id "../etc/passwd"
    assert_failure
}

@test "validate_module_id: rejects special chars (injection)" {
    run validate_module_id 'mod;rm -rf'
    assert_failure
}

@test "validate_module_id: rejects pipes" {
    run validate_module_id "a|b"
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# discover_modules
# ═══════════════════════════════════════════════════════════════

@test "discover_modules: finds modules with manifests" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()

    discover_modules

    [[ -n "${MODULE_REGISTRY[test-editor]:-}" ]]
    [[ -n "${MODULE_REGISTRY[test-browser]:-}" ]]
    [[ -n "${MODULE_REGISTRY[test-tool]:-}" ]]
}

@test "discover_modules: ignores dirs without manifests" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    create_fixture_module_no_manifest "no-manifest" "editors"
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()

    discover_modules

    [[ -z "${MODULE_REGISTRY[no-manifest]:-}" ]]
}

@test "discover_modules: correct module paths" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()

    discover_modules

    [[ "${MODULE_REGISTRY[test-editor]}" == *"/editors/test-editor/" ]]
}

@test "discover_modules: empty dir returns no modules" {
    require_bash4
    mkdir -p "${TEST_TEMP_DIR}/empty_modules"
    export OMNISET_MODULES="${TEST_TEMP_DIR}/empty_modules"
    declare -gA MODULE_REGISTRY=()

    discover_modules

    [[ ${#MODULE_REGISTRY[@]} -eq 0 ]]
}

# ═══════════════════════════════════════════════════════════════
# get_module_dir
# ═══════════════════════════════════════════════════════════════

@test "get_module_dir: finds module from registry" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    run get_module_dir "test-editor"
    assert_success
    assert_output --partial "editors/test-editor"
}

@test "get_module_dir: filesystem fallback when not in registry" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    # Don't call discover_modules — registry is empty

    run get_module_dir "test-editor"
    assert_success
    assert_output --partial "editors/test-editor"
}

@test "get_module_dir: fails for nonexistent module" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    run get_module_dir "nonexistent-module"
    assert_failure
}

@test "get_module_dir: rejects invalid module ID" {
    require_bash4
    run get_module_dir "../etc/passwd"
    assert_failure
    assert_output --partial "Invalid module ID"
}

# ═══════════════════════════════════════════════════════════════
# get_module_info
# ═══════════════════════════════════════════════════════════════

@test "get_module_info: returns manifest value" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    # Mock yq to return a value
    mock_yq_value "Test Editor"

    run get_module_info "test-editor" "display_name"
    assert_success
    assert_output "Test Editor"
}

@test "get_module_info: returns default for missing key" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    # Mock yq to return null
    mock_yq_value "null"

    run get_module_info "test-editor" "nonexistent_key" "default_val"
    assert_success
    assert_output "default_val"
}

# ═══════════════════════════════════════════════════════════════
# module_supports_arch
# ═══════════════════════════════════════════════════════════════

@test "module_supports_arch: supported architecture" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules
    export ARCH="amd64"

    # Mock yq returns "true" for architecture.amd64
    mock_yq_value "true"

    run module_supports_arch "test-editor"
    assert_success
}

@test "module_supports_arch: unsupported architecture" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules
    export ARCH="armhf"

    # Mock yq returns "false" for architecture.armhf
    mock_yq_value "false"

    run module_supports_arch "test-editor"
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# is_module_installed
# ═══════════════════════════════════════════════════════════════

@test "is_module_installed: detected via command" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    # Mock yq to return the command name
    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
echo "$@" >> "${MOCK_LOG_DIR}/yq.log"
if [[ "$2" == *"provides.commands"* ]]; then
    echo "test-editor"
elif [[ "$2" == *"provides.packages"* ]]; then
    echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    # Make the command exist
    create_mock "test-editor" 0

    run is_module_installed "test-editor"
    assert_success
}

@test "is_module_installed: not installed when command missing" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    # Mock yq to return nonexistent commands/packages
    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
echo "$@" >> "${MOCK_LOG_DIR}/yq.log"
echo ""
MOCK
    chmod +x "${MOCK_BIN}/yq"

    run is_module_installed "test-editor"
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# install_module
# ═══════════════════════════════════════════════════════════════

@test "install_module: runs install.sh successfully" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    # Mock yq calls
    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Test Editor"
elif [[ "$2" == *"architecture"* ]]; then echo "true"
elif [[ "$2" == *"disk_mb"* ]]; then echo "100"
elif [[ "$2" == *"provides.commands"* ]]; then echo ""
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
elif [[ "$2" == *"dependencies"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    # Force install (skip is_installed check)
    run install_module "test-editor" "true"
    assert_success
    assert_output --partial "installed successfully"
}

@test "install_module: fails for nonexistent module" {
    require_bash4
    export OMNISET_MODULES="${TEST_TEMP_DIR}/empty"
    mkdir -p "$OMNISET_MODULES"
    declare -gA MODULE_REGISTRY=()

    run install_module "nonexistent"
    assert_failure
    assert_output --partial "Module not found"
}

@test "install_module: skips already installed module" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    # Mock yq and make the command exist (module is "installed")
    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Test Editor"
elif [[ "$2" == *"provides.commands"* ]]; then echo "test-editor"
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"
    create_mock "test-editor" 0

    run install_module "test-editor" "false"
    assert_success
    assert_output --partial "already installed"
}

@test "install_module: respects force flag to reinstall" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Test Editor"
elif [[ "$2" == *"architecture"* ]]; then echo "true"
elif [[ "$2" == *"disk_mb"* ]]; then echo "100"
elif [[ "$2" == *"provides.commands"* ]]; then echo "test-editor"
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
elif [[ "$2" == *"dependencies"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"
    create_mock "test-editor" 0

    run install_module "test-editor" "true"
    assert_success
    assert_output --partial "installed successfully"
}

@test "install_module: fails on unsupported architecture" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Test Editor"
elif [[ "$2" == *"architecture"* ]]; then echo "false"
elif [[ "$2" == *"provides.commands"* ]]; then echo ""
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    run install_module "test-editor" "true"
    assert_failure
    assert_output --partial "doesn't support"
}

@test "install_module: tracks failure in FAILED_MODULES" {
    require_bash4
    local module_dir
    module_dir=$(create_fixture_module_failing "fail-mod" "development")
    export OMNISET_MODULES="${TEST_TEMP_DIR}/modules"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Fail Module"
elif [[ "$2" == *"architecture"* ]]; then echo "true"
elif [[ "$2" == *"disk_mb"* ]]; then echo "100"
elif [[ "$2" == *"provides.commands"* ]]; then echo ""
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
elif [[ "$2" == *"dependencies"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    install_module "fail-mod" "true" || true

    [[ ${#FAILED_MODULES[@]} -gt 0 ]]
    [[ "${FAILED_MODULES[0]}" == "fail-mod" ]]
}

@test "install_module: falls back to auto_install when no install.sh" {
    require_bash4
    local module_dir="${TEST_TEMP_DIR}/modules/development/auto-mod"
    mkdir -p "$module_dir"

    cat > "${module_dir}/manifest.yaml" << 'YAML'
name: auto-mod
display_name: Auto Module
category: development
description: Module with no install.sh
architecture:
  amd64: true
install_methods:
  - type: apt
    packages:
      - auto-mod-pkg
provides:
  commands: []
  packages: []
YAML
    # No install.sh — should trigger auto_install_module

    export OMNISET_MODULES="${TEST_TEMP_DIR}/modules"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Auto Module"
elif [[ "$2" == *"architecture"* ]]; then echo "true"
elif [[ "$2" == *"disk_mb"* ]]; then echo "100"
elif [[ "$2" == *"provides.commands"* ]]; then echo ""
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
elif [[ "$2" == *"dependencies"* ]]; then echo ""
elif [[ "$2" == *"install_methods | length"* ]]; then echo "1"
elif [[ "$2" == *".type"* ]]; then echo "apt"
elif [[ "$2" == *"packages"* ]]; then echo "auto-mod-pkg"
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    # Mock pkg_install to succeed
    export PKG_INSTALL="true"

    run install_module "auto-mod" "true"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# install_modules (sequential)
# ═══════════════════════════════════════════════════════════════

@test "install_modules: processes all modules sequentially" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules
    export OMNISET_PARALLEL=false

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Test Module"
elif [[ "$2" == *"architecture"* ]]; then echo "true"
elif [[ "$2" == *"disk_mb"* ]]; then echo "100"
elif [[ "$2" == *"provides.commands"* ]]; then echo ""
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
elif [[ "$2" == *"dependencies"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    run install_modules "test-editor" "test-browser"
    assert_success
    assert_output --partial "Installing 2 modules"
    assert_output --partial "Installation Summary"
}

@test "install_modules: returns 1 on any failure" {
    require_bash4
    # Create one good module and one that doesn't exist
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules
    export OMNISET_PARALLEL=false

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Test Module"
elif [[ "$2" == *"architecture"* ]]; then echo "true"
elif [[ "$2" == *"disk_mb"* ]]; then echo "100"
elif [[ "$2" == *"provides.commands"* ]]; then echo ""
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
elif [[ "$2" == *"dependencies"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    run install_modules "test-editor" "nonexistent-mod"
    assert_failure
    assert_output --partial "Failed"
}

@test "install_modules: prints summary with counts" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules
    export OMNISET_PARALLEL=false

    cat > "${MOCK_BIN}/yq" << 'MOCK'
#!/bin/bash
if [[ "$2" == *"display_name"* ]]; then echo "Test Module"
elif [[ "$2" == *"architecture"* ]]; then echo "true"
elif [[ "$2" == *"disk_mb"* ]]; then echo "100"
elif [[ "$2" == *"provides.commands"* ]]; then echo ""
elif [[ "$2" == *"provides.packages"* ]]; then echo ""
elif [[ "$2" == *"dependencies"* ]]; then echo ""
else echo ""
fi
MOCK
    chmod +x "${MOCK_BIN}/yq"

    run install_modules "test-editor"
    assert_success
    assert_output --partial "Total"
    assert_output --partial "Installed"
}

# ═══════════════════════════════════════════════════════════════
# uninstall_module
# ═══════════════════════════════════════════════════════════════

@test "uninstall_module: runs uninstall.sh" {
    require_bash4
    local modules_dir
    modules_dir=$(create_fixture_module_tree)
    export OMNISET_MODULES="$modules_dir"
    declare -gA MODULE_REGISTRY=()
    discover_modules

    mock_yq_value "Test Editor"

    run uninstall_module "test-editor"
    assert_success
    assert_output --partial "uninstalled"
}

@test "uninstall_module: fails for nonexistent module" {
    require_bash4
    export OMNISET_MODULES="${TEST_TEMP_DIR}/modules"
    mkdir -p "$OMNISET_MODULES"
    declare -gA MODULE_REGISTRY=()

    run uninstall_module "nonexistent"
    assert_failure
    assert_output --partial "Module not found"
}
