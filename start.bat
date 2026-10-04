@echo off
title CloudMC

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

python app.py

pause
