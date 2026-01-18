#!/bin/bash
# .NET SDK Uninstallation
# modules/development/dotnet/uninstall.sh

set -euo pipefail

echo "Removing .NET SDK..."

# Remove installation
rm -rf "$HOME/.dotnet"

# Remove NuGet cache
rm -rf "$HOME/.nuget"

# Clean bashrc
sed -i '/# .NET SDK/,/DOTNET_CLI_TELEMETRY/d' ~/.bashrc 2>/dev/null || true
sed -i '/DOTNET_ROOT/d' ~/.bashrc 2>/dev/null || true

echo ".NET SDK removed"
