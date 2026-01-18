#!/bin/bash
# OmniSet v2 - System Detection
# lib/system/detect.sh

# ═══════════════════════════════════════════════════════════════
# Distribution Detection
# ═══════════════════════════════════════════════════════════════

detect_distro() {
    # Reset values
    export DISTRO_ID=""
    export DISTRO_VERSION=""
    export DISTRO_NAME=""
    export DISTRO_FAMILY=""
    export DISTRO_TYPE=""

    # Try /etc/os-release first (standard on modern distros)
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_VERSION="${VERSION_ID:-}"
        DISTRO_NAME="${PRETTY_NAME:-$ID}"
        DISTRO_FAMILY="${ID_LIKE:-$ID}"
    elif [[ -f /etc/lsb-release ]]; then
        # shellcheck source=/dev/null
        source /etc/lsb-release
        DISTRO_ID="${DISTRIB_ID,,}"  # lowercase
        DISTRO_VERSION="${DISTRIB_RELEASE:-}"
        DISTRO_NAME="${DISTRIB_DESCRIPTION:-$DISTRIB_ID}"
        DISTRO_FAMILY="$DISTRO_ID"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO_ID="debian"
        DISTRO_VERSION=$(cat /etc/debian_version)
        DISTRO_NAME="Debian $DISTRO_VERSION"
        DISTRO_FAMILY="debian"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO_ID="rhel"
        DISTRO_NAME=$(cat /etc/redhat-release)
        DISTRO_FAMILY="rhel fedora"
    else
        DISTRO_ID="unknown"
        DISTRO_NAME="Unknown Linux"
        DISTRO_FAMILY="unknown"
    fi

    # Normalize to family type for package management
    case "$DISTRO_ID" in
        ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian|neon)
            DISTRO_TYPE="debian"
            ;;
        fedora|rhel|centos|rocky|alma|oracle)
            DISTRO_TYPE="rhel"
            ;;
        arch|manjaro|endeavouros|garuda|artix)
            DISTRO_TYPE="arch"
            ;;
        opensuse*|suse*|sles)
            DISTRO_TYPE="suse"
            ;;
        alpine)
            DISTRO_TYPE="alpine"
            ;;
        void)
            DISTRO_TYPE="void"
            ;;
        gentoo)
            DISTRO_TYPE="gentoo"
            ;;
        *)
            # Try to detect from family
            if [[ "$DISTRO_FAMILY" == *"debian"* ]]; then
                DISTRO_TYPE="debian"
            elif [[ "$DISTRO_FAMILY" == *"rhel"* ]] || [[ "$DISTRO_FAMILY" == *"fedora"* ]]; then
                DISTRO_TYPE="rhel"
            elif [[ "$DISTRO_FAMILY" == *"arch"* ]]; then
                DISTRO_TYPE="arch"
            else
                DISTRO_TYPE="unknown"
            fi
            ;;
    esac

    export DISTRO_ID DISTRO_VERSION DISTRO_NAME DISTRO_FAMILY DISTRO_TYPE
}

# ═══════════════════════════════════════════════════════════════
# Architecture Detection
# ═══════════════════════════════════════════════════════════════

detect_arch() {
    local raw_arch
    raw_arch=$(uname -m)

    # Normalize architecture names
    case "$raw_arch" in
        x86_64|amd64)
            export ARCH="amd64"
            export ARCH_ALT="x86_64"
            ;;
        aarch64|arm64)
            export ARCH="arm64"
            export ARCH_ALT="aarch64"
            ;;
        armv7l|armhf)
            export ARCH="armhf"
            export ARCH_ALT="armv7l"
            ;;
        armv6l)
            export ARCH="armel"
            export ARCH_ALT="armv6l"
            ;;
        i386|i686)
            export ARCH="i386"
            export ARCH_ALT="i686"
            ;;
        *)
            export ARCH="$raw_arch"
            export ARCH_ALT="$raw_arch"
            ;;
    esac

    export ARCH_RAW="$raw_arch"
}

