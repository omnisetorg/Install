#!/bin/bash
# Java (SDKMAN) Uninstallation
# modules/development/java/uninstall.sh

set -euo pipefail

echo "Removing Java and SDKMAN..."

# Remove SDKMAN and all SDKs
if [[ -d "$HOME/.sdkman" ]]; then
    rm -rf "$HOME/.sdkman"
fi

# Clean bashrc
sed -i '/# SDKMAN/,/sdkman-init.sh/d' ~/.bashrc 2>/dev/null || true
sed -i '/SDKMAN_DIR/d' ~/.bashrc 2>/dev/null || true

echo "Java and SDKMAN removed"
echo "Note: All Java versions managed by SDKMAN were removed"
