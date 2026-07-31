# Episode 12: Backup & Recovery - Artifacts

> **Testing Guide для Episode 12**

---

## 📦 Содержимое

Этот каталог содержит тестовые данные и инструкции для практических заданий Episode 12.

---

## 🛠️ Setup Instructions

### 1. Prepare Test Environment

```bash
# Create test data directory
mkdir -p /home/student/data

# Create some test files
cd /home/student/data
for i in {1..50}; do
    echo "Sample data file $i - $(date)" > file$i.txt
done

# Create subdirectories
mkdir -p /home/student/data/{docs,images,logs}
echo "Important document" > /home/student/data/docs/important.txt
echo "Log entry" > /home/student/data/logs/app.log

# Set proper permissions
chmod 755 /home/student/data
chmod 644 /home/student/data/*.txt
```

### 2. Create Backup Directories

```bash
# Create backup structure
sudo mkdir -p /backup/{full,incremental,offsite}
sudo chown -R $USER:$USER /backup
```

### 3. Generate SSH Key (for offsite backup)

```bash
# Generate key for remote backup
ssh-keygen -t ed25519 -f ~/.ssh/backup_key -N "" -C "backup@$(hostname)"

# If you have remote server, copy key:
# ssh-copy-id -i ~/.ssh/backup_key.pub backup@remote-server
```

---

## ✅ Testing Tasks

### Task 1: Full Backup Test

```bash
# Run starter.sh
./starter.sh

# Choose option 1 (Full backup)
# Verify:
ls -lh /backup/full/

# Check backup content:
tar -tzf /backup/full/backup-full-*.tar.gz | head -20
```

**Expected result:**
- Backup file created in `/backup/full/`
- `.sha256` checksum file created
- Log entry in `/var/log/backup.log`

---

### Task 2: Incremental Backup Test

```bash
# Add new files to test data
echo "New data" > /home/student/data/new-file.txt

# Run incremental backup
./starter.sh
# Choose option 2

# Verify:
ls -lh /backup/incremental/

# Check with rsync dry-run to see differences:
rsync -avin /home/student/data/ /backup/incremental/incremental-latest/
```

**Expected result:**
- New incremental backup directory created
- Only changed files copied (hard links for unchanged)
- Disk space saved compared to full backup

---

### Task 3: Offsite Backup Test

**Note:** Requires remote server or simulate with local directory.

```bash
# Simulate remote with local directory:
sudo mkdir -p /backup/remote
sudo chown $USER:$USER /backup/remote

# Modify script to use local "remote":
REMOTE_BACKUP_PATH="/backup/remote"

# Run offsite backup
./starter.sh
# Choose option 3
```

---

### Task 4: Restore Test

```bash
# Identify backup file
BACKUP_FILE=$(ls -t /backup/full/backup-full-*.tar.gz | head -1)

# Restore to test directory
./starter.sh
# Choose option 4
# Enter backup file path and restore directory

# Verify restored data:
ls -lh /tmp/restore/
diff -r /home/student/data /tmp/restore/home/student/data
```

**Expected result:**
- Checksum verified
- Data extracted to restore directory
- All files present and identical to source

---

### Task 5: Health Check Test

```bash
# Run health check
./starter.sh
# Choose option 5

# Expected output:
# - Latest backup age (< 48 hours = OK)
# - Backup size
# - Health status (OK/WARNING/CRITICAL)
```

---

### Task 6: Cleanup Old Backups Test

```bash
# Create old backup (simulate with timestamp manipulation)
touch -d "40 days ago" /backup/full/old-backup.tar.gz

# Run cleanup
./starter.sh
# Choose option 6

# Verify:
ls -lh /backup/full/
# old-backup.tar.gz should be deleted
```

---

### Task 7: Disaster Recovery Test

**This is the big one! Tests complete backup/restore cycle.**

```bash
# Run disaster recovery test
./starter.sh
# Choose option 7

# This will:
# 1. Create 100 test files
# 2. Generate checksums
# 3. Backup files
# 4. DELETE all files (simulate disaster)
# 5. Restore from backup
# 6. Verify checksums
# 7. Cleanup

# Expected: All steps succeed, checksums match
```

