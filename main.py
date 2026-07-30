import sqlite3
import datetime
import asyncio
import httpx
from fastapi import FastAPI, Request, HTTPException, Depends, status
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.responses import JSONResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import secrets

app = FastAPI(title="Hysteria 2 Panel API")
security = HTTPBasic()

# Allow CORS for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DB_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "database.db")
HYSTERIA_TRAFFIC_API = "http://127.0.0.1:8080"
HYSTERIA_SECRET = "" # If you set a secret in config.yaml, put it here

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
            data_limit_gb REAL DEFAULT 0,
            data_used_bytes INTEGER DEFAULT 0,
            expire_date TEXT,
            device_limit INTEGER DEFAULT 0,
            is_active BOOLEAN DEFAULT 1,
            role TEXT DEFAULT 'user'
        )
    ''')
    
    # Create default admin if not exists
    c.execute("SELECT * FROM users WHERE role='admin'")
    if not c.fetchone():
        c.execute("INSERT INTO users (username, password, role) VALUES (?, ?, ?)", 
                  ("admin", "admin123", "admin"))
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
    conn.close()
    if not admin or admin["password"] != credentials.password:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    return admin["username"]

@app.post("/api/login")
def login(admin: str = Depends(get_current_admin)):
    return {"success": True, "admin": admin}

@app.put("/api/admin")
def update_admin(data: AdminUpdate, current_admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    try:
        c.execute("UPDATE users SET username=?, password=? WHERE username=? AND role='admin'", 
                  (data.new_username, data.new_password, current_admin))
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
    
    if ":" in auth_str:
        username, password = auth_str.split(":", 1)
        c.execute("SELECT * FROM users WHERE username = ? AND password = ?", (username, password))
    else:
        # Password only auth
        password = auth_str
        c.execute("SELECT * FROM users WHERE password = ?", (password,))
        
    user = c.fetchone()
    conn.close()
    
    if not user:
        return JSONResponse({"ok": False, "error": "user not found or wrong password"})
        
    username = user["username"] # Get username for tracking
        
    if not user["is_active"]:
        return JSONResponse({"ok": False, "error": "account disabled"})
        
    # Check Expiration
    if user["expire_date"]:
        try:
            exp_date = datetime.datetime.fromisoformat(user["expire_date"].replace('Z', '+00:00'))
            # Naive comparison fallback if no tzinfo
            if exp_date.tzinfo is None:
                if datetime.datetime.now() > exp_date:
                    return JSONResponse({"ok": False, "error": "account expired"})
            else:
                if datetime.datetime.now(datetime.timezone.utc) > exp_date:
                    return JSONResponse({"ok": False, "error": "account expired"})
        except Exception as e:
            pass # Invalid date format, ignore or block
            
    # Check Data Limit
    if user["data_limit_gb"] > 0:
        limit_bytes = user["data_limit_gb"] * 1024 * 1024 * 1024
        if user["data_used_bytes"] >= limit_bytes:
            return JSONResponse({"ok": False, "error": "data limit reached"})
            
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
    c.execute("SELECT id, username, password, data_limit_gb, data_used_bytes, expire_date, device_limit, is_active, role FROM users WHERE role != 'admin'")
    users = [dict(row) for row in c.fetchall()]
    conn.close()
    return {"users": users}

@app.post("/api/users")
def add_user(user: UserCreate, admin: str = Depends(get_current_admin)):
    conn = get_db()
    c = conn.cursor()
    try:
        c.execute("""
            INSERT INTO users (username, password, data_limit_gb, expire_date, device_limit, is_active)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (user.username, user.password, user.data_limit_gb, user.expire_date, user.device_limit, user.is_active))
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
    c.execute("""
        UPDATE users SET username=?, password=?, data_limit_gb=?, expire_date=?, device_limit=?, is_active=?
        WHERE id=? AND role != 'admin'
    """, (user.username, user.password, user.data_limit_gb, user.expire_date, user.device_limit, user.is_active, user_id))
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