# ═══════════════════════════════════════════════════════════════
# Virtualization Detection
# ═══════════════════════════════════════════════════════════════

detect_virtualization() {
    export VIRT_TYPE="bare-metal"
    export IS_CONTAINER=false
    export IS_VM=false
    export IS_WSL=false

    # Check for WSL
    if grep -qi "microsoft" /proc/version 2>/dev/null; then
        VIRT_TYPE="wsl"
        IS_VM=true
        IS_WSL=true
        return
    fi

    # Check for Docker
    if [[ -f /.dockerenv ]]; then
        VIRT_TYPE="docker"
        IS_CONTAINER=true
        return
    fi

    # Check for container via cgroup
    if grep -q "/docker\|/lxc\|/kubepods" /proc/1/cgroup 2>/dev/null; then
        IS_CONTAINER=true
        if grep -q "/docker" /proc/1/cgroup 2>/dev/null; then
            VIRT_TYPE="docker"
        elif grep -q "/lxc" /proc/1/cgroup 2>/dev/null; then
            VIRT_TYPE="lxc"
        elif grep -q "/kubepods" /proc/1/cgroup 2>/dev/null; then
            VIRT_TYPE="kubernetes"
        fi
        return
    fi

    # Check for systemd-detect-virt
    if command -v systemd-detect-virt &>/dev/null; then
        local detected
        detected=$(systemd-detect-virt 2>/dev/null)
        if [[ "$detected" != "none" ]]; then
            VIRT_TYPE="$detected"
            case "$detected" in
                docker|lxc|lxc-libvirt|systemd-nspawn|podman)
                    IS_CONTAINER=true
                    ;;
                *)
                    IS_VM=true
                    ;;
            esac
            return
        fi
    fi

    # Check CPU info for hypervisors
    if grep -q "hypervisor" /proc/cpuinfo 2>/dev/null; then
        IS_VM=true

        # Try to identify specific hypervisor
        if grep -q "QEMU" /proc/cpuinfo 2>/dev/null; then
            VIRT_TYPE="qemu"
        elif [[ -d /proc/xen ]]; then
            VIRT_TYPE="xen"
        elif [[ -f /sys/class/dmi/id/product_name ]]; then
            local product
            product=$(cat /sys/class/dmi/id/product_name 2>/dev/null)
            case "$product" in
                *VirtualBox*) VIRT_TYPE="virtualbox" ;;
                *VMware*) VIRT_TYPE="vmware" ;;
                *KVM*) VIRT_TYPE="kvm" ;;
                *Parallels*) VIRT_TYPE="parallels" ;;
                *Hyper-V*) VIRT_TYPE="hyperv" ;;
            esac
        fi
    fi

    # Check for AWS EC2
    if [[ -f /sys/hypervisor/uuid ]] && head -c 3 /sys/hypervisor/uuid 2>/dev/null | grep -qi "ec2"; then
        VIRT_TYPE="aws-ec2"
        IS_VM=true
    fi
}

# ═══════════════════════════════════════════════════════════════
# Hardware Detection
# ═══════════════════════════════════════════════════════════════

detect_hardware() {
    # CPU
    if [[ -f /proc/cpuinfo ]]; then
        export CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo 2>/dev/null | cut -d: -f2 | xargs)
        export CPU_CORES=$(nproc 2>/dev/null || grep -c "processor" /proc/cpuinfo)
    else
        export CPU_MODEL="Unknown"
        export CPU_CORES=1
    fi

    # Memory
    if command -v free &>/dev/null; then
        export MEM_TOTAL_KB=$(free | awk '/^Mem:/ {print $2}')
        export MEM_AVAILABLE_KB=$(free | awk '/^Mem:/ {print $7}')
        export MEM_TOTAL_MB=$((MEM_TOTAL_KB / 1024))
        export MEM_AVAILABLE_MB=$((MEM_AVAILABLE_KB / 1024))
    else
        export MEM_TOTAL_MB=0
        export MEM_AVAILABLE_MB=0
    fi

    # Disk - root filesystem
    if command -v df &>/dev/null; then
        local df_output
        df_output=$(df -BM / 2>/dev/null | tail -1)
        export DISK_TOTAL_MB=$(echo "$df_output" | awk '{print $2}' | tr -d 'M')
        export DISK_AVAILABLE_MB=$(echo "$df_output" | awk '{print $4}' | tr -d 'M')
        export DISK_USED_PERCENT=$(echo "$df_output" | awk '{print $5}' | tr -d '%')
    else
        export DISK_TOTAL_MB=0
        export DISK_AVAILABLE_MB=0
        export DISK_USED_PERCENT=0
    fi
}

