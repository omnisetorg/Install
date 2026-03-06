#!/usr/bin/env bats
# Tests for lib/system/detect.sh

load "../helpers/test_helper"
load "../helpers/mock_commands"
load "../helpers/fixture_os_release"

setup() {
    setup_temp_dir
    setup_mock_bin
    disable_colors
    source_lib "ui/colors.sh"
    source_lib "ui/print.sh"
    source_lib "system/detect.sh"
}

teardown() {
    teardown_temp_dir
}

# ═══════════════════════════════════════════════════════════════
# detect_arch
# ═══════════════════════════════════════════════════════════════

@test "detect_arch: x86_64 → amd64" {
    mock_uname "x86_64"
    detect_arch
    [[ "$ARCH" == "amd64" ]]
    [[ "$ARCH_ALT" == "x86_64" ]]
}

@test "detect_arch: aarch64 → arm64" {
    mock_uname "aarch64"
    detect_arch
    [[ "$ARCH" == "arm64" ]]
    [[ "$ARCH_ALT" == "aarch64" ]]
}

@test "detect_arch: armv7l → armhf" {
    mock_uname "armv7l"
    detect_arch
    [[ "$ARCH" == "armhf" ]]
    [[ "$ARCH_ALT" == "armv7l" ]]
}

@test "detect_arch: i686 → i386" {
    mock_uname "i686"
    detect_arch
    [[ "$ARCH" == "i386" ]]
    [[ "$ARCH_ALT" == "i686" ]]
}

@test "detect_arch: unknown passthrough" {
    mock_uname "riscv64"
    detect_arch
    [[ "$ARCH" == "riscv64" ]]
    [[ "$ARCH_ALT" == "riscv64" ]]
}

@test "detect_arch: sets ARCH_RAW" {
    mock_uname "x86_64"
    detect_arch
    [[ "$ARCH_RAW" == "x86_64" ]]
}

# ═══════════════════════════════════════════════════════════════
# detect_distro — via os-release
# ═══════════════════════════════════════════════════════════════

@test "detect_distro: Ubuntu 22.04" {
    local fixture
    fixture=$(create_ubuntu_2204_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "ubuntu" ]]
    [[ "$DISTRO_VERSION" == "22.04" ]]
    [[ "$DISTRO_TYPE" == "debian" ]]
}

@test "detect_distro: Debian 12" {
    local fixture
    fixture=$(create_debian_12_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "debian" ]]
    [[ "$DISTRO_VERSION" == "12" ]]
    [[ "$DISTRO_TYPE" == "debian" ]]
}

@test "detect_distro: Linux Mint → debian type" {
    local fixture
    fixture=$(create_linuxmint_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "linuxmint" ]]
    [[ "$DISTRO_TYPE" == "debian" ]]
}

@test "detect_distro: Pop!_OS → debian type" {
    local fixture
    fixture=$(create_pop_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "pop" ]]
    [[ "$DISTRO_TYPE" == "debian" ]]
}

@test "detect_distro: Fedora 39" {
    local fixture
    fixture=$(create_fedora_39_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "fedora" ]]
    [[ "$DISTRO_VERSION" == "39" ]]
    [[ "$DISTRO_TYPE" == "rhel" ]]
}

@test "detect_distro: CentOS → rhel type" {
    local fixture
    fixture=$(create_centos_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "centos" ]]
    [[ "$DISTRO_TYPE" == "rhel" ]]
}

@test "detect_distro: Rocky → rhel type" {
    local fixture
    fixture=$(create_rocky_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "rocky" ]]
    [[ "$DISTRO_TYPE" == "rhel" ]]
}

@test "detect_distro: Arch Linux" {
    local fixture
    fixture=$(create_arch_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "arch" ]]
    [[ "$DISTRO_TYPE" == "arch" ]]
}

@test "detect_distro: Manjaro → arch type" {
    local fixture
    fixture=$(create_manjaro_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "manjaro" ]]
    [[ "$DISTRO_TYPE" == "arch" ]]
}

@test "detect_distro: openSUSE → suse type" {
    local fixture
    fixture=$(create_opensuse_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "opensuse-tumbleweed" ]]
    [[ "$DISTRO_TYPE" == "suse" ]]
}

@test "detect_distro: Alpine" {
    local fixture
    fixture=$(create_alpine_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "alpine" ]]
    [[ "$DISTRO_TYPE" == "alpine" ]]
}

@test "detect_distro: ID_LIKE fallback for debian derivative" {
    local fixture
    fixture=$(create_os_release_fixture "custom-distro" "1.0" "Custom Distro 1.0" "debian")
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "custom-distro" ]]
    [[ "$DISTRO_TYPE" == "debian" ]]
}

