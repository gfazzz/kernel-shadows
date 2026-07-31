# Episode 12: Starter Configurations

> **Liisa:** "Automation = systemd timers + logrotate. Configure correctly, test thoroughly."

---

## 📁 Structure

```
starter/
├── systemd/          ← Systemd service/timer units (automation)
│   ├── backup-full.service
│   ├── backup-full.timer
│   ├── backup-incremental.service
│   └── backup-incremental.timer
└── logrotate.d/      ← Logrotate config (log management)
    └── backup
```

---

## 🎯 Your Tasks

### Task 1: Complete Systemd Service Unit

**File:** `systemd/backup-full.service`

Fill in TODOs:
1. **Description:** What does this service do?
2. **After:** Start after `network-online.target` (wait for network)
3. **User/Group:** Run as `root` (needs /backup access)
4. **ExecStart:** Command to run: `/usr/local/bin/backup_manager.sh backup_full`
5. **StandardOutput/Error:** Send logs to `journal`
6. **Security:**
   - `NoNewPrivileges=true` (prevent privilege escalation)
   - `PrivateTmp=true` (isolated /tmp)
   - `ProtectSystem=strict` (read-only system directories)
   - `ReadWritePaths=/backup /var/log` (allow writes here)
7. **Resource Limits:**
   - `CPUQuota=50%` (limit CPU usage to 50%)
   - `MemoryLimit=2G` (limit memory to 2GB)

**Why these settings?**
- **Security:** Principle of least privilege (systemd hardening)
- **Resource limits:** Prevent backup from consuming all server resources
- **Logging:** Centralized logs via journalctl for monitoring

---

### Task 2: Complete Systemd Timer Unit

**File:** `systemd/backup-full.timer`

Fill in TODOs:
1. **OnCalendar:** `Sun *-*-* 02:00:00` (every Sunday at 02:00)
2. **Persistent:** `true` (run missed schedules on boot)
3. **OnBootSec:** `5min` (run 5min after boot if missed)
4. **RandomizedDelaySec:** `15min` (randomize ±15min to avoid thundering herd)

**Why Persistent=true?**

Liisa's story: "Skype datacenter in Tallinn. Server maintenance on Saturday night. Rebooted Sunday 04:00. Without `Persistent=true`, Sunday backup at 02:00 would be **missed**. With `Persistent=true`, backup ran at 04:05 after boot. Data safe."

**Aha! момент:** Persistent timers = insurance against downtime.

---

### Task 3: Complete Logrotate Config

**File:** `logrotate.d/backup`

Fill in TODOs:
1. **Frequency:** `daily` (rotate every day)
2. **Retention:** `rotate 30` (keep 30 days)
3. **Compression:** `compress` + `delaycompress`
4. **Permissions:** `create 640 root adm`
5. **Postrotate:** Email summary on Mondays

**Why 30 days retention?**
- Compliance (GDPR, HIPAA требуют audit trail)
- Forensics (troubleshooting after disaster)
- Trend analysis (identify backup failures over time)

**Why delaycompress?**
- Log rotation происходит, но файл может ещё дописываться
- `log.1` остаётся uncompressed на 1 день, потом compress
- Prevents corruption если process ещё пишет в log

---

## ✅ Installation

After completing TODOs:

```bash
# 1. Copy systemd units
sudo cp starter/systemd/*.service /etc/systemd/system/
sudo cp starter/systemd/*.timer /etc/systemd/system/

# 2. Reload systemd (register new units)
sudo systemctl daemon-reload

# 3. Enable timers (start on boot)
sudo systemctl enable backup-full.timer
sudo systemctl enable backup-incremental.timer

# 4. Start timers immediately
sudo systemctl start backup-full.timer
sudo systemctl start backup-incremental.timer

# 5. Verify timers are scheduled
sudo systemctl list-timers | grep backup
```

**Expected output:**
```
NEXT                         LEFT     LAST  PASSED  UNIT
Sun 2025-10-19 02:00:00 EET  1d left  n/a   n/a     backup-full.timer
Mon 2025-10-20 02:00:00 EET  2d left  n/a   n/a     backup-incremental.timer
```

---

### Install Logrotate Config

```bash
# 1. Copy config
sudo cp starter/logrotate.d/backup /etc/logrotate.d/

# 2. Test configuration (dry-run, no actual rotation)
sudo logrotate -d /etc/logrotate.d/backup

# 3. Force rotation (for testing)
sudo logrotate -f /etc/logrotate.d/backup

# 4. Verify
ls -lh /var/log/backup.log*
```

**Expected:**
```
-rw-r----- 1 root adm    0 Oct 12 10:00 /var/log/backup.log
-rw-r----- 1 root adm  1.2K Oct 11 23:59 /var/log/backup.log.1
-rw-r----- 1 root adm  856  Oct 10 23:59 /var/log/backup.log.2.gz
```

---

## 🧪 Testing

### Test 1: Manual Trigger (don't wait for schedule)

```bash
# Trigger backup-full service manually
sudo systemctl start backup-full.service

# Watch logs in real-time
sudo journalctl -u backup-full.service -f

# Check status
sudo systemctl status backup-full.service
```

**Expected:**
- Service runs
- Logs appear in journalctl
- Backup created in `/backup/full/`
- Exit code 0 (success)

---

### Test 2: Verify Timer Schedule

```bash
# Show next scheduled run
sudo systemctl list-timers backup-full.timer

# Check timer status
sudo systemctl status backup-full.timer

# Analyze calendar expression
systemd-analyze calendar "Sun *-*-* 02:00:00"
```

