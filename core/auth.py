import json
import os
import hashlib
from config import DATA_DIR, ADMIN_USERNAME, ADMIN_PASSWORD

USERS_FILE = os.path.join(DATA_DIR, 'users.json')

def _load_users():
    if os.path.exists(USERS_FILE):
        with open(USERS_FILE, 'r') as f:
            return json.load(f)
    users = {}
    users[ADMIN_USERNAME] = {
        'password': hashlib.sha256(ADMIN_PASSWORD.encode()).hexdigest(),
        'role': 'admin',
        'servers': []
    }
    _save_users(users)
    return users

def _save_users(users):
    with open(USERS_FILE, 'w') as f:
        json.dump(users, f, indent=2)

def authenticate(username, password):
    users = _load_users()
    if username in users:
        hashed = hashlib.sha256(password.encode()).hexdigest()
        if users[username]['password'] == hashed:
            return {'username': username, 'role': users[username]['role']}
    return None

def create_user(username, password, role='user'):
    users = _load_users()
    if username in users:
        return False
    users[username] = {
        'password': hashlib.sha256(password.encode()).hexdigest(),
        'role': role,
        'servers': []
    }
    _save_users(users)
    return True

def get_user_servers(username):
    users = _load_users()
    if username in users:
        return users[username].get('servers', [])
    return []

def add_server_to_user(username, server_id):
    users = _load_users()
    if username in users:
        if server_id not in users[username]['servers']:
            users[username]['servers'].append(server_id)
            _save_users(users)
            return True
    return False
