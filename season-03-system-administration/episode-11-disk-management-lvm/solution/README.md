# Episode 11: Disk Management & LVM — Solution README

## 📋 Overview

This directory contains the **reference solution** for Episode 11: Disk Management & LVM.

**Files:**
```
solution/
├── disk_manager.sh         # Main bash script (LVM automation)
├── configs/
│   ├── fstab.example       # /etc/fstab configuration example
│   ├── disk-monitor.service # systemd service for disk monitoring
│   └── disk-monitor.timer   # systemd timer (runs every 30 min)
├── scripts/
│   └── disk-monitor.sh     # Disk space monitoring script
└── README.md              # This file (workflow guide)
```

**Purpose:**  
This solution demonstrates **production-ready disk management** using:
- ✅ LVM (Physical Volumes, Volume Groups, Logical Volumes)
- ✅ Filesystems (ext4, xfs)
- ✅ `/etc/fstab` (automated mounting)
- ✅ systemd (disk space monitoring automation)
- ✅ SMART monitoring (disk health checks)
- ✅ Data migration (rsync from failing disk)

---

## 🎯 Episode 11 Solution Type: Type A (Bash Automation OK)

**Type A Balance:**
- 70% time: LVM commands, disk inspection, fstab configuration
- 20% time: Configuration files (/etc/fstab, systemd units)
- 10% time: Bash automation (`disk_manager.sh`, `disk-monitor.sh`)

**Philosophy:**  
LVM commands are the core skill. Bash automation is a **tool** to speed up repetitive tasks, not a replacement for understanding the underlying commands.

**Kristjan:**  
*"Disk management — это не просто запустить скрипт. Это понимание PV → VG → LV цепочки. Скрипт — это automation после того как ты освоил manual workflow."*

---

## 🛠️ Solution Workflow (Step-by-Step)

### Prerequisites

1. **2+ disks available** (or use loop devices for testing)
   ```bash
   # Check available disks
   lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
   
   # For demo: Create loop devices
   dd if=/dev/zero of=/tmp/disk1.img bs=1M count=1024
   sudo losetup -fP /tmp/disk1.img
   ```

2. **Required packages installed:**
   ```bash
   sudo apt update
   sudo apt install -y lvm2 smartmontools parted rsync
   ```

3. **Run as root or with sudo**
   ```bash
   # Most commands require root privileges
   sudo -i  # or use sudo before each command
   ```

---

### Step 1: Disk Health Check (SMART Monitoring)

**Goal:** Identify failing disks **before** they cause data loss.

```bash
# Install smartmontools (if not installed)
sudo apt install smartmontools

# Quick health check
sudo smartctl -H /dev/sda
# Output: PASSED (✅ healthy) or FAILED (❌ replace immediately!)

# Detailed SMART data
sudo smartctl -a /dev/sda

# Check critical attributes (reallocated sectors, pending sectors)
sudo smartctl -A /dev/sda | grep -E "Reallocated|Pending|Uncorrectable"

# Example output:
#   5 Reallocated_Sector_Ct   0x0033   100   100   010    Pre-fail  Always   -   0
# 197 Current_Pending_Sector  0x0012   100   100   000    Old_age   Always   -   0
# 198 Offline_Uncorrectable   0x0010   100   100   000    Old_age   Always   -   0
#
# If any value > 0 → WARNING! Disk is degrading.
# If Reallocated > 50 → CRITICAL! Plan migration ASAP.
```

**Interpret SMART attributes:**
- **Reallocated_Sector_Ct:** Bad sectors that were remapped to spare area
  - 0 = Perfect ✅
  - 1-50 = Acceptable (monitor closely) ⚠️
  - >50 = Failing disk (replace soon) 🚨
  - >200 = Critical (replace NOW!) ❌

---

### Step 2: Partitioning (GPT)

**Goal:** Create a partition on the new disk for LVM.

```bash
# Choose your disk (CAREFUL! Wrong disk = data loss!)
NEW_DISK="/dev/sdc"  # Adjust to your system!

# Check disk is empty and available
lsblk $NEW_DISK
sudo fdisk -l $NEW_DISK

# Create GPT partition table
sudo parted $NEW_DISK mklabel gpt

# Create partition (use entire disk)
sudo parted $NEW_DISK mkpart primary 0% 100%

# Set partition type to LVM
sudo parted $NEW_DISK set 1 lvm on

# Verify
sudo parted $NEW_DISK print

# Output:
# Model: ... (scsi)
# Disk /dev/sdc: 500GB
# Partition Table: gpt
# 
# Number  Start   End     Size    File system  Name     Flags
#  1      1049kB  500GB   500GB                primary  lvm

# Update kernel partition table
sudo partprobe $NEW_DISK
```

