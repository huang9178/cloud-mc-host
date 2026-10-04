@echo off
title CloudMC Diagnostic Tool

echo ========================================
echo    CloudMC Diagnostic Tool
echo ========================================
echo.

cd /d "%~dp0"

echo [1] Current directory:
cd
echo.

echo [2] Checking Python...
where python
if errorlevel 1 (
    echo [FAIL] Python NOT found!
    echo.
    echo Please install Python first:
    echo 1. Download: https://www.python.org/downloads/
    echo 2. Run installer
    echo 3. CHECK "Add Python to PATH" !!!
    echo 4. Click Install Now
    echo 5. RESTART your computer!
    echo.
) else (
    echo [OK] Python found
    python --version
)
echo.

echo [3] Checking pip...
where pip
if errorlevel 1 (
    echo [FAIL] pip NOT found
) else (
    echo [OK] pip found
    pip --version
)
echo.

echo [4] Checking required packages...
python -c "import flask; print('[OK] flask', flask.__version__)" 2>nul || echo "[MISSING] flask"
python -c "import flask_socketio; print('[OK] flask_socketio')" 2>nul || echo "[MISSING] flask_socketio"
python -c "import flask_login; print('[OK] flask_login')" 2>nul || echo "[MISSING] flask_login"
python -c "import psutil; print('[OK] psutil')" 2>nul || echo "[MISSING] psutil"
echo.

echo [5] Checking app.py...
if exist app.py (
    echo [OK] app.py exists
    python -c "import app; print('[OK] app.py imports successfully')" 2>&1
) else (
    echo [FAIL] app.py NOT found!
    echo Make sure you extracted ALL files and are running from the correct folder.
)
echo.

echo [6] Checking port 5000...
netstat -ano | find ":5000" >nul
if errorlevel 1 (
    echo [OK] Port 5000 is free
) else (
    echo [WARN] Port 5000 is already in use!
    netstat -ano | find ":5000"
)
echo.

echo ========================================
echo    Diagnostic Complete
echo ========================================
echo.
echo If everything shows [OK], run start.bat to launch.
echo If something shows [FAIL] or [MISSING], see above for fix.
echo.
pause
