#!/bin/bash
# Spotify Installation
# modules/media/spotify/install.sh

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

install_spotify() {
    print_step "Installing Spotify..."

    if command -v spotify &>/dev/null; then
        print_warning "Spotify is already installed"
        return 0
    fi

    # Try snap (official)
    if command -v snap &>/dev/null; then
        sudo snap install spotify
        print_success "Spotify installed via snap"
        return 0
    fi

    # Try flatpak
    if command -v flatpak &>/dev/null; then
        flatpak install -y flathub com.spotify.Client
        print_success "Spotify installed via Flatpak"
        return 0
    fi

    # Manual installation (apt repository)
    case "$ARCH" in
        amd64)
            # Add Spotify repository
            curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | \
                sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg

            echo "deb http://repository.spotify.com stable non-free" | \
                sudo tee /etc/apt/sources.list.d/spotify.list

            sudo apt-get update
            sudo apt-get install -y spotify-client
            ;;
        *)
            print_error "Spotify not available for $ARCH via apt"
            print_bullet "Try: sudo snap install spotify"
            print_bullet "Or: flatpak install flathub com.spotify.Client"
            return 1
            ;;
    esac

    print_success "Spotify installed"
}

main() {
    print_step "Installing Spotify for $ARCH"

    install_spotify

    echo ""
    echo "════════════════════════════════════════════"
    echo "Spotify Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Spotify music client installed"

    echo ""
    print_bullet "Run 'spotify' to start"
    print_bullet "Stream millions of songs"
    print_bullet "Free tier available with ads"
}

main "$@"
