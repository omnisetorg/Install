#!/bin/bash
# Ansible Uninstallation
# modules/devops/ansible/uninstall.sh

set -euo pipefail

echo "Removing Ansible..."

# Remove via pipx
pipx uninstall ansible-core 2>/dev/null || true

# Remove via pip
pip3 uninstall -y ansible argcomplete 2>/dev/null || true

# Remove via apt
sudo apt-get remove -y ansible 2>/dev/null || true

# Remove config
rm -rf ~/.ansible
rm -f ~/.ansible.cfg

# Clean bashrc
sed -i '/ansible-argcomplete/d' ~/.bashrc 2>/dev/null || true

sudo apt-get autoremove -y

echo "Ansible removed"
