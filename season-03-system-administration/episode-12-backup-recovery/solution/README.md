# Episode 12: Backup & Recovery — Solution Workflow

## 📋 Обзор решения

Это complete production-ready backup система, разработанная по стандартам **Skype backup engineering** (by Liisa Kask).

**Компоненты:**
- ✅ `backup_manager.sh` (394 lines) — master backup script
- ✅ Systemd units (8 files) — automated scheduling
- ✅ Logrotate config — log management
- ✅ Documentation — disaster recovery procedures

**Философия:** 3-2-1-T Rule (3 copies, 2 media, 1 offsite, TESTED)

---

## 🚀 Quick Start

### 1. Установить backup_manager.sh

```bash
# Copy script
sudo cp solution/backup_manager.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/backup_manager.sh

# Test manually
/usr/local/bin/backup_manager.sh

# Choose option 9 (Run all tasks) для полного теста
```

---

### 2. Установить systemd units

```bash
# Copy all service files
sudo cp solution/configs/systemd/*.service /etc/systemd/system/
sudo cp solution/configs/systemd/*.timer /etc/systemd/system/

# Reload systemd
sudo systemctl daemon-reload

# Enable timers (автозапуск)
sudo systemctl enable backup-full.timer
sudo systemctl enable backup-incremental.timer
sudo systemctl enable backup-offsite.timer
sudo systemctl enable backup-health-check.timer

# Start timers
sudo systemctl start backup-full.timer
sudo systemctl start backup-incremental.timer
sudo systemctl start backup-offsite.timer
sudo systemctl start backup-health-check.timer

# Verify timers active
sudo systemctl list-timers | grep backup
```

**Expected output:**
```
Sun 2025-10-19 02:00:00 EET  ... backup-full.timer
Mon 2025-10-20 02:00:00 EET  ... backup-incremental.timer
...  03:00:00 EET  ... backup-offsite.timer
...  06:00:00 EET  ... backup-health-check.timer
```

---

### 3. Установить logrotate config

```bash
# Copy config
sudo cp solution/configs/logrotate.d/backup /etc/logrotate.d/

# Test configuration (dry-run)
sudo logrotate -d /etc/logrotate.d/backup

# Force rotation (для тестирования)
sudo logrotate -f /etc/logrotate.d/backup

# Verify
ls -lh /var/log/backup.log*
```

---

### 4. Настроить offsite backup (SSH keys)

```bash
# Generate SSH key для backup
ssh-keygen -t ed25519 -f ~/.ssh/backup_key -N "" -C "backup@$(hostname)"

# Copy к remote server
ssh-copy-id -i ~/.ssh/backup_key.pub backup@remote-server

# Test connection
ssh -i ~/.ssh/backup_key backup@remote-server "echo Connection OK"

# Update script config (если нужно)
sudo nano /usr/local/bin/backup_manager.sh
# Измени REMOTE_BACKUP_HOST, REMOTE_BACKUP_USER, REMOTE_BACKUP_PATH
```

---

## 📊 Monitoring

### Check timer status

```bash
# List all backup timers
sudo systemctl list-timers | grep backup

# Status конкретного timer
sudo systemctl status backup-full.timer
sudo systemctl status backup-health-check.timer
```

### View logs (systemd journal)

```bash
# All backup logs
sudo journalctl -t backup-full -t backup-incremental -f

# Specific service
sudo journalctl -u backup-full.service -f

# Last 24 hours
sudo journalctl -u backup-full.service --since "24 hours ago"

# Only errors
sudo journalctl -u backup-full.service -p err
```

### Traditional log file

```bash
# Real-time
tail -f /var/log/backup.log

# Last 100 lines
tail -100 /var/log/backup.log

# Search for errors
grep -i error /var/log/backup.log
grep -i failed /var/log/backup.log
```

---

## 🧪 Testing

### Manual run (test без ожидания timer)

```bash
# Full backup
sudo systemctl start backup-full.service
sudo journalctl -u backup-full.service -f

# Incremental
sudo systemctl start backup-incremental.service

# Health check
sudo systemctl start backup-health-check.service
```

### Disaster recovery simulation

```bash
# См. README.md → Cycle 6 для полного Krylov attack simulation script

# Quick test:
# 1. Create test data
mkdir -p /tmp/test-data
echo "Important data" > /tmp/test-data/file.txt

# 2. Backup
SOURCE_DATA_DIR=/tmp/test-data /usr/local/bin/backup_manager.sh backup_full

# 3. "Disaster" — delete data
rm -rf /tmp/test-data

# 4. Restore (manual, from latest backup)
LATEST_BACKUP=$(ls -t /backup/full/backup-full-*.tar.gz | head -1)
tar -xzf "$LATEST_BACKUP" -C /

# 5. Verify
ls -lh /tmp/test-data/file.txt
```

---

## 🔧 Troubleshooting

### Timer not running

