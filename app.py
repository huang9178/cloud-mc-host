import os
import uuid
import time
from flask import Flask, render_template, request, redirect, url_for, session, jsonify, send_file, flash
from flask_socketio import SocketIO, emit
from config import SECRET_KEY, MAX_SERVERS
from core.auth import authenticate, create_user, get_user_servers, add_server_to_user
from core.server_manager import MCServer, list_servers
from core.file_manager import FileManager
from core.backup_manager import BackupManager

app = Flask(__name__)
app.config['SECRET_KEY'] = SECRET_KEY
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024
socketio = SocketIO(app, cors_allowed_origins="*")

def login_required(f):
    def wrapper(*args, **kwargs):
        if 'username' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    wrapper.__name__ = f.__name__
    return wrapper

@app.route('/')
def index():
    if 'username' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        user = authenticate(username, password)
        if user:
            session['username'] = user['username']
            session['role'] = user['role']
            return redirect(url_for('dashboard'))
        flash('用户名或密码错误', 'error')
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')
        if create_user(username, password):
            flash('注册成功，请登录', 'success')
            return redirect(url_for('login'))
        flash('用户名已存在', 'error')
    return render_template('register.html')

@app.route('/dashboard')
@login_required
def dashboard():
    servers = list_servers()
    user_servers = get_user_servers(session['username'])
    my_servers = [s for s in servers if s['id'] in user_servers or session['role'] == 'admin']
    return render_template('dashboard.html', servers=my_servers, username=session['username'])

@app.route('/server/<server_id>')
@login_required
def server_detail(server_id):
    server = MCServer(server_id)
    config = server.get_config()
    if not config:
        flash('服务器不存在', 'error')
        return redirect(url_for('dashboard'))
    return render_template('server.html', server=config, username=session['username'])

@app.route('/api/servers', methods=['GET'])
@login_required
def api_list_servers():
    servers = list_servers()
    user_servers = get_user_servers(session['username'])
    my_servers = [s for s in servers if s['id'] in user_servers or session['role'] == 'admin']
    return jsonify({'servers': my_servers})

@app.route('/api/servers', methods=['POST'])
@login_required
def api_create_server():
    data = request.get_json()
    name = data.get('name', 'My Server')
    version = data.get('version', '1.20.1')
    loader = data.get('loader', 'fabric')
    memory = data.get('memory', '2G')
    port = data.get('port', 25565)
    auto_start = data.get('auto_start', False)
    servers = list_servers()
    if len(servers) >= MAX_SERVERS:
        return jsonify({'success': False, 'message': '已达到最大服务器数量限制'})
    server_id = str(uuid.uuid4())[:8]
    server = MCServer(server_id)
    config = server.create(name, version, loader, memory, port, auto_start)
    add_server_to_user(session['username'], server_id)
    return jsonify({'success': True, 'server': config})

@app.route('/api/servers/<server_id>/start', methods=['POST'])
@login_required
def api_start_server(server_id):
    server = MCServer(server_id)
    success, message = server.start()
    return jsonify({'success': success, 'message': message})

@app.route('/api/servers/<server_id>/stop', methods=['POST'])
@login_required
def api_stop_server(server_id):
    server = MCServer(server_id)
    success, message = server.stop()
    return jsonify({'success': success, 'message': message})

@app.route('/api/servers/<server_id>/restart', methods=['POST'])
@login_required
def api_restart_server(server_id):
    server = MCServer(server_id)
    success, message = server.restart()
    return jsonify({'success': success, 'message': message})

@app.route('/api/servers/<server_id>/delete', methods=['DELETE'])
@login_required
def api_delete_server(server_id):
    server = MCServer(server_id)
    server.delete()
    return jsonify({'success': True, 'message': '服务器已删除'})

@app.route('/api/servers/<server_id>', methods=['PUT'])
@login_required
def api_update_server(server_id):
    data = request.get_json()
    server = MCServer(server_id)
    config = server.get_config()
    if not config:
        return jsonify({'success': False, 'message': '服务器不存在'})
    updates = {}
    if 'name' in data:
        updates['name'] = data['name']
    if 'memory' in data:
        updates['memory'] = data['memory']
    if 'port' in data:
        updates['port'] = data['port']
    if 'auto_start' in data:
        updates['auto_start'] = data['auto_start']
    if updates:
        config = server.update_config(**updates)
    return jsonify({'success': True, 'server': config})

@app.route('/api/servers/<server_id>/stats', methods=['GET'])
@login_required
def api_server_stats(server_id):
    server = MCServer(server_id)
    stats = server.get_stats()
    return jsonify({'stats': stats})

@app.route('/api/servers/<server_id>/logs', methods=['GET'])
@login_required
def api_server_logs(server_id):
    server = MCServer(server_id)
    lines = request.args.get('lines', 100, type=int)
    logs = server.get_logs(lines)
    return jsonify({'logs': logs})

@app.route('/api/servers/<server_id>/command', methods=['POST'])
@login_required
def api_server_command(server_id):
    data = request.get_json()
    command = data.get('command', '')
    server = MCServer(server_id)
    success, message = server.send_command(command)
    return jsonify({'success': success, 'message': message})

