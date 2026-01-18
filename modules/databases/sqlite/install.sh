#!/bin/bash
# SQLite Installation
# modules/databases/sqlite/install.sh

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

install_sqlite() {
    print_step "Installing SQLite..."

    if command -v sqlite3 &>/dev/null; then
        print_warning "SQLite is already installed"
        sqlite3 --version
        return 0
    fi

    sudo apt-get update
    sudo apt-get install -y sqlite3 libsqlite3-dev

    print_success "SQLite installed"
}

install_sqlitebrowser() {
    print_step "Installing DB Browser for SQLite..."

    if command -v sqlitebrowser &>/dev/null; then
        print_warning "DB Browser for SQLite already installed"
        return 0
    fi

    sudo apt-get install -y sqlitebrowser

    print_success "DB Browser for SQLite installed"
}

install_litecli() {
    print_step "Installing litecli (enhanced CLI)..."

    if command -v litecli &>/dev/null; then
        print_warning "litecli already installed"
        return 0
    fi

    if command -v pipx &>/dev/null; then
        pipx install litecli
    elif command -v pip3 &>/dev/null; then
        pip3 install --user litecli
    else
        print_warning "pip not found, skipping litecli"
        return 0
    fi

    print_success "litecli installed"
}

main() {
    print_step "Installing SQLite Tools for $ARCH"

    install_sqlite
    install_sqlitebrowser
    install_litecli

    echo ""
    echo "════════════════════════════════════════════"
    echo "SQLite Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v sqlite3 &>/dev/null; then
        print_success "SQLite version: $(sqlite3 --version)"
    fi

    echo ""
    print_bullet "CLI: sqlite3 database.db"
    print_bullet "Enhanced CLI: litecli database.db"
    print_bullet "GUI: sqlitebrowser"
    echo ""
    print_bullet "SQLite is file-based, no server needed"
    print_bullet "Great for development and embedded use"
}

main "$@"
