# Hysteria 2 + FastAPI Web Panel (Version 2) Architecture Guide

## 1. System Overview
The system consists of two main components running on a Linux VPS:
1. **Hysteria 2 Core**: High-performance, anti-censorship VPN protocol based on QUIC.
2. **FastAPI Web Panel**: A lightweight, asynchronous Python backend serving a responsive HTML/CSS/JS frontend for user management.

## 2. Component Breakdown

### A. Hysteria 2 Configuration (`/etc/hysteria/config.yaml`)
- **Listen Port**: Usually `443` (UDP).
- **TLS**: Uses Let's Encrypt certificates generated via `certbot`.
- **Auth**: Uses external HTTP authentication, pointing to the FastAPI Web Panel (`http://127.0.0.1:3000/auth`). Auth uses bcrypt password verification with transparent upgrade support for legacy plaintext passwords.
- **Masquerade**: Proxies unauthorized TCP traffic to a fallback site (e.g., `bing.com`) to hide the server's true nature.
- **Obfuscation**: Uses `salamander` to bypass Deep Packet Inspection (DPI) common in strict ISPs (e.g., MPT/Ooredoo).
- **Traffic Stats API**: Listens locally on `127.0.0.1:8080` to provide `/online`, `/traffic`, and `/kick` API access to the Web Panel.

### B. FastAPI Web Panel (`/opt/hy2-panel/main.py`)
- **Database**: SQLite3 (`database.db`). Stores users, data limits, expiration dates, and admin credentials.
- **Authentication Endpoint (`/auth`)**: Hysteria 2 calls this endpoint on every client connection attempt. The panel checks the SQLite database for valid credentials using **bcrypt.checkpw()** for hashed passwords, with a **Transparent Upgrade** fallback that auto-upgrades any remaining plaintext password to bcrypt on first use. This ensures zero downtime for existing users.
- **Traffic Poller (Background Task)**: An `asyncio` background loop polls `127.0.0.1:8080/traffic?clear=1` every 10 seconds. It updates user data consumption in SQLite and immediately kicks users who exceed their data or expiration limits via `127.0.0.1:8080/kick`.
- **Last Seen Tracking**: The poller compares the previous `/online` state with the current state. When a user disappears, their timestamp is saved to memory, which is displayed on the UI.
- **Device Limits**: "1 Device" means 1 active QUIC connection (1 connected app). IP addresses are irrelevant. If `device_limit` is 2, the user can use 2 apps simultaneously. Setting it to `0` means unlimited. Setting Data Limit to `0` also means unlimited.

### C. Automation Scripts (Bash)
- **`install.sh`**: Handles the complete one-click setup.
  - Installs dependencies.
  - Generates random passwords if not provided.
  - Modifies `sysctl.conf` for BBR, TCP Fast Open, and **64MB UDP buffers** for optimal QUIC performance.
  - Sets up UFW firewall and port hopping (`iptables` REDIRECT).
  - Fetches Hysteria 2 binary and configures Systemd services with `network-online.target` and `RestartSec=5s`.
  - Acquires SSL via Certbot.
  - Installs Python dependencies and configures Nginx reverse proxy with SSL Session Cache and Security Headers.
- **`server_fix.sh`**: One-time fix script for existing running servers. Applies all stability and security improvements without requiring a full reinstall.
- **`uninstall.sh`**: Completely removes Hysteria 2, the Web Panel, Python environments, Nginx configs, and systemd services.
- **`status.sh`**: Diagnostic tool. Outputs the current Hysteria config, service status, UFW/iptables rules, and the tail of system logs for both Hysteria and the Web Panel.

## 3. Network & Routing (Port Hopping)
To combat UDP blocking/throttling on standard ports, the system uses **UDP Port Hopping**.
- **Rule**: `iptables -t nat -A PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports 443`
- **Mechanism**: Clients connect to any random port between 20000-50000. The Linux kernel (iptables) transparently redirects this packet to Hysteria listening on port 443. This prevents ISPs from easily identifying and blocking the VPN traffic.

## 4. Troubleshooting & Known Behaviors

### A. "timeout: no recent network activity" Log in Hysteria
- **Meaning**: This is a **NORMAL** log. It means a TCP stream (e.g., to Google Play Services or Facebook MQTT) established by a client went idle because the phone was locked or the app stopped sending data. Hysteria gracefully closes it to save memory.
- **Action Required**: None. Do not confuse this with a network block.

### B. Duplicate iptables Port Hopping Rules
- **Symptom**: Running `status.sh` shows multiple identical `REDIRECT` rules under the iptables section.
- **Cause**: Running `ufw reload` multiple times without explicitly flushing the `PREROUTING` chain in `/etc/ufw/before.rules`.
- **Fix**: Run the following in the terminal:
  ```bash
  while iptables -t nat -D PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports 443 2>/dev/null; do :; done
  iptables -t nat -A PREROUTING -p udp --dport 20000:50000 -j REDIRECT --to-ports 443
  ```

### C. Mobile Apps Not Connecting (HTTP/3 / QUIC Loop issues)
- **Symptom**: Users with Facebook/YouTube on mobile experience hangs or infinite loading.
- **Cause**: Having `reject(all, udp/443)` in the Hysteria ACL block prevents mobile apps from falling back from HTTP/3 to HTTP/2 gracefully.
- **Fix**: Ensure the `acl` block does NOT contain `reject(all, udp/443)`. (This was removed in the latest `install.sh`).

### D. "Application error 0x0 (remote)" in Hysteria Logs
- **Meaning**: This is **NORMAL**. The client (mobile app) closed the QUIC connection cleanly from its side. Code `0x0` is a graceful NO_ERROR close initiated by the client app or OS.
- **Action Required**: None.

### E. "dial tcp4 198.18.0.x: i/o timeout" in Hysteria Logs
- **Meaning**: This is **NORMAL**. The IP range `198.18.0.0/15` is reserved (RFC 2544 benchmarking / CGNAT). Some client apps try to connect to fake internal addresses. The server correctly times out since those IPs are unreachable.
- **Action Required**: None.

## 5. Migration (Backup & Restore)
- **Method**: The Web Panel exports `users` and `admin` credentials to a JSON file.
- **Import Modes**:
  - `Merge`: Adds new users, ignores duplicates.
  - `Replace`: Deletes all existing users and replaces them entirely with the backup file.

---
*Generated for AI Context Persistence. Any AI reading this repository should use this file as the definitive ground truth for how this system operates and how to troubleshoot it.*
