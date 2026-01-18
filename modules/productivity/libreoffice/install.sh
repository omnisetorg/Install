#!/bin/bash
# LibreOffice Installation
# modules/productivity/libreoffice/install.sh

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

install_libreoffice() {
    print_step "Installing LibreOffice..."

    if command -v libreoffice &>/dev/null; then
        print_warning "LibreOffice is already installed"
        libreoffice --version
        return 0
    fi

    sudo apt-get update
    sudo apt-get install -y libreoffice libreoffice-gtk3

    print_success "LibreOffice installed"
}

install_extras() {
    print_step "Installing LibreOffice extras..."

    # Language packs (English)
    sudo apt-get install -y libreoffice-l10n-en-gb 2>/dev/null || true

    # Additional fonts
    sudo apt-get install -y fonts-liberation fonts-crosextra-carlito fonts-crosextra-caladea 2>/dev/null || true

    print_success "Extras installed"
}

main() {
    print_step "Installing LibreOffice for $ARCH"

    install_libreoffice
    install_extras

    echo ""
    echo "════════════════════════════════════════════"
    echo "LibreOffice Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v libreoffice &>/dev/null; then
        print_success "LibreOffice version: $(libreoffice --version | head -1)"
    fi

    echo ""
    print_bullet "Writer - Word processing"
    print_bullet "Calc - Spreadsheets"
    print_bullet "Impress - Presentations"
    print_bullet "Draw - Vector graphics"
    print_bullet "Base - Databases"
}

main "$@"
