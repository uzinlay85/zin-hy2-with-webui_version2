# Hysteria 2 Technical Study Guide & Reference

> **မှတ်ချက်:** ဤစာရွက်စာတမ်းသည် Hysteria 2 Official Documentation နှင့် လူသုံးများသော Commercial Panels/Guides (H-UI, CSJoy, SecureNetX, Hiddify) များမှ နည်းပညာ သဘောတရားများ၊ Architecture များနှင့် Performance Tuning များကို စနစ်တကျ လေ့လာဆန်းစစ်ရန် သိမ်းဆည်းထားသော အကိုးအကား (Study Reference Guide) ဖြစ်ပါသည်။

---

## ၁။ Hysteria 2 ဆိုတာ ဘာလဲ?

- **Protocol type**  
  - Hysteria 2 သည် QUIC Protocol ကို အခြေခံထားသော TCP/UDP Proxy Protocol ဖြစ်ပြီး HTTP/3 Traffic အဖြစ် ရည်ရွယ်ချက်ရှိရှိ ဟန်ဆောင် (Mimic) ပြုလုပ်ထားပါသည်။
  - TCP/UDP proxy modes (SOCKS5, HTTP proxy, TUN mode) များကို Client ဘက်တွင် Expose ပြုလုပ်နိုင်သဖြင့် Browser, Gaming, Streaming App အားလုံးကို VPN ကဲ့သို့ စွမ်းဆောင်ရည်မြင့် ချိတ်ဆက်စေပါသည်။

- **Design goals**  
  - High throughput (Streaming, Gaming, Downloading တွင် မြန်ဆန်ခြင်း)
  - Lossy / High-latency နယ်ပယ်များ (ဥပမာ - မိုဘိုင်း အင်တာနက်လိုင်းများ) တွင် Throughput အမြင့်ဆုံး ရရှိစေခြင်း
  - Censorship Resistance (HTTP/3 Server သို့ ဟန်ဆောင်ခြင်း၊ Masquerade၊ Port Hopping ပါဝင်ခြင်း)

- **Brutal Congestion Control**  
  - Hysteria 2 Core တွင် **Brutal** ဟုခေါ်သော Aggressive Congestion Control Algorithm ကို သုံးစွဲထားပြီး User-defined Bandwidth Target ရောက်ရှိစေရန် dynamic speed enforcement ပြုလုပ်ပေးပါသည်။

---

## ၂။ Architecture: Server + Client Structure

### 2.1 Server ပိုင်း (Core Design)

- **Installation & Setup**:
  - Official Binary, Direct Download, One-Click Scripts (`get.hy2.sh`), Systemd Services.

- **Config Core Fields**:
  - `listen`: UDP listen address (Single port `:443` သို့မဟုတ် Multi-port `:20000-50000`).
  - `tls`: SSL Certificate (`cert` + `key`)၊ Let's Encrypt သို့မဟုတ် Self-signed TLS.
  - `auth`: Authentication Modes (`none`, `password`, `userpass`, `http`).
  - `masquerade`: Proxy, File, String modes (HTTP/3 Server ဟန်ဆောင်ခြင်း).
  - `resolver`: DNS Resolvers (`udp`, `tcp`, `doh`).
  - `bandwidth`: Up/Down Mbps targets (Brutal congestion tuning).
  - `quic`: Window sizes, maxIdleTimeout, keepAlivePeriod.
  - `trafficStats`: Local API (`127.0.0.1:8080`) for panel monitoring.

### 2.2 Client ပိုင်း

- **Client Capabilities**: Official CLI Client, SOCKS5, HTTP Proxy, TUN mode (System-wide VPN).
- **URI Scheme**:
  `hysteria2://[auth@]hostname[:port]/?[params]#tag`
  - `auth`: Credentials (`user:pass` or token)
  - `hostname`: Domain or IP
  - `mport`: Port hopping range (`20000-50000`)
  - `sni`: SNI matching SSL cert
  - `#tag`: Node label

---

## ၃။ Main Features (Official & Popular Guides)

### 3.1 High Performance & QUIC Tuning
- **Brutal Algorithm**: User Bandwidth Enforcement (`up: 50 mbps`, `down: 200 mbps`).
- **QUIC Receive Windows**: 8MB / 20MB receive windows for optimal cellular stability.

### 3.2 Anti-Censorship Mechanisms
- **Masquerade Proxy**: Reverse proxy to real sites (Cloudflare, Bing, etc.)
- **Obfuscation (Obfs)**: `salamander` or `gecko` modes for strict DPI bypass.
- **Port Hopping**: Dynamic UDP port switching (`mport=20000-50000`).

### 3.3 Multi-User & Panels Integration
- **HTTP Auth Mode (`auth: http`)**:
  - Hysteria 2 Core calls `/auth` API on external FastAPI/NodeJS backend.
  - Backend verifies user status, expiration, data quota, and returns speed limits (`up_mbps`, `down_mbps`).

---

## ၄။ Typical Setup Patterns

### Commercial Multi-User Pattern:
```yaml
listen: :443 # (Or iptables REDIRECT 20000-50000 -> 443)

tls:
  cert: /etc/letsencrypt/live/node.domain.com/fullchain.pem
  key: /etc/letsencrypt/live/node.domain.com/privkey.pem

auth:
  type: http
  http:
    url: http://127.0.0.1:3000/auth

masquerade:
  type: proxy
  proxy:
    url: https://www.cloudflare.com/
    rewriteHost: true

trafficStats:
  listen: 127.0.0.1:8080

quic:
  maxIdleTimeout: 120s
  keepAlivePeriod: 5s

resolver:
  type: udp
  udp:
    addr: 1.1.1.1:53
    timeout: 4s

bandwidth:
  up: 1 gbps
  down: 1 gbps
```

---

## ၅။ Performance & Best Practices

1. **UDP Buffers**: `sysctl` settings `rmem_max` and `wmem_max` set to 16MB - 64MB.
2. **Cloudflare Proxy Settings**: Cloudflare proxy MUST be OFF (DNS Only mode / Gray Cloud).
3. **Mobile Connection Persistence**: `maxIdleTimeout: 120s` and `keepAlivePeriod: 5s` to prevent CGNAT timeouts.
