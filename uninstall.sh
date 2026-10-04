#!/bin/bash
# CloudMC Linux/Mac Uninstaller

set -e

echo "========================================"
echo "   CloudMC Auto-Startup Uninstaller"
echo "========================================"
echo ""

OS="$(uname -s)"

echo "[1/2] Removing auto-start..."
if [ "$OS" = "Linux" ]; then
    systemctl --user stop cloudmc.service 2>/dev/null || true
    systemctl --user disable cloudmc.service 2>/dev/null || true
    rm -f "$HOME/.config/systemd/user/cloudmc.service"
    systemctl --user daemon-reload
    echo "systemd service removed."
elif [ "$OS" = "Darwin" ]; then
    PLIST_FILE="$HOME/Library/LaunchAgents/com.cloudmc.host.plist"
    launchctl unload "$PLIST_FILE" 2>/dev/null || true
    rm -f "$PLIST_FILE"
    echo "LaunchAgent removed."
fi

echo "[2/2] Stopping running services..."
pkill -f "python.*app.py" 2>/dev/null || true
echo "All CloudMC processes stopped."

echo ""
echo "========================================"
echo "   Uninstall Complete!"
echo "========================================"
echo ""
echo "CloudMC auto-startup has been removed."
echo "To reinstall, run install.sh"
echo ""
