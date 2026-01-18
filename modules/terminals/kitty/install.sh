#!/bin/bash
# Kitty Terminal Installation
# modules/terminals/kitty/install.sh

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

install_kitty() {
    print_step "Installing Kitty..."

    if command -v kitty &>/dev/null; then
        print_warning "Kitty is already installed"
        kitty --version
        return 0
    fi

    case "$ARCH" in
        amd64|arm64)
            # Official installer (recommended)
            curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n

            # Create symlinks
            mkdir -p ~/.local/bin
            ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/
            ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/

            # Desktop integration
            mkdir -p ~/.local/share/applications
            cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/
            cp ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/

            # Update icon paths
            sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
                ~/.local/share/applications/kitty*.desktop
            sed -i "s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" \
                ~/.local/share/applications/kitty*.desktop
            ;;
        *)
            # Try apt
            if apt-cache policy kitty 2>/dev/null | grep -q "Candidate: [0-9]"; then
                sudo apt-get update
                sudo apt-get install -y kitty
            else
                print_error "Kitty not available for $ARCH"
                return 1
            fi
            ;;
    esac

    print_success "Kitty installed"
}

configure_kitty() {
    print_step "Configuring Kitty..."

    local config_dir="$HOME/.config/kitty"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/kitty.conf" ]]; then
        cat > "$config_dir/kitty.conf" << 'EOF'
# Font
font_family      monospace
font_size        12.0

# Window
window_padding_width 10
background_opacity 0.95
hide_window_decorations no

# Tab bar
tab_bar_style powerline
tab_powerline_style slanted

# Colors (Catppuccin Mocha)
foreground #cdd6f4
background #1e1e2e
selection_foreground #1e1e2e
selection_background #f5e0dc

# Shortcuts
map ctrl+shift+t new_tab
map ctrl+shift+w close_tab
map ctrl+shift+right next_tab
map ctrl+shift+left previous_tab
EOF
        print_success "Created default configuration"
    fi
}

main() {
    print_step "Installing Kitty for $ARCH"

    install_kitty
    configure_kitty

    # Add to PATH if needed
    if [[ -d "$HOME/.local/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    fi

    echo ""
    echo "════════════════════════════════════════════"
    echo "Kitty Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v kitty &>/dev/null || [[ -f "$HOME/.local/kitty.app/bin/kitty" ]]; then
        local version
        version=$("$HOME/.local/kitty.app/bin/kitty" --version 2>/dev/null || kitty --version)
        print_success "Kitty version: $version"
    fi

    echo ""
    print_bullet "Config: ~/.config/kitty/kitty.conf"
    print_bullet "Run 'kitty' to start"
    print_bullet "Press Ctrl+Shift+F5 to reload config"
}

main "$@"
