# SystemD Units — KERNEL SHADOWS Episode 10

## 📁 Structure

```
systemd/
├── shadow-monitor.service      # Real-time system monitoring service
├── shadow-backup.service       # One-shot backup task
├── shadow-backup.timer         # Timer to run backup daily
└── README.md                   # This file
```

---

## 🎯 What is SystemD?

**SystemD** is the modern Linux init system and service manager (replaced SysV init, Upstart).

**Key Features:**
- **Service Management:** Start, stop, restart services
- **Dependency Management:** Service A requires Service B
- **Resource Limits:** Prevent runaway processes (CPU, memory, I/O)
- **Security Hardening:** Sandboxing, privilege isolation
- **Timers:** Cron replacement (better dependency management, logging)
- **Logging:** Integrated with journalctl (no separate log files needed)

---

## 📋 Files Explained

### 1. `shadow-monitor.service` — Real-Time Monitoring

**What:** Continuously monitors system for suspicious activity  
**Type:** `simple` (runs in foreground)  
**Restarts:** Automatically on failure

**Use Case:**
- Detect backdoor processes (Krylov's attacks)
- Monitor network connections
- Alert on suspicious file changes

```bash
# Start service
sudo systemctl start shadow-monitor.service

# Enable on boot
sudo systemctl enable shadow-monitor.service

# Check status
sudo systemctl status shadow-monitor.service

# View logs
sudo journalctl -u shadow-monitor.service -f
```

---

### 2. `shadow-backup.service` — Backup Task

**What:** Creates encrypted backup of operations data  
**Type:** `oneshot` (runs once and exits)  
**Triggered by:** `shadow-backup.timer` (daily at 2 AM)

**Use Case:**
- Automated backups (no manual cron jobs)
- Integrated with systemd journal
- Resource limits (won't overload system)

```bash
# Manual backup
sudo systemctl start shadow-backup.service

# Check last run
sudo systemctl status shadow-backup.service

# View backup logs
sudo journalctl -u shadow-backup.service | tail -50
```

---

### 3. `shadow-backup.timer` — Backup Scheduler

**What:** Triggers `shadow-backup.service` daily at 2 AM  
**Type:** Timer unit (cron replacement)  
**Schedule:** `OnCalendar=*-*-* 02:00:00`

**Advantages over Cron:**
- Dependency management (wait for network, time-sync)
- Integrated logging (journalctl)
- `Persistent=true` catches missed runs (if system off)
- `RandomizedDelaySec` distributes load across servers

```bash
# Enable timer
sudo systemctl enable shadow-backup.timer

# Start timer
sudo systemctl start shadow-backup.timer

# List all timers
sudo systemctl list-timers --all

# See next run time
sudo systemctl list-timers shadow-backup.timer
```

---

## 🚀 Deployment Instructions

### Step 1: Deploy Service Units

```bash
# Copy units to systemd directory
sudo cp systemd/shadow-monitor.service /etc/systemd/system/
sudo cp systemd/shadow-backup.service /etc/systemd/system/
sudo cp systemd/shadow-backup.timer /etc/systemd/system/

# Set permissions (644)
sudo chmod 644 /etc/systemd/system/shadow-*.service
sudo chmod 644 /etc/systemd/system/shadow-*.timer

# Reload systemd (recognize new units)
sudo systemctl daemon-reload
```

### Step 2: Deploy Service Scripts

```bash
# Create monitoring script
sudo cp scripts/shadow-monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/shadow-monitor.sh

# Create backup script
sudo cp scripts/shadow-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/shadow-backup.sh
```

### Step 3: Create Service User (for shadow-monitor)

```bash
# Create system user (no login, no home)
sudo useradd -r -s /bin/false shadow-monitor

# Create working directory
sudo mkdir -p /var/operations/shadow-monitor
sudo chown shadow-monitor:shadow-monitor /var/operations/shadow-monitor
```

### Step 4: Enable and Start Services

```bash
# Monitor service (real-time)
sudo systemctl enable shadow-monitor.service
sudo systemctl start shadow-monitor.service

# Backup timer (scheduled)
sudo systemctl enable shadow-backup.timer
sudo systemctl start shadow-backup.timer

# Verify
sudo systemctl status shadow-monitor.service
sudo systemctl list-timers shadow-backup.timer
```

---

## 🧪 Testing

### Test 1: Monitor Service Running

```bash
# Check status
sudo systemctl status shadow-monitor.service

# Should show:
# Active: active (running) since ...
# Main PID: 12345

# View logs
sudo journalctl -u shadow-monitor.service -f
```

### Test 2: Manual Backup

```bash
# Trigger backup manually
sudo systemctl start shadow-backup.service

# Check result
sudo systemctl status shadow-backup.service

# Should show:
# Active: inactive (dead) (normal for oneshot)
# Status: "Backup completed successfully"

# View logs
sudo journalctl -u shadow-backup.service
```

### Test 3: Timer Schedule

```bash
# List all timers
sudo systemctl list-timers --all

# Should show:
# NEXT                         LEFT          LAST  PASSED  UNIT                  ACTIVATES
# 2025-10-12 02:00:00 UTC  5h 23min left  n/a   n/a     shadow-backup.timer  shadow-backup.service
```

### Test 4: Service Restart on Failure

```bash
# Kill monitor process (simulate crash)
sudo pkill -f shadow-monitor.sh

# Wait 10 seconds (RestartSec=10s)
sleep 10

# Check status (should be restarted)
sudo systemctl status shadow-monitor.service

# Should show:
# Active: active (running) since ...
# Restarts: 1 (or more)
```

### Test 5: Resource Limits

```bash
# Check current resource usage
systemctl show shadow-monitor.service -p CPUUsageNSec
systemctl show shadow-monitor.service -p MemoryCurrent

# Should be within limits:
# CPUQuota=25%  → Max 25% of one core
# MemoryLimit=128M → Max 128MB RAM
```

---

## 🔍 Verification Commands

### Service Status

```bash
# Check all Shadow services
sudo systemctl status 'shadow-*'

# Check specific service
sudo systemctl status shadow-monitor.service

# See if enabled (starts on boot)
sudo systemctl is-enabled shadow-monitor.service
```

### Logs

```bash
# All logs for service
sudo journalctl -u shadow-monitor.service

# Follow logs (real-time)
sudo journalctl -u shadow-monitor.service -f

# Logs since boot
sudo journalctl -u shadow-monitor.service -b

# Last 50 lines
sudo journalctl -u shadow-monitor.service -n 50

# Show only errors
sudo journalctl -u shadow-monitor.service -p err
```

### Timers

```bash
# List all active timers
sudo systemctl list-timers

# Show specific timer
sudo systemctl list-timers shadow-backup.timer

# Check timer status
sudo systemctl status shadow-backup.timer
```

### Dependencies

```bash
# Show service dependencies
systemctl list-dependencies shadow-monitor.service

# Reverse dependencies (who depends on this)
systemctl list-dependencies --reverse shadow-monitor.service
```

### Resource Usage

```bash
# CPU and memory usage
systemd-cgtop

# Specific service
systemctl show shadow-monitor.service | grep -E 'CPU|Memory|Tasks'
```

---

## 🛡️ Security Features Explained

### 1. `NoNewPrivileges=true`
```
Prevents privilege escalation (process cannot gain more privileges)
Example: Service cannot execute suid binaries
```

### 2. `PrivateTmp=true`
```
Service gets private /tmp directory
Cannot see or access other processes' temp files
```

### 3. `ProtectKernelModules=true`
```
Cannot load/unload kernel modules (prevents rootkits)
```

### 4. `ProtectHome=true`
```
Cannot access /home, /root, /run/user
```

### 5. `CPUQuota=25%`
```
Max 25% of one CPU core (prevents CPU exhaustion)
```

### 6. `MemoryLimit=128M`
```
Max 128MB RAM (prevents memory exhaustion)
```

### 7. `User=shadow-monitor`
```
Runs as unprivileged user, not root
```

---

## 📊 SystemD vs Alternatives

| Feature | SystemD | SysV Init | Cron |
|---------|---------|-----------|------|
| Dependency management | ✅ | ❌ | ❌ |
| Resource limits | ✅ | ❌ | ❌ |
| Security hardening | ✅ | ❌ | ❌ |
| Integrated logging | ✅ | ❌ | ❌ |
| Socket activation | ✅ | ❌ | ❌ |
| Parallel startup | ✅ | ❌ | N/A |
| Timers (scheduling) | ✅ | ❌ | ✅ |
| Simple syntax | ❌ | ✅ | ✅ |

**Boris:** "SystemD is complex, but powerful. Enterprise systems use it."

---

## 🚨 Troubleshooting

### Service won't start

```bash
# Check for syntax errors
sudo systemd-analyze verify shadow-monitor.service

# Check detailed status
sudo systemctl status shadow-monitor.service -l

# Check logs
sudo journalctl -u shadow-monitor.service -n 50
```

### Common Issues

**1. ExecStart file not found**
```bash
# Error: Failed to execute command: No such file or directory

# Fix: Check script path
sudo ls -la /usr/local/bin/shadow-monitor.sh

# Make executable
sudo chmod +x /usr/local/bin/shadow-monitor.sh
```

**2. User doesn't exist**
```bash
# Error: Failed to determine user credentials: No such process

# Fix: Create user
sudo useradd -r -s /bin/false shadow-monitor
```

**3. Permission denied**
```bash
# Error: Permission denied

# Fix: Check file permissions
sudo chown root:root /etc/systemd/system/shadow-monitor.service
sudo chmod 644 /etc/systemd/system/shadow-monitor.service
```

**4. Service keeps restarting**
```bash
# Check restart loop
sudo systemctl status shadow-monitor.service

# Fix: Check script for errors
sudo journalctl -u shadow-monitor.service -n 100
```

---

## 🔗 Related Documentation

- **man systemd.service** — Service unit configuration
- **man systemd.timer** — Timer unit configuration
- **man systemd.exec** — Execution options (User, CPUQuota, etc.)
- **man systemd.resource-control** — Resource limits
- **man journalctl** — Log viewing

---

## 💡 Best Practices

### 1. Always use `systemctl daemon-reload`
```bash
# After editing any unit file
sudo systemctl daemon-reload
```

### 2. Test units before deploying
```bash
sudo systemd-analyze verify shadow-monitor.service
```

### 3. Use `Type=notify` for complex services
```
Type=notify
# Service sends readiness notification to systemd
```

### 4. Set resource limits
```
CPUQuota=50%
MemoryLimit=256M
# Prevent runaway processes
```

### 5. Enable security hardening
```
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
```

### 6. Use timers instead of cron
```
OnCalendar=daily
Persistent=true
# Better than: 0 2 * * * /path/to/script
```

---

**"SystemD unit = production-ready service. Resource limits, security hardening, auto-restart. That's enterprise-grade."**

— Boris Kuznetsov, SystemD Architect

**Saint Petersburg, Russia • SystemD Mastery Achieved!** 🇷🇺

