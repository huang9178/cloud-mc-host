@echo off
title CloudMC Installer

echo ========================================
echo    CloudMC Auto-Startup Installer
echo ========================================
echo.

cd /d "%~dp0"

REM Check Python
where python >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python not found!
    echo.
    echo Please install Python 3.8 or later:
    echo Download: https://www.python.org/downloads/
    echo.
    echo IMPORTANT: Check "Add Python to PATH" during installation!
    echo.
    pause
    exit /b 1
)

echo [1/4] Python found:
python --version
echo.

echo [2/4] Installing Python dependencies...
pip install -r requirements.txt
if errorlevel 1 (
    echo [WARNING] Dependency installation may have failed.
    echo Please run manually: pip install -r requirements.txt
) else (
    echo Dependencies installed successfully.
)
echo.

echo [3/4] Creating startup shortcut...

set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "VBS_PATH=%~dp0start-hidden.vbs"
set "LNK_PATH=%STARTUP_FOLDER%\CloudMC.lnk"

powershell -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%LNK_PATH%'); $sc.TargetPath = '%VBS_PATH%'; $sc.WorkingDirectory = '%~dp0'; $sc.Description = 'CloudMC Server Host'; $sc.Save()"

if exist "%LNK_PATH%" (
    echo Startup shortcut created: %LNK_PATH%
) else (
    echo [ERROR] Failed to create startup shortcut!
    pause
    exit /b 1
)
echo.

echo [4/4] Installation complete!
echo.
echo ========================================
echo    Installation Successful!
echo ========================================
echo.
echo What was configured:
echo   1. Python dependencies installed
echo   2. Auto-startup added to Windows startup folder
echo   3. Watchdog will monitor and auto-restart services
echo   4. Management panel runs hidden in background
echo.
echo Access URL: http://localhost:5000
echo Default account: admin / admin123
echo.
echo CloudMC will start automatically on next boot!
echo.
set /p choice="Start now? (Y/N): "
if /i "%choice%"=="Y" (
    echo Starting...
    start "" "%VBS_PATH%"
    timeout /t 3 /nobreak >nul
    echo Started! Opening browser...
    start http://localhost:5000
)

echo.
pause
