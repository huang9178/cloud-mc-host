@echo off
title CloudMC Watchdog
cd /d "%~dp0"

echo ========================================
echo    CloudMC Watchdog Started
echo    Monitoring management panel
echo    Close this window to stop all services
echo ========================================
echo.

REM Detect Python command
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
    echo [ERROR] Python not found! Cannot monitor.
    pause
    exit /b 1
)

echo Using Python: %PYTHON_CMD%
echo.

:loop
    tasklist /fi "imagename eq python.exe" /v | find /i "app.py" >nul
    if errorlevel 1 (
        echo [%date% %time%] Management panel not running, starting...
        start "CloudMC" /min %PYTHON_CMD% app.py
        timeout /t 5 /nobreak >nul
    )

    timeout /t 30 /nobreak >nul
    goto loop