**Why GPT (not MBR)?**
- ✅ Supports disks >2TB
- ✅ Supports 128 partitions (vs 4 in MBR)
- ✅ Has backup partition table (more reliable)
- ✅ Modern standard

---

### Step 3: LVM Setup (PV → VG → LV)

**Goal:** Create flexible storage using LVM.

#### 3.1: Create Physical Volume (PV)

```bash
# Create PV from partition
sudo pvcreate /dev/sdc1

# Verify
sudo pvs
# Output:
#   PV         VG   Fmt  Attr PSize   PFree  
#   /dev/sdc1       lvm2 ---  500.00g 500.00g

# Detailed info
sudo pvdisplay /dev/sdc1
```

#### 3.2: Create Volume Group (VG)

```bash
# Create VG named "vg_data" from PV
sudo vgcreate vg_data /dev/sdc1

# Verify
sudo vgs
# Output:
#   VG      #PV #LV #SN Attr   VSize   VFree  
#   vg_data   1   0   0 wz--n- 500.00g 500.00g

# Detailed info
sudo vgdisplay vg_data
```

#### 3.3: Create Logical Volumes (LV)

```bash
# Create LV for databases (200GB, xfs)
sudo lvcreate -L 200G -n lv_databases vg_data

# Create LV for logs (100GB, ext4)
sudo lvcreate -L 100G -n lv_logs vg_data

# Create LV for backups (50GB, ext4)
sudo lvcreate -L 50G -n lv_backups vg_data

# Verify
sudo lvs
# Output:
#   LV           VG      Attr       LSize   Pool Origin Data%
#   lv_backups   vg_data -wi-a-----  50.00g
#   lv_databases vg_data -wi-a----- 200.00g
#   lv_logs      vg_data -wi-a----- 100.00g

# Check remaining free space in VG
sudo vgs
# Output:
#   VG      #PV #LV #SN Attr   VSize   VFree  
#   vg_data   1   3   0 wz--n- 500.00g 150.00g
#                                       ^^^^^^^ Can create more LVs later!
```

---

### Step 4: Create Filesystems

**Goal:** Format LVs with appropriate filesystems.

```bash
# XFS for databases (high performance, large files)
sudo mkfs.xfs -L DATABASES /dev/vg_data/lv_databases

# ext4 for logs (stable, general purpose)
sudo mkfs.ext4 -L LOGS /dev/vg_data/lv_logs

# ext4 for backups
sudo mkfs.ext4 -L BACKUPS /dev/vg_data/lv_backups

# Verify
sudo blkid | grep vg_data
# Output shows UUID and filesystem type for each LV
```

**Why XFS for databases?**
- ✅ High performance for large sequential writes
- ✅ Excellent for large files (DB files often >10GB)
- ✅ Online growth (can extend without unmounting)
- ❌ Cannot shrink (only grow)

**Why ext4 for logs/backups?**
- ✅ Stable, well-tested
- ✅ Good all-around performance
- ✅ Can shrink and grow
- ✅ Easy recovery

---

### Step 5: Mount & Configure /etc/fstab

**Goal:** Mount filesystems and configure automatic mounting at boot.

#### 5.1: Manual Mounting (Temporary)

```bash
# Create mount points
sudo mkdir -p /mnt/databases
sudo mkdir -p /mnt/logs
sudo mkdir -p /mnt/backups

# Mount filesystems
sudo mount /dev/vg_data/lv_databases /mnt/databases
sudo mount /dev/vg_data/lv_logs /mnt/logs
sudo mount /dev/vg_data/lv_backups /mnt/backups

# Verify
df -h | grep -E "databases|logs|backups"
# Output:
# /dev/mapper/vg_data-lv_databases  197G   61M  187G   1% /mnt/databases
# /dev/mapper/vg_data-lv_logs        99G   24M   94G   1% /mnt/logs
# /dev/mapper/vg_data-lv_backups     49G   24M   46G   1% /mnt/backups
```

