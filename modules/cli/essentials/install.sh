#!/bin/bash
# Essential CLI Tools Installation
# modules/cli/essentials/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Source library functions if available
if [[ -f "${OMNISET_LIB:-}/ui/print.sh" ]]; then
    source "${OMNISET_LIB}/ui/print.sh"
else
    # Fallback print functions
    print_step() { echo "==> $1"; }
    print_success() { echo "✓ $1"; }
    print_warning() { echo "⚠ $1"; }
    print_error() { echo "✗ $1" >&2; }
    print_bullet() { echo "  • $1"; }
fi

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    print_step "Installing Essential CLI Tools for $ARCH"

    local packages=(
        curl wget git vim htop unzip zip jq tree ncdu tmux
        build-essential software-properties-common
    )

    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y "${packages[@]}"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y "${packages[@]}"
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm --needed "${packages[@]}"
    elif command -v zypper &>/dev/null; then
        sudo zypper install -y "${packages[@]}"
    elif command -v apk &>/dev/null; then
        sudo apk add "${packages[@]}"
    else
        print_error "No supported package manager found"
        return 1
    fi

    print_success "Essential CLI tools installed"
}

main "$@"
