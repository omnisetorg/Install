#!/bin/bash
# LazyGit Installation
# modules/cli/lazygit/install.sh

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

install_lazygit() {
    print_step "Installing LazyGit..."

    if command -v lazygit &>/dev/null; then
        print_warning "LazyGit is already installed"
        lazygit --version
        return 0
    fi

    local version
    version=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

    case "$ARCH" in
        amd64)
            local arch_name="x86_64"
            ;;
        arm64)
            local arch_name="arm64"
            ;;
        armhf)
            local arch_name="armv6"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac

    local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch_name}.tar.gz"

    wget -qO /tmp/lazygit.tar.gz "$url"
    tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo mv /tmp/lazygit /usr/local/bin/
    rm /tmp/lazygit.tar.gz

    print_success "LazyGit installed"
}

main() {
    print_step "Installing LazyGit for $ARCH"

    install_lazygit

    echo ""
    echo "════════════════════════════════════════════"
    echo "LazyGit Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v lazygit &>/dev/null; then
        print_success "LazyGit version: $(lazygit --version)"
    fi

    echo ""
    print_bullet "Run 'lazygit' in a git repository"
    print_bullet "Press '?' for help inside lazygit"
}

main "$@"