**Expected output (systemd-analyze):**
```
  Original form: Sun *-*-* 02:00:00
Normalized form: Sun *-*-* 02:00:00
    Next elapse: Sun 2025-10-19 02:00:00 EET
       (in UTC): Sun 2025-10-19 00:00:00 UTC
```

---

### Test 3: Persistent Timer (missed schedule)

**Scenario:** Server was off during scheduled backup time.

```bash
# 1. Stop timer
sudo systemctl stop backup-full.timer

# 2. Simulate "missed schedule" by waiting past 02:00 (or change system time)
# (In real test, you'd wait or use faketime)

# 3. Restart timer
sudo systemctl start backup-full.timer

# 4. Check if backup ran immediately (Persistent=true)
sudo journalctl -u backup-full.service --since "5 minutes ago"
```

**Aha! момент:** С `Persistent=true`, backup запускается сразу после start timer если schedule was missed!

---

### Test 4: Resource Limits

**Monitor backup during execution:**

```bash
# Start backup in background
sudo systemctl start backup-full.service &

# Monitor resource usage
systemctl show backup-full.service -p CPUUsageNSec -p MemoryCurrent

# Check if limits are enforced
systemctl show backup-full.service | grep -E "CPUQuota|MemoryLimit"
```

**Expected:**
- CPUQuota=50% (backup uses max 50% CPU)
- MemoryLimit=2147483648 (2GB in bytes)

---

### Test 5: Logrotate Functionality

```bash
# Create test log
echo "Test entry $(date)" | sudo tee -a /var/log/backup.log

# Force rotation
sudo logrotate -f /etc/logrotate.d/backup

# Verify rotation happened
ls -lh /var/log/backup.log*

# Check compressed logs
zcat /var/log/backup.log.2.gz | head
```

---

## 📊 Comparison: Cron vs Systemd Timers

| Feature | Cron | Systemd Timer |
|---------|------|---------------|
| **Missed schedules** | ❌ Lost forever | ✅ Runs on boot (Persistent=true) |
| **Logging** | ⚠️ Basic (syslog) | ✅ journalctl (structured, searchable) |
| **Dependencies** | ❌ No | ✅ After=network.target, etc. |
| **Resource limits** | ❌ No | ✅ CPUQuota, MemoryLimit, TasksMax |
| **Randomization** | ❌ No | ✅ RandomizedDelaySec (avoid thundering herd) |
| **Easy monitoring** | ⚠️ Grep syslog | ✅ systemctl list-timers |
| **Retry logic** | ❌ No | ✅ Restart=on-failure, RestartSec |

**Liisa:** *"Cron is legacy. Systemd timers — современный Linux. Persistent timers гарантируют execution даже если server был offline."*

---

## 🚨 Troubleshooting

### Problem: Timer not listed in `systemctl list-timers`

**Solution:**
```bash
# Check if timer file exists
ls -l /etc/systemd/system/backup-full.timer

# Reload systemd
sudo systemctl daemon-reload

# Re-enable
sudo systemctl enable backup-full.timer
sudo systemctl start backup-full.timer
```

---

### Problem: Service fails immediately

**Solution:**
```bash
# Check detailed logs
sudo journalctl -u backup-full.service -n 50 --no-pager

# Test script manually
sudo /usr/local/bin/backup_manager.sh backup_full

# Check script permissions
ls -l /usr/local/bin/backup_manager.sh
# Should be: -rwxr-xr-x (executable)

# Check backup directory permissions
ls -ld /backup
# Should allow root write access
```

---

### Problem: Logrotate doesn't run

**Solution:**
```bash
# Check logrotate config syntax
sudo logrotate -d /etc/logrotate.d/backup

# Check cron (logrotate runs via cron)
systemctl status cron

# Manual test
sudo logrotate -v /etc/logrotate.d/backup
```

---

## 📚 Advanced: Systemd Timer Calendar Syntax

```
OnCalendar Examples:

*-*-* 02:00:00            Every day at 02:00
Sun *-*-* 02:00:00        Every Sunday at 02:00
Mon..Sat *-*-* 02:00:00   Monday-Saturday at 02:00
*-*-* 00,06,12,18:00:00   Every 6 hours (00:00, 06:00, 12:00, 18:00)
*-*-01 00:00:00           1st of month at midnight
Mon *-*-1..7 00:00:00     First Monday of month

# Test calendar syntax
systemd-analyze calendar "Sun *-*-* 02:00:00"
```

---

## 🎓 Learning Checkpoints

After completing this task, you should understand:

- ✅ How to write systemd service units (Type, ExecStart, security)
- ✅ How to write systemd timer units (OnCalendar, Persistent)
- ✅ Why Persistent=true is critical for backups
- ✅ How to configure logrotate (rotation, compression, retention)
- ✅ How to test systemd timers (manual trigger, list-timers)
- ✅ How resource limits protect system stability
- ✅ Why systemd timers > cron for critical tasks

---

## 📖 Reference

Compare your work with `solution/configs/` after completing.

**Liisa's wisdom:**
> *"Configuration = declarative (what you want). Scripts = imperative (how to do it). Systemd = configuration. Bash = scripts. Both critical. Master both."*

---

## 🔗 Additional Resources

- `man systemd.service` — service unit documentation
- `man systemd.timer` — timer unit documentation
- `man systemd.resource-control` — resource limits
- `man logrotate` — log rotation tool
- `man systemd-analyze` — analyze systemd configuration

---

<div align="center">

**"Automation без configuration = половина работы."**

*Episode 12: Backup & Recovery Starter Guide*

[← Back to Episode README](../README.md)

</div>