**Expected output:**
```
✓ Created 100 test files
✓ Backup created
✗ Data destroyed!
✓ Data restored
✓ All checksums verified! Data integrity confirmed!
DISASTER RECOVERY TEST: SUCCESSFUL ✓
```

---

### Task 8: Generate Report Test

```bash
# Run report generation
./starter.sh
# Choose option 8

# View report
cat /tmp/backup-report-*.txt
```

**Expected report sections:**
- Header with date/time
- Full backups list
- Incremental backups list
- Storage usage
- Backup health check
- System info

---

## 🧪 Advanced Testing Scenarios

### Scenario 1: Krylov Attack Simulation

Recreate the disaster from Episode 12 plot:

```bash
# Day 1: Create production data
mkdir -p /tmp/production/data
echo "Day 1 critical data" > /tmp/production/data/day1.txt

# Full backup
tar -czf /backup/day1-full.tar.gz /tmp/production/data

# Day 2: Add more data
echo "Day 2 additional data" > /tmp/production/data/day2.txt

# Incremental backup
rsync -av /tmp/production/data/ /backup/incremental-day2/

# Day 3: KRYLOV ATTACK! Data corrupted
rm -rf /tmp/production/data/*
echo "HACKED BY KRYLOV" > /tmp/production/data/HACKED.txt

# Discovery: Identify clean backup (day 2)
# Restore:
tar -xzf /backup/day1-full.tar.gz -C /tmp/
rsync -av /backup/incremental-day2/ /tmp/production/data/

# Verify:
ls -lh /tmp/production/data/
# Should have: day1.txt, day2.txt (NOT day3.txt or HACKED.txt)
```

---

### Scenario 2: 3-2-1 Backup Rule Test

Test the complete 3-2-1 rule:

```bash
# 3 copies:
# 1. Original: /home/student/data
# 2. Local backup: /backup/full
# 3. Offsite backup: remote:/backup

# 2 different media:
# - SSD (production)
# - HDD (backup)

# 1 offsite:
# - Remote server

# Verify all copies exist:
ls -lh /home/student/data        # Original
ls -lh /backup/full               # Copy 1
ls -lh /backup/remote             # Copy 2 (offsite)

# Simulate disaster: local disk failure
# You should still have remote backup!
```

---

### Scenario 3: Encryption Test

Add encryption to backups:

```bash
# Generate GPG key
gpg --gen-key

# Encrypted backup
tar -czf - /home/student/data | \
    gpg --encrypt -r your-email@example.com > \
    /backup/encrypted-backup.tar.gz.gpg

# Encrypted restore
gpg --decrypt /backup/encrypted-backup.tar.gz.gpg | \
    tar -xzf - -C /tmp/restore/

# Store GPG key in multiple locations:
# - Password manager
# - Printed on paper in safe
# - USB drive in different location
```

---

## 🚨 Troubleshooting

### Problem: "Permission denied" when creating backup

**Solution:**
```bash
# Check permissions
ls -ld /backup

# Fix permissions
sudo chown -R $USER:$USER /backup
chmod 755 /backup
```

---

### Problem: "No space left on device"

**Solution:**
```bash
# Check disk usage
df -h /backup

# Clean old backups
find /backup/full -name "*.tar.gz" -mtime +30 -delete

# Or move to external storage
rsync -av --remove-source-files /backup/full/ /mnt/external/
```

---

### Problem: Restore fails with "checksum mismatch"

**Solution:**
```bash
# Backup may be corrupted!
# Try previous backup:
PREV_BACKUP=$(ls -t /backup/full/*.tar.gz | sed -n '2p')
tar -xzf "$PREV_BACKUP" -C /tmp/restore/

# If all backups fail → check hardware (disk errors?)
sudo smartctl -a /dev/sda
```

---

### Problem: rsync incremental backup too slow

**Solution:**
```bash
# Use rsync with compression and bandwidth limit:
rsync -avz --bwlimit=10000 /source/ /backup/

# Or use --inplace for large files:
rsync -av --inplace --no-whole-file /source/ /backup/
```