#### 5.2: Configure /etc/fstab (Permanent)

**⚠️ CRITICAL: ALWAYS BACKUP /etc/fstab BEFORE EDITING!**

```bash
# 1. Backup original fstab
sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d)

# 2. Get UUIDs (IMPORTANT: Use UUID, not device paths!)
sudo blkid /dev/vg_data/lv_databases
# Output: UUID="a1b2c3d4-e5f6-4a5b-9c8d-7e6f5a4b3c2d" TYPE="xfs"

sudo blkid /dev/vg_data/lv_logs
# Output: UUID="f1e2d3c4-b5a6-4f5e-9d8c-7e6f5a4b3c2d" TYPE="ext4"

sudo blkid /dev/vg_data/lv_backups
# Output: UUID="c1d2e3f4-a5b6-4c5d-9e8f-7a6b5c4d3e2f" TYPE="ext4"

# 3. Edit /etc/fstab
sudo nano /etc/fstab

# 4. Add entries (REPLACE UUIDs with your actual UUIDs!):
UUID=a1b2c3d4-e5f6-4a5b-9c8d-7e6f5a4b3c2d  /mnt/databases  xfs   defaults,noatime,nofail  0  2
UUID=f1e2d3c4-b5a6-4f5e-9d8c-7e6f5a4b3c2d  /mnt/logs       ext4  defaults,noatime,nofail  0  2
UUID=c1d2e3f4-a5b6-4c5d-9e8f-7a6b5c4d3e2f  /mnt/backups    ext4  defaults,noatime,nofail  0  2

# 5. Save and exit (Ctrl+O, Enter, Ctrl+X)
```

#### 5.3: Test fstab (BEFORE REBOOT!)

**⚠️ CRITICAL: Never reboot without testing fstab!**

```bash
# 1. Unmount all filesystems
sudo umount /mnt/databases
sudo umount /mnt/logs
sudo umount /mnt/backups

# 2. Test mount -a (mount all from fstab)
sudo mount -a

# 3. Verify all mounted successfully
df -h | grep -E "databases|logs|backups"

# If error → FIX /etc/fstab NOW!
# If all OK → safe to reboot
```

**fstab Options Explained:**
- `defaults`: rw, suid, dev, exec, auto, nouser, async
- `noatime`: Don't update access time (PERFORMANCE BOOST!)
- `nofail`: Don't fail boot if device missing (safe for non-critical mounts)
- `0`: No dump (backup) — 0 for modern systems
- `2`: fsck pass — check filesystem after root (1 = root only)

---

### Step 6: Data Migration (If Needed)

**Goal:** Safely copy data from old/failing disk to new LV.

**Scenario:** Old disk `/dev/sdb1` is failing (high Reallocated sectors), need to migrate to `/dev/vg_data/lv_databases`.

```bash
# 1. Mount old disk READ-ONLY (safety!)
sudo mkdir -p /mnt/old_db
sudo mount -o ro /dev/sdb1 /mnt/old_db

# 2. Verify new LV is mounted
mountpoint /mnt/databases || sudo mount /dev/vg_data/lv_databases /mnt/databases

# 3. Copy data with rsync (SAFE, RESUMABLE)
sudo rsync -avh --progress /mnt/old_db/ /mnt/databases/

# Options:
# -a: archive mode (preserve permissions, timestamps, symlinks)
# -v: verbose (show what's being copied)
# -h: human-readable sizes
# --progress: show progress bar

# 4. Verify data integrity (compare)
diff -r /mnt/old_db/ /mnt/databases/
# No output = perfect copy ✅

# 5. Unmount old disk
sudo umount /mnt/old_db

# 6. Retire old disk (physically remove)
```

**Why rsync (not cp)?**
- ✅ Resumable (if interrupted, rerun same command)
- ✅ Incremental (only copies changes)
- ✅ Preserves metadata (permissions, timestamps)
- ✅ Progress bar
- ✅ Checksum verification (optional with --checksum)

---

### Step 7: LVM Operations (Resize, Extend, Snapshot)

#### 7.1: Extend Logical Volume (Add Space)

```bash
# Check VG free space
sudo vgs
# Output: VG has 150GB free

# Extend lv_databases by 50GB
sudo lvextend -L +50G /dev/vg_data/lv_databases

# Grow filesystem (CRITICAL! Don't forget this step!)
# For XFS:
sudo xfs_growfs /mnt/databases

# For ext4:
sudo resize2fs /dev/vg_data/lv_databases

# Verify
df -h | grep databases
# Size should now show +50GB ✅
```

