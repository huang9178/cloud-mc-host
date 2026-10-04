const socket = io();
let currentPath = '';

async function fetchAPI(url, options = {}) {
    const response = await fetch(url, {
        headers: { 'Content-Type': 'application/json' },
        ...options
    });
    return response.json();
}

function switchTab(tabName) {
    document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
    document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));
    event.target.classList.add('active');
    document.getElementById(tabName + '-tab').classList.add('active');
    if (tabName === 'files') loadFiles();
    if (tabName === 'backups') loadBackups();
    if (tabName === 'console') loadLogs();
}

async function startServer() {
    if (!confirm('确定要启动服务器吗？')) return;
    const result = await fetchAPI(`/api/servers/${SERVER_ID}/start`, { method: 'POST' });
    alert(result.message);
    location.reload();
}

async function stopServer() {
    if (!confirm('确定要停止服务器吗？')) return;
    const result = await fetchAPI(`/api/servers/${SERVER_ID}/stop`, { method: 'POST' });
    alert(result.message);
    location.reload();
}

async function restartServer() {
    if (!confirm('确定要重启服务器吗？')) return;
    const result = await fetchAPI(`/api/servers/${SERVER_ID}/restart`, { method: 'POST' });
    alert(result.message);
    location.reload();
}

async function loadLogs() {
    try {
        const result = await fetchAPI(`/api/servers/${SERVER_ID}/logs?lines=200`);
        const output = document.getElementById('consoleOutput');
        output.innerHTML = result.logs.split('\n').map(line => {
            let className = 'log-line';
            if (line.includes('ERROR')) className = 'log-error';
            else if (line.includes('Done') || line.includes('Success')) className = 'log-success';
            else if (line.includes('INFO')) className = 'log-info';
            return `<div class="${className}">${escapeHtml(line)}</div>`;
        }).join('');
        output.scrollTop = output.scrollHeight;
    } catch (e) {}
}

