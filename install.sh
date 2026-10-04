#!/bin/bash
# CloudMC Linux/Mac Installer
# Supports: Ubuntu, Debian, CentOS, Fedora, Arch, macOS

set -e

echo "========================================"
echo "   CloudMC Auto-Startup Installer"
echo "========================================"
echo ""

cd "$(dirname "$0")"

# Detect OS
OS="$(uname -s)"
DISTRO=""
if [ "$OS" = "Linux" ]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
    fi
fi

echo "[1/5] Detected OS: $OS $DISTRO"
echo ""

# Check Python
echo "[2/5] Checking Python..."
if command -v python3 &> /dev/null; then
    PYTHON=python3
    echo "Python found: $(python3 --version)"
elif command -v python &> /dev/null; then
    PYTHON=python
    echo "Python found: $(python --version)"
else
    echo "Python not found! Installing..."
    if [ "$OS" = "Linux" ]; then
        if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv
        elif [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ] || [ "$DISTRO" = "rhel" ]; then
            sudo dnf install -y python3 python3-pip
        elif [ "$DISTRO" = "arch" ] || [ "$DISTRO" = "manjaro" ]; then
            sudo pacman -S --noconfirm python python-pip
        else
            echo "Please install Python 3 manually: https://www.python.org/downloads/"
            exit 1
        fi
    elif [ "$OS" = "Darwin" ]; then
        if command -v brew &> /dev/null; then
            brew install python3
        else
            echo "Please install Homebrew first: https://brew.sh/"
            echo "Or install Python from: https://www.python.org/downloads/macos/"
            exit 1
        fi
    fi
    PYTHON=python3
    echo "Python installed: $(python3 --version)"
fi
echo ""

# Check Java (for MC server)
echo "[3/5] Checking Java (for MC server)..."
if command -v java &> /dev/null; then
    echo "Java found: $(java -version 2>&1 | head -1)"
else
    echo "Java not found. MC server requires Java 17+."
    echo "Install Java (optional, can install later):"
    if [ "$OS" = "Linux" ]; then
        if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
            echo "  sudo apt-get install openjdk-17-jre-headless"
        elif [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ]; then
            echo "  sudo dnf install java-17-openjdk-headless"
        fi
    elif [ "$OS" = "Darwin" ]; then
        echo "  brew install openjdk@17"
    fi
    read -p "Install Java now? (y/N): " install_java
    if [ "$install_java" = "y" ] || [ "$install_java" = "Y" ]; then
        if [ "$OS" = "Linux" ]; then
            if [ "$DISTRO" = "ubuntu" ] || [ "$DISTRO" = "debian" ]; then
                sudo apt-get install -y openjdk-17-jre-headless
            elif [ "$DISTRO" = "centos" ] || [ "$DISTRO" = "fedora" ]; then
                sudo dnf install -y java-17-openjdk-headless
            fi
        elif [ "$OS" = "Darwin" ]; then
            brew install openjdk@17
        fi
        echo "Java installed."
    fi
fi
echo ""

# Install Python dependencies
echo "[4/5] Installing Python dependencies..."
$PYTHON -m pip install -r requirements.txt --quiet
echo "Dependencies installed."
echo ""

# Setup auto-start
echo "[5/5] Setting up auto-start..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$OS" = "Linux" ]; then
    # systemd service
    SERVICE_FILE="$HOME/.config/systemd/user/cloudmc.service"
    mkdir -p "$HOME/.config/systemd/user"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=CloudMC Server Host
After=network.target

[Service]
Type=simple
WorkingDirectory=$SCRIPT_DIR
ExecStart=$PYTHON $SCRIPT_DIR/app.py
Restart=always
RestartSec=10
Environment=PATH=/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable cloudmc.service
    systemctl --user start cloudmc.service
    
    # Enable lingering for boot without login
    sudo loginctl enable-linger $USER 2>/dev/null || true
    
    echo "systemd service created and enabled."
    echo "Service will start automatically on boot."

elif [ "$OS" = "Darwin" ]; then
    # macOS LaunchAgent
    PLIST_FILE="$HOME/Library/LaunchAgents/com.cloudmc.host.plist"
    mkdir -p "$HOME/Library/LaunchAgents"
    
    cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.cloudmc.host</string>
    <key>ProgramArguments</key>
    <array>
        <string>$PYTHON</string>
        <string>$SCRIPT_DIR/app.py</string>
    </array>
    <key>WorkingDirectory</key>
    <string>$SCRIPT_DIR</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$SCRIPT_DIR/cloudmc.log</string>
    <key>StandardErrorPath</key>
    <string>$SCRIPT_DIR/cloudmc-error.log</string>
</dict>
</plist>
EOF

    launchctl load "$PLIST_FILE" 2>/dev/null || launchctl bootstrap gui/$(id -u) "$PLIST_FILE"
    echo "LaunchAgent created and loaded."
    echo "Service will start automatically on login."
fi

echo ""
echo "========================================"
echo "   Installation Complete!"
echo "========================================"
echo ""
echo "Access URL: http://localhost:5000"
echo "Default account: admin / admin123"
echo ""
echo "Service is now running and will auto-start on boot!"
echo ""

# Open browser
if [ "$OS" = "Linux" ]; then
    xdg-open http://localhost:5000 2>/dev/null || true
elif [ "$OS" = "Darwin" ]; then
    open http://localhost:5000
fi
