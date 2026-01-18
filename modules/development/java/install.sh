#!/bin/bash
# Java (OpenJDK) Installation via SDKMAN
# modules/development/java/install.sh

set -euo pipefail

ARCH="${1:-amd64}"
OPTIONS="${2:-}"

# Parse options
JAVA_VERSION="${OPTIONS:-21}"  # Default to LTS 21

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

install_sdkman() {
    print_step "Installing SDKMAN..."

    if [[ -d "$HOME/.sdkman" ]]; then
        print_warning "SDKMAN is already installed"
        return 0
    fi

    # Install dependencies
    sudo apt-get update
    sudo apt-get install -y curl zip unzip

    # Install SDKMAN
    curl -s "https://get.sdkman.io" | bash

    print_success "SDKMAN installed"
}

install_java() {
    print_step "Installing Java ${JAVA_VERSION}..."

    # Source SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

    if ! command -v sdk &>/dev/null; then
        print_error "SDKMAN not found"
        return 1
    fi

    # Find the latest version matching requested major version
    local java_identifier
    java_identifier=$(sdk list java 2>/dev/null | grep -E "^\s*${JAVA_VERSION}\." | grep -E "tem|zulu|open" | head -1 | awk '{print $NF}')

    if [[ -z "$java_identifier" ]]; then
        # Fallback to direct version
        java_identifier="${JAVA_VERSION}-tem"
    fi

    print_bullet "Installing $java_identifier..."
    sdk install java "$java_identifier" || sdk install java "${JAVA_VERSION}-open"

    print_success "Java installed"
}

install_build_tools() {
    print_step "Installing build tools..."

    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

    # Install Maven
    if ! command -v mvn &>/dev/null; then
        sdk install maven
        print_success "Maven installed"
    fi

    # Install Gradle
    if ! command -v gradle &>/dev/null; then
        sdk install gradle
        print_success "Gradle installed"
    fi
}

configure_java() {
    print_step "Configuring Java..."

    # Add SDKMAN to shell
    if [[ -f ~/.bashrc ]] && ! grep -q "SDKMAN" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF
        print_success "Shell configuration updated"
    fi
}

main() {
    print_step "Installing Java for $ARCH"

    install_sdkman
    install_java
    install_build_tools
    configure_java

    echo ""
    echo "════════════════════════════════════════════"
    echo "Java Installation Complete"
    echo "════════════════════════════════════════════"

    # Source and verify
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"

    if command -v java &>/dev/null; then
        print_success "Java version: $(java -version 2>&1 | head -1)"
    fi

    echo ""
    print_bullet "Managed via SDKMAN"
    print_bullet "Run 'sdk list java' to see versions"
    print_bullet "Run 'sdk install java <version>' to install"
    print_bullet "Run 'source ~/.bashrc' to activate"
}

main "$@"
