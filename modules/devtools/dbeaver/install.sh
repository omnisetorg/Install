#!/bin/bash
# DBeaver Installation
# modules/devtools/dbeaver/install.sh

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

install_dbeaver() {
    print_step "Installing DBeaver..."

    if command -v dbeaver &>/dev/null; then
        print_warning "DBeaver is already installed"
        return 0
    fi

    case "$ARCH" in
        amd64)
            # Download latest deb package
            local url="https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb"
            ;;
        arm64)
            local url="https://dbeaver.io/files/dbeaver-ce_latest_arm64.deb"
            ;;
        *)
            print_error "DBeaver not available for $ARCH"
            return 1
            ;;
    esac

    print_bullet "Downloading DBeaver Community Edition..."
    wget -qO /tmp/dbeaver.deb "$url"

    # Install
    sudo dpkg -i /tmp/dbeaver.deb || sudo apt-get install -f -y
    rm /tmp/dbeaver.deb

    print_success "DBeaver installed"
}

main() {
    print_step "Installing DBeaver for $ARCH"

    install_dbeaver

    echo ""
    echo "════════════════════════════════════════════"
    echo "DBeaver Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "DBeaver Community Edition installed"

    echo ""
    print_bullet "Run 'dbeaver' to start"
    print_bullet "Supports PostgreSQL, MySQL, SQLite, MongoDB, etc."
    print_bullet "ER diagrams, data export, SQL editor"
}

main "$@"
