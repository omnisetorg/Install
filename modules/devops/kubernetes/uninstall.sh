#!/bin/bash
# Kubernetes Tools Uninstallation
# modules/devops/kubernetes/uninstall.sh

set -euo pipefail

echo "Removing Kubernetes Tools..."

# Remove kubectl
sudo rm -f /usr/local/bin/kubectl

# Remove k9s
sudo rm -f /usr/local/bin/k9s

# Remove kubectx and kubens
sudo rm -f /usr/local/bin/kubectx
sudo rm -f /usr/local/bin/kubens

# Remove config (optional - preserves cluster configs)
# rm -rf ~/.kube

# Clean bashrc
sed -i '/kubectl completion/d' ~/.bashrc 2>/dev/null || true
sed -i '/alias k=kubectl/d' ~/.bashrc 2>/dev/null || true
sed -i '/__start_kubectl/d' ~/.bashrc 2>/dev/null || true

echo "Kubernetes Tools removed"
echo "Note: ~/.kube config was preserved"
