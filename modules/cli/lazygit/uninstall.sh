#!/bin/bash
# LazyGit Uninstallation
# modules/cli/lazygit/uninstall.sh

set -euo pipefail

echo "Removing LazyGit..."

# Remove binary
sudo rm -f /usr/local/bin/lazygit

# Remove config
rm -rf ~/.config/lazygit

echo "LazyGit removed"
