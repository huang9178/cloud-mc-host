@echo off
title CloudMC Server Host
cd /d "%~dp0"

REM Detect Python command (try python3 first, then python)
set "PYTHON_CMD="
python3 --version >nul 2>&1
if not errorlevel 1 (
    set "PYTHON_CMD=python3"
) else (
    python --version >nul 2>&1
    if not errorlevel 1 (
        set "PYTHON_CMD=python"
    )
)

if "%PYTHON_CMD%"=="" (
    echo [ERROR] Python not found!
    echo.
    echo Please install Python 3.8+:
    echo 1. Download: https://www.python.org/downloads/
    echo 2. Check "Add Python to PATH" during installation
    echo 3. Disable Windows Store alias: Settings -^> Apps -^> App execution aliases
    echo 4. Restart computer
    echo.
    pause
    exit /b 1
)

echo ========================================
echo    CloudMC Server Host
echo ========================================
echo.
echo Python: %PYTHON_CMD%
echo Access URL: http://localhost:5000
echo Default account: admin / admin123
echo.
echo Press Ctrl+C to stop.
echo ========================================
echo.

%PYTHON_CMD% app.py

echo.
echo ========================================
echo CloudMC has stopped.
echo If it crashed, scroll up to see the error.
echo ========================================
echo.
pause
