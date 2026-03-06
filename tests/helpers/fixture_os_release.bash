#!/bin/bash
# OmniSet Test OS-Release Fixtures
# Generates fake /etc/os-release style files for testing detect_distro

# Create an os-release fixture file
# Usage: create_os_release_fixture "distro_id" "version" "pretty_name" "id_like"
create_os_release_fixture() {
    local distro_id="$1"
    local version="$2"
    local pretty_name="$3"
    local id_like="${4:-$distro_id}"

    local fixture_file="${TEST_TEMP_DIR}/os-release"

    cat > "$fixture_file" << OS_RELEASE
ID=${distro_id}
VERSION_ID="${version}"
PRETTY_NAME="${pretty_name}"
ID_LIKE="${id_like}"
NAME="${pretty_name}"
VERSION="${version}"
OS_RELEASE

    echo "$fixture_file"
}

# Create an lsb-release fixture file
create_lsb_release_fixture() {
    local distrib_id="$1"
    local release="$2"
    local description="$3"

    local fixture_file="${TEST_TEMP_DIR}/lsb-release"

    cat > "$fixture_file" << LSB_RELEASE
DISTRIB_ID=${distrib_id}
DISTRIB_RELEASE=${release}
DISTRIB_DESCRIPTION="${description}"
DISTRIB_CODENAME=test
LSB_RELEASE

    echo "$fixture_file"
}

# Create a debian_version fixture file
create_debian_version_fixture() {
    local version="$1"
    local fixture_file="${TEST_TEMP_DIR}/debian_version"
    echo "$version" > "$fixture_file"
    echo "$fixture_file"
}

# Create a redhat-release fixture file
create_redhat_release_fixture() {
    local content="$1"
    local fixture_file="${TEST_TEMP_DIR}/redhat-release"
    echo "$content" > "$fixture_file"
    echo "$fixture_file"
}

# Create proc/version fixture (for WSL detection)
create_proc_version_fixture() {
    local content="$1"
    local fixture_file="${TEST_TEMP_DIR}/proc_version"
    echo "$content" > "$fixture_file"
    echo "$fixture_file"
}

# Create cgroup fixture (for container detection)
create_cgroup_fixture() {
    local content="$1"
    local fixture_file="${TEST_TEMP_DIR}/cgroup"
    echo "$content" > "$fixture_file"
    echo "$fixture_file"
}

# Create cpuinfo fixture
create_cpuinfo_fixture() {
    local content="$1"
    local fixture_file="${TEST_TEMP_DIR}/cpuinfo"
    echo "$content" > "$fixture_file"
    echo "$fixture_file"
}

# ── Pre-built distro fixtures ──────────────────────────────────

create_ubuntu_2204_fixture() {
    create_os_release_fixture "ubuntu" "22.04" "Ubuntu 22.04.3 LTS" "debian"
}

create_debian_12_fixture() {
    create_os_release_fixture "debian" "12" "Debian GNU/Linux 12 (bookworm)" "debian"
}

create_fedora_39_fixture() {
    create_os_release_fixture "fedora" "39" "Fedora Linux 39" "fedora"
}

create_arch_fixture() {
    create_os_release_fixture "arch" "" "Arch Linux" "arch"
}

create_manjaro_fixture() {
    create_os_release_fixture "manjaro" "23.1" "Manjaro Linux" "arch"
}

create_opensuse_fixture() {
    create_os_release_fixture "opensuse-tumbleweed" "20240101" "openSUSE Tumbleweed" "suse"
}

create_alpine_fixture() {
    create_os_release_fixture "alpine" "3.19" "Alpine Linux v3.19" "alpine"
}

create_linuxmint_fixture() {
    create_os_release_fixture "linuxmint" "21.3" "Linux Mint 21.3" "ubuntu debian"
}

create_pop_fixture() {
    create_os_release_fixture "pop" "22.04" "Pop!_OS 22.04 LTS" "ubuntu debian"
}

create_centos_fixture() {
    create_os_release_fixture "centos" "9" "CentOS Stream 9" "rhel fedora"
}

create_rocky_fixture() {
    create_os_release_fixture "rocky" "9.3" "Rocky Linux 9.3" "rhel centos fedora"
}
