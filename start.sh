#!/bin/bash
cd "$(dirname "$0")"

export SECRET_KEY="${SECRET_KEY:-cloud-mc-host-secret-key-2026}"
export ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

if [ ! -d "venv" ]; then
    echo "创建虚拟环境..."
    python3 -m venv venv
fi

source venv/bin/activate

echo "安装依赖..."
pip install -r requirements.txt

echo "启动CloudMC托管系统..."
echo "访问地址: http://localhost:5000"
echo "默认账号: admin / admin123"
echo ""

python app.py
