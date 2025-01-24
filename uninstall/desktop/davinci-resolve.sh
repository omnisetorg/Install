#!/bin/bash

echo "Starting DaVinci Resolve uninstallation..."

# Check if the uninstaller exists
uninstaller_path="/opt/resolve/uninstall"

if [ -f "$uninstaller_path" ]; then
    echo "Found DaVinci Resolve uninstaller at $uninstaller_path. Running uninstaller..."
    sudo "$uninstaller_path"
    echo "DaVinci Resolve has been uninstalled successfully."
else
    echo "Uninstaller not found. Attempting manual removal..."

    # Manual cleanup
    echo "Removing DaVinci Resolve files..."
    sudo rm -rf /opt/resolve
    echo "Removing configuration files..."
    sudo rm -rf ~/.resolve
    sudo rm -rf ~/Library/Preferences/BlackmagicDesign/DaVinciResolve

    echo "DaVinci Resolve files and configuration have been removed."
fi

echo "Uninstallation complete!"