**⚠️ CRITICAL:** Two-step process!
1. `lvextend` — grows the LV (block device)
2. `resize2fs` (ext4) or `xfs_growfs` (xfs) — grows the filesystem

Forget step 2 → filesystem doesn't see new space!

#### 7.2: Snapshot (Backup Before Risky Operation)

```bash
# Create snapshot before risky operation (e.g., database upgrade)
sudo lvcreate -L 10G -s -n lv_databases_snap /dev/vg_data/lv_databases

# -L 10G: snapshot size (for delta changes)
# -s: snapshot flag
# -n: snapshot name

# Check snapshot
sudo lvs
# Output shows snapshot with 0% data usage

# If something goes wrong → revert to snapshot:
# sudo lvconvert --merge /dev/vg_data/lv_databases_snap
# (requires unmounting lv_databases first)

# If all OK → remove snapshot:
sudo lvremove /dev/vg_data/lv_databases_snap
```

---

### Step 8: Production Monitoring (systemd + Timer)

**Goal:** Automate disk space monitoring with systemd.

#### 8.1: Install Monitoring Script

```bash
# Copy script to /usr/local/bin/
sudo cp scripts/disk-monitor.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/disk-monitor.sh

# Test script manually
sudo /usr/local/bin/disk-monitor.sh

# Expected output:
# [2025-10-11 13:00:00] [INFO] Disk Space Monitoring Started
# [2025-10-11 13:00:00] [INFO] / is 45% full — OK
# [2025-10-11 13:00:00] [INFO] /mnt/databases is 35% full — OK
# ...
```

#### 8.2: Install systemd Service & Timer

```bash
# Copy service and timer files
sudo cp configs/disk-monitor.service /etc/systemd/system/
sudo cp configs/disk-monitor.timer /etc/systemd/system/

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable timer (start on boot)
sudo systemctl enable disk-monitor.timer

# Start timer NOW
sudo systemctl start disk-monitor.timer

# Check timer status
sudo systemctl status disk-monitor.timer

# List when timer will run next
systemctl list-timers disk-monitor.timer

# Expected output:
# NEXT                         LEFT     LAST PASSED UNIT                   ACTIVATES
# Sat 2025-10-11 13:30:00 UTC  15min    n/a  n/a    disk-monitor.timer     disk-monitor.service
```

#### 8.3: View Logs

```bash
# View service logs (last 50 entries)
sudo journalctl -u disk-monitor.service -n 50

# Follow logs in real-time
sudo journalctl -u disk-monitor.service -f

# View timer logs
sudo journalctl -u disk-monitor.timer -n 20
```

---

## 🧪 Testing the Solution

### Test 1: LVM Functionality

```bash
# Verify PV, VG, LV
sudo pvs
sudo vgs
sudo lvs

# Verify all LVs are active
sudo lvdisplay | grep "LV Status"
# Should show "available" for all LVs
```

### Test 2: Filesystem Mount

```bash
# Verify all filesystems mounted
df -h | grep -E "databases|logs|backups"

# Verify mount options
mount | grep -E "databases|logs|backups"
# Should show noatime option
```

### Test 3: fstab Persistence

```bash
# Unmount all
sudo umount /mnt/databases
sudo umount /mnt/logs
sudo umount /mnt/backups

# Test mount -a
sudo mount -a

# Verify
df -h | grep -E "databases|logs|backups"

# If all mounted → fstab is correct ✅
```

### Test 4: Monitoring Alerts (Simulate High Usage)

```bash
# Create large file to fill disk (90%+)
sudo dd if=/dev/zero of=/mnt/logs/testfile bs=1M count=80000
# (adjust count to reach 90% usage)

# Trigger monitor manually
sudo systemctl start disk-monitor.service

# Check logs for alert
sudo journalctl -u disk-monitor.service -n 20
# Should see CRITICAL alert ✅

# Cleanup
sudo rm /mnt/logs/testfile
```

---

## 📊 Expected Results

### Disk Layout

