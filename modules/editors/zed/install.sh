#!/bin/bash
# Zed Editor Installation
# modules/editors/zed/install.sh

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

install_zed() {
    print_step "Installing Zed..."

    if command -v zed &>/dev/null || [[ -f "$HOME/.local/bin/zed" ]]; then
        print_warning "Zed is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64|arm64)
            # Official installer
            curl -fsSL https://zed.dev/install.sh | sh
            ;;
        *)
            print_error "Zed not available for $ARCH"
            return 1
            ;;
    esac

    print_success "Zed installed"
}

configure_zed() {
    print_step "Configuring Zed..."

    local config_dir="$HOME/.config/zed"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/settings.json" ]]; then
        cat > "$config_dir/settings.json" << 'EOF'
{
  "theme": "One Dark",
  "ui_font_size": 14,
  "buffer_font_size": 13,
  "buffer_font_family": "JetBrains Mono",
  "format_on_save": "on",
  "autosave": "on_focus_change",
  "vim_mode": false,
  "tab_size": 2,
  "soft_wrap": "editor_width",
  "terminal": {
    "font_size": 13,
    "font_family": "JetBrains Mono"
  }
}
EOF
        print_success "Created default configuration"
    fi
}

main() {
    print_step "Installing Zed for $ARCH"

    install_zed
    configure_zed

    # Ensure ~/.local/bin is in PATH
    if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi

    echo ""
    echo "════════════════════════════════════════════"
    echo "Zed Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v zed &>/dev/null || [[ -f "$HOME/.local/bin/zed" ]]; then
        print_success "Zed installed successfully"
    fi

    echo ""
    print_bullet "Run 'zed' to start"
    print_bullet "Config: ~/.config/zed/settings.json"
    print_bullet "Built by the creators of Atom"
    print_bullet "Native performance with Rust"
}

main "$@"
