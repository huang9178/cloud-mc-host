@echo off
cd /d "%~dp0"

if not exist venv (
    echo 创建虚拟环境...
    python -m venv venv
)

call venv\Scripts\activate.bat

echo 安装依赖...
pip install -r requirements.txt

echo 启动CloudMC托管系统...
echo 访问地址: http://localhost:5000
echo 默认账号: admin / admin123
echo.

python app.py

pause