function sendCommand() {
    const input = document.getElementById('commandInput');
    const command = input.value.trim();
    if (!command) return;
    socket.emit('send_command', { server_id: SERVER_ID, command });
    input.value = '';
    setTimeout(loadLogs, 500);
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

async function loadFiles() {
    try {
        const result = await fetchAPI(`/api/servers/${SERVER_ID}/files?path=${encodeURIComponent(currentPath)}`);
        document.getElementById('currentPath').textContent = '/' + currentPath;
        const list = document.getElementById('fileList');
        list.innerHTML = result.files.map(file => `
            <div class="file-item" ondblclick="openFile('${file.path}', '${file.type}')">
                <div class="file-icon">${file.type === 'directory' ? '📁' : '📄'}</div>
                <div class="file-name">${file.name}</div>
                <div class="file-size">${file.type === 'file' ? formatSize(file.size) : ''}</div>
                <div class="file-actions">
                    ${file.type === 'file' ? `<button class="btn btn-outline" onclick="downloadFile('${file.path}')">下载</button>` : ''}
                    <button class="btn btn-danger" onclick="deleteFile('${file.path}')">删除</button>
                </div>
            </div>
        `).join('');
    } catch (e) {}
}

function openFile(path, type) {
    if (type === 'directory') {
        currentPath = path;
        loadFiles();
    } else {
        editFile(path);
    }
}

function goBack() {
    if (currentPath) {
        const parts = currentPath.split('/');
        parts.pop();
        currentPath = parts.join('/');
        loadFiles();
    }
}

async function editFile(path) {
    try {
        const result = await fetchAPI(`/api/servers/${SERVER_ID}/files/content?path=${encodeURIComponent(path)}`);
        const content = prompt('编辑文件内容（仅支持文本文件）：', result.content || '');
        if (content !== null) {
            await fetchAPI(`/api/servers/${SERVER_ID}/files/content`, {
                method: 'POST',
                body: JSON.stringify({ path, content })
            });
            alert('文件已保存');
        }
    } catch (e) {}
}

async function downloadFile(path) {
    window.open(`/api/servers/${SERVER_ID}/files/download?path=${encodeURIComponent(path)}`, '_blank');
}

async function deleteFile(path) {
    if (!confirm('确定要删除这个文件/文件夹吗？')) return;
    await fetchAPI(`/api/servers/${SERVER_ID}/files/delete`, {
        method: 'POST',
        body: JSON.stringify({ path })
    });
    loadFiles();
}

function showUploadModal() {
    document.getElementById('uploadModal').classList.add('active');
}

function closeUploadModal() {
    document.getElementById('uploadModal').classList.remove('active');
}

async function uploadFile() {
    const input = document.getElementById('uploadFile');
    if (!input.files.length) { alert('请选择文件'); return; }
    const formData = new FormData();
    formData.append('path', currentPath);
    for (let file of input.files) {
        formData.append('file', file);
    }
    const response = await fetch(`/api/servers/${SERVER_ID}/files/upload`, {
        method: 'POST',
        body: formData
    });
    const result = await response.json();
    if (result.success) {
        alert('上传成功');
        closeUploadModal();
        loadFiles();
    } else {
        alert(result.message || '上传失败');
    }
}

function showNewFolderModal() {
    document.getElementById('newFolderModal').classList.add('active');
}

function closeNewFolderModal() {
    document.getElementById('newFolderModal').classList.remove('active');
}

async function createFolder() {
    const name = document.getElementById('newFolderName').value.trim();
    if (!name) { alert('请输入文件夹名称'); return; }
    await fetchAPI(`/api/servers/${SERVER_ID}/files`, {
        method: 'POST',
        body: JSON.stringify({ path: currentPath, name, action: 'mkdir' })
    });
    closeNewFolderModal();
    loadFiles();
}

async function loadBackups() {
    try {
        const result = await fetchAPI(`/api/servers/${SERVER_ID}/backups`);
        const list = document.getElementById('backupList');
        if (!result.backups.length) {
            list.innerHTML = '<div class="empty-state"><div class="empty-icon">💾</div><p>暂无备份</p></div>';
            return;
        }
        list.innerHTML = result.backups.map(backup => `
            <div class="backup-item">
                <div class="backup-icon">💾</div>
                <div class="backup-info">
                    <div class="backup-name">${backup.name}</div>
                    <div class="backup-meta">${formatSize(backup.size)} · ${new Date(backup.created_at * 1000).toLocaleString()}</div>
                </div>
                <div class="backup-actions">
                    <button class="btn btn-primary" onclick="restoreBackup('${backup.name}')">恢复</button>
                    <button class="btn btn-danger" onclick="deleteBackup('${backup.name}')">删除</button>
                </div>
            </div>
        `).join('');
    } catch (e) {}
}

async function createBackup() {
    const name = prompt('备份名称（留空自动生成）：', '');
    const result = await fetchAPI(`/api/servers/${SERVER_ID}/backups`, {
        method: 'POST',
        body: JSON.stringify({ name: name || null })
    });
    if (result.success) {
        alert('备份创建成功');
        loadBackups();
    } else {
        alert('创建失败');
    }
}

async function restoreBackup(name) {
    if (!confirm(`确定要恢复备份"${name}"吗？当前数据将被覆盖！`)) return;
    const result = await fetchAPI(`/api/servers/${SERVER_ID}/backups/restore`, {
        method: 'POST',
        body: JSON.stringify({ name })
    });
    alert(result.message);
    loadBackups();
}

async function deleteBackup(name) {
    if (!confirm('确定要删除这个备份吗？')) return;
    await fetchAPI(`/api/servers/${SERVER_ID}/backups/delete`, {
        method: 'POST',
        body: JSON.stringify({ name })
    });
    loadBackups();
}

async function saveSettings() {
    const data = {
        name: document.getElementById('settingName').value,
        memory: document.getElementById('settingMemory').value,
        port: parseInt(document.getElementById('settingPort').value)
    };
    await fetchAPI(`/api/servers/${SERVER_ID}`, {
        method: 'PUT',
        body: JSON.stringify(data)
    });
    alert('设置已保存');
}

async function loadServerStats() {
    try {
        const result = await fetchAPI(`/api/servers/${SERVER_ID}/stats`);
        const stats = result.stats;
        document.getElementById('serverStatus').textContent = stats.status === 'running' ? '运行中' : '已停止';
        document.getElementById('cpuUsage').textContent = stats.cpu_percent ? stats.cpu_percent.toFixed(1) + '%' : '--';
        document.getElementById('memUsage').textContent = stats.memory_mb ? (stats.memory_mb / 1024).toFixed(1) + 'GB' : '--';
    } catch (e) {}
}

function formatSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

socket.on('connect', () => {
    socket.emit('subscribe_console', { server_id: SERVER_ID });
});

socket.on('command_result', (data) => {
    loadLogs();
});

setInterval(() => {
    if (document.getElementById('console-tab').classList.contains('active')) {
        loadLogs();
    }
    loadServerStats();
}, 3000);

loadLogs();
loadServerStats();
