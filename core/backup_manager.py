import os
import time
import zipfile
import shutil
from config import SERVERS_DIR, BACKUPS_DIR

class BackupManager:
    def __init__(self, server_id):
        self.server_id = server_id
        self.server_dir = os.path.join(SERVERS_DIR, server_id)
        self.backup_dir = os.path.join(BACKUPS_DIR, server_id)
        os.makedirs(self.backup_dir, exist_ok=True)

    def create_backup(self, name=None):
        if not name:
            name = f'backup_{time.strftime("%Y%m%d_%H%M%S")}'
        backup_file = os.path.join(self.backup_dir, f'{name}.zip')
        with zipfile.ZipFile(backup_file, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(self.server_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, self.server_dir)
                    zipf.write(file_path, arcname)
        return {
            'name': name,
            'file': backup_file,
            'size': os.path.getsize(backup_file),
            'created_at': time.time()
        }

    def list_backups(self):
        backups = []
        if os.path.exists(self.backup_dir):
            for file in os.listdir(self.backup_dir):
                if file.endswith('.zip'):
                    file_path = os.path.join(self.backup_dir, file)
                    backups.append({
                        'name': file.replace('.zip', ''),
                        'file': file_path,
                        'size': os.path.getsize(file_path),
                        'created_at': os.path.getctime(file_path)
                    })
        return sorted(backups, key=lambda x: x['created_at'], reverse=True)

    def restore_backup(self, backup_name):
        backup_file = os.path.join(self.backup_dir, f'{backup_name}.zip')
        if not os.path.exists(backup_file):
            return False, '备份不存在'
        if os.path.exists(self.server_dir):
            shutil.rmtree(self.server_dir)
        os.makedirs(self.server_dir, exist_ok=True)
        with zipfile.ZipFile(backup_file, 'r') as zipf:
            zipf.extractall(self.server_dir)
        return True, '备份已恢复'

    def delete_backup(self, backup_name):
        backup_file = os.path.join(self.backup_dir, f'{backup_name}.zip')
        if os.path.exists(backup_file):
            os.remove(backup_file)
            return True
        return False

    def get_backup_size(self):
        total_size = 0
        if os.path.exists(self.backup_dir):
            for file in os.listdir(self.backup_dir):
                file_path = os.path.join(self.backup_dir, file)
                if os.path.isfile(file_path):
                    total_size += os.path.getsize(file_path)
        return total_size
