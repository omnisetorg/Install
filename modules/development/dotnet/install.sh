#!/bin/bash
# .NET SDK Installation
# modules/development/dotnet/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Parse options
DOTNET_VERSION="${OPTIONS:-9.0}"  # Default to .NET 9

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

install_dotnet() {
    print_step "Installing .NET SDK ${DOTNET_VERSION}..."

    if command -v dotnet &>/dev/null; then
        print_warning ".NET is already installed"
        dotnet --list-sdks
        return 0
    fi

    case "$ARCH" in
        amd64|arm64)
            # Use Microsoft's install script
            wget -qO /tmp/dotnet-install.sh https://dot.net/v1/dotnet-install.sh
            chmod +x /tmp/dotnet-install.sh

            # Install SDK
            /tmp/dotnet-install.sh --channel "$DOTNET_VERSION" --install-dir "$HOME/.dotnet"

            rm /tmp/dotnet-install.sh
            ;;
        *)
            print_error ".NET not available for $ARCH"
            return 1
            ;;
    esac

    print_success ".NET SDK installed"
}

configure_dotnet() {
    print_step "Configuring .NET..."

    # Add to PATH
    if [[ -f ~/.bashrc ]] && ! grep -q "DOTNET_ROOT" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# .NET SDK
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"

# Disable telemetry (optional)
export DOTNET_CLI_TELEMETRY_OPTOUT=1
EOF
        print_success "Shell configuration updated"
    fi

    # Export for current session
    export DOTNET_ROOT="$HOME/.dotnet"
    export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
}

install_tools() {
    print_step "Installing common .NET tools..."

    export DOTNET_ROOT="$HOME/.dotnet"
    export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"

    # Install Entity Framework tools
    "$HOME/.dotnet/dotnet" tool install --global dotnet-ef 2>/dev/null || true

    # Install code formatting tool
    "$HOME/.dotnet/dotnet" tool install --global dotnet-format 2>/dev/null || true

    print_success "Common tools installed"
}

main() {
    print_step "Installing .NET SDK for $ARCH"

    install_dotnet
    configure_dotnet
    install_tools

    echo ""
    echo "════════════════════════════════════════════"
    echo ".NET SDK Installation Complete"
    echo "════════════════════════════════════════════"

    export DOTNET_ROOT="$HOME/.dotnet"
    export PATH="$PATH:$DOTNET_ROOT"

    if [[ -f "$HOME/.dotnet/dotnet" ]]; then
        print_success ".NET version: $("$HOME/.dotnet/dotnet" --version)"
        echo ""
        print_bullet "SDKs installed:"
        "$HOME/.dotnet/dotnet" --list-sdks
    fi

    echo ""
    print_bullet "Run 'source ~/.bashrc' to activate"
    print_bullet "Create new project: dotnet new console -n MyApp"
    print_bullet "Run project: dotnet run"
}

main "$@"
