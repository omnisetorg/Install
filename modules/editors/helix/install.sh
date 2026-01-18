#!/bin/bash
# Helix Editor Installation
# modules/editors/helix/install.sh

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

install_helix() {
    print_step "Installing Helix..."

    if command -v hx &>/dev/null; then
        print_warning "Helix is already installed"
        hx --version
        return 0
    fi

    # Try apt first (Ubuntu 24.04+)
    if apt-cache policy helix 2>/dev/null | grep -q "Candidate: [0-9]"; then
        sudo apt-get update
        sudo apt-get install -y helix
        print_success "Helix installed via apt"
        return 0
    fi

    # Try snap
    if command -v snap &>/dev/null; then
        sudo snap install helix --classic
        print_success "Helix installed via snap"
        return 0
    fi

    # Manual installation
    case "$ARCH" in
        amd64)
            local arch_name="x86_64"
            ;;
        arm64)
            local arch_name="aarch64"
            ;;
        *)
            print_error "Helix not available for $ARCH"
            return 1
            ;;
    esac

    local version
    version=$(curl -s "https://api.github.com/repos/helix-editor/helix/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    local url="https://github.com/helix-editor/helix/releases/download/${version}/helix-${version}-${arch_name}-linux.tar.xz"

    wget -qO /tmp/helix.tar.xz "$url"
    sudo tar -xf /tmp/helix.tar.xz -C /opt
    sudo ln -sf /opt/helix-${version}-${arch_name}-linux/hx /usr/local/bin/hx

    # Set runtime path
    echo "export HELIX_RUNTIME=/opt/helix-${version}-${arch_name}-linux/runtime" >> ~/.bashrc

    rm /tmp/helix.tar.xz

    print_success "Helix installed"
}

configure_helix() {
    print_step "Configuring Helix..."

    local config_dir="$HOME/.config/helix"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/config.toml" ]]; then
        cat > "$config_dir/config.toml" << 'EOF'
theme = "catppuccin_mocha"

[editor]
line-number = "relative"
mouse = true
cursorline = true
auto-save = true
auto-format = true
completion-trigger-len = 1
idle-timeout = 50
true-color = true
color-modes = true

[editor.cursor-shape]
insert = "bar"
normal = "block"
select = "underline"

[editor.statusline]
left = ["mode", "spinner", "file-name", "file-modification-indicator"]
center = []
right = ["diagnostics", "selections", "position", "file-encoding", "file-line-ending", "file-type"]

[editor.lsp]
display-messages = true
display-inlay-hints = true

[editor.indent-guides]
render = true
character = "│"

[keys.normal]
C-s = ":w"
C-q = ":q"
space.f = "file_picker"
space.b = "buffer_picker"
EOF
        print_success "Created default configuration"
    fi
}

fetch_grammars() {
    print_step "Fetching tree-sitter grammars..."

    if command -v hx &>/dev/null; then
        hx --grammar fetch 2>/dev/null || true
        hx --grammar build 2>/dev/null || true
        print_success "Grammars fetched"
    fi
}

main() {
    print_step "Installing Helix for $ARCH"

    install_helix
    configure_helix
    fetch_grammars

    echo ""
    echo "════════════════════════════════════════════"
    echo "Helix Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v hx &>/dev/null; then
        print_success "Helix version: $(hx --version)"
    fi

    echo ""
    print_bullet "Run 'hx' to start"
    print_bullet "Config: ~/.config/helix/config.toml"
    print_bullet "Press Space for command menu"
    print_bullet "Built-in LSP and tree-sitter support"
}

main "$@"
