#!/bin/bash
# Terraform Uninstallation
# modules/devops/terraform/uninstall.sh

set -euo pipefail

echo "Removing Terraform..."

# Remove via apt
sudo apt-get remove -y terraform 2>/dev/null || true

# Remove HashiCorp repository
sudo rm -f /etc/apt/sources.list.d/hashicorp.list
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Remove Terragrunt
sudo rm -f /usr/local/bin/terragrunt

# Remove config and cache
rm -rf ~/.terraform.d
rm -f ~/.terraformrc

sudo apt-get autoremove -y

echo "Terraform removed"
