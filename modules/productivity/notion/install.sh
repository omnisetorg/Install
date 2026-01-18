#!/bin/bash
# Notion Installation
# modules/productivity/notion/install.sh

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

install_notion() {
    print_step "Installing Notion..."

    # Check if already installed
    if command -v notion-app &>/dev/null || command -v notion &>/dev/null; then
        print_warning "Notion is already installed"
        return 0
    fi

    # Try snap (unofficial but works well)
    if command -v snap &>/dev/null; then
        sudo snap install notion-snap-reborn
        print_success "Notion installed via snap"
        return 0
    fi

    # Manual installation using notion-app-enhanced
    case "$ARCH" in
        amd64)
            local version
            version=$(curl -s "https://api.github.com/repos/notion-enhancer/notion-repackaged/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

            if [[ -n "$version" ]]; then
                wget -qO /tmp/notion.deb "https://github.com/notion-enhancer/notion-repackaged/releases/download/v${version}/notion-app-enhanced_${version}_amd64.deb"
                sudo dpkg -i /tmp/notion.deb || sudo apt-get install -f -y
                rm /tmp/notion.deb
            else
                print_error "Could not find Notion release"
                print_bullet "Try using the web version: https://notion.so"
                return 1
            fi
            ;;
        arm64)
            print_warning "Notion desktop not officially available for arm64"
            print_bullet "Use web version: https://notion.so"
            print_bullet "Or try snap: sudo snap install notion-snap-reborn"
            return 1
            ;;
        *)
            print_error "Notion not available for $ARCH"
            return 1
            ;;
    esac

    print_success "Notion installed"
}

main() {
    print_step "Installing Notion for $ARCH"

    install_notion

    echo ""
    echo "════════════════════════════════════════════"
    echo "Notion Installation Complete"
    echo "════════════════════════════════════════════"

    print_success "Notion workspace installed"

    echo ""
    print_bullet "Run 'notion-app' or 'notion-app-enhanced' to start"
    print_bullet "All-in-one workspace for notes, docs, wikis"
    print_bullet "Web version: https://notion.so"
}

main "$@"
