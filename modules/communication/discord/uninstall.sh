#!/bin/bash
# Discord Uninstall Script
set -euo pipefail

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_info() { echo "ℹ $1"; }
fi

REMOVE_CONFIG="${1:-false}"

print_step "Uninstalling Discord..."

# Remove via package managers
if command -v apt-get &>/dev/null; then
    sudo apt-get remove -y discord 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
fi

if command -v dnf &>/dev/null; then
    sudo dnf remove -y discord 2>/dev/null || true
fi

if command -v pacman &>/dev/null; then
    sudo pacman -Rs --noconfirm discord 2>/dev/null || true
fi

# Remove Flatpak version
if command -v flatpak &>/dev/null; then
    flatpak uninstall -y com.discordapp.Discord 2>/dev/null || true
fi

# Remove Snap version
if command -v snap &>/dev/null; then
    sudo snap remove discord 2>/dev/null || true
fi

# Remove config files if requested
if [[ "$REMOVE_CONFIG" == "true" ]] || [[ "$REMOVE_CONFIG" == "--purge" ]]; then
    print_step "Removing configuration files..."
    rm -rf "$HOME/.config/discord" 2>/dev/null || true
    rm -rf "$HOME/.local/share/discord" 2>/dev/null || true
    rm -rf "$HOME/.cache/discord" 2>/dev/null || true
    print_success "Configuration files removed"
else
    print_info "Config files preserved at ~/.config/discord"
    print_info "Use --purge to remove all data"
fi

print_success "Discord uninstalled"
