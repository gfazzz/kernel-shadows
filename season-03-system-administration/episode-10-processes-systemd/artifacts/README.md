# Episode 10 Artifacts
## Processes & SystemD

This directory contains testing and simulation materials for Episode 10.

---

## 📁 Contents

Since this episode focuses on **real system processes and systemd**, there are **no static test files**. Instead, you'll work with:

1. **Real processes** on your system
2. **SystemD units** you create
3. **Journald logs** generated in real-time

---

## 🎭 Simulating Backdoor Process (for testing)

To test your backdoor detection skills, you can simulate a suspicious process:

### Option 1: Simple Bash Loop (safe)

```bash
# Create fake backdoor script
cat > /tmp/sshd_backup << 'EOF'
#!/bin/bash
while true; do
    sleep 60
done
EOF

chmod +x /tmp/sshd_backup

# Run it in background
/tmp/sshd_backup &

# Note the PID
echo "Backdoor PID: $!"

# Your task: Find and kill it!
```

### Option 2: Using `sleep` with fake name

```bash
# Start process with suspicious name
(exec -a sshd_backup sleep 3600) &
echo "Backdoor PID: $!"

# Find it:
ps aux | grep sshd_backup
pgrep -a sshd_backup

# Kill it:
kill -15 <PID>
```

### Option 3: Netcat Listener (more realistic)

```bash
# Start fake network listener
nc -l -p 9999 &
echo "Listener PID: $!"

# Find it:
netstat -tulpn | grep 9999
# or
ss -tulpn | grep 9999

# Kill it
kill $!
```

---

## 🧪 Testing Your Scripts

### Test 1: Process Detection

```bash
# 1. Start fake backdoor
(exec -a sshd_backup sleep 3600) &
backdoor_pid=$!

# 2. Run your detection script
./starter.sh

# 3. Verify detection
# Your script should identify PID: $backdoor_pid

# 4. Cleanup
kill $backdoor_pid
```

### Test 2: SystemD Service

```bash
# After creating shadow-monitor.service:

# Check status
systemctl status shadow-monitor.service

# Check logs
journalctl -u shadow-monitor.service -n 50

# Test restart
sudo systemctl restart shadow-monitor.service

# Verify running
ps aux | grep shadow-monitor
```

### Test 3: SystemD Timer

```bash
# After creating shadow-backup.timer:

# Check timer
systemctl list-timers shadow-backup.timer

# Trigger manual run
sudo systemctl start shadow-backup.service

# Check backup
ls -lh /var/backups/shadow/

# Check logs
journalctl -u shadow-backup.service
```

---

## 🔍 Verification Checklist

### Process Management:
- [ ] Can find processes with `ps aux`
- [ ] Can use `pgrep` to search by name
- [ ] Can inspect `/proc/PID/` directories
- [ ] Can kill process with SIGTERM
- [ ] Can force kill with SIGKILL
- [ ] Can verify process is dead

### SystemD Services:
- [ ] Created `/usr/local/bin/shadow-monitor.sh`
- [ ] Created `/etc/systemd/system/shadow-monitor.service`
- [ ] Ran `systemctl daemon-reload`
- [ ] Service starts successfully
- [ ] Service is enabled (auto-start)
- [ ] Logs appear in journalctl

### SystemD Timers:
- [ ] Created `/usr/local/bin/shadow-backup.sh`
- [ ] Created `/etc/systemd/system/shadow-backup.service`
- [ ] Created `/etc/systemd/system/shadow-backup.timer`
- [ ] Timer is enabled and started
- [ ] Timer shows in `systemctl list-timers`
- [ ] Manual trigger works
- [ ] Backups created in `/var/backups/shadow/`

### Journalctl:
- [ ] Can view service logs: `journalctl -u servicename`
- [ ] Can filter by time: `--since`, `--until`
- [ ] Can filter by priority: `-p err`
- [ ] Can follow logs: `-f`
- [ ] Can check disk usage: `--disk-usage`

