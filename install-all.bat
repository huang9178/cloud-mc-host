@echo off
title CloudMC One-Click Installer (Including Python)
setlocal enabledelayedexpansion

echo ========================================
echo    CloudMC One-Click Installer
echo    (Auto-install Python if needed)
echo ========================================
echo.

cd /d "%~dp0"

REM ============================================
REM Step 1: Check if Python is already installed
REM ============================================
echo [Step 1/6] Checking Python...
where python >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
    echo [OK] Python already installed: !PYVER!
    goto :python_ok
)

echo [INFO] Python not found. Will install automatically.
echo.

REM ============================================
REM Step 2: Try winget first (Windows 10/11 built-in)
REM ============================================
echo [Step 2/6] Installing Python...
echo.

where winget >nul 2>&1
if not errorlevel 1 (
    echo [Method 1] Using winget to install Python...
    winget install Python.Python.3.12 --accept-package-agreements --accept-source-agreements --silent
    if not errorlevel 1 (
        echo [OK] Python installed via winget!
        goto :refresh_path
    )
    echo [WARN] winget install failed, trying download method...
)

REM ============================================
REM Step 3: Download Python installer directly
REM ============================================
echo [Method 2] Downloading Python installer...

set "PYTHON_URL=https://www.python.org/ftp/python/3.12.7/python-3.12.7-amd64.exe"
set "PYTHON_INSTALLER=%TEMP%\python-installer.exe"

echo Downloading from: %PYTHON_URL%
echo.

REM Use PowerShell to download (more reliable than certutil)
powershell -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%PYTHON_INSTALLER%' -UseBasicParsing; Write-Host 'Download complete' } catch { Write-Host ('Download failed: ' + $_.Exception.Message); exit 1 }"

if not exist "%PYTHON_INSTALLER%" (
    echo.
    echo [ERROR] Failed to download Python installer!
    echo.
    echo Please install Python manually:
    echo 1. Open: https://www.python.org/downloads/
    echo 2. Download and run installer
    echo 3. CHECK "Add Python to PATH"
    echo 4. Restart computer
    echo 5. Run this script again
    echo.
    pause
    exit /b 1
)

echo.
echo [Method 2] Installing Python silently (this may take 1-2 minutes)...
echo Please wait, do not close this window!
echo.

REM Silent install: for all users, add to PATH, no UI
"%PYTHON_INSTALLER%" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 Include_pip=1 Include_tcltk=1

if errorlevel 1 (
    echo [ERROR] Python installation failed!
    echo Trying per-user install...
    "%PYTHON_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0 Include_pip=1
)

REM Clean up installer
del "%PYTHON_INSTALLER%" 2>nul

:refresh_path
echo.
echo [Step 3/6] Refreshing environment variables...

REM Refresh PATH from registry
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "SYSTEM_PATH=%%b"
for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"
set "PATH=%SYSTEM_PATH%;%USER_PATH%"

REM Also add common Python paths manually
set "PATH=%PATH%;%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;C:\Program Files\Python312;C:\Program Files\Python312\Scripts"

echo [OK] Environment variables refreshed.
echo.

:python_ok
REM ============================================
REM Step 4: Verify Python
REM ============================================
echo [Step 4/6] Verifying Python installation...

where python >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Python still not found after installation!
    echo.
    echo Please RESTART your computer, then run this script again.
    echo (Environment variables require restart to take effect)
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('python --version 2^>^&1') do set PYVER=%%i
echo [OK] Python is working: !PYVER!
echo.

REM ============================================
REM Step 5: Install Python dependencies
REM ============================================
echo [Step 5/6] Installing Python dependencies...
echo (This may take 1-3 minutes on first run)
echo.

python -m pip install --upgrade pip --quiet
python -m pip install -r requirements.txt

if errorlevel 1 (
    echo [WARN] Some dependencies may have failed. Trying again with --user...
    python -m pip install --user -r requirements.txt
)

echo [OK] Dependencies installed.
echo.

REM ============================================
REM Step 6: Setup auto-start and launch
REM ============================================
echo [Step 6/6] Setting up auto-start and launching...

set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "VBS_PATH=%~dp0start-hidden.vbs"
set "LNK_PATH=%STARTUP_FOLDER%\CloudMC.lnk"

if not exist "%STARTUP_FOLDER%" mkdir "%STARTUP_FOLDER%"

powershell -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%LNK_PATH%'); $sc.TargetPath = '%VBS_PATH%'; $sc.WorkingDirectory = '%~dp0'; $sc.Description = 'CloudMC Server Host'; $sc.Save()" 2>nul

echo [OK] Auto-start configured.
echo.

echo Starting CloudMC in background...
start "" "%VBS_PATH%"

timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo    Installation Complete!
echo ========================================
echo.
echo Python: !PYVER!
echo Access URL: http://localhost:5000
echo Default account: admin / admin123
echo.
echo CloudMC is now running and will auto-start on boot!
echo.
echo Opening browser in 3 seconds...
timeout /t 3 /nobreak >nul
start http://localhost:5000

echo.
echo You can close this window now.
echo To stop CloudMC, run: uninstall-startup.bat
echo.
pause