```
/dev/sdc (500GB SSD)
│
└─ /dev/sdc1 (500GB partition, GPT)
   │
   └─ PV: /dev/sdc1
      │
      └─ VG: vg_data (500GB)
         │
         ├─ LV: lv_databases (200GB) → /mnt/databases (xfs)
         ├─ LV: lv_logs (100GB) → /mnt/logs (ext4)
         ├─ LV: lv_backups (50GB) → /mnt/backups (ext4)
         └─ Free: 150GB (for future expansion)
```

### /etc/fstab Entries

```
UUID=...  /mnt/databases  xfs   defaults,noatime,nofail  0  2
UUID=...  /mnt/logs       ext4  defaults,noatime,nofail  0  2
UUID=...  /mnt/backups    ext4  defaults,noatime,nofail  0  2
```

### systemd Timer Schedule

- Runs every 30 minutes (`*:0/30`)
- Runs 5 min after boot
- Alerts if disk usage ≥ 90%
- Logs to journald and syslog

---

## 🔧 Troubleshooting

### Problem: LV won't mount

```bash
# Check LV is active
sudo lvdisplay /dev/vg_data/lv_databases | grep "LV Status"

# If inactive → activate
sudo lvchange -ay /dev/vg_data/lv_databases

# Check filesystem
sudo fsck -f /dev/vg_data/lv_databases  # for ext4
sudo xfs_repair /dev/vg_data/lv_databases  # for xfs
```

### Problem: fstab error on boot

```bash
# Boot to rescue mode
# Mount root filesystem read-write
mount -o remount,rw /

# Edit fstab
nano /etc/fstab

# Test
mount -a

# Reboot
reboot
```

### Problem: VG has no free space

```bash
# Check VG free space
sudo vgs

# If 0 free → add new disk to VG
sudo pvcreate /dev/sdd1
sudo vgextend vg_data /dev/sdd1

# Now can extend LVs
sudo lvextend -L +100G /dev/vg_data/lv_databases
sudo xfs_growfs /mnt/databases
```

### Problem: Timer not running

```bash
# Check if timer is enabled
systemctl is-enabled disk-monitor.timer

# If disabled → enable
sudo systemctl enable disk-monitor.timer
sudo systemctl start disk-monitor.timer

# Check timer status
systemctl status disk-monitor.timer

# Check service status
systemctl status disk-monitor.service
```

---

## ✅ Completion Checklist

- [ ] LVM setup complete (PV → VG → LV)
- [ ] Filesystems created (xfs for databases, ext4 for logs/backups)
- [ ] `/etc/fstab` configured with UUID and tested
- [ ] All filesystems mount automatically after reboot
- [ ] Data migration completed (if applicable)
- [ ] systemd monitoring service installed and enabled
- [ ] systemd timer runs every 30 minutes
- [ ] Monitoring alerts work (tested with high disk usage)
- [ ] SMART monitoring configured (optional: `smartd` daemon)
- [ ] Documentation updated (mount points, UUIDs)

---

## 🎓 Key Takeaways

### LVM Flexibility

- ✅ **Resize on-the-fly:** Extend/reduce LVs without downtime
- ✅ **Add disks easily:** Extend VG with new PVs
- ✅ **Snapshots:** Instant backups for risky operations
- ✅ **Thin provisioning:** Allocate space as needed (not covered in this episode)

### Production Best Practices

1. **Always use UUID in fstab** (not device paths)
2. **Always use `noatime`** for performance (databases especially)
3. **Always test fstab with `mount -a`** before reboot
4. **Always backup fstab** before editing
5. **Automate monitoring** (systemd timers, not manual checks)
6. **SMART monitoring** (catch failing disks early)
7. **RAID for redundancy** (RAID 10 for databases, not RAID 5)
8. **Regular backups** (RAID ≠ backup!)

### Kristjan's Final Advice

*"LVM — это не просто 'больше места'. Это философия flexible storage. Ты можешь resize, snapshot, migrate — всё налёт. Без LVM — ты привязан к fixed partitions. С LVM — ты контролируешь storage."*

*"Disk management — это foundation Linux SysAdmin. Процессы работают на дисках. Данные живут на дисках. Без правильного disk management — всё остальное бессмысленно."*

---

**Episode 11: Complete! 🎉**

**Liisa:** *"Макс, ты спас 500GB production данных за 3 часа. Это настоящий sysadmin work."*

**Next:** Episode 12 — Backup & Recovery (Disaster Recovery, rsync, tar, systemd timers)