---

### Problem: SSH offsite backup fails with "Permission denied"

**Solution:**
```bash
# Verify SSH key
ssh -i ~/.ssh/backup_key backup@remote-server

# Check remote permissions
ssh backup@remote-server "ls -ld ~/backup"

# Re-copy key if needed
ssh-copy-id -i ~/.ssh/backup_key backup@remote-server
```

---

## 📊 Performance Benchmarks

**Typical backup times (1GB data):**

| Method | Time | Size | Notes |
|--------|------|------|-------|
| tar.gz | ~30s | 300MB | Best compression |
| rsync (full) | ~15s | 1GB | Fast, no compression |
| rsync (incremental) | ~2s | 50MB | Only changes |

**Storage efficiency (100GB data, 30 days):**

| Strategy | Total Storage | Notes |
|----------|---------------|-------|
| Daily full | 3TB | 30 × 100GB |
| Weekly full + daily incremental | 700GB | 4 × 100GB + 26 × 10GB |
| Monthly full + daily differential | 1.2TB | Best for most cases |

---

## 🎓 Learning Checkpoints

After completing all tasks, you should be able to:

- [ ] Create full backups with tar
- [ ] Create incremental backups with rsync
- [ ] Set up offsite backups via SSH
- [ ] Restore data from backups
- [ ] Verify backup integrity (checksums)
- [ ] Automate backups with cron
- [ ] Test disaster recovery procedures
- [ ] Monitor backup health
- [ ] Clean up old backups
- [ ] Generate backup status reports
- [ ] Implement 3-2-1 backup rule
- [ ] Encrypt sensitive backups
- [ ] Document disaster recovery plan

---

## 📝 Liisa's Final Checklist

Before considering your backup system "production-ready", verify:

- ✅ Automated backups running (cron)
- ✅ Full backup weekly
- ✅ Incremental backup daily
- ✅ Offsite backup exists
- ✅ Restore tested successfully (within last 30 days)
- ✅ Health monitoring active
- ✅ Logs reviewed regularly
- ✅ Retention policy implemented
- ✅ Disaster recovery plan documented
- ✅ Team knows restore procedures

**Liisa's wisdom:**
> *"If you can't test restore in 5 minutes without documentation — your backup system is too complex. Keep it simple. Keep it tested."*

---

## 🔗 Additional Resources

- `man tar` - tar archive command
- `man rsync` - remote sync tool
- `man cron` - scheduling daemon
- `man gpg` - encryption tool
- https://www.backblaze.com/blog/the-3-2-1-backup-strategy/ - 3-2-1 rule explained

---

<div align="center">

**"Untested backup = no backup."**

*Episode 12: Backup & Recovery Testing Guide*

[← Back to Episode README](../README.md)

</div>


---

## 🔧 Testing Systemd Timers (Episode 12 Modern Approach)

### Setup Systemd Backup Automation

Episode 12 refactored to include **systemd timers** (modern alternative to cron).

**Files:**
- `solution/configs/systemd/*.service` (backup services)
- `solution/configs/systemd/*.timer` (schedules)

### Install and Test

```bash
# 1. Copy systemd units
sudo cp solution/configs/systemd/*.service /etc/systemd/system/
sudo cp solution/configs/systemd/*.timer /etc/systemd/system/

# 2. Reload systemd
sudo systemctl daemon-reload

# 3. Enable timers
sudo systemctl enable backup-full.timer
sudo systemctl enable backup-incremental.timer
sudo systemctl enable backup-health-check.timer

# 4. Start timers
sudo systemctl start backup-full.timer
sudo systemctl start backup-incremental.timer
sudo systemctl start backup-health-check.timer

# 5. Verify timers scheduled
sudo systemctl list-timers | grep backup
```

**Expected output:**
```
NEXT                         LEFT     LAST  PASSED  UNIT                        
Sun 2025-10-19 02:00:00 EET  1d left  n/a   n/a     backup-full.timer
Mon 2025-10-20 02:00:00 EET  2d left  n/a   n/a     backup-incremental.timer
...  06:00:00 EET             5h left  n/a   n/a     backup-health-check.timer
```

