#!/bin/bash
# Terraform Installation
# modules/devops/terraform/install.sh

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

install_terraform() {
    print_step "Installing Terraform..."

    if command -v terraform &>/dev/null; then
        print_warning "Terraform is already installed"
        terraform version
        return 0
    fi

    # Add HashiCorp GPG key
    wget -O- https://apt.releases.hashicorp.com/gpg | \
        sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    # Add repository
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Install
    sudo apt-get update
    sudo apt-get install -y terraform

    print_success "Terraform installed"
}

install_terragrunt() {
    print_step "Installing Terragrunt..."

    if command -v terragrunt &>/dev/null; then
        print_warning "Terragrunt is already installed"
        return 0
    fi

    local version
    version=$(curl -s "https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    local arch_name
    case "$ARCH" in
        amd64) arch_name="amd64" ;;
        arm64) arch_name="arm64" ;;
        *) arch_name="amd64" ;;
    esac

    wget -qO /tmp/terragrunt "https://github.com/gruntwork-io/terragrunt/releases/download/${version}/terragrunt_linux_${arch_name}"
    chmod +x /tmp/terragrunt
    sudo mv /tmp/terragrunt /usr/local/bin/

    print_success "Terragrunt installed"
}

configure_terraform() {
    print_step "Configuring Terraform..."

    # Enable bash completion
    if [[ -f ~/.bashrc ]] && ! grep -q "terraform -install-autocomplete" ~/.bashrc; then
        terraform -install-autocomplete 2>/dev/null || true
    fi

    # Create plugin cache directory
    mkdir -p ~/.terraform.d/plugin-cache

    # Configure plugin cache
    if [[ ! -f ~/.terraformrc ]]; then
        cat > ~/.terraformrc << 'EOF'
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
EOF
        print_success "Plugin cache configured"
    fi
}

main() {
    print_step "Installing Terraform for $ARCH"

    install_terraform
    install_terragrunt
    configure_terraform

    echo ""
    echo "════════════════════════════════════════════"
    echo "Terraform Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v terraform &>/dev/null; then
        print_success "Terraform version: $(terraform version | head -1)"
    fi

    if command -v terragrunt &>/dev/null; then
        print_success "Terragrunt version: $(terragrunt --version)"
    fi

    echo ""
    print_bullet "terraform init - Initialize working directory"
    print_bullet "terraform plan - Preview changes"
    print_bullet "terraform apply - Apply changes"
}

main "$@"
