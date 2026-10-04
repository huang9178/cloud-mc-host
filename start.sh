#!/bin/bash
# CloudMC Start Script for Linux/Mac

cd "$(dirname "$0")"

echo "========================================"
echo "   CloudMC Server Host"
echo "========================================"
echo ""
echo "Access URL: http://localhost:5000"
echo "Default account: admin / admin123"
echo ""
echo "Press Ctrl+C to stop."
echo "========================================"
echo ""

# Detect Python
if command -v python3 &> /dev/null; then
    PYTHON=python3
elif command -v python &> /dev/null; then
    PYTHON=python
else
    echo "Error: Python not found!"
    echo "Please install Python 3.8+"
    exit 1
fi

$PYTHON app.py
