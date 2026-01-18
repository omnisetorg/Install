#!/bin/bash
# Sublime Text Installation
# modules/editors/sublime/install.sh

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

install_sublime() {
    print_step "Installing Sublime Text..."

    if command -v subl &>/dev/null; then
        print_warning "Sublime Text is already installed"
        subl --version
        return 0
    fi

    # Add Sublime Text repository
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | \
        gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

    echo "deb https://download.sublimetext.com/ apt/stable/" | \
        sudo tee /etc/apt/sources.list.d/sublime-text.list

    sudo apt-get update
    sudo apt-get install -y sublime-text

    print_success "Sublime Text installed"
}

install_package_control() {
    print_step "Installing Package Control..."

    local packages_dir="$HOME/.config/sublime-text/Installed Packages"
    mkdir -p "$packages_dir"

    if [[ ! -f "$packages_dir/Package Control.sublime-package" ]]; then
        wget -qO "$packages_dir/Package Control.sublime-package" \
            "https://packagecontrol.io/Package%20Control.sublime-package"
        print_success "Package Control installed"
    else
        print_warning "Package Control already installed"
    fi
}

configure_sublime() {
    print_step "Configuring Sublime Text..."

    local config_dir="$HOME/.config/sublime-text/Packages/User"
    mkdir -p "$config_dir"

    if [[ ! -f "$config_dir/Preferences.sublime-settings" ]]; then
        cat > "$config_dir/Preferences.sublime-settings" << 'EOF'
{
    "font_face": "JetBrains Mono",
    "font_size": 12,
    "theme": "Default Dark.sublime-theme",
    "color_scheme": "Monokai.sublime-color-scheme",
    "tab_size": 2,
    "translate_tabs_to_spaces": true,
    "trim_trailing_white_space_on_save": true,
    "ensure_newline_at_eof_on_save": true,
    "save_on_focus_lost": true,
    "highlight_line": true,
    "line_padding_top": 2,
    "line_padding_bottom": 2,
    "margin": 4,
    "word_wrap": true,
    "show_encoding": true,
    "show_line_endings": true
}
EOF
        print_success "Created default configuration"
    fi
}

main() {
    print_step "Installing Sublime Text for $ARCH"

    install_sublime
    install_package_control
    configure_sublime

    echo ""
    echo "════════════════════════════════════════════"
    echo "Sublime Text Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v subl &>/dev/null; then
        print_success "Sublime Text version: $(subl --version)"
    fi

    echo ""
    print_bullet "Run 'subl' to start"
    print_bullet "Ctrl+Shift+P for Command Palette"
    print_bullet "Package Control ready for extensions"
}

main "$@"
