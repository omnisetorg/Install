#!/bin/bash
set -euo pipefail

echo "Removing AWS CLI..."

# Remove official installer version
sudo rm -rf /usr/local/aws-cli 2>/dev/null || true
sudo rm -f /usr/local/bin/aws /usr/local/bin/aws_completer 2>/dev/null || true

# Remove pip version
pip3 uninstall -y awscli 2>/dev/null || true

echo "AWS CLI removed"
echo "Note: ~/.aws credentials were preserved"
