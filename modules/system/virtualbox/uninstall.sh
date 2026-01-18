#!/bin/bash
# VirtualBox Uninstallation
# modules/system/virtualbox/uninstall.sh

set -euo pipefail

echo "Removing VirtualBox..."

# Remove via apt
sudo apt-get remove -y virtualbox* 2>/dev/null || true

# Remove repository
sudo rm -f /etc/apt/sources.list.d/virtualbox.list
sudo rm -f /usr/share/keyrings/oracle-virtualbox-2016.gpg

# Remove kernel modules
sudo /sbin/vboxconfig 2>/dev/null || true

# Remove config (preserves VMs)
# rm -rf ~/.config/VirtualBox
# rm -rf ~/VirtualBox\ VMs

sudo apt-get autoremove -y

echo "VirtualBox removed"
echo "Note: VM files in ~/VirtualBox VMs were preserved"