@app.route('/api/servers/<server_id>/files', methods=['GET'])
@login_required
def api_list_files(server_id):
    path = request.args.get('path', '')
    fm = FileManager(server_id)
    files = fm.list_files(path)
    return jsonify({'files': files, 'path': path})

@app.route('/api/servers/<server_id>/files/upload', methods=['POST'])
@login_required
def api_upload_file(server_id):
    path = request.form.get('path', '')
    if 'file' not in request.files:
        return jsonify({'success': False, 'message': '没有文件'})
    file = request.files['file']
    fm = FileManager(server_id)
    result = fm.upload_file(file, path)
    return jsonify({'success': True, 'file': result})

@app.route('/api/servers/<server_id>/files/download', methods=['GET'])
@login_required
def api_download_file(server_id):
    path = request.args.get('path', '')
    fm = FileManager(server_id)
    file_path = fm.download_file(path)
    if file_path:
        return send_file(file_path, as_attachment=True)
    return jsonify({'success': False, 'message': '文件不存在'})

@app.route('/api/servers/<server_id>/files/delete', methods=['POST'])
@login_required
def api_delete_file(server_id):
    data = request.get_json()
    path = data.get('path', '')
    fm = FileManager(server_id)
    success = fm.delete_file(path)
    return jsonify({'success': success})

@app.route('/api/servers/<server_id>/files/content', methods=['GET'])
@login_required
def api_get_file_content(server_id):
    path = request.args.get('path', '')
    fm = FileManager(server_id)
    content = fm.get_file_content(path)
    return jsonify({'content': content})

@app.route('/api/servers/<server_id>/files/content', methods=['POST'])
@login_required
def api_save_file_content(server_id):
    data = request.get_json()
    path = data.get('path', '')
    content = data.get('content', '')
    fm = FileManager(server_id)
    fm.save_file_content(path, content)
    return jsonify({'success': True})

@app.route('/api/servers/<server_id>/backups', methods=['GET'])
@login_required
def api_list_backups(server_id):
    bm = BackupManager(server_id)
    backups = bm.list_backups()
    return jsonify({'backups': backups})

@app.route('/api/servers/<server_id>/backups', methods=['POST'])
@login_required
def api_create_backup(server_id):
    data = request.get_json() or {}
    name = data.get('name')
    bm = BackupManager(server_id)
    backup = bm.create_backup(name)
    return jsonify({'success': True, 'backup': backup})

@app.route('/api/servers/<server_id>/backups/restore', methods=['POST'])
@login_required
def api_restore_backup(server_id):
    data = request.get_json()
    name = data.get('name', '')
    bm = BackupManager(server_id)
    success, message = bm.restore_backup(name)
    return jsonify({'success': success, 'message': message})

@app.route('/api/servers/<server_id>/backups/delete', methods=['POST'])
@login_required
def api_delete_backup(server_id):
    data = request.get_json()
    name = data.get('name', '')
    bm = BackupManager(server_id)
    success = bm.delete_backup(name)
    return jsonify({'success': success})

@app.route('/api/system/stats', methods=['GET'])
@login_required
def api_system_stats():
    import psutil
    stats = {
        'cpu_percent': psutil.cpu_percent(interval=0.1),
        'memory_total': psutil.virtual_memory().total,
        'memory_used': psutil.virtual_memory().used,
        'memory_percent': psutil.virtual_memory().percent,
        'disk_total': psutil.disk_usage('/').total,
        'disk_used': psutil.disk_usage('/').used,
        'disk_percent': psutil.disk_usage('/').percent,
        'servers_count': len(list_servers())
    }
    return jsonify({'stats': stats})

@socketio.on('connect')
def handle_connect():
    emit('connected', {'message': '已连接到控制台'})

@socketio.on('subscribe_console')
def handle_subscribe_console(data):
    server_id = data.get('server_id')
    session['console_server'] = server_id
    emit('subscribed', {'server_id': server_id})

@socketio.on('send_command')
def handle_send_command(data):
    server_id = data.get('server_id')
    command = data.get('command', '')
    server = MCServer(server_id)
    success, message = server.send_command(command)
    emit('command_result', {'success': success, 'message': message, 'command': command})

if __name__ == '__main__':
    print("=" * 50)
    print("  CloudMC 云服务器托管系统启动中...")
    print("=" * 50)
    print(f"  访问地址: http://localhost:5000")
    print(f"  默认账号: {ADMIN_USERNAME} / {ADMIN_PASSWORD}")
    print("=" * 50)

    # 自动启动配置了auto_start的服务器
    try:
        from core.server_manager import auto_start_servers
        started = auto_start_servers()
        if started:
            print(f"  已自动启动 {len(started)} 个服务器: {', '.join(started)}")
    except Exception as e:
        print(f"  自动启动检查失败: {e}")

    print("=" * 50)
    socketio.run(app, host='0.0.0.0', port=5000, debug=False, allow_unsafe_werkzeug=True)
