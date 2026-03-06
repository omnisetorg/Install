#!/usr/bin/env bats
# Tests for lib/install/uninstall.sh

load "../helpers/test_helper"
load "../helpers/mock_commands"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    source_lib "install/uninstall.sh"

    create_sudo_noop
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# remove_package
# ═══════════════════════════════════════════════════════════════

@test "remove_package: tries apt-get when available" {
    create_mock "apt-get" 0
    create_sudo_passthrough
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    mock_command_not_exists "zypper"
    mock_command_not_exists "apk"

    run remove_package "test-pkg"
    assert_success
    assert_mock_called "sudo"
}

@test "remove_package: tries dnf when available" {
    mock_command_not_exists "apt-get"
    create_mock "dnf" 0
    create_sudo_passthrough
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    mock_command_not_exists "zypper"
    mock_command_not_exists "apk"

    run remove_package "test-pkg"
    assert_success
    assert_mock_called "sudo"
}

@test "remove_package: tries pacman when available" {
    mock_command_not_exists "apt-get"
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    create_mock "pacman" 0
    create_sudo_passthrough
    mock_command_not_exists "zypper"
    mock_command_not_exists "apk"

    run remove_package "test-pkg"
    assert_success
    assert_mock_called "sudo"
}

@test "remove_package: tries zypper when available" {
    mock_command_not_exists "apt-get"
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    create_mock "zypper" 0
    create_sudo_passthrough
    mock_command_not_exists "apk"

    run remove_package "test-pkg"
    assert_success
    assert_mock_called "sudo"
}

@test "remove_package: tries apk when available" {
    mock_command_not_exists "apt-get"
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    mock_command_not_exists "zypper"
    create_mock "apk" 0
    create_sudo_passthrough

    run remove_package "test-pkg"
    assert_success
    assert_mock_called "sudo"
}

# ═══════════════════════════════════════════════════════════════
# remove_flatpak
# ═══════════════════════════════════════════════════════════════

@test "remove_flatpak: calls flatpak uninstall" {
    create_mock "flatpak" 0
    run remove_flatpak "com.example.App"
    assert_success
    assert_mock_called "flatpak"
}

@test "remove_flatpak: succeeds even when flatpak not installed" {
    mock_command_not_exists "flatpak"
    run remove_flatpak "com.example.App"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# remove_snap
# ═══════════════════════════════════════════════════════════════

@test "remove_snap: calls snap remove" {
    create_mock "snap" 0
    run remove_snap "test-snap"
    assert_success
}

@test "remove_snap: succeeds when snap not installed" {
    mock_command_not_exists "snap"
    run remove_snap "test-snap"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# remove_docker
# ═══════════════════════════════════════════════════════════════

@test "remove_docker: stops and removes container" {
    create_mock "docker" 0
    run remove_docker "test-container"
    assert_success
    assert_mock_called "docker"
}

@test "remove_docker: removes image when specified" {
    create_mock "docker" 0
    run remove_docker "test-container" "test-image:latest"
    assert_success
    assert_mock_called_with "docker" "rmi"
}

@test "remove_docker: succeeds when docker not installed" {
    mock_command_not_exists "docker"
    run remove_docker "test-container"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# cleanup_orphans
# ═══════════════════════════════════════════════════════════════

@test "cleanup_orphans: calls autoremove on apt" {
    create_mock "apt-get" 0
    create_sudo_passthrough
    mock_command_not_exists "dnf"
    mock_command_not_exists "pacman"

    run cleanup_orphans
    assert_success
    assert_mock_called "sudo"
}

# ═══════════════════════════════════════════════════════════════
# remove_config_dirs
# ═══════════════════════════════════════════════════════════════

@test "remove_config_dirs: removes standard directories" {
    # Create fake config dirs in temp location
    local app="testapp-$$"
    mkdir -p "$HOME/.config/$app"
    mkdir -p "$HOME/.cache/$app"

    # Pass empty extra dir to avoid unbound variable error with set -u
    run remove_config_dirs "$app" ""
    assert_success

    [[ ! -d "$HOME/.config/$app" ]]
    [[ ! -d "$HOME/.cache/$app" ]]
}

@test "remove_config_dirs: handles extra directories" {
    local extra_dir="${TEST_TEMP_DIR}/extra_config"
    mkdir -p "$extra_dir"

    run remove_config_dirs "testapp-extra" "$extra_dir"
    assert_success
    [[ ! -d "$extra_dir" ]]
}

# ═══════════════════════════════════════════════════════════════
# remove_apt_repo
# ═══════════════════════════════════════════════════════════════

@test "remove_apt_repo: removes list and keyring files" {
    # This calls sudo rm -f on several paths
    run remove_apt_repo "test-repo"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# remove_service
# ═══════════════════════════════════════════════════════════════

@test "remove_service: stops and disables system service" {
    mock_systemctl_noop

    run remove_service "test-service"
    assert_success
}

@test "remove_service: handles user services" {
    create_mock "systemctl" 0

    run remove_service "test-service" "true"
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# full_uninstall
# ═══════════════════════════════════════════════════════════════

@test "full_uninstall: orchestrates complete removal" {
    create_mock "apt-get" 0
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    mock_command_not_exists "zypper"
    mock_command_not_exists "apk"
    mock_command_not_exists "flatpak"
    mock_command_not_exists "snap"
    mock_command_not_exists "docker"

    run full_uninstall "test-module" "pkg1 pkg2"
    assert_success
    assert_output --partial "uninstalled"
}

@test "full_uninstall: calls flatpak removal when specified" {
    create_mock "apt-get" 0
    create_mock "flatpak" 0
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    mock_command_not_exists "zypper"
    mock_command_not_exists "apk"

    run full_uninstall "test-module" "pkg1" "com.example.App"
    assert_success
    assert_mock_called "flatpak"
}

@test "full_uninstall: removes config when requested" {
    mkdir -p "$HOME/.config/test-uninstall-cfg"

    create_mock "apt-get" 0
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    mock_command_not_exists "zypper"
    mock_command_not_exists "apk"
    mock_command_not_exists "flatpak"
    mock_command_not_exists "snap"
    mock_command_not_exists "docker"

    run full_uninstall "test-uninstall-cfg" "pkg1" "" "" "" "true"
    assert_success
    [[ ! -d "$HOME/.config/test-uninstall-cfg" ]]
}
