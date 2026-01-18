#!/bin/bash
# Ansible Installation
# modules/devops/ansible/install.sh

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

install_ansible() {
    print_step "Installing Ansible..."

    if command -v ansible &>/dev/null; then
        print_warning "Ansible is already installed"
        ansible --version | head -1
        return 0
    fi

    # Install via pipx (recommended)
    if command -v pipx &>/dev/null; then
        pipx install ansible-core
        pipx inject ansible-core argcomplete
        print_success "Ansible installed via pipx"
        return 0
    fi

    # Install via pip
    if command -v pip3 &>/dev/null; then
        pip3 install --user ansible argcomplete
        print_success "Ansible installed via pip"
        return 0
    fi

    # Fallback to apt
    sudo apt-get update
    sudo apt-get install -y ansible

    print_success "Ansible installed via apt"
}

install_dependencies() {
    print_step "Installing dependencies..."

    sudo apt-get update
    sudo apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        sshpass

    # Install pipx if not present
    if ! command -v pipx &>/dev/null; then
        pip3 install --user pipx
        python3 -m pipx ensurepath
    fi

    print_success "Dependencies installed"
}

configure_ansible() {
    print_step "Configuring Ansible..."

    # Create ansible directory
    mkdir -p ~/.ansible

    # Create default config if not exists
    if [[ ! -f ~/.ansible.cfg ]]; then
        cat > ~/.ansible.cfg << 'EOF'
[defaults]
inventory = ~/.ansible/hosts
host_key_checking = False
retry_files_enabled = False
stdout_callback = yaml

[ssh_connection]
pipelining = True
EOF
        print_success "Default configuration created"
    fi

    # Create empty inventory
    if [[ ! -f ~/.ansible/hosts ]]; then
        cat > ~/.ansible/hosts << 'EOF'
# Ansible inventory file
# Add your hosts here

[local]
localhost ansible_connection=local

# [webservers]
# server1.example.com
# server2.example.com

# [databases]
# db1.example.com
EOF
        print_success "Inventory file created"
    fi

    # Enable bash completion
    if [[ -f ~/.bashrc ]] && ! grep -q "ansible-argcomplete" ~/.bashrc; then
        echo 'eval "$(register-python-argcomplete ansible)"' >> ~/.bashrc 2>/dev/null || true
        echo 'eval "$(register-python-argcomplete ansible-playbook)"' >> ~/.bashrc 2>/dev/null || true
    fi
}

main() {
    print_step "Installing Ansible for $ARCH"

    install_dependencies
    install_ansible
    configure_ansible

    echo ""
    echo "════════════════════════════════════════════"
    echo "Ansible Installation Complete"
    echo "════════════════════════════════════════════"

    if command -v ansible &>/dev/null; then
        print_success "Ansible version: $(ansible --version | head -1)"
    fi

    echo ""
    print_bullet "Config: ~/.ansible.cfg"
    print_bullet "Inventory: ~/.ansible/hosts"
    print_bullet "ansible-playbook playbook.yml - Run playbook"
    print_bullet "ansible all -m ping - Test connectivity"
}

main "$@"
