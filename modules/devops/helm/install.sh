#!/bin/bash
# Helm Installation
# modules/devops/helm/install.sh

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

install_helm() {
    print_step "Installing Helm..."

    if command -v helm &>/dev/null; then
        print_warning "Helm is already installed"
        helm version --short
        return 0
    fi

    # Use official install script
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

    print_success "Helm installed"
}

configure_helm() {
    print_step "Configuring Helm..."

    # Enable bash completion
    if [[ -f ~/.bashrc ]] && ! grep -q "helm completion" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# Helm completion
source <(helm completion bash)
EOF
        print_success "Bash completion configured"
    fi

    # Add common repositories
    if command -v helm &>/dev/null; then
        print_bullet "Adding common Helm repositories..."
        helm repo add stable https://charts.helm.sh/stable 2>/dev/null || true
        helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
        helm repo update 2>/dev/null || true
    fi
}

main() {
    print_step "Installing Helm for $ARCH"

    install_helm
    configure_helm

    echo ""
    echo "════════════════════════════════════════════"
    echo "Helm Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v helm &>/dev/null; then
        print_success "Helm version: $(helm version --short)"
    fi

    echo ""
    print_bullet "helm repo add <name> <url> - Add repository"
    print_bullet "helm search repo <name> - Search charts"
    print_bullet "helm install <release> <chart> - Install chart"
}

main "$@"
