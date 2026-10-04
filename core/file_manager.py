import os
import shutil
import zipfile
from config import SERVERS_DIR

class FileManager:
    def __init__(self, server_id):
        self.server_id = server_id
        self.server_dir = os.path.join(SERVERS_DIR, server_id)

    def list_files(self, path=''):
        target_dir = os.path.join(self.server_dir, path)
        if not os.path.exists(target_dir):
            return []
        files = []
        for item in os.listdir(target_dir):
            item_path = os.path.join(target_dir, item)
            if os.path.isdir(item_path):
                files.append({
                    'name': item,
                    'type': 'directory',
                    'size': 0,
                    'path': os.path.join(path, item)
                })
            else:
                files.append({
                    'name': item,
                    'type': 'file',
                    'size': os.path.getsize(item_path),
                    'path': os.path.join(path, item)
                })
        return sorted(files, key=lambda x: (x['type'] != 'directory', x['name']))

    def upload_file(self, file_storage, path=''):
        target_dir = os.path.join(self.server_dir, path)
        os.makedirs(target_dir, exist_ok=True)
        filename = file_storage.filename
        target_path = os.path.join(target_dir, filename)
        file_storage.save(target_path)
        return {'name': filename, 'path': os.path.join(path, filename), 'size': os.path.getsize(target_path)}

    def download_file(self, path):
        target_path = os.path.join(self.server_dir, path)
        if os.path.exists(target_path) and os.path.isfile(target_path):
            return target_path
        return None

    def delete_file(self, path):
        target_path = os.path.join(self.server_dir, path)
        if os.path.exists(target_path):
            if os.path.isdir(target_path):
                shutil.rmtree(target_path)
            else:
                os.remove(target_path)
            return True
        return False

    def create_directory(self, path, name):
        target_dir = os.path.join(self.server_dir, path, name)
        os.makedirs(target_dir, exist_ok=True)
        return True

    def rename_file(self, path, new_name):
        old_path = os.path.join(self.server_dir, path)
        if not os.path.exists(old_path):
            return False
        dir_path = os.path.dirname(old_path)
        new_path = os.path.join(dir_path, new_name)
        os.rename(old_path, new_path)
        return True

    def get_file_content(self, path):
        target_path = os.path.join(self.server_dir, path)
        if os.path.exists(target_path) and os.path.isfile(target_path):
            try:
                with open(target_path, 'r', encoding='utf-8', errors='ignore') as f:
                    return f.read()
            except:
                return None
        return None

    def save_file_content(self, path, content):
        target_path = os.path.join(self.server_dir, path)
        os.makedirs(os.path.dirname(target_path), exist_ok=True)
        with open(target_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return True

    def get_directory_size(self, path=''):
        target_dir = os.path.join(self.server_dir, path)
        total_size = 0
        for dirpath, dirnames, filenames in os.walk(target_dir):
            for f in filenames:
                fp = os.path.join(dirpath, f)
                if os.path.exists(fp):
                    total_size += os.path.getsize(fp)
        return total_size