### System Health:
- [ ] Can check load average: `uptime`
- [ ] Can check memory: `free -h`
- [ ] Can sort processes by CPU: `ps aux --sort=-%cpu`
- [ ] Can sort processes by memory: `ps aux --sort=-%mem`
- [ ] Can check failed services: `systemctl --failed`

---

## 🐛 Troubleshooting

### "Permission denied" when creating service

**Problem:**
```
bash: /etc/systemd/system/shadow-monitor.service: Permission denied
```

**Solution:**
Use `sudo`:
```bash
sudo tee /etc/systemd/system/shadow-monitor.service << 'EOF'
...
EOF
```

---

### Service fails to start

**Problem:**
```
Job for shadow-monitor.service failed.
```

**Solution:**
Check logs:
```bash
journalctl -u shadow-monitor.service -n 50
systemctl status shadow-monitor.service
```

Common issues:
- Script not executable: `sudo chmod +x /usr/local/bin/shadow-monitor.sh`
- Syntax error in script: `bash -n /usr/local/bin/shadow-monitor.sh`
- Wrong shebang: Check first line is `#!/bin/bash`
- Missing dependency: Install required tools

---

### Timer not triggering

**Problem:**
Timer shows in list but service never runs.

**Solution:**
1. Check timer is enabled AND started:
```bash
systemctl enable shadow-backup.timer
systemctl start shadow-backup.timer
```

2. Check OnCalendar syntax:
```bash
systemd-analyze calendar "hourly"
```

3. Force trigger to test:
```bash
sudo systemctl start shadow-backup.service
journalctl -u shadow-backup.service
```

4. Verify service is Type=oneshot:
```bash
systemctl cat shadow-backup.service | grep Type
```

---

### "Cannot find process" when killing

**Problem:**
```
kill: (12345): No such process
```

**Solution:**
Process already dead or PID wrong:
```bash
# Verify process exists
ps -p 12345

# Or search by name
pgrep processname

# Use correct PID
kill -15 $(pgrep processname)
```

---

### Journalctl shows "No entries"

**Problem:**
```
journalctl -u shadow-monitor.service
-- No entries --
```

**Solution:**
1. Service might not have started yet:
```bash
systemctl status shadow-monitor.service
```

2. Service might not be logging to journal:
Check service unit has:
```ini
StandardOutput=journal
StandardError=journal
```

3. Use logger in script:
```bash
logger -t shadow-monitor "Test message"
journalctl -t shadow-monitor
```

---

### Script runs manually but not via systemd

**Problem:**
Script works when run directly: `./shadow-monitor.sh`
But fails when started by systemd.

**Solution:**
Common causes:

1. **Environment variables:**
   SystemD has minimal environment. Add to service:
   ```ini
   Environment="PATH=/usr/local/bin:/usr/bin:/bin"
   ```

2. **Working directory:**
   Add to service:
   ```ini
   WorkingDirectory=/usr/local/bin
   ```

3. **Relative paths:**
   Use absolute paths in script:
   ```bash
   # Bad:
   ./some_tool

   # Good:
   /usr/bin/some_tool
   ```

4. **User permissions:**
   Check User= in service file matches file permissions.

---

## 📚 Man Pages Reference

Essential man pages for Episode 10:

```bash
man ps          # Process status
man top         # Process monitoring
man kill        # Send signals
man pgrep       # Process grep
man pkill       # Process kill

man systemd            # SystemD overview
man systemctl          # SystemD control
man systemd.service    # Service units
man systemd.timer      # Timer units
man systemd.unit       # Unit files

man journalctl         # Journal query
man systemd-journald   # Journal daemon

man proc        # /proc filesystem
```

---

## 💡 Pro Tips

### 1. Process Forensics

