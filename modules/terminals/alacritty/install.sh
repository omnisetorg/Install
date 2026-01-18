#!/bin/bash
# Alacritty Installation
# modules/terminals/alacritty/install.sh

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

install_alacritty() {
    print_step "Installing Alacritty..."

    if command -v alacritty &>/dev/null; then
        print_warning "Alacritty is already installed"
        alacritty --version
        return 0
    fi

    # Try apt first (Ubuntu 24.04+)
    if apt-cache policy alacritty 2>/dev/null | grep -q "Candidate: [0-9]"; then
        sudo apt-get update
        sudo apt-get install -y alacritty
        print_success "Alacritty installed via apt"
        return 0
    fi

    # Try snap
    if command -v snap &>/dev/null; then
        sudo snap install alacritty --classic
        print_success "Alacritty installed via snap"
        return 0
    fi

    # Manual build from source
    print_step "Building from source..."

    # Install dependencies
    sudo apt-get update
    sudo apt-get install -y cmake pkg-config libfreetype6-dev libfontconfig1-dev \
        libxcb-xfixes0-dev libxkbcommon-dev python3

    # Install Rust if not present
    if ! command -v cargo &>/dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi

    cargo install alacritty

    # Install desktop entry
    if [[ -f "$HOME/.cargo/bin/alacritty" ]]; then
        sudo ln -sf "$HOME/.cargo/bin/alacritty" /usr/local/bin/alacritty
    fi

    print_success "Alacritty installed from source"
}

configure_alacritty() {
    print_step "Configuring Alacritty..."

    local config_dir="$HOME/.config/alacritty"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/alacritty.toml" ]]; then
        cat > "$config_dir/alacritty.toml" << 'EOF'
[window]
padding = { x = 10, y = 10 }
dynamic_padding = true
decorations = "full"
opacity = 0.95

[font]
size = 12.0

[font.normal]
family = "monospace"
style = "Regular"

[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"
EOF
        print_success "Created default configuration"
    fi
}

main() {
    print_step "Installing Alacritty for $ARCH"

    install_alacritty
    configure_alacritty

    echo ""
    echo "════════════════════════════════════════════"
    echo "Alacritty Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v alacritty &>/dev/null; then
        print_success "Alacritty version: $(alacritty --version)"
    fi

    echo ""
    print_bullet "Config: ~/.config/alacritty/alacritty.toml"
    print_bullet "Run 'alacritty' to start"
}

main "$@"
