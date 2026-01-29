#!/bin/bash
# Google Chrome Uninstall Script
set -euo pipefail

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_info() { echo "ℹ $1"; }
fi

REMOVE_DATA="${1:-false}"

print_step "Uninstalling Google Chrome..."

# Remove via package managers
if command -v apt-get &>/dev/null; then
    sudo apt-get remove -y google-chrome-stable google-chrome-beta google-chrome-unstable 2>/dev/null || true
    sudo apt-get autoremove -y 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/google-chrome.list 2>/dev/null || true
    sudo rm -f /usr/share/keyrings/google-chrome.gpg 2>/dev/null || true
fi

if command -v dnf &>/dev/null; then
    sudo dnf remove -y google-chrome-stable 2>/dev/null || true
fi

if command -v pacman &>/dev/null; then
    sudo pacman -Rs --noconfirm google-chrome 2>/dev/null || true
fi

# Remove Flatpak version
if command -v flatpak &>/dev/null; then
    flatpak uninstall -y com.google.Chrome 2>/dev/null || true
fi

# Remove data if requested
if [[ "$REMOVE_DATA" == "true" ]] || [[ "$REMOVE_DATA" == "--purge" ]]; then
    print_step "Removing Chrome user data..."
    rm -rf "$HOME/.config/google-chrome" 2>/dev/null || true
    rm -rf "$HOME/.cache/google-chrome" 2>/dev/null || true
    rm -rf "$HOME/.local/share/google-chrome" 2>/dev/null || true
    print_success "Chrome data removed"
else
    print_info "Chrome profile preserved at ~/.config/google-chrome"
    print_info "Use --purge to remove all browsing data"
fi

print_success "Google Chrome uninstalled"
