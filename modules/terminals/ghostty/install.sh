#!/bin/bash
# Ghostty Installation
# modules/terminals/ghostty/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_bullet() { echo "  • $1"; }
fi

install_ghostty() {
    print_step "Installing Ghostty..."

    if command -v ghostty &>/dev/null; then
        print_warning "Ghostty is already installed"
        ghostty --version
        return 0
    fi

    case "$ARCH" in
        amd64|arm64)
            # Check for official package first
            if apt-cache policy ghostty 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get update
                sudo apt-get install -y ghostty
                print_success "Ghostty installed via apt"
                return 0
            fi

            # Build from source (requires Zig)
            print_step "Building from source..."

            # Install build dependencies
            sudo apt-get update
            sudo apt-get install -y git libgtk-4-dev libadwaita-1-dev

            # Install Zig if not present
            if ! command -v zig &>/dev/null; then
                print_step "Installing Zig..."
                local zig_version="0.13.0"
                local zig_arch
                [[ "$ARCH" == "amd64" ]] && zig_arch="x86_64" || zig_arch="aarch64"

                wget -qO /tmp/zig.tar.xz "https://ziglang.org/download/${zig_version}/zig-linux-${zig_arch}-${zig_version}.tar.xz"
                sudo tar -xf /tmp/zig.tar.xz -C /opt
                sudo ln -sf /opt/zig-linux-${zig_arch}-${zig_version}/zig /usr/local/bin/zig
                rm /tmp/zig.tar.xz
            fi

            # Clone and build
            local build_dir="/tmp/ghostty-build"
            rm -rf "$build_dir"
            git clone --depth 1 https://github.com/ghostty-org/ghostty.git "$build_dir"
            cd "$build_dir"

            zig build -Doptimize=ReleaseFast
            sudo cp zig-out/bin/ghostty /usr/local/bin/

            # Install desktop entry
            sudo cp -r zig-out/share/* /usr/local/share/ 2>/dev/null || true

            rm -rf "$build_dir"
            ;;
        *)
            print_error "Ghostty not available for $ARCH"
            return 1
            ;;
    esac

    print_success "Ghostty installed"
}

configure_ghostty() {
    print_step "Configuring Ghostty..."

    local config_dir="$HOME/.config/ghostty"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/config" ]]; then
        cat > "$config_dir/config" << 'EOF'
# Font
font-family = monospace
font-size = 12

# Window
window-padding-x = 10
window-padding-y = 10
background-opacity = 0.95

# Colors (Catppuccin Mocha)
background = #1e1e2e
foreground = #cdd6f4

# Behavior
copy-on-select = true
confirm-close-surface = false
EOF
        print_success "Created default configuration"
    fi
}

main() {
    print_step "Installing Ghostty for $ARCH"

    install_ghostty
    configure_ghostty

    echo ""
    echo "════════════════════════════════════════════"
    echo "Ghostty Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v ghostty &>/dev/null; then
        print_success "Ghostty version: $(ghostty --version)"
    fi

    echo ""
    print_bullet "Config: ~/.config/ghostty/config"
    print_bullet "Run 'ghostty' to start"
    print_bullet "Native performance with GPU acceleration"
}

main "$@"
