@echo off
title CloudMC Server Host

cd /d "%~dp0"

echo ========================================
echo    CloudMC Server Host
echo ========================================
echo.
echo Access URL: http://localhost:5000
echo Default account: admin / admin123
echo.
echo Press Ctrl+C to stop.
echo ========================================
echo.

REM Check Python first
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python NOT found!
    echo.
    echo Please install Python 3.8 or later:
    echo 1. Download: https://www.python.org/downloads/
    echo 2. Run installer
    echo 3. CHECK "Add Python to PATH" - VERY IMPORTANT!
    echo 4. Click Install Now
    echo 5. RESTART your computer!
    echo.
    pause
    exit /b 1
)

echo Python version:
python --version
echo.

echo Starting CloudMC...
echo.

python app.py

echo.
echo ========================================
echo CloudMC has stopped.
echo If it crashed, scroll up to see the error.
echo ========================================
echo.
pause
