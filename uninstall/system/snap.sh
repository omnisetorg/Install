#!/bin/bash

# Re-enable Snap services if they were disabled
# Location: uninstall/system/snap.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "Re-enabling Snap services..."

if [ -x "$PROJECT_ROOT/scripts/disable-snap.sh" ]; then
    "$PROJECT_ROOT/scripts/disable-snap.sh" enable
else
    echo "Manual re-enable with:"
    echo "sudo systemctl unmask snapd.service"
    echo "sudo systemctl enable snapd.service snapd.socket snapd.seeded.service"
    echo "sudo systemctl start snapd.service"
fi