@test "detect_distro: ID_LIKE fallback for rhel derivative" {
    local fixture
    fixture=$(create_os_release_fixture "custom-rhel" "1.0" "Custom RHEL 1.0" "rhel fedora")
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_ID" == "custom-rhel" ]]
    [[ "$DISTRO_TYPE" == "rhel" ]]
}

@test "detect_distro: unknown when no files exist" {
    OMNISET_OS_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_LSB_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_DEBIAN_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    OMNISET_REDHAT_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent4" \
    detect_distro
    [[ "$DISTRO_ID" == "unknown" ]]
    [[ "$DISTRO_TYPE" == "unknown" ]]
}

@test "detect_distro: PRETTY_NAME populated" {
    local fixture
    fixture=$(create_ubuntu_2204_fixture)
    OMNISET_OS_RELEASE_FILE="$fixture" detect_distro
    [[ "$DISTRO_NAME" == "Ubuntu 22.04.3 LTS" ]]
}

# ═══════════════════════════════════════════════════════════════
# detect_distro — fallback files
# ═══════════════════════════════════════════════════════════════

@test "detect_distro: fallback to lsb-release" {
    require_bash4  # ${,,} lowercase syntax
    local fixture
    fixture=$(create_lsb_release_fixture "Ubuntu" "22.04" "Ubuntu 22.04 LTS")
    OMNISET_OS_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_LSB_RELEASE_FILE="$fixture" \
    detect_distro
    [[ "$DISTRO_ID" == "ubuntu" ]]
}

@test "detect_distro: fallback to debian_version" {
    local fixture
    fixture=$(create_debian_version_fixture "12.4")
    OMNISET_OS_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_LSB_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_DEBIAN_VERSION_FILE="$fixture" \
    detect_distro
    [[ "$DISTRO_ID" == "debian" ]]
    [[ "$DISTRO_VERSION" == "12.4" ]]
}

@test "detect_distro: fallback to redhat-release" {
    local fixture
    fixture=$(create_redhat_release_fixture "Red Hat Enterprise Linux release 9.3")
    OMNISET_OS_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_LSB_RELEASE_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_DEBIAN_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    OMNISET_REDHAT_RELEASE_FILE="$fixture" \
    detect_distro
    [[ "$DISTRO_ID" == "rhel" ]]
}

# ═══════════════════════════════════════════════════════════════
# detect_desktop
# ═══════════════════════════════════════════════════════════════

@test "detect_desktop: GNOME normalization" {
    require_bash4  # ${,,} lowercase syntax
    XDG_CURRENT_DESKTOP="GNOME" XDG_SESSION_TYPE="wayland" detect_desktop
    [[ "$DESKTOP_ENV" == "gnome" ]]
    [[ "$SESSION_TYPE" == "wayland" ]]
}

@test "detect_desktop: KDE/Plasma normalization" {
    require_bash4  # ${,,} lowercase syntax
    XDG_CURRENT_DESKTOP="KDE" XDG_SESSION_TYPE="x11" detect_desktop
    [[ "$DESKTOP_ENV" == "kde" ]]
}

@test "detect_desktop: Plasma normalization" {
    require_bash4  # ${,,} lowercase syntax
    XDG_CURRENT_DESKTOP="Plasma" XDG_SESSION_TYPE="wayland" detect_desktop
    [[ "$DESKTOP_ENV" == "kde" ]]
}

@test "detect_desktop: i3 → tiling-wm" {
    require_bash4  # ${,,} lowercase syntax
    XDG_CURRENT_DESKTOP="i3" XDG_SESSION_TYPE="x11" detect_desktop
    [[ "$DESKTOP_ENV" == "tiling-wm" ]]
}

@test "detect_desktop: sway → tiling-wm" {
    require_bash4  # ${,,} lowercase syntax
    XDG_CURRENT_DESKTOP="sway" XDG_SESSION_TYPE="wayland" detect_desktop
    [[ "$DESKTOP_ENV" == "tiling-wm" ]]
}

@test "detect_desktop: headless when no DISPLAY or WAYLAND_DISPLAY" {
    require_bash4  # ${,,} lowercase syntax
    unset DISPLAY WAYLAND_DISPLAY
    XDG_CURRENT_DESKTOP="unknown" XDG_SESSION_TYPE="tty" detect_desktop
    [[ "$IS_HEADLESS" == "true" ]]
}

@test "detect_desktop: not headless when DISPLAY set" {
    require_bash4  # ${,,} lowercase syntax
    DISPLAY=":0" XDG_CURRENT_DESKTOP="gnome" detect_desktop
    [[ "$IS_HEADLESS" == "false" ]]
}

