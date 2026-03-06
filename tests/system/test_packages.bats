#!/usr/bin/env bats
# Tests for lib/system/packages.sh

load "../helpers/test_helper"
load "../helpers/mock_commands"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    source_lib "system/detect.sh"
    source_lib "system/packages.sh"

    # Create common mock commands
    create_sudo_noop
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# detect_package_manager
# ═══════════════════════════════════════════════════════════════

@test "detect_package_manager: debian → apt" {
    export DISTRO_TYPE="debian"
    detect_package_manager
    [[ "$PKG_MANAGER" == "apt" ]]
}

@test "detect_package_manager: rhel with dnf → dnf" {
    export DISTRO_TYPE="rhel"
    create_mock "dnf" 0
    detect_package_manager
    [[ "$PKG_MANAGER" == "dnf" ]]
}

@test "detect_package_manager: rhel without dnf → yum" {
    export DISTRO_TYPE="rhel"
    mock_command_not_exists "dnf"
    create_mock "yum" 0
    detect_package_manager
    [[ "$PKG_MANAGER" == "yum" ]]
}

@test "detect_package_manager: arch → pacman" {
    export DISTRO_TYPE="arch"
    detect_package_manager
    [[ "$PKG_MANAGER" == "pacman" ]]
}

@test "detect_package_manager: suse → zypper" {
    export DISTRO_TYPE="suse"
    detect_package_manager
    [[ "$PKG_MANAGER" == "zypper" ]]
}

@test "detect_package_manager: alpine → apk" {
    export DISTRO_TYPE="alpine"
    detect_package_manager
    [[ "$PKG_MANAGER" == "apk" ]]
}

@test "detect_package_manager: fallback detects apt-get" {
    export DISTRO_TYPE="unknown"
    create_mock "apt-get" 0
    detect_package_manager
    [[ "$PKG_MANAGER" == "apt" ]]
}

@test "detect_package_manager: fails when no package manager found" {
    export DISTRO_TYPE="unknown"
    mock_command_not_exists "apt-get"
    mock_command_not_exists "dnf"
    mock_command_not_exists "yum"
    mock_command_not_exists "pacman"
    mock_command_not_exists "zypper"
    mock_command_not_exists "apk"

    run detect_package_manager
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# _setup_* functions
# ═══════════════════════════════════════════════════════════════

@test "_setup_apt: sets correct PKG_INSTALL" {
    _setup_apt
    [[ "$PKG_INSTALL" == "sudo apt-get install -y" ]]
}

@test "_setup_apt: sets correct PKG_REMOVE" {
    _setup_apt
    [[ "$PKG_REMOVE" == "sudo apt-get remove -y" ]]
}

@test "_setup_dnf: sets correct PKG_INSTALL" {
    _setup_dnf
    [[ "$PKG_INSTALL" == "sudo dnf install -y" ]]
}

@test "_setup_pacman: sets correct PKG_INSTALL" {
    _setup_pacman
    [[ "$PKG_INSTALL" == "sudo pacman -S --noconfirm" ]]
}

@test "_setup_zypper: sets correct PKG_INSTALL" {
    _setup_zypper
    [[ "$PKG_INSTALL" == "sudo zypper install -y" ]]
}

@test "_setup_apk: sets correct PKG_INSTALL" {
    _setup_apk
    [[ "$PKG_INSTALL" == "sudo apk add" ]]
}

# ═══════════════════════════════════════════════════════════════
# pkg_install / pkg_remove
# ═══════════════════════════════════════════════════════════════

@test "pkg_install: calls correct command" {
    export PKG_INSTALL="echo INSTALL"
    run pkg_install "vim" "git"
    assert_success
    assert_output --partial "INSTALL vim git"
}

@test "pkg_install: handles empty args gracefully" {
    run pkg_install
    assert_success
    assert_output --partial "No packages specified"
}

@test "pkg_remove: calls correct command" {
    export PKG_REMOVE="echo REMOVE"
    run pkg_remove "vim"
    assert_success
    assert_output --partial "REMOVE vim"
}

@test "pkg_remove: handles empty args" {
    run pkg_remove
    assert_success
}

# ═══════════════════════════════════════════════════════════════
# pkg_is_installed
# ═══════════════════════════════════════════════════════════════

@test "pkg_is_installed: dpkg check for apt" {
    export PKG_MANAGER="apt"
    mock_dpkg_installed "vim"

    run pkg_is_installed "vim"
    assert_success
}

@test "pkg_is_installed: rpm check for dnf" {
    export PKG_MANAGER="dnf"
    create_mock "rpm" 0  # rpm -q succeeds → package installed

    run pkg_is_installed "vim"
    assert_success
}

@test "pkg_is_installed: pacman check" {
    export PKG_MANAGER="pacman"
    create_mock "pacman" 0  # pacman -Q succeeds

    run pkg_is_installed "vim"
    assert_success
}

@test "pkg_is_installed: returns 1 for unknown manager" {
    export PKG_MANAGER="unknown"
    run pkg_is_installed "vim"
    assert_failure
}

# ═══════════════════════════════════════════════════════════════
# install_deb
# ═══════════════════════════════════════════════════════════════

@test "install_deb: works on apt" {
    export PKG_MANAGER="apt"
    create_mock "dpkg" 0
    create_mock "apt-get" 0

    run install_deb "/tmp/test.deb"
    assert_success
}

@test "install_deb: fails on pacman" {
    export PKG_MANAGER="pacman"
    mock_command_not_exists "alien"

    run install_deb "/tmp/test.deb"
    assert_failure
    assert_output --partial "Cannot install .deb"
}

# ═══════════════════════════════════════════════════════════════
# add_apt_repo
# ═══════════════════════════════════════════════════════════════

@test "add_apt_repo: fails on non-apt system" {
    export PKG_MANAGER="pacman"
    run add_apt_repo "deb http://example.com stable main"
    assert_failure
    assert_output --partial "only works on Debian"
}
