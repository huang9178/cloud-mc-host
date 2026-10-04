@echo off
chcp 65001 >nul
title CloudMC 开机自启动安装程序

echo ========================================
echo    CloudMC 开机自启动安装程序
echo ========================================
echo.

cd /d "%~dp0"

REM 检查Python是否安装
python --version >nul 2>&1
if errorlevel 1 (
    echo [错误] 未检测到Python，请先安装Python 3.8+
    echo 下载地址: https://www.python.org/downloads/
    pause
    exit /b 1
)

echo [1/4] 检查Python环境... OK
python --version

echo [2/4] 安装Python依赖...
pip install -r requirements.txt -q
if errorlevel 1 (
    echo [警告] 依赖安装可能失败，请手动运行: pip install -r requirements.txt
) else (
    echo 依赖安装完成
)

echo [3/4] 创建启动快捷方式...

REM 获取启动文件夹路径
set "STARTUP_FOLDER=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

REM 创建VBS启动脚本的快捷方式
set "VBS_PATH=%~dp0start-hidden.vbs"
set "LNK_PATH=%STARTUP_FOLDER%\CloudMC.lnk"

REM 使用PowerShell创建快捷方式
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $sc = $ws.CreateShortcut('%LNK_PATH%'); $sc.TargetPath = '%VBS_PATH%'; $sc.WorkingDirectory = '%~dp0'; $sc.Description = 'CloudMC云服务器托管系统'; $sc.Save()"

if exist "%LNK_PATH%" (
    echo 快捷方式创建成功: %LNK_PATH%
) else (
    echo [错误] 快捷方式创建失败
    pause
    exit /b 1
)

echo [4/4] 配置完成！
echo.
echo ========================================
echo    安装成功！
echo ========================================
echo.
echo 已配置以下内容：
echo   1. Python依赖已安装
echo   2. 开机自启动已添加到启动文件夹
echo   3. 守护进程会自动监控并重启服务
echo   4. 管理面板后台隐藏运行（无弹窗）
echo.
echo 访问地址: http://localhost:5000
echo 默认账号: admin / admin123
echo.
echo 下次开机时，CloudMC会自动启动！
echo.
echo 是否现在启动？(Y/N)
set /p choice=
if /i "%choice%"=="Y" (
    echo 正在启动...
    start "" "%VBS_PATH%"
    timeout /t 3 /nobreak >nul
    echo 启动完成！浏览器将自动打开...
    start http://localhost:5000
)

echo.
pause