```bash
# Check if enabled
sudo systemctl is-enabled backup-full.timer

# Check status
sudo systemctl status backup-full.timer

# Re-enable
sudo systemctl enable --now backup-full.timer
```

### Backup failed

```bash
# Check logs
sudo journalctl -u backup-full.service --since "1 hour ago"

# Check disk space
df -h /backup

# Check permissions
ls -ld /backup
# Should be: drwxr-xr-x root root

# Check script permissions
ls -l /usr/local/bin/backup_manager.sh
# Should be: -rwxr-xr-x root root
```

### Offsite sync failed

```bash
# Check SSH key
ls -l ~/.ssh/backup_key
# Should be: -rw------- (600)

# Test SSH connection
ssh -i ~/.ssh/backup_key backup@remote-server

# Check remote disk space
ssh -i ~/.ssh/backup_key backup@remote-server "df -h"

# Manual rsync test
rsync -av -e "ssh -i ~/.ssh/backup_key" /backup/full/ backup@remote-server:/backup/test/
```

### Logrotate not working

```bash
# Test config
sudo logrotate -d /etc/logrotate.d/backup

# Check cron
ls -l /etc/cron.daily/logrotate
# Should exist

# Force rotation
sudo logrotate -f /etc/logrotate.d/backup

# Check status
sudo cat /var/lib/logrotate/status | grep backup
```

---

## 📈 Production Recommendations

### Security

1. **Encrypt sensitive backups:**
```bash
# GPG encryption
tar -czf - /sensitive-data | gpg --encrypt -r admin@example.com > backup.tar.gz.gpg
```

2. **Immutable backups (ransomware protection):**
```bash
# Make backup immutable
sudo chattr +i /backup/critical.tar.gz

# List immutable files
lsattr /backup/*.tar.gz | grep "i"

# Remove when need to delete
sudo chattr -i /backup/old.tar.gz
```

3. **SSH key security:**
```bash
# Protect private key
chmod 600 ~/.ssh/backup_key

# Backup key to safe location (offsite!)
cp ~/.ssh/backup_key* /media/usb-drive/backup-keys/
```

### Performance

1. **Schedule backups during low-traffic hours:**
   - Full backup: 02:00 Sunday (lowest traffic)
   - Incremental: 02:00 daily (nights)
   - Offsite: 03:00 (after local complete)

2. **Resource limits (already configured in systemd units):**
   - CPUQuota=50% (не монополизировать CPU)
   - MemoryLimit=2G (ограничить RAM usage)

3. **Parallel offsite sync (если много серверов):**
```bash
# Use rsync with bandwidth limit
rsync -av --bwlimit=10000 ... # 10MB/s max
```

### Compliance

| Requirement | Solution |
|-------------|----------|
| **Retention (7 years)** | Modify `cleanup_old_backups()` в скрипте |
| **Audit trail** | Все логируется в journald + /var/log/backup.log |
| **Encryption** | Добавить GPG в backup_full() |
| **Offsite (3-2-1)** | ✅ Уже настроено |
| **Testing** | Monthly restore test (документируй!) |

---

## 📋 Maintenance Checklist

### Weekly
```
[ ] Check backup health: systemctl status backup-health-check.timer
[ ] Review logs: tail -100 /var/log/backup.log
[ ] Check disk space: df -h /backup
```

### Monthly
```
[ ] Test restore (pick random backup, restore to test environment)
[ ] Review offsite backups (verify remote copies exist)
[ ] Check retention policy (old backups cleaned up?)
[ ] Update documentation (если procedures изменились)
```

### Quarterly
```
[ ] Full disaster recovery drill (вся команда)
[ ] Review RTO/RPO (still acceptable?)
[ ] Audit backup security (SSH keys, encryption)
[ ] Test restore on fresh server (validate procedures)
```

---

## 🎓 Success Criteria

Вы successfully implemented Episode 12 если:

- [x] Backups run automatically (systemd timers active)
- [x] Full backup каждую неделю (Sunday 02:00)
- [x] Incremental backup ежедневно (Mon-Sat 02:00)
- [x] Offsite sync работает (SSH keys configured)
- [x] Health checks run every 6 hours
- [x] Logs rotated (logrotate configured)
- [x] At least ONE successful restore tested
- [x] Documentation complete (DR procedures written)

**Liisa Kask approves!** ✅

---

## 📞 Support

**In case of disaster:**

1. **DON'T PANIC** (Liisa's rule #1)
2. Follow disaster recovery procedures (см. README.md → Cycle 8)
3. Check backups: `ls -lh /backup/full/`
4. Verify integrity: `sha256sum -c backup.tar.gz.sha256`
5. Restore and test
6. Document what happened (для forensics)

**LILITH:** *"Backup без testing — это надежда. Надежда не стратегия. Test your backups. Monthly."*

**Liisa:** *"Skype taught me: preparation beats panic. If you know procedures, tested backups, documented plan — disaster is just a checklist. Follow checklist → problem solved."*

---

**Next:** Season 4 — DevOps & Automation (Amsterdam 🇳🇱)

