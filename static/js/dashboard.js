let currentPath = '';

async function fetchAPI(url, options = {}) {
    const response = await fetch(url, {
        headers: { 'Content-Type': 'application/json' },
        ...options
    });
    return response.json();
}

function showCreateModal() {
    document.getElementById('createModal').classList.add('active');
}

function closeCreateModal() {
    document.getElementById('createModal').classList.remove('active');
}

async function createServer() {
    const data = {
        name: document.getElementById('serverName').value || 'My Server',
        version: document.getElementById('serverVersion').value,
        loader: document.getElementById('serverLoader').value,
        memory: document.getElementById('serverMemory').value,
        port: parseInt(document.getElementById('serverPort').value)
    };
    const result = await fetchAPI('/api/servers', {
        method: 'POST',
        body: JSON.stringify(data)
    });
    if (result.success) {
        alert('服务器创建成功！请上传服务端JAR文件后启动。');
        location.reload();
    } else {
        alert(result.message || '创建失败');
    }
}

async function startServer(serverId) {
    if (!confirm('确定要启动服务器吗？')) return;
    const result = await fetchAPI(`/api/servers/${serverId}/start`, { method: 'POST' });
    alert(result.message);
    location.reload();
}

async function stopServer(serverId) {
    if (!confirm('确定要停止服务器吗？')) return;
    const result = await fetchAPI(`/api/servers/${serverId}/stop`, { method: 'POST' });
    alert(result.message);
    location.reload();
}

async function deleteServer(serverId) {
    if (!confirm('确定要删除服务器吗？所有数据将丢失！')) return;
    const result = await fetchAPI(`/api/servers/${serverId}/delete`, { method: 'DELETE' });
    alert(result.message);
    location.reload();
}

async function loadSystemStats() {
    try {
        const result = await fetchAPI('/api/system/stats');
        const stats = result.stats;
        document.getElementById('cpu-stat').textContent = stats.cpu_percent.toFixed(1) + '%';
        document.getElementById('mem-stat').textContent = stats.memory_percent.toFixed(1) + '%';
        document.getElementById('disk-stat').textContent = stats.disk_percent.toFixed(1) + '%';
    } catch (e) {}
}

setInterval(loadSystemStats, 5000);
loadSystemStats();