### Manual Trigger (Test Without Waiting)

```bash
# Test full backup service
sudo systemctl start backup-full.service

# Watch logs in real-time
sudo journalctl -u backup-full.service -f

# Check status
sudo systemctl status backup-full.service
```

### Testing Scenarios

#### Test 1: Health Check Timer (Runs Every 6h)

```bash
# Trigger manually
sudo systemctl start backup-health-check.service

# Check logs
sudo journalctl -u backup-health-check.service -n 50

# Verify exit code
systemctl show -p ExecMainStatus backup-health-check.service
```

**Success:** ExitStatus=0 (OK), ExitStatus=1 (WARNING), ExitStatus=2 (CRITICAL)

#### Test 2: Persistent Timers (Missed Schedule Recovery)

**Scenario:** Server off during scheduled backup time.

```bash
# 1. Stop timer
sudo systemctl stop backup-full.timer

# 2. Check status
sudo systemctl status backup-full.timer
# Should show: Loaded, inactive (dead)

# 3. Simulate "missed" schedule
# (Timer has Persistent=true, so it will run on next boot)

# 4. Restart timer
sudo systemctl start backup-full.timer

# 5. If schedule was missed, service should run immediately
sudo journalctl -u backup-full.service --since "5 minutes ago"
```

**Key feature:** `Persistent=true` means missed schedules will execute on boot!

#### Test 3: Resource Limits

Systemd units have resource limits configured:

```bash
# Check configured limits
systemctl show backup-full.service | grep -E "CPU|Memory|Tasks"

# Expected:
# CPUQuota=50%
# MemoryLimit=2G
```

Test during backup:

```bash
# Start backup
sudo systemctl start backup-full.service &

# Monitor resource usage
while systemctl is-active backup-full.service; do
    systemctl show backup-full.service -p CPUUsageNSec -p MemoryCurrent
    sleep 1
done
```

#### Test 4: Failure Handling

```bash
# 1. Break backup (simulate failure)
sudo chmod 000 /backup  # Remove permissions

# 2. Trigger backup
sudo systemctl start backup-full.service

# 3. Check failure
systemctl status backup-full.service
# Should show: failed

# 4. Check logs
sudo journalctl -u backup-full.service -p err

# 5. Fix and retry
sudo chmod 755 /backup
sudo systemctl start backup-full.service
```

### Comparison: Cron vs Systemd Timers

| Feature | Cron | Systemd Timer |
|---------|------|---------------|
| **Missed schedules** | ❌ Lost forever | ✅ Runs on boot (Persistent=true) |
| **Logging** | ⚠️ Basic (syslog) | ✅ journalctl (structured) |
| **Dependencies** | ❌ No | ✅ After=network.target |
| **Resource limits** | ❌ No | ✅ CPUQuota, MemoryLimit |
| **Randomization** | ❌ No | ✅ RandomizedDelaySec |
| **Easy monitoring** | ⚠️ Cron logs | ✅ systemctl list-timers |

**Liisa:** *"Cron is legacy. Systemd timers — это modern Linux. Persistent timers гарантируют execution даже если server был offline."*

### Troubleshooting Systemd Timers

#### Timer not listed

```bash
# Check if timer exists
ls -l /etc/systemd/system/backup-*.timer

# Reload systemd
sudo systemctl daemon-reload

# Re-enable
sudo systemctl enable backup-full.timer
sudo systemctl start backup-full.timer
```

#### Timer shows but service doesn't run

```bash
# Check timer status
sudo systemctl status backup-full.timer

# Check service status
sudo systemctl status backup-full.service

# Check logs
sudo journalctl -u backup-full.service --since "today"

# Check script exists
ls -l /usr/local/bin/backup_manager.sh
# Should be: -rwxr-xr-x (executable)
```

#### Service fails immediately

```bash
# Check script errors
sudo journalctl -u backup-full.service -n 50

# Test script manually
sudo /usr/local/bin/backup_manager.sh backup_full

# Check permissions
ls -ld /backup
# Should be: drwxr-xr-x root root
```

