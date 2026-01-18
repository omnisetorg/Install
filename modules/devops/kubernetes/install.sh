#!/bin/bash
# Kubernetes Tools Installation
# modules/devops/kubernetes/install.sh

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

install_kubectl() {
    print_step "Installing kubectl..."

    if command -v kubectl &>/dev/null; then
        print_warning "kubectl is already installed"
        kubectl version --client --short 2>/dev/null || kubectl version --client
        return 0
    fi

    local version
    version=$(curl -L -s https://dl.k8s.io/release/stable.txt)

    curl -LO "https://dl.k8s.io/release/${version}/bin/linux/${ARCH}/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    print_success "kubectl installed"
}

install_k9s() {
    print_step "Installing k9s..."

    if command -v k9s &>/dev/null; then
        print_warning "k9s is already installed"
        return 0
    fi

    local version
    version=$(curl -s "https://api.github.com/repos/derailed/k9s/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    local arch_name
    case "$ARCH" in
        amd64) arch_name="amd64" ;;
        arm64) arch_name="arm64" ;;
        *) arch_name="amd64" ;;
    esac

    wget -qO /tmp/k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${version}/k9s_Linux_${arch_name}.tar.gz"
    tar -xzf /tmp/k9s.tar.gz -C /tmp k9s
    sudo mv /tmp/k9s /usr/local/bin/
    rm /tmp/k9s.tar.gz

    print_success "k9s installed"
}

install_kubectx() {
    print_step "Installing kubectx and kubens..."

    if command -v kubectx &>/dev/null; then
        print_warning "kubectx is already installed"
        return 0
    fi

    local version
    version=$(curl -s "https://api.github.com/repos/ahmetb/kubectx/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    local arch_name
    case "$ARCH" in
        amd64) arch_name="x86_64" ;;
        arm64) arch_name="arm64" ;;
        *) arch_name="x86_64" ;;
    esac

    # kubectx
    wget -qO /tmp/kubectx.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${version}/kubectx_${version}_linux_${arch_name}.tar.gz"
    tar -xzf /tmp/kubectx.tar.gz -C /tmp kubectx
    sudo mv /tmp/kubectx /usr/local/bin/
    rm /tmp/kubectx.tar.gz

    # kubens
    wget -qO /tmp/kubens.tar.gz "https://github.com/ahmetb/kubectx/releases/download/${version}/kubens_${version}_linux_${arch_name}.tar.gz"
    tar -xzf /tmp/kubens.tar.gz -C /tmp kubens
    sudo mv /tmp/kubens /usr/local/bin/
    rm /tmp/kubens.tar.gz

    print_success "kubectx and kubens installed"
}

configure_kubectl() {
    print_step "Configuring kubectl..."

    # Enable bash completion
    if [[ -f ~/.bashrc ]] && ! grep -q "kubectl completion" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# kubectl completion
source <(kubectl completion bash)
alias k=kubectl
complete -o default -F __start_kubectl k
EOF
        print_success "Bash completion configured"
    fi

    # Create config directory
    mkdir -p ~/.kube
}

main() {
    print_step "Installing Kubernetes Tools for $ARCH"

    install_kubectl
    install_k9s
    install_kubectx
    configure_kubectl

    echo ""
    echo "════════════════════════════════════════════"
    echo "Kubernetes Tools Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v kubectl &>/dev/null; then
        print_success "kubectl: $(kubectl version --client --short 2>/dev/null || kubectl version --client | head -1)"
    fi

    echo ""
    print_bullet "kubectl - Kubernetes CLI"
    print_bullet "k9s - Terminal UI for K8s"
    print_bullet "kubectx - Switch contexts quickly"
    print_bullet "kubens - Switch namespaces quickly"
    print_bullet "Alias: k=kubectl"
}

main "$@"