@test "detect_desktop: session type from XDG_SESSION_TYPE" {
    require_bash4  # ${,,} lowercase syntax
    XDG_CURRENT_DESKTOP="GNOME" XDG_SESSION_TYPE="wayland" detect_desktop
    [[ "$DISPLAY_SERVER" == "wayland" ]]
}

# ═══════════════════════════════════════════════════════════════
# detect_network
# ═══════════════════════════════════════════════════════════════

@test "detect_network: internet available via ping" {
    mock_ping_success
    mock_ip_route "192.168.1.100"
    detect_network
    [[ "$HAS_INTERNET" == "true" ]]
}

@test "detect_network: no internet when ping fails" {
    mock_ping_failure
    mock_command_not_exists "ip"
    detect_network
    [[ "$HAS_INTERNET" == "false" ]]
}

# ═══════════════════════════════════════════════════════════════
# detect_virtualization
# ═══════════════════════════════════════════════════════════════

@test "detect_virtualization: WSL detected via proc/version" {
    local fixture
    fixture=$(create_proc_version_fixture "Linux version 5.15.0 (Microsoft@Microsoft.com)")
    OMNISET_PROC_VERSION_FILE="$fixture" \
    OMNISET_DOCKERENV_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_CGROUP_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_CPUINFO_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    detect_virtualization
    [[ "$VIRT_TYPE" == "wsl" ]]
    [[ "$IS_WSL" == "true" ]]
    [[ "$IS_VM" == "true" ]]
}

@test "detect_virtualization: Docker detected via dockerenv" {
    touch "${TEST_TEMP_DIR}/dockerenv"
    OMNISET_PROC_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_DOCKERENV_FILE="${TEST_TEMP_DIR}/dockerenv" \
    OMNISET_CGROUP_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_CPUINFO_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    detect_virtualization
    [[ "$VIRT_TYPE" == "docker" ]]
    [[ "$IS_CONTAINER" == "true" ]]
}

@test "detect_virtualization: Docker detected via cgroup" {
    local fixture
    fixture=$(create_cgroup_fixture "12:memory:/docker/abc123")
    OMNISET_PROC_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_DOCKERENV_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_CGROUP_FILE="$fixture" \
    OMNISET_CPUINFO_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    detect_virtualization
    [[ "$VIRT_TYPE" == "docker" ]]
    [[ "$IS_CONTAINER" == "true" ]]
}

@test "detect_virtualization: LXC detected via cgroup" {
    local fixture
    fixture=$(create_cgroup_fixture "12:memory:/lxc/container1")
    OMNISET_PROC_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_DOCKERENV_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_CGROUP_FILE="$fixture" \
    OMNISET_CPUINFO_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    detect_virtualization
    [[ "$VIRT_TYPE" == "lxc" ]]
    [[ "$IS_CONTAINER" == "true" ]]
}

@test "detect_virtualization: Kubernetes detected via cgroup" {
    local fixture
    fixture=$(create_cgroup_fixture "12:memory:/kubepods/pod-xyz")
    OMNISET_PROC_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_DOCKERENV_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_CGROUP_FILE="$fixture" \
    OMNISET_CPUINFO_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    detect_virtualization
    [[ "$VIRT_TYPE" == "kubernetes" ]]
    [[ "$IS_CONTAINER" == "true" ]]
}

@test "detect_virtualization: bare-metal when no indicators" {
    # Remove systemd-detect-virt from PATH
    mock_command_not_exists "systemd-detect-virt"
    OMNISET_PROC_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_DOCKERENV_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_CGROUP_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    OMNISET_CPUINFO_FILE="${TEST_TEMP_DIR}/nonexistent4" \
    detect_virtualization
    [[ "$VIRT_TYPE" == "bare-metal" ]]
    [[ "$IS_CONTAINER" == "false" ]]
    [[ "$IS_VM" == "false" ]]
}

@test "detect_virtualization: hypervisor detected via cpuinfo" {
    local fixture
    fixture=$(create_cpuinfo_fixture "flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat hypervisor")
    mock_command_not_exists "systemd-detect-virt"
    OMNISET_PROC_VERSION_FILE="${TEST_TEMP_DIR}/nonexistent" \
    OMNISET_DOCKERENV_FILE="${TEST_TEMP_DIR}/nonexistent2" \
    OMNISET_CGROUP_FILE="${TEST_TEMP_DIR}/nonexistent3" \
    OMNISET_CPUINFO_FILE="$fixture" \
    detect_virtualization
    [[ "$IS_VM" == "true" ]]
}
