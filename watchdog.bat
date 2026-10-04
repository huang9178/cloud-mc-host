@echo off
title CloudMC Watchdog

cd /d "%~dp0"

echo ========================================
echo    CloudMC Watchdog Started
echo    Monitoring management panel
echo    Close this window to stop all services
echo ========================================
echo.

:loop
    tasklist /fi "imagename eq python.exe" /v | find /i "app.py" >nul
    if errorlevel 1 (
        echo [%date% %time%] Management panel not running, starting...
        start "CloudMC" /min python app.py
        timeout /t 5 /nobreak >nul
    )

    timeout /t 30 /nobreak >nul
    goto loop
