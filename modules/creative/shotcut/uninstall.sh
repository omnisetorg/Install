#!/bin/bash
set -euo pipefail

echo "Removing Shotcut..."

sudo snap remove shotcut 2>/dev/null || true
flatpak uninstall -y org.shotcut.Shotcut 2>/dev/null || true
sudo apt-get remove -y shotcut 2>/dev/null || true

echo "Shotcut removed"