### Advanced: Systemd Timer Calendar Syntax

```
OnCalendar Examples:

*-*-* 02:00:00         Every day at 02:00
Sun *-*-* 02:00:00     Every Sunday at 02:00
Mon..Sat *-*-* 02:00:00  Monday-Saturday at 02:00
*-*-* 00,06,12,18:00:00  Every 6 hours
*-*-01 00:00:00        1st of month at midnight

# Test calendar syntax
systemd-analyze calendar "Sun *-*-* 02:00:00"
# Shows: Next elapse times
```

**LILITH:** *"Systemd timers = cron на steroids. Persistent, dependency-aware, resource-limited. Production-ready."*

---

## 📊 Logrotate Testing (Type B Configuration!)

Episode 12 includes **logrotate configuration** for backup logs.

**File:** `solution/configs/logrotate.d/backup`

### Install Logrotate Config

```bash
# Copy config
sudo cp solution/configs/logrotate.d/backup /etc/logrotate.d/

# Test configuration (dry-run, no actual rotation)
sudo logrotate -d /etc/logrotate.d/backup
```

**Expected output:**
```
reading config file /etc/logrotate.d/backup
...
rotating pattern: /var/log/backup.log  after 1 days (30 rotations)
...
```

### Force Rotation (Test)

```bash
# Create test log (if doesn't exist)
sudo touch /var/log/backup.log
echo "Test log entry $(date)" | sudo tee -a /var/log/backup.log

# Force rotation
sudo logrotate -f /etc/logrotate.d/backup

# Verify rotation happened
ls -lh /var/log/backup.log*
```

**Expected:**
```
/var/log/backup.log       (new, empty)
/var/log/backup.log.1     (old log, uncompressed)
/var/log/backup.log.2.gz  (older log, compressed)
```

### Test Postrotate Script

Logrotate config includes `postrotate` section that emails weekly summaries.

```bash
# Check postrotate section
grep -A 10 "postrotate" /etc/logrotate.d/backup

# Simulate Monday (day 1 of week)
# Postrotate should send email if it's Monday
```

**Note:** Email functionality requires `mail` command installed:
```bash
sudo apt install mailutils
```

### Logrotate Best Practices

**From config:**
- `daily` — rotate каждый день (для активных backup logs)
- `rotate 30` — хранить 30 дней (compliance, forensics)
- `compress` — gzip старые логи (экономия места)
- `delaycompress` — не compress самый свежий (может дописываться)
- `create 640 root adm` — новый лог с правильными permissions

**Liisa:** *"Логи backup — это black box после disaster. Храните минимум 30 дней. Forensics требует истории."*

---

## ✅ Complete Testing Checklist

### Systemd Timers
```
[ ] All timers installed and enabled
[ ] Timers appear in 'systemctl list-timers'
[ ] Manual trigger works (systemctl start backup-full.service)
[ ] Logs visible in journalctl
[ ] Resource limits active (CPUQuota, MemoryLimit)
[ ] Persistent timer recovers missed schedules
```

### Backup Functionality
```
[ ] Full backup creates .tar.gz with checksum
[ ] Incremental backup uses hard links (space efficient)
[ ] Offsite sync works (SSH keys configured)
[ ] Restore tested (at least one successful restore)
[ ] Health check detects old backups
[ ] Cleanup removes old backups (retention policy)
```

### Logrotate
```
[ ] Config installed in /etc/logrotate.d/
[ ] Dry-run test passes (logrotate -d)
[ ] Force rotation works (logrotate -f)
[ ] Old logs compressed
[ ] Postrotate script runs (if Monday)
```

### Production Ready
```
[ ] Documentation complete (DR procedures)
[ ] Team trained (everyone knows procedures)
[ ] RTO/RPO measured (business agreed)
[ ] Monthly restore test scheduled
[ ] Monitoring configured (health checks every 6h)
```

**If all checkboxes ✓ — готов к production!**

**Liisa approves!** 🎉

---

**Next:** Season 4 — DevOps & Automation (Amsterdam 🇳🇱)