# ═══════════════════════════════════════════════════════════════
# Desktop Environment Detection
# ═══════════════════════════════════════════════════════════════

detect_desktop() {
    export DESKTOP_ENV="${XDG_CURRENT_DESKTOP:-unknown}"
    export SESSION_TYPE="${XDG_SESSION_TYPE:-unknown}"
    export DISPLAY_SERVER="$SESSION_TYPE"

    # Normalize desktop environment names
    case "${DESKTOP_ENV,,}" in
        gnome*) DESKTOP_ENV="gnome" ;;
        kde*|plasma*) DESKTOP_ENV="kde" ;;
        xfce*) DESKTOP_ENV="xfce" ;;
        lxde*) DESKTOP_ENV="lxde" ;;
        lxqt*) DESKTOP_ENV="lxqt" ;;
        mate*) DESKTOP_ENV="mate" ;;
        cinnamon*) DESKTOP_ENV="cinnamon" ;;
        budgie*) DESKTOP_ENV="budgie" ;;
        unity*) DESKTOP_ENV="unity" ;;
        deepin*) DESKTOP_ENV="deepin" ;;
        pantheon*) DESKTOP_ENV="pantheon" ;;
        i3*|sway*|bspwm*|awesome*|openbox*)
            DESKTOP_ENV="tiling-wm"
            ;;
    esac

    # Check if running headless
    if [[ -z "${DISPLAY:-}" ]] && [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        export IS_HEADLESS=true
    else
        export IS_HEADLESS=false
    fi
}

# ═══════════════════════════════════════════════════════════════
# Network Detection
# ═══════════════════════════════════════════════════════════════

detect_network() {
    export HAS_INTERNET=false
    export PRIMARY_IP=""

    # Check internet connectivity
    if ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        HAS_INTERNET=true
    elif ping -c 1 -W 3 1.1.1.1 &>/dev/null; then
        HAS_INTERNET=true
    fi

    # Get primary IP
    if command -v ip &>/dev/null; then
        PRIMARY_IP=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' || echo "")
    fi
}

# ═══════════════════════════════════════════════════════════════
# Full System Detection
# ═══════════════════════════════════════════════════════════════

detect_system() {
    detect_distro
    detect_arch
    detect_virtualization
    detect_hardware
    detect_desktop
    detect_network
}

# Print system summary
print_system_summary() {
    print_header "System Information"

    print_kv "Distribution" "$DISTRO_NAME"
    print_kv "Type" "$DISTRO_TYPE"
    print_kv "Architecture" "$ARCH ($ARCH_ALT)"
    print_kv "Virtualization" "$VIRT_TYPE"
    print_kv "Desktop" "$DESKTOP_ENV ($SESSION_TYPE)"
    print_kv "CPU" "$CPU_MODEL"
    print_kv "CPU Cores" "$CPU_CORES"
    print_kv "Memory" "${MEM_TOTAL_MB}MB (${MEM_AVAILABLE_MB}MB available)"
    print_kv "Disk" "${DISK_AVAILABLE_MB}MB free (${DISK_USED_PERCENT}% used)"
    print_kv "Network" "$([[ $HAS_INTERNET == true ]] && echo "Connected ($PRIMARY_IP)" || echo "No internet")"

    if [[ "$IS_WSL" == true ]]; then
        print_warning "Running in WSL - some features may be limited"
    fi

    if [[ "$IS_CONTAINER" == true ]]; then
        print_warning "Running in container - some features may be limited"
    fi
}
