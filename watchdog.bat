@echo off
chcp 65001 >nul
title CloudMC 守护进程

cd /d "%~dp0"

echo ========================================
echo    CloudMC 守护进程已启动
echo    监控管理面板和MC服务器
echo    关闭此窗口将停止所有服务
echo ========================================
echo.

:loop
    REM 检查管理面板是否运行
    tasklist /fi "imagename eq python.exe" /v | find /i "app.py" >nul
    if errorlevel 1 (
        echo [%date% %time%] 管理面板未运行，正在启动...
        start "CloudMC管理面板" /min python app.py
        timeout /t 5 /nobreak >nul
    )

    REM 检查MC服务器是否运行（如果配置了自动启动）
    if exist "data\servers" (
        for /d %%d in ("data\servers\*") do (
            if exist "%%d\server_config.json" (
                REM 检查是否配置了自动启动
                findstr /c:"\"auto_start\": true" "%%d\server_config.json" >nul 2>&1
                if not errorlevel 1 (
                    REM 检查Java进程是否运行
                    tasklist /fi "imagename eq java.exe" | find /i "java.exe" >nul
                    if errorlevel 1 (
                        echo [%date% %time%] MC服务器未运行，正在启动...
                        REM 这里可以添加自动启动MC服务器的逻辑
                    )
                )
            )
        )
    )

    timeout /t 30 /nobreak >nul
    goto loop
