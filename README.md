# ☁️ CloudMC - 云MC服务器托管系统

一个开源的Minecraft服务器托管管理面板，支持多服务器管理、文件管理、实时控制台、备份恢复。

## ✨ 功能特性

- 🎮 **多服务器管理** - 创建/启动/停止/重启/删除多个MC服务器
- 🖥️ **实时控制台** - WebSocket实时日志，在线发送服务器命令
- 📁 **文件管理** - 上传/下载/删除/编辑文件，支持模组上传
- 💾 **备份系统** - 一键备份/恢复，ZIP压缩
- 👥 **用户系统** - 注册/登录，多用户隔离
- 📊 **资源监控** - CPU/内存/磁盘实时监控
- 🔧 **自定义配置** - 内存分配、端口、版本、加载器
- 🐳 **Docker支持** - 一键部署

## 🚀 快速开始

### 方式一：直接运行（推荐）

```bash
# Linux/Mac
chmod +x start.sh
./start.sh

# Windows
start.bat
```

### 方式二：Docker部署

```bash
docker-compose up -d
```

### 方式三：手动运行

```bash
pip install -r requirements.txt
python app.py
```

访问：http://localhost:5000

默认账号：`admin` / `admin123`

## 📖 使用说明

### 1. 创建服务器
1. 登录后点击"创建服务器"
2. 填写服务器名称、版本、加载器、内存、端口
3. 点击创建

### 2. 上传服务端
1. 进入服务器管理页面
2. 切换到"文件管理"标签
3. 上传服务端JAR文件（如fabric-server-launch.jar）
4. 确保JAR文件名与创建时的加载器匹配

### 3. 启动服务器
1. 点击"启动"按钮
2. 在"控制台"标签查看启动日志
3. 等待显示"Done"即启动成功

### 4. 安装模组
1. 在文件管理中进入`mods`文件夹（没有则新建）
2. 上传模组JAR文件
3. 重启服务器

## ⚙️ 配置说明

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SECRET_KEY` | cloud-mc-host-secret-key-2026 | Flask密钥 |
| `ADMIN_USERNAME` | admin | 管理员用户名 |
| `ADMIN_PASSWORD` | admin123 | 管理员密码 |
| `DOCKER_ENABLED` | false | 是否启用Docker模式 |
| `MAX_SERVERS` | 10 | 最大服务器数量 |

### 支持的服务端类型
- Fabric
- Forge
- Paper
- Vanilla（原版）

### 支持的版本
- 1.20.1
- 1.20.4
- 1.21
- 1.21.1
- 其他版本可手动上传JAR

## 📁 项目结构

```
cloud-mc-host/
├── app.py                 # 主程序
├── config.py              # 配置文件
├── requirements.txt       # Python依赖
├── Dockerfile             # Docker镜像
├── docker-compose.yml     # Docker Compose
├── start.sh               # Linux启动脚本
├── start.bat              # Windows启动脚本
├── core/                  # 核心模块
│   ├── auth.py            # 用户认证
│   ├── server_manager.py  # 服务器管理
│   ├── file_manager.py    # 文件管理
│   └── backup_manager.py  # 备份管理
├── templates/             # HTML模板
│   ├── login.html
│   ├── register.html
│   ├── dashboard.html
│   └── server.html
├── static/                # 静态文件
│   ├── css/style.css
│   └── js/
│       ├── dashboard.js
│       └── server.js
└── data/                  # 数据目录
    ├── servers/           # 服务器数据
    ├── backups/           # 备份文件
    └── users.json         # 用户数据
```

## 🔌 API接口

### 认证
- `POST /login` - 登录
- `POST /register` - 注册
- `GET /logout` - 退出

### 服务器
- `GET /api/servers` - 获取服务器列表
- `POST /api/servers` - 创建服务器
- `POST /api/servers/<id>/start` - 启动
- `POST /api/servers/<id>/stop` - 停止
- `POST /api/servers/<id>/restart` - 重启
- `DELETE /api/servers/<id>/delete` - 删除
- `GET /api/servers/<id>/stats` - 获取状态
- `GET /api/servers/<id>/logs` - 获取日志
- `POST /api/servers/<id>/command` - 发送命令

### 文件管理
- `GET /api/servers/<id>/files` - 列出文件
- `POST /api/servers/<id>/files/upload` - 上传文件
- `GET /api/servers/<id>/files/download` - 下载文件
- `POST /api/servers/<id>/files/delete` - 删除文件
- `GET /api/servers/<id>/files/content` - 读取文件
- `POST /api/servers/<id>/files/content` - 保存文件

### 备份
- `GET /api/servers/<id>/backups` - 列出备份
- `POST /api/servers/<id>/backups` - 创建备份
- `POST /api/servers/<id>/backups/restore` - 恢复备份
- `POST /api/servers/<id>/backups/delete` - 删除备份

### 系统
- `GET /api/system/stats` - 系统资源监控

## 🛡️ 安全建议

1. **修改默认密码** - 首次登录后立即修改管理员密码
2. **使用强密钥** - 设置复杂的`SECRET_KEY`环境变量
3. **反向代理** - 生产环境建议使用Nginx反向代理并启用HTTPS
4. **防火墙** - 只开放必要端口（5000管理端口，25565游戏端口）
5. **定期备份** - 定期创建服务器备份

## 🌐 内网穿透

使用frp或ngrok将管理面板和游戏端口暴露到公网：

```bash
# frp配置示例
[common]
server_addr = your-frp-server.com
server_port = 7000

[cloudmc-web]
type = http
local_port = 5000
custom_domains = mc.yourdomain.com

[minecraft]
type = tcp
local_ip = 127.0.0.1
local_port = 25565
remote_port = 25565
```

## 📝 注意事项

1. **Java环境** - 需要安装Java 17或更高版本
2. **内存分配** - 根据服务器物理内存合理分配，不要超过可用内存
3. **服务端JAR** - 创建服务器后需要手动上传对应版本的服务端JAR
4. **EULA** - 系统已自动同意Minecraft EULA
5. **端口冲突** - 多个服务器需要使用不同端口

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

MIT License
