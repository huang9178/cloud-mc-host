@echo off
chcp 65001 >nul
title CloudMC 开机自启动卸载程序

echo ========================================
echo    CloudMC 开机自启动卸载程序
echo ========================================
echo.

REM 获取启动文件夹路径
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
set "LNK_PATH=%STARTUP_FOLDER%\CloudMC.lnk"

echo [1/2] 移除开机自启动...
if exist "%LNK_PATH%" (
    del "%LNK_PATH%"
    echo 已移除: %LNK_PATH%
) else (
    echo 未找到开机自启动项（可能已被移除）
)

echo [2/2] 停止正在运行的服务...
taskkill /f /im python.exe 2>nul
echo 已停止所有Python进程

echo.
echo ========================================
echo    卸载完成！
echo ========================================
echo.
echo CloudMC开机自启动已移除。
echo 如需重新安装，请运行 install-startup.bat
echo.
pause
