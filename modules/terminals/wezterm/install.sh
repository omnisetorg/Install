#!/bin/bash
# WezTerm Installation
# modules/terminals/wezterm/install.sh

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

install_wezterm() {
    print_step "Installing WezTerm..."

    if command -v wezterm &>/dev/null; then
        print_warning "WezTerm is already installed"
        wezterm --version
        return 0
    fi

    case "$ARCH" in
        amd64)
            # Add WezTerm repository
            curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
            echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | \
                sudo tee /etc/apt/sources.list.d/wezterm.list

            sudo apt-get update
            sudo apt-get install -y wezterm
            ;;
        arm64)
            # Try flatpak
            if command -v flatpak &>/dev/null; then
                flatpak install -y flathub org.wezfurlong.wezterm
                print_success "WezTerm installed via Flatpak"
                return 0
            fi

            # Download AppImage
            local version
            version=$(curl -s "https://api.github.com/repos/wez/wezterm/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

            wget -qO /tmp/wezterm.AppImage "https://github.com/wez/wezterm/releases/download/${version}/WezTerm-${version}-Ubuntu20.04.AppImage"
            chmod +x /tmp/wezterm.AppImage
            sudo mv /tmp/wezterm.AppImage /usr/local/bin/wezterm
            ;;
        *)
            print_error "WezTerm not available for $ARCH"
            return 1
            ;;
    esac

    print_success "WezTerm installed"
}

configure_wezterm() {
    print_step "Configuring WezTerm..."

    local config_dir="$HOME/.config/wezterm"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/wezterm.lua" ]]; then
        cat > "$config_dir/wezterm.lua" << 'EOF'
local wezterm = require 'wezterm'
local config = {}

-- Font
config.font = wezterm.font 'JetBrains Mono'
config.font_size = 12.0

-- Window
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.window_background_opacity = 0.95

-- Colors (Catppuccin Mocha)
config.color_scheme = 'Catppuccin Mocha'

-- Tab bar
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true

-- Keybindings
config.keys = {
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab { confirm = true } },
}

return config
EOF
        print_success "Created default configuration"
    fi
}

main() {
    print_step "Installing WezTerm for $ARCH"

    install_wezterm
    configure_wezterm

    echo ""
    echo "════════════════════════════════════════════"
    echo "WezTerm Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v wezterm &>/dev/null; then
        print_success "WezTerm version: $(wezterm --version)"
    fi

    echo ""
    print_bullet "Config: ~/.config/wezterm/wezterm.lua"
    print_bullet "Run 'wezterm' to start"
    print_bullet "Lua-based configuration for flexibility"
}

main "$@"
