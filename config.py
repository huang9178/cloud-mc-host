import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(BASE_DIR, 'data')
SERVERS_DIR = os.path.join(DATA_DIR, 'servers')
BACKUPS_DIR = os.path.join(DATA_DIR, 'backups')

SECRET_KEY = os.environ.get('SECRET_KEY', 'cloud-mc-host-secret-key-2026')
ADMIN_USERNAME = os.environ.get('ADMIN_USERNAME', 'admin')
ADMIN_PASSWORD = os.environ.get('ADMIN_PASSWORD', 'admin123')

DOCKER_ENABLED = os.environ.get('DOCKER_ENABLED', 'false').lower() == 'true'
DEFAULT_JAVA_MEMORY = '2G'
DEFAULT_SERVER_PORT = 25565
MAX_SERVERS = 10

for d in [DATA_DIR, SERVERS_DIR, BACKUPS_DIR]:
    os.makedirs(d, exist_ok=True)
