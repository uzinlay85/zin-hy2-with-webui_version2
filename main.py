import sqlite3
import datetime
import asyncio
import httpx
import time
from fastapi import FastAPI, Request, HTTPException, Depends, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import secrets
import bcrypt
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

app = FastAPI(title="Hysteria 2 Panel API")
security = HTTPBasic()

# Security Setup
limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Removed permissive CORSMiddleware to enforce Same-Origin Policy

DB_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "database.db")
HYSTERIA_TRAFFIC_API = "http://127.0.0.1:8080"
HYSTERIA_SECRET = "" # If you set a secret in config.yaml, put it here

# In-memory last seen tracking
last_seen_db = {}      # {"username": unix_timestamp}
previous_online = set() # track previous online set to detect disconnects

# Serve static files for the frontend
os.makedirs("static", exist_ok=True)
app.mount("/static", StaticFiles(directory="static"), name="static")

def get_db():
    conn = sqlite3.connect(DB_FILE, check_same_thread=False)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    conn = get_db()
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            display_password TEXT,
            data_limit_gb REAL DEFAULT 0,
            data_used_bytes INTEGER DEFAULT 0,
            expire_date TEXT,
            device_limit INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT 1,
            role TEXT DEFAULT 'user'
        )
    ''')
    # Migration: add display_password column for existing databases
    try:
        c.execute("ALTER TABLE users ADD COLUMN display_password TEXT")
    except Exception:
        pass  # Column already exists
    
    # Create default admin if not exists
    c.execute("SELECT * FROM users WHERE role='admin'")
    if not c.fetchone():
        c.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", 
                  ("admin", "ADMIN_PASSWORD_PLACEHOLDER", "admin"))
    conn.commit()
    conn.close()

init_db()

# Models
class UserCreate(BaseModel):
    username: str
    password: str
    data_limit_gb: float = 0.0
    expire_date: str = ""
    device_limit: int = 0
    is_active: bool = True

class AdminUpdate(BaseModel):
    new_username: str
    new_password: str

def get_current_admin(credentials: HTTPBasicCredentials = Depends(security)):
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT * FROM users WHERE username = ? AND role = 'admin'", (credentials.username,))
    admin = c.fetchone()
    
    if not admin:
        conn.close()
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
        
    db_password = admin["password"]
    is_valid = False
    
    # Check if password is mathematically hashed
    if db_password.startswith("$2b$") or db_password.startswith("$2a$"):
        is_valid = bcrypt.checkpw(credentials.password.encode('utf-8'), db_password.encode('utf-8'))
    else:
        # Plaintext check (Transparent Upgrade to Hash)
        if db_password == credentials.password:
            is_valid = True
            hashed_password = bcrypt.hashpw(credentials.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            c.execute("UPDATE users SET password = ? WHERE id = ?", (hashed_password, admin["id"]))
            conn.commit()

    conn.close()
    
    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    return admin["username"]

@app.post("/api/login")
@limiter.limit("5/minute")
def login(request: Request, admin: str = Depends(get_current_admin)):
    return {"success": True, "admin": admin}

@app.put("/api/admin")
@limiter.limit("5/minute")
def update_admin(request: Request, data: AdminUpdate, current_admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    try:
        hashed_password = bcrypt.hashpw(data.new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        c.execute("UPDATE users SET username=?, password=? WHERE username=? AND role='admin'", 
                  (data.new_username, hashed_password, current_admin))
        conn.commit()
    except sqlite3.IntegrityError:
        conn.close()
        raise HTTPException(status_code=400, detail="Username already exists")
    conn.close()
    return {"success": True}

# --- Hysteria 2 Authentication Endpoint ---
@app.post("/auth")
async def hysteria_auth(request: Request):
    """
    Hysteria 2 calls this endpoint when a client connects.
    Payload: {"addr": "...", "auth": "username:password", "tx": 0, "rx": 0}
    """
    try:
        data = await request.json()
    except:
        return JSONResponse({"ok": False, "error": "invalid json"})
    
    auth_str = data.get("auth", "")
    
    conn = get_db()
    c = conn.cursor()
    
    user = None
    input_password = ""
    
    if ":" in auth_str:
        username, input_password = auth_str.split(":", 1)
        c.execute("SELECT * FROM users WHERE username = ? AND role != 'admin'", (username,))
        user = c.fetchone()
    else:
        # Password-only auth: search by username match after verifying password
        # We must fetch all users and verify with bcrypt (can't SQL-match hashed passwords)
        input_password = auth_str
        c.execute("SELECT * FROM users WHERE role != 'admin'")
        all_users = c.fetchall()
        for candidate in all_users:
            db_pw = candidate["password"]
            if db_pw.startswith("$2b$") or db_pw.startswith("$2a$"):
                try:
                    if bcrypt.checkpw(input_password.encode('utf-8'), db_pw.encode('utf-8')):
                        user = candidate
                        break
                except Exception:
                    continue
            else:
                # Plaintext fallback (will be upgraded below)
                if db_pw == input_password:
                    user = candidate
                    break
    
    if not user:
        conn.close()
        return JSONResponse({"ok": False, "error": "user not found or wrong password"})
    
    # --- Transparent Password Upgrade (Plaintext → bcrypt) ---
    # If password is still plaintext, verify & upgrade to bcrypt on first successful auth
    db_password = user["password"]
    is_valid = False
    if db_password.startswith("$2b$") or db_password.startswith("$2a$"):
        try:
            is_valid = bcrypt.checkpw(input_password.encode('utf-8'), db_password.encode('utf-8'))
        except Exception:
            is_valid = False
    else:
        # Plaintext - verify and upgrade to bcrypt on first successful auth
        if db_password == input_password:
            is_valid = True
            new_hash = bcrypt.hashpw(input_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            # Save bcrypt hash AND save original password to display_password for URI generation
            c.execute("UPDATE users SET password = ?, display_password = ? WHERE id = ?",
                      (new_hash, input_password, user["id"]))
            conn.commit()
    
    if not is_valid:
        conn.close()
        return JSONResponse({"ok": False, "error": "user not found or wrong password"})
        
    username = user["username"]  # Get username for tracking
        
    if not user["is_active"]:
        conn.close()
        return JSONResponse({"ok": False, "error": "account disabled"})
        
    # Check Expiration
    if user["expire_date"]:
        try:
            exp_date = datetime.datetime.fromisoformat(user["expire_date"].replace('Z', '+00:00'))
            # Naive comparison fallback if no tzinfo
            if exp_date.tzinfo is None:
                if datetime.datetime.now() > exp_date:
                    conn.close()
                    return JSONResponse({"ok": False, "error": "account expired"})
            else:
                if datetime.datetime.now(datetime.timezone.utc) > exp_date:
                    conn.close()
                    return JSONResponse({"ok": False, "error": "account expired"})
        except Exception as e:
            pass  # Invalid date format, ignore
            
    # Check Data Limit
    if user["data_limit_gb"] > 0:
        limit_bytes = user["data_limit_gb"] * 1024 * 1024 * 1024
        if user["data_used_bytes"] >= limit_bytes:
            conn.close()
            return JSONResponse({"ok": False, "error": "data limit reached"})
            
    conn.close()
    
    # Check Device Limit via Hysteria Online API
    if user["device_limit"] > 0:
        try:
            async with httpx.AsyncClient() as client:
                headers = {"Authorization": HYSTERIA_SECRET} if HYSTERIA_SECRET else {}
                resp = await client.get(f"{HYSTERIA_TRAFFIC_API}/online", headers=headers, timeout=2.0)
                if resp.status_code == 200:
                    online_data = resp.json()
                    current_devices = online_data.get(username, 0)
                    if current_devices >= user["device_limit"]:
                        return JSONResponse({"ok": False, "error": "device limit reached"})
        except Exception as e:
            print(f"Error checking online devices: {e}")
            # Allow if we can't check
            
    # Success! Return the username as the ID so Hysteria tracks it by username
    return JSONResponse({"ok": True, "id": username})

# --- Management API (For Web Panel) ---

@app.get("/api/users")
def get_users(admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT id, username, password, display_password, data_limit_gb, data_used_bytes, expire_date, device_limit, is_active, role FROM users WHERE role != 'admin'")
    rows = c.fetchall()
    conn.close()
    users = []
    for row in rows:
        u = dict(row)
        # Return display_password (original) as 'password' for link generation in the UI.
        # Fall back to password field for legacy users who haven't connected yet after upgrade.
        raw_pw = u.get("display_password") or u.get("password", "")
        # If the fallback is a bcrypt hash (old bug), show placeholder so admin knows to reset
        if raw_pw and (raw_pw.startswith("$2b$") or raw_pw.startswith("$2a$")):
            raw_pw = "[RESET PASSWORD - Edit user to set new password]"  # tells admin to reset
        u["password"] = raw_pw
        del u["display_password"]
        users.append(u)
    return {"users": users}

@app.get("/api/online")
async def get_online_users(admin: str = Depends(get_current_admin)):
    """Returns currently online users from Hysteria2 /online API.
    Response: { "username": connection_count, ... }
    """
    try:
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": HYSTERIA_SECRET} if HYSTERIA_SECRET else {}
            resp = await client.get(f"{HYSTERIA_TRAFFIC_API}/online", headers=headers, timeout=3.0)
            if resp.status_code == 200:
                return resp.json()  # e.g. {"john": 2, "jane": 1}
    except Exception as e:
        print(f"Error fetching online users: {e}")
    return {}

@app.get("/api/lastseen")
async def get_last_seen(admin: str = Depends(get_current_admin)):
    """Returns last seen timestamps for offline users.
    Response: { "username": unix_timestamp, ... }
    """
    return last_seen_db

# --- Backup & Restore ---

@app.get("/api/backup")
def backup_database(admin: str = Depends(get_current_admin)):
    """Export all users and admin as a JSON backup file."""
    conn = get_db()
    c = conn.cursor()
    # Export display_password (original) as the password field in backup
    c.execute("SELECT username, password, display_password, data_limit_gb, data_used_bytes, expire_date, device_limit, is_active FROM users WHERE role != 'admin'")
    rows = c.fetchall()
    users = []
    for row in rows:
        u = dict(row)
        # Use display_password (original) for backup so it can be used in URIs after restore
        u["password"] = u.get("display_password") or u.get("password", "")
        del u["display_password"]
        users.append(u)
    c.execute("SELECT username, password FROM users WHERE role = 'admin' LIMIT 1")
    admin_row = c.fetchone()
    conn.close()

    backup = {
        "version": "1",
        "created_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "admin": dict(admin_row) if admin_row else {},
        "users": users
    }
    from fastapi.responses import Response
    import json
    filename = f"hy2-backup-{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}.json"
    return Response(
        content=json.dumps(backup, indent=2, ensure_ascii=False),
        media_type="application/json",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'}
    )

class RestoreOptions(BaseModel):
    backup: dict
    restore_admin: bool = False  # whether to also restore admin credentials
    mode: str = "merge"          # "merge" = skip existing, "replace" = overwrite all

@app.post("/api/restore")
def restore_database(opts: RestoreOptions, admin: str = Depends(get_current_admin)):
    """Import users from a JSON backup. Modes: merge (skip existing) or replace (overwrite)."""
    backup = opts.backup
    users = backup.get("users", [])
    if not isinstance(users, list):
        raise HTTPException(status_code=400, detail="Invalid backup format")

    conn = get_db()
    c = conn.cursor()

    # If replace mode, remove all existing non-admin users first
    if opts.mode == "replace":
        c.execute("DELETE FROM users WHERE role != 'admin'")

    imported = 0
    skipped = 0
    for u in users:
        try:
            if opts.mode == "merge":
                # Skip if username already exists
                c.execute("SELECT id FROM users WHERE username = ?", (u["username"],))
                if c.fetchone():
                    skipped += 1
                    continue
            raw_pw = u.get("password", "")
            # Always store display_password as the original plaintext for URI generation
            display_pw = raw_pw
            # If password is plaintext, hash it for storage
            if raw_pw and not (raw_pw.startswith("$2b$") or raw_pw.startswith("$2a$")):
                hashed_pw = bcrypt.hashpw(raw_pw.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
            else:
                hashed_pw = raw_pw  # Already hashed (old backup), keep as-is
                display_pw = u.get("display_password", raw_pw)  # Preserve original if available
            c.execute("""
                INSERT OR REPLACE INTO users
                  (username, password, display_password, data_limit_gb, data_used_bytes, expire_date, device_limit, is_active, role)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'user')
            """, (
                u.get("username", ""),
                hashed_pw,
                display_pw,
                u.get("data_limit_gb", 0),
                u.get("data_used_bytes", 0),
                u.get("expire_date", ""),
                u.get("device_limit", 0),
                u.get("is_active", True)
            ))
            imported += 1
        except Exception as e:
            skipped += 1

    # Optionally restore admin credentials
    if opts.restore_admin and backup.get("admin"):
        adm = backup["admin"]
        c.execute("UPDATE users SET username=?, password=? WHERE role='admin'",
                  (adm.get("username", admin), adm.get("password", "")))

    conn.commit()
    conn.close()
    return {"success": True, "imported": imported, "skipped": skipped, "mode": opts.mode}

@app.post("/api/users")
def add_user(user: UserCreate, admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    try:
        # Store original password for URI display, bcrypt hash for authentication
        hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        c.execute("""
            INSERT INTO users (username, password, display_password, data_limit_gb, expire_date, device_limit, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (user.username, hashed_password, user.password,
               user.data_limit_gb, user.expire_date, user.device_limit, user.is_active))
        conn.commit()
    except sqlite3.IntegrityError:
        conn.close()
        raise HTTPException(status_code=400, detail="Username already exists")
    conn.close()
    return {"success": True}

@app.put("/api/users/{user_id}")
def update_user(user_id: int, user: UserCreate, admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    # Check if password is being changed (not already hashed)
    if user.password and not (user.password.startswith("$2b$") or user.password.startswith("$2a$")):
        # New plaintext password: hash for auth, keep original for display/URI
        new_password = bcrypt.hashpw(user.password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        display_pw = user.password
    else:
        # Already hashed (e.g., from legacy path): keep hash, don't touch display_password
        new_password = user.password
        display_pw = None  # Will use COALESCE to keep existing display_password in DB
    
    if display_pw is not None:
        c.execute("""
            UPDATE users SET username=?, password=?, display_password=?,
                             data_limit_gb=?, expire_date=?, device_limit=?, is_active=?
            WHERE id=? AND role != 'admin'
        """, (user.username, new_password, display_pw,
               user.data_limit_gb, user.expire_date, user.device_limit, user.is_active, user_id))
    else:
        c.execute("""
            UPDATE users SET username=?, password=?,
                             data_limit_gb=?, expire_date=?, device_limit=?, is_active=?
            WHERE id=? AND role != 'admin'
        """, (user.username, new_password,
               user.data_limit_gb, user.expire_date, user.device_limit, user.is_active, user_id))
    conn.commit()
    conn.close()
    return {"success": True}

from fastapi import BackgroundTasks

@app.delete("/api/users/{user_id}")
def delete_user(user_id: int, background_tasks: BackgroundTasks, admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    c.execute("SELECT username FROM users WHERE id=? AND role != 'admin'", (user_id,))
    row = c.fetchone()
    if row:
        username = row["username"]
        c.execute("DELETE FROM users WHERE id=?", (user_id,))
        conn.commit()
        # Kick the user immediately
        background_tasks.add_task(kick_user, username)
    conn.close()
    return {"success": True}
    
@app.post("/api/users/{user_id}/reset_data")
def reset_user_data(user_id: int, admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    c.execute("UPDATE users SET data_used_bytes=0 WHERE id=? AND role != 'admin'", (user_id,))
    conn.commit()
    conn.close()
    return {"success": True}

# --- Traffic Poller Background Task ---

async def kick_user(username: str):
    try:
        async with httpx.AsyncClient() as client:
            headers = {"Authorization": HYSTERIA_SECRET} if HYSTERIA_SECRET else {}
            await client.post(f"{HYSTERIA_TRAFFIC_API}/kick", json=[username], headers=headers, timeout=5.0)
            print(f"Kicked user {username}")
    except Exception as e:
        print(f"Failed to kick user {username}: {e}")

async def traffic_poller():
    global previous_online
    while True:
        try:
            # Poll traffic and clear it on Hysteria side
            async with httpx.AsyncClient() as client:
                headers = {"Authorization": HYSTERIA_SECRET} if HYSTERIA_SECRET else {}
                resp = await client.get(f"{HYSTERIA_TRAFFIC_API}/traffic?clear=1", headers=headers, timeout=10.0)
                
                if resp.status_code == 200:
                    traffic_data = resp.json() # {"username": {"tx": 123, "rx": 456}}
                    
                    if traffic_data:
                        conn = get_db()
                        c = conn.cursor()
                        
                        for username, stats in traffic_data.items():
                            total_bytes = stats.get("tx", 0) + stats.get("rx", 0)
                            if total_bytes > 0:
                                c.execute("UPDATE users SET data_used_bytes = data_used_bytes + ? WHERE username = ?", (total_bytes, username))
                                
                        conn.commit()
                        
                        # Check for users who exceeded limits
                        c.execute("SELECT username, data_limit_gb, data_used_bytes, expire_date FROM users WHERE role != 'admin'")
                        users = c.fetchall()
                        for u in users:
                            should_kick = False
                            
                            # Check data limit
                            if u["data_limit_gb"] > 0:
                                limit_bytes = u["data_limit_gb"] * 1024 * 1024 * 1024
                                if u["data_used_bytes"] >= limit_bytes:
                                    should_kick = True
                                    
                            # Check expiration
                            if not should_kick and u["expire_date"]:
                                try:
                                    exp_date = datetime.datetime.fromisoformat(u["expire_date"].replace('Z', '+00:00'))
                                    if exp_date.tzinfo is None:
                                        if datetime.datetime.now() > exp_date:
                                            should_kick = True
                                    else:
                                        if datetime.datetime.now(datetime.timezone.utc) > exp_date:
                                            should_kick = True
                                except:
                                    pass
                                    
                            if should_kick:
                                await kick_user(u["username"])
                                
                        conn.close()
                        
        except Exception as e:
            print(f"Traffic poller error: {e}")

        # Track last seen (who went offline since last poll)
        try:
            async with httpx.AsyncClient() as online_client:
                headers = {"Authorization": HYSTERIA_SECRET} if HYSTERIA_SECRET else {}
                online_resp = await online_client.get(f"{HYSTERIA_TRAFFIC_API}/online", headers=headers, timeout=3.0)
                if online_resp.status_code == 200:
                    current_online = set(online_resp.json().keys())
                    # Users who went offline since last check
                    went_offline = previous_online - current_online
                    now = int(time.time())
                    for username in went_offline:
                        last_seen_db[username] = now
                    previous_online = current_online
        except Exception as e:
            print(f"Last seen tracker error: {e}")

        await asyncio.sleep(10) # Poll every 10 seconds

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(traffic_poller())

# Serve the Frontend HTML
@app.get("/")
def serve_index():
    return FileResponse("static/index.html")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=3000)
