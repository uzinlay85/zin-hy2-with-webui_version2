lucide.createIcons();
    const API_URL = 'api/users';
    let usersList = [];
    let filteredList = [];
    let currentView = localStorage.getItem('hy2_view') || 'list';
    let onlineData = {};   // { username: connection_count }
    let lastSeenData = {}; // { username: unix_timestamp }

    /* ── Helpers ── */
    function formatBytes(bytes, d = 2) {
        if (!+bytes) return '0 B';
        const k = 1024, sizes = ['B','KB','MB','GB','TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return `${parseFloat((bytes / Math.pow(k, i)).toFixed(d))} ${sizes[i]}`;
    }

    function timeAgo(unixTs) {
        if (!unixTs) return '';
        const secs = Math.floor(Date.now() / 1000) - unixTs;
        if (secs < 60)  return `${secs}s ago`;
        if (secs < 3600) return `${Math.floor(secs/60)}m ago`;
        if (secs < 86400) return `${Math.floor(secs/3600)}h ago`;
        return `${Math.floor(secs/86400)}d ago`;
    }

    function showToast(msg, icon = '<i data-lucide="check-circle" style="width:22px;height:22px;display:inline-block;vertical-align:middle;"></i>') {
        const t = document.getElementById('toast');
        document.getElementById('toastMsg').textContent = msg;
        t.children[0].innerHTML = icon;
        t.classList.add('show');
        setTimeout(() => t.classList.remove('show'), 2800);
    }

    /* ── Auth ── */
    let authHeader = sessionStorage.getItem('hy2_auth');

    document.addEventListener("DOMContentLoaded", () => {
        setView(currentView, false);
        if (authHeader) {
            document.getElementById('loginOverlay').style.display = 'none';
            fetchUsers();
            fetchOnline();
            fetchLastSeen();
        }
    });

    function setView(view, save = true) {
        currentView = view;
        if (save) localStorage.setItem('hy2_view', view);
        document.getElementById('btnList').classList.toggle('active', view === 'list');
        document.getElementById('btnCard').classList.toggle('active', view === 'card');
        renderUsers();
    }

    async function doLogin(e) {
        e.preventDefault();
        const u = document.getElementById('loginUsername').value;
        const p = document.getElementById('loginPassword').value;
        const btn = document.getElementById('loginBtn');
        const err = document.getElementById('loginError');
        btn.textContent = 'Signing in…'; btn.disabled = true;
        err.style.display = 'none';
        const token = 'Basic ' + btoa(u + ':' + p);
        try {
            const res = await fetch('api/login', { method: 'POST', headers: { Authorization: token } });
            if (res.ok) {
                sessionStorage.setItem('hy2_auth', token);
                authHeader = token;
                document.getElementById('loginOverlay').style.display = 'none';
                fetchUsers();
            } else { err.style.display = 'block'; }
        } catch { err.textContent = '<i data-lucide="x-circle" style="width:18px;height:18px;display:inline-block;vertical-align:middle;"></i> Connection failed'; err.style.display = 'block'; }
        btn.textContent = 'Sign In'; btn.disabled = false;
    }

    function doLogout() {
        sessionStorage.removeItem('hy2_auth');
        authHeader = null;
        document.getElementById('loginOverlay').style.display = 'flex';
    }

    async function apiFetch(url, opts = {}) {
        if (!opts.headers) opts.headers = {};
        if (authHeader) opts.headers.Authorization = authHeader;
        const res = await fetch(url, opts);
        if (res.status === 401) {
            sessionStorage.removeItem('hy2_auth'); authHeader = null;
            document.getElementById('loginOverlay').style.display = 'flex';
            throw new Error('Unauthorized');
        }
        return res;
    }

    /* ── Data ── */
    async function fetchUsers() {
        if (!authHeader) return;
        try {
            const res = await apiFetch(API_URL);
            const data = await res.json();
            usersList = data.users;
            filterUsers();
            updateStats();
        } catch (err) { console.error(err); }
    }

    function updateStats() {
        let active = 0, inactive = 0, totalBytes = 0;
        usersList.forEach(u => {
            totalBytes += u.data_used_bytes || 0;
            const expired = u.expire_date && new Date() > new Date(u.expire_date);
            const limitHit = u.data_limit_gb > 0 && u.data_used_bytes >= u.data_limit_gb * 1024**3;
            if (u.is_active && !expired && !limitHit) active++;
            else inactive++;
            totalBytes += u.data_used_bytes;
        });
        document.getElementById('statTotal').textContent = usersList.length;
        document.getElementById('statActive').textContent = active;
        document.getElementById('statInactive').textContent = inactive;
        document.getElementById('statUsage').textContent = formatBytes(totalBytes);
    }

    function filterUsers() {
        const q = (document.getElementById('searchInput').value || '').toLowerCase();
        filteredList = q
            ? usersList.filter(u => u.username.toLowerCase().includes(q) || u.password.toLowerCase().includes(q))
            : [...usersList];
        document.getElementById('userCountLabel').textContent = `${filteredList.length} user${filteredList.length !== 1 ? 's' : ''}`;
        renderUsers();
    }

    function getUserStatus(u) {
        const expired  = u.expire_date && new Date() > new Date(u.expire_date);
        const limitHit = u.data_limit_gb > 0 && u.data_used_bytes >= u.data_limit_gb * 1024**3;
        if (!u.is_active) return { label: '<i data-lucide="slash" style="width:12px;height:12px;display:inline-block;vertical-align:middle;"></i> Disabled', cls: 'badge-red' };
        if (expired)      return { label: '<i data-lucide="clock" style="width:12px;height:12px;display:inline-block;vertical-align:middle;"></i> Expired',  cls: 'badge-orange' };
        if (limitHit)     return { label: '<i data-lucide="wifi-off" style="width:12px;height:12px;display:inline-block;vertical-align:middle;"></i> Data Limit', cls: 'badge-red' };
        return                   { label: '<i data-lucide="check-circle" style="width:22px;height:22px;display:inline-block;vertical-align:middle;"></i> Active',   cls: 'badge-green' };
    }

    function renderUsers() {
        const container = document.getElementById('usersContainer');
        container.innerHTML = '';

        if (!filteredList.length) {
            container.innerHTML = `<div class="empty-state"><div class="icon"><i data-lucide="user" style="width:32px;height:32px;display:inline-block;vertical-align:middle;"></i></div><p>No users found</p></div>`;
            return;
        }

        if (currentView === 'list') {
            renderListView(container);
        } else {
            renderCardView(container);
        }
    }

    function renderListView(container) {
        const list = document.createElement('div');
        list.className = 'users-list';

        filteredList.forEach(u => {
            const used  = formatBytes(u.data_used_bytes);
            const limit = u.data_limit_gb > 0 ? `${u.data_limit_gb} GB` : '∞';
            const pct   = u.data_limit_gb > 0 ? Math.min(100, (u.data_used_bytes / (u.data_limit_gb * 1024**3)) * 100) : 0;
            const expText = u.expire_date ? u.expire_date.split('T')[0] : 'Never';
            const devText = u.device_limit > 0 ? u.device_limit : '∞';
            const { label, cls } = getUserStatus(u);
            const initials = u.username.slice(0,2).toUpperCase();
            const online = isOnline(u.username);
            const connCount = onlineData[u.username] || 0;
            const onlinePill = online
                ? `<span class="online-badge"><span class="online-dot" style="width:6px;height:6px;"></span>${connCount} conn</span>`
                : '';
            const lastSeen = !online && lastSeenData[u.username]
                ? `<span style="font-size:10px;color:var(--muted);">Last seen: ${timeAgo(lastSeenData[u.username])}</span>`
                : '';

            const item = document.createElement('div');
            item.className = 'list-item' + (online ? ' list-item-online' : '');
            item.innerHTML = `
                <div class="list-avatar ${online ? 'avatar-online' : 'avatar-offline-dim'}">${initials}</div>
                <div class="list-main">
                    <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap;">
                        <div class="list-name" title="${u.username}">${u.username}</div>
                        ${online ? `
                        <span class="online-status-badge">
                            <span class="dot-anim"></span>
                            ONLINE &nbsp;·&nbsp; ${connCount} conn${connCount > 1 ? 's' : ''}
                        </span>` : ''}
                    </div>
                    <div style="display:flex;align-items:center;gap:8px;">
                        <div class="list-pass">${u.password}</div>
                        ${lastSeen}
                    </div>
                </div>
                <div class="list-meta">
                    <div class="list-meta-item">
                        <div class="list-meta-label">Status</div>
                        <span class="badge ${cls}" style="font-size:10px;padding:2px 8px;">${label}</span>
                    </div>
                    <div class="list-meta-item">
                        <div class="list-meta-label">Expires</div>
                        <div class="list-meta-val" style="font-size:12px;">${expText}</div>
                    </div>
                    <div class="list-meta-item">
                        <div class="list-meta-label">Devices</div>
                        <div class="list-meta-val">${devText}</div>
                    </div>
                </div>
                <div class="list-progress">
                    <div class="progress-bar" style="margin-bottom:4px;">
                        <div class="progress-fill ${pct > 85 ? 'danger' : ''}" style="width:${pct}%"></div>
                    </div>
                    <div style="display:flex;justify-content:space-between;font-size:10px;color:var(--muted);">
                        <span>${used}</span><span>${limit}</span>
                    </div>
                </div>
                <div class="list-actions">
                    <button class="icon-btn copy" onclick="copyLink(${u.id})" title="Copy Link"><i data-lucide="link" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i></button>
                    <button class="icon-btn reset" onclick="resetData(${u.id})" title="Reset Data"><i data-lucide="refresh-cw" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i></button>
                    <button class="icon-btn edit" onclick="editUser(${u.id})" title="Edit"><i data-lucide="edit-3" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i></button>
                    <button class="icon-btn del" onclick="deleteUser(${u.id})" title="Delete"><i data-lucide="trash-2" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i></button>
                </div>
            `;
            list.appendChild(item);
        });
        container.appendChild(list);
        lucide.createIcons();
    }

    function renderCardView(container) {
        const grid = document.createElement('div');
        grid.className = 'users-grid';

        filteredList.forEach(u => {
            const used = formatBytes(u.data_used_bytes);
            const limit = u.data_limit_gb > 0 ? `${u.data_limit_gb} GB` : 'Unlimited';
            const pct   = u.data_limit_gb > 0 ? Math.min(100, (u.data_used_bytes / (u.data_limit_gb * 1024**3)) * 100) : 0;
            const expText = u.expire_date ? u.expire_date.split('T')[0] : 'Never';
            const devText = u.device_limit > 0 ? u.device_limit : '∞';
            const { label: badge, cls: bclass } = getUserStatus(u);
            const online = isOnline(u.username);
            const connCount = onlineData[u.username] || 0;
            const lastSeenText = !online && lastSeenData[u.username]
                ? timeAgo(lastSeenData[u.username]) : '';

            const card = document.createElement('div');
            card.className = 'user-card' + (online ? ' card-online' : '');
            card.innerHTML = `
                ${online ? `<div style="position:absolute;top:0;left:0;right:0;height:3px;background:linear-gradient(90deg,#10b981,#34d399);border-radius:16px 16px 0 0;"></div>` : ''}
                <div class="user-card-top">
                    <div class="user-info">
                        <div style="display:flex;align-items:center;gap:8px;margin-bottom:4px;">
                            <div class="user-name" title="${u.username}">${u.username}</div>
                        </div>
                        ${online
                            ? `<span class="online-status-badge" style="margin-bottom:6px;display:inline-flex;"><span class="dot-anim"></span>ONLINE &nbsp;·&nbsp; ${connCount} conn${connCount>1?'s':''}</span>`
                            : lastSeenText ? `<span style="font-size:11px;color:var(--muted);margin-bottom:4px;display:block;">Last seen: ${lastSeenText}</span>` : ''
                        }
                        <div class="user-pass">${u.password}</div>
                    </div>
                    <span class="badge ${bclass}">${badge}</span>
                </div>
                <div class="data-row">
                    <span class="data-label">Used / Limit</span>
                    <span class="data-value">${used} / ${limit}</span>
                </div>
                <div class="progress-bar">
                    <div class="progress-fill ${pct > 85 ? 'danger' : ''}" style="width:${pct}%"></div>
                </div>
                <div class="meta-row">
                    <div class="meta-item"><i data-lucide="calendar" style="width:14px;height:14px;display:inline-block;vertical-align:middle;margin-top:-2px;"></i> Expires: <span>${expText}</span></div>
                    <div class="meta-item"><i data-lucide="smartphone" style="width:14px;height:14px;display:inline-block;vertical-align:middle;margin-top:-2px;"></i> Devices: <span>${devText}</span></div>
                </div>
                <div class="card-actions">
                    <button class="action-btn copy" onclick="copyLink(${u.id})" title="Copy Link"><i data-lucide="link" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i> Copy</button>
                    <button class="action-btn reset" onclick="resetData(${u.id})" title="Reset Data"><i data-lucide="refresh-cw" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i> Reset</button>
                    <button class="action-btn edit" onclick="editUser(${u.id})" title="Edit"><i data-lucide="edit-3" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i> Edit</button>
                    <button class="action-btn del" onclick="deleteUser(${u.id})" title="Delete"><i data-lucide="trash-2" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i></button>
                </div>
            `;
            grid.appendChild(card);
        });
        container.appendChild(grid);
        lucide.createIcons();
    }

    /* ── Actions ── */
    function copyLink(id) {
        const u = usersList.find(x => x.id === id);
        if (!u) return;
        const domain = window.location.hostname;
        // <i data-lucide="check-circle" style="width:22px;height:22px;display:inline-block;vertical-align:middle;"></i> Universal link - app အားလုံးအတွက် (Clash Meta, Sing-box, ShadowRocket, NekoBox, V2rayN)
        const link = `hysteria2://${u.password}@${domain}:443?security=tls&obfs=salamander&obfs-password=OBFS_PASSWORD_PLACEHOLDER&fm=%7B%22quicParams%22%3A%7B%22udpHop%22%3A%7B%22ports%22%3A%2220000-50000%22%7D%7D%7D&mport=20000-50000&sni=${domain}#${u.username}`;
        navigator.clipboard.writeText(link)
            .then(() => showToast('Link copied to clipboard!', '<i data-lucide="link" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i>'))
            .catch(() => prompt('Copy this link:', link));
    }

    async function resetData(id) {
        if (!confirm('Reset used data to 0 for this user?')) return;
        try {
            await apiFetch(`${API_URL}/${id}/reset_data`, { method: 'POST' });
            showToast('Data usage reset!', '<i data-lucide="refresh-cw" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i>');
            fetchUsers();
        } catch (err) { console.error(err); }
    }

    async function deleteUser(id) {
        const u = usersList.find(x => x.id === id);
        if (!confirm(`Delete user "${u?.username}"? This cannot be undone.`)) return;
        try {
            await apiFetch(`${API_URL}/${id}`, { method: 'DELETE' });
            showToast('User deleted', '<i data-lucide="trash-2" style="width:14px;height:14px;display:inline-block;vertical-align:middle;"></i>');
            fetchUsers();
        } catch (err) { console.error(err); }
    }

    /* ── Modals ── */
    function openModal() {
        document.getElementById('modalTitle').textContent = 'Add New User';
        document.getElementById('userForm').reset();
        document.getElementById('userId').value = '';
        document.getElementById('password').value = Math.random().toString(36).slice(-6);
        document.getElementById('dataLimit').value = '0';
        document.getElementById('deviceLimit').value = '1';
        document.getElementById('isActive').checked = true;
        document.getElementById('userModal').classList.add('active');
    }

    function closeModal() { document.getElementById('userModal').classList.remove('active'); }

    function editUser(id) {
        const u = usersList.find(x => x.id === id);
        if (!u) return;
        document.getElementById('modalTitle').textContent = 'Edit User';
        document.getElementById('userId').value = u.id;
        document.getElementById('username').value = u.username;
        document.getElementById('password').value = u.password;
        document.getElementById('dataLimit').value = u.data_limit_gb;
        document.getElementById('deviceLimit').value = u.device_limit;
        document.getElementById('isActive').checked = u.is_active;
        document.getElementById('expireDate').value = u.expire_date ? u.expire_date.split('T')[0] : '';
        document.getElementById('userModal').classList.add('active');
    }

    async function saveUser(e) {
        e.preventDefault();
        const id = document.getElementById('userId').value;
        let exp = document.getElementById('expireDate').value;
        if (exp) exp = exp + 'T23:59:59Z';
        const payload = {
            username: document.getElementById('username').value,
            password: document.getElementById('password').value,
            data_limit_gb: parseFloat(document.getElementById('dataLimit').value) || 0,
            device_limit: parseInt(document.getElementById('deviceLimit').value) || 0,
            expire_date: exp,
            is_active: document.getElementById('isActive').checked
        };
        try {
            const res = await apiFetch(id ? `${API_URL}/${id}` : API_URL, {
                method: id ? 'PUT' : 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload)
            });
            if (res.ok) {
                closeModal();
                showToast(id ? 'User updated!' : 'User created!', '<i data-lucide="check-circle" style="width:22px;height:22px;display:inline-block;vertical-align:middle;"></i>');
                fetchUsers();
            } else {
                const err = await res.json();
                alert('Error: ' + (err.detail || 'Failed to save'));
            }
        } catch (err) { console.error(err); alert('Request failed'); }
    }

    function openAdminModal() {
        document.getElementById('adminForm').reset();
        document.getElementById('adminModal').classList.add('active');
    }
    function closeAdminModal() { document.getElementById('adminModal').classList.remove('active'); }

    async function updateAdmin(e) {
        e.preventDefault();
        try {
            const res = await apiFetch('api/admin', {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    new_username: document.getElementById('newAdminUser').value,
                    new_password: document.getElementById('newAdminPass').value
                })
            });
            if (res.ok) {
                alert('Admin credentials updated. Please login again.');
                sessionStorage.removeItem('hy2_auth');
                window.location.reload();
            } else {
                const err = await res.json();
                alert('Error: ' + (err.detail || 'Failed'));
            }
        } catch (err) { console.error(err); }
    }

    /* ── Backup & Restore ── */
    function openBackupModal() {
        document.getElementById('restoreFile').value = '';
        document.getElementById('restoreResult').style.display = 'none';
        document.getElementById('backupModal').classList.add('active');
    }
    function closeBackupModal() { document.getElementById('backupModal').classList.remove('active'); }

    async function doBackup() {
        const btn = document.getElementById('backupDownloadBtn');
        btn.textContent = '⏳ Preparing...'; btn.disabled = true;
        try {
            const res = await apiFetch('api/backup');
            if (!res.ok) throw new Error('Failed');
            const blob = await res.blob();
            const cd = res.headers.get('Content-Disposition') || '';
            const match = cd.match(/filename="([^"]+)"/);
            const filename = match ? match[1] : `hy2-backup-${Date.now()}.json`;
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url; a.download = filename; a.click();
            URL.revokeObjectURL(url);
            showToast('Backup downloaded!', '<i data-lucide="save" style="width:16px;height:16px;display:inline-block;vertical-align:middle;"></i>');
        } catch (err) {
            alert('Backup failed: ' + err.message);
        }
        btn.textContent = '<i data-lucide="save" style="width:16px;height:16px;display:inline-block;vertical-align:middle;"></i> Download Backup File'; btn.disabled = false;
    }

    async function doRestore() {
        const fileInput = document.getElementById('restoreFile');
        const mode = document.getElementById('restoreMode').value;
        const restoreAdmin = document.getElementById('restoreAdmin').checked;
        const resultDiv = document.getElementById('restoreResult');

        if (!fileInput.files.length) {
            alert('Please select a backup .json file first.');
            return;
        }

        const confirmMsg = mode === 'replace'
            ? '⚠️ REPLACE MODE: This will DELETE all current users and import from backup.\n\nAre you sure?'
            : 'Import users from backup? (Existing usernames will be skipped)';
        if (!confirm(confirmMsg)) return;

        const btn = document.getElementById('restoreBtn');
        btn.textContent = '⏳ Restoring...'; btn.disabled = true;
        resultDiv.style.display = 'none';

        try {
            const text = await fileInput.files[0].text();
            const backup = JSON.parse(text);

            const res = await apiFetch('api/restore', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ backup, mode, restore_admin: restoreAdmin })
            });

            const data = await res.json();
            if (res.ok && data.success) {
                resultDiv.style.display = 'block';
                resultDiv.innerHTML = `
                    <div style="background:rgba(16,185,129,0.1);border:1px solid rgba(16,185,129,0.3);border-radius:10px;padding:12px;">
                        <div style="color:#10b981;font-weight:700;margin-bottom:4px;"><i data-lucide="check-circle" style="width:22px;height:22px;display:inline-block;vertical-align:middle;"></i> Restore Complete!</div>
                        <div style="font-size:13px;color:var(--muted);">
                            Imported: <strong style="color:var(--text);">${data.imported}</strong> users &nbsp;·&nbsp;
                            Skipped: <strong style="color:var(--text);">${data.skipped}</strong> &nbsp;·&nbsp;
                            Mode: <strong style="color:var(--text);">${data.mode}</strong>
                        </div>
                    </div>`;
                fetchUsers();
                showToast(`Restored ${data.imported} users!`, '<i data-lucide="download" style="width:18px;height:18px;display:inline-block;vertical-align:middle;"></i>');
            } else {
                resultDiv.style.display = 'block';
                resultDiv.innerHTML = `<div style="background:rgba(239,68,68,0.1);border:1px solid rgba(239,68,68,0.3);border-radius:10px;padding:12px;color:#ef4444;"><i data-lucide="x-circle" style="width:18px;height:18px;display:inline-block;vertical-align:middle;"></i> ${data.detail || 'Restore failed'}</div>`;
            }
        } catch (err) {
            alert('Error: ' + err.message);
        }
        btn.textContent = '<i data-lucide="download" style="width:18px;height:18px;display:inline-block;vertical-align:middle;"></i> Restore Now'; btn.disabled = false;
    }

    /* ── Online Status ── */
    async function fetchOnline() {
        if (!authHeader) return;
        try {
            const res = await apiFetch('api/online');
            onlineData = await res.json();
            renderOnlinePanel();
            renderUsers();
            document.getElementById('statOnline').textContent = Object.keys(onlineData).length;
        } catch (err) { console.error('Online fetch error:', err); }
    }

    async function fetchLastSeen() {
        if (!authHeader) return;
        try {
            const res = await apiFetch('api/lastseen');
            lastSeenData = await res.json(); // { "username": unix_timestamp }
            renderUsers(); // re-render to update last seen labels
        } catch (err) { console.error('Last seen fetch error:', err); }
    }

    function renderOnlinePanel() {
        const body = document.getElementById('onlinePanelBody');
        const names = Object.keys(onlineData);
        if (!names.length) {
            body.innerHTML = '<div class="online-empty">No users online right now</div>';
            return;
        }
        body.innerHTML = names.map(name => {
            const count = onlineData[name];
            return `
                <div class="online-user-row">
                    <div class="online-dot"></div>
                    <div class="online-user-name">${name}</div>
                    <div class="online-conn-count"><span>${count}</span> connection${count > 1 ? 's' : ''}</div>
                </div>
            `;
        }).join('');
    }

    function toggleOnlinePanel() {
        document.getElementById('onlinePanel').classList.toggle('collapsed');
    }

    function isOnline(username) {
        return username in onlineData;
    }

    /* ── Init ── */
    setInterval(fetchUsers, 10000);
    setInterval(fetchOnline, 5000);   // poll online every 5s
    setInterval(fetchLastSeen, 10000); // poll last seen every 10s