```bash
# Full process tree
ps auxf
pstree -p

# Process by user
ps -u username

# Zombie processes
ps aux | awk '$8=="Z"'

# Open files by process
lsof -p PID

# Network connections by process
lsof -i -nP | grep PID
```

### 2. SystemD Power Features

```bash
# Service dependencies
systemctl list-dependencies servicename

# Service properties
systemctl show servicename

# Edit service (creates override)
systemctl edit servicename

# View full unit with overrides
systemctl cat servicename

# Analyze boot time
systemd-analyze blame
```

### 3. Journalctl Advanced

```bash
# Boot-specific logs
journalctl -b 0      # current boot
journalctl -b -1     # previous boot

# Kernel messages
journalctl -k

# Priority levels combined
journalctl -p crit..err  # crit, err only

# JSON output for parsing
journalctl -o json-pretty

# Specific fields
journalctl _SYSTEMD_UNIT=sshd.service

# Multiple filters (AND logic)
journalctl _COMM=sudo _UID=1000
```

### 4. Timer Syntax Examples

```bash
# Every 15 minutes
OnCalendar=*:0/15

# Every day at 3 AM
OnCalendar=*-*-* 03:00:00

# Weekdays at 9 AM
OnCalendar=Mon..Fri 09:00

# First day of month
OnCalendar=*-*-01 00:00:00

# Relative to boot
OnBootSec=15min

# Relative to last activation
OnUnitActiveSec=1h
```

---

## 🎓 Learning Resources

### Online Documentation:
- [SystemD Homepage](https://systemd.io/)
- [ArchWiki: systemd](https://wiki.archlinux.org/title/Systemd)
- [Lennart Poettering's Blog](http://0pointer.de/blog/)
- [Red Hat: SystemD Guide](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/configuring_basic_system_settings/assembly_working-with-systemd_configuring-basic-system-settings)

### Books:
- "Linux System Programming" by Robert Love
- "The Linux Programming Interface" by Michael Kerrisk
- "How Linux Works" by Brian Ward

### Practice:
- Experiment on VM or container (Docker)
- Check systemd units on your system: `/lib/systemd/system/`
- Study real services: `systemctl cat sshd.service`

---

## 🛡️ Security Notes

1. **Backdoor processes** often disguise as system services:
   - Check executable path: `/proc/PID/exe`
   - Check parent process: `ps -p PID -o ppid=`
   - Check user: `ps -p PID -o user=`

2. **SystemD security** features to use:
   - `NoNewPrivileges=true` — prevent privilege escalation
   - `PrivateTmp=true` — isolated /tmp
   - `ProtectSystem=strict` — read-only system dirs
   - `ProtectHome=true` — hide home directories

3. **Journald security**:
   - Logs can reveal sensitive data
   - Set permissions: `chmod 640` for reports
   - Regular cleanup: `journalctl --vacuum-time=30d`

4. **Process monitoring** best practices:
   - Monitor /tmp, /var/tmp, /dev/shm for executables
   - Check unusual network listeners
   - Watch for processes with system-like names
   - Track CPU/memory spikes (crypto miners)

---

## ✅ Episode 10 Success Criteria

You've successfully completed Episode 10 if:

- [x] Can find and analyze processes (ps, pgrep, /proc)
- [x] Can send signals and kill processes (SIGTERM, SIGKILL)
- [x] Created working systemd service (shadow-monitor)
- [x] Created working systemd timer (shadow-backup)
- [x] Can analyze logs with journalctl
- [x] Can monitor system health (load, memory, CPU)
- [x] Generated comprehensive audit report
- [x] Understand systemd philosophy: "Modern init system"

---

**Boris Kuznetsov:**  
*"Init scripts — это прошлое. SystemD — это настоящее. Ты понял."*

**LILITH:**  
*"Процессы — это пульс системы. Systemd — это сердце. Контролируй их."*

---

**Next:** Episode 11 - Disk Management & LVM (Tallinn, Estonia 🇪🇪)

