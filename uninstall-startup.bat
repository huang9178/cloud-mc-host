@echo off
title CloudMC Uninstaller

echo ========================================
echo    CloudMC Auto-Startup Uninstaller
echo ========================================
echo.

set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LNK_PATH=%STARTUP_FOLDER%\CloudMC.lnk"

echo [1/2] Removing auto-startup...
if exist "%LNK_PATH%" (
    del "%LNK_PATH%"
    echo Removed: %LNK_PATH%
) else (
    echo Auto-startup entry not found (may already be removed).
)

echo [2/2] Stopping running services...
taskkill /f /im python.exe 2>nul
echo All Python processes stopped.

echo.
echo ========================================
echo    Uninstall Complete!
echo ========================================
echo.
echo CloudMC auto-startup has been removed.
echo To reinstall, run install-startup.bat
echo.
pause
