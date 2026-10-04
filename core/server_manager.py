import json
import os
import subprocess
import time
import psutil
from config import SERVERS_DIR, DEFAULT_JAVA_MEMORY, DEFAULT_SERVER_PORT

class MCServer:
    def __init__(self, server_id):
        self.server_id = server_id
        self.server_dir = os.path.join(SERVERS_DIR, server_id)
        self.config_file = os.path.join(self.server_dir, 'server_config.json')
        self.process = None

    def create(self, name, version='1.20.1', loader='fabric', memory=DEFAULT_JAVA_MEMORY, port=DEFAULT_SERVER_PORT):
        os.makedirs(self.server_dir, exist_ok=True)
        config = {
            'id': self.server_id,
            'name': name,
            'version': version,
            'loader': loader,
            'memory': memory,
            'port': port,
            'status': 'stopped',
            'created_at': time.time(),
            'jar_file': f'{loader}-server-launch.jar'
        }
        with open(self.config_file, 'w') as f:
            json.dump(config, f, indent=2)
        eula_file = os.path.join(self.server_dir, 'eula.txt')
        with open(eula_file, 'w') as f:
            f.write('eula=true\n')
        return config

    def get_config(self):
        if os.path.exists(self.config_file):
            with open(self.config_file, 'r') as f:
                return json.load(f)
        return None

    def update_config(self, **kwargs):
        config = self.get_config()
        if config:
            config.update(kwargs)
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=2)
            return config
        return None

    def start(self):
        config = self.get_config()
        if not config:
            return False, '服务器不存在'
        if self.is_running():
            return False, '服务器已在运行'
        jar_file = os.path.join(self.server_dir, config['jar_file'])
        if not os.path.exists(jar_file):
            return False, f'服务端JAR不存在: {config["jar_file"]}'
        log_file = os.path.join(self.server_dir, 'server.log')
        cmd = [
            'java',
            f'-Xmx{config["memory"]}',
            f'-Xms{config["memory"]}',
            '-jar', jar_file,
            'nogui'
        ]
        with open(log_file, 'a') as log:
            self.process = subprocess.Popen(
                cmd,
                cwd=self.server_dir,
                stdout=log,
                stderr=subprocess.STDOUT,
                stdin=subprocess.PIPE
            )
        self.update_config(status='running', pid=self.process.pid)
        return True, '服务器启动中'

    def stop(self):
        config = self.get_config()
        if not config:
            return False, '服务器不存在'
        if not self.is_running():
            return False, '服务器未运行'
        pid = config.get('pid')
        if pid:
            try:
                p = psutil.Process(pid)
                p.terminate()
                p.wait(timeout=30)
            except:
                try:
                    p.kill()
                except:
                    pass
        self.update_config(status='stopped', pid=None)
        return True, '服务器已停止'

    def restart(self):
        self.stop()
        time.sleep(3)
        return self.start()

    def is_running(self):
        config = self.get_config()
        if not config:
            return False
        pid = config.get('pid')
        if pid:
            try:
                return psutil.pid_exists(pid)
            except:
                return False
        return False

    def get_logs(self, lines=100):
        log_file = os.path.join(self.server_dir, 'server.log')
        if os.path.exists(log_file):
            with open(log_file, 'r') as f:
                all_lines = f.readlines()
                return ''.join(all_lines[-lines:])
        return '暂无日志'

    def send_command(self, command):
        if not self.is_running():
            return False, '服务器未运行'
        config = self.get_config()
        pid = config.get('pid')
        if pid:
            try:
                p = psutil.Process(pid)
                for child in p.children(recursive=True):
                    if child.name() == 'java':
                        child_pid = child.pid
                        break
                else:
                    child_pid = pid
            except:
                child_pid = pid
        try:
            with open(f'/proc/{child_pid}/fd/0', 'w') as stdin:
                stdin.write(command + '\n')
            return True, '命令已发送'
        except:
            return False, '发送命令失败'

    def delete(self):
        if self.is_running():
            self.stop()
        import shutil
        if os.path.exists(self.server_dir):
            shutil.rmtree(self.server_dir)
        return True

    def get_stats(self):
        config = self.get_config()
        if not config:
            return None
        stats = {
            'id': self.server_id,
            'name': config['name'],
            'status': 'running' if self.is_running() else 'stopped',
            'version': config['version'],
            'loader': config['loader'],
            'memory': config['memory'],
            'port': config['port'],
            'players': 0,
            'tps': 0
        }
        if self.is_running():
            pid = config.get('pid')
            if pid:
                try:
                    p = psutil.Process(pid)
                    stats['cpu_percent'] = p.cpu_percent(interval=0.1)
                    stats['memory_mb'] = p.memory_info().rss / 1024 / 1024
                except:
                    pass
        return stats


def list_servers():
    servers = []
    if os.path.exists(SERVERS_DIR):
        for server_id in os.listdir(SERVERS_DIR):
            server_dir = os.path.join(SERVERS_DIR, server_id)
            if os.path.isdir(server_dir):
                config_file = os.path.join(server_dir, 'server_config.json')
                if os.path.exists(config_file):
                    with open(config_file, 'r') as f:
                        config = json.load(f)
                    servers.append(config)
    return servers
