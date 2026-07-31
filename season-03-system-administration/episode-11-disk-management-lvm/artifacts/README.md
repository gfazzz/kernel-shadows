# Episode 11 Artifacts
## Disk Management & LVM

This directory contains testing materials for Episode 11.

---

## 📁 Contents

Since this episode focuses on **real disk operations**, most work is done on actual block devices. This directory provides:

1. **Simulation instructions** for testing without real hardware
2. **Troubleshooting guides** for common issues
3. **Testing best practices**

---

## 🎭 Simulating Disk Operations (for safe testing)

### Option 1: Loop Devices (safest for learning)

Loop devices let you create virtual disks from files:

```bash
# Create virtual disk files (1GB each)
dd if=/dev/zero of=/tmp/disk1.img bs=1M count=1024
dd if=/dev/zero of=/tmp/disk2.img bs=1M count=1024
dd if=/dev/zero of=/tmp/disk3.img bs=1M count=1024

# Create loop devices
sudo losetup -fP /tmp/disk1.img
sudo losetup -fP /tmp/disk2.img
sudo losetup -fP /tmp/disk3.img

# Find assigned loop devices
losetup -a

# Now use them like real disks
# Example: /dev/loop0, /dev/loop1, /dev/loop2
```

**Cleanup:**
```bash
# Unmount everything first
sudo umount /dev/loop0* 2>/dev/null

# Detach loop devices
sudo losetup -d /dev/loop0
sudo losetup -d /dev/loop1
sudo losetup -d /dev/loop2

# Remove files
rm /tmp/disk*.img
```

---

### Option 2: Virtual Machine with Extra Disks

If testing in VirtualBox/VMware:

1. **Add virtual disks** to your VM (Settings → Storage → Add Hard Disk)
2. **Size:** 1-2GB each is enough for testing
3. **Quantity:** Add 3-4 disks for LVM and RAID testing
4. **Boot VM** and proceed with episode tasks

**Advantages:**
- Closer to real hardware
- Can test full LVM/RAID stack
- Safe to destroy (just delete virtual disks)

---

### Option 3: Cloud VM with Block Storage

AWS, DigitalOcean, Linode:

1. **Create VM** (cheapest tier is fine)
2. **Add block volumes** (usually $0.10/GB/month)
3. **Attach volumes** to VM
4. **Test**, then **detach and delete** volumes

**Warning:** Don't forget to delete volumes after testing (they cost money!)

---

## 🧪 Testing Your Scripts

### Test 1: Disk Health Check

```bash
# Install smartmontools if needed
sudo apt install smartmontools

# Run your disk health script
./starter.sh

# Verify output includes:
# - lsblk output
# - SMART status
# - I/O statistics
```

**Expected output:**
- List of all block devices
- SMART health status (PASSED or FAILED)
- No critical errors in dmesg

---

### Test 2: LVM Setup

```bash
# After creating LVM
sudo pvs    # Should show your PV
sudo vgs    # Should show your VG
sudo lvs    # Should show your LV

# Check mounted
df -h | grep vg_data

# Test resize
sudo lvresize -L +100M /dev/vg_data/lv_data
sudo resize2fs /dev/vg_data/lv_data
df -h | grep vg_data  # Verify size increased
```

---

### Test 3: RAID Configuration

```bash
# Check RAID status
cat /proc/mdstat
# Should show: md0 : active raid1 ...

# Detailed info
sudo mdadm --detail /dev/md0

# Simulate disk failure
sudo mdadm --fail /dev/md0 /dev/sdd1
cat /proc/mdstat  # Should show [U_] (one failed)

# Replace disk
sudo mdadm --remove /dev/md0 /dev/sdd1
sudo mdadm --add /dev/md0 /dev/sdd1
cat /proc/mdstat  # Should show rebuilding
```

---

## 🐛 Troubleshooting

### "Device is busy" when unmounting

**Problem:**
```
umount: /mnt/data: target is busy
```

**Solution:**
```bash
# Find what's using it
lsof +f -- /mnt/data
fuser -vm /mnt/data

# Kill processes if safe
sudo fuser -km /mnt/data

# Then unmount
sudo umount /mnt/data
```

---

### LVM: "Device not found"

**Problem:**
```
Device /dev/vg_data/lv_data not found
```

**Solution:**
```bash
# Scan for LVM volumes
sudo vgscan
sudo lvscan

# Activate volume group
sudo vgchange -ay vg_data

# Check again
ls -l /dev/vg_data/
```

---

### RAID: "mdadm: Cannot open /dev/md0"

**Problem:**
RAID array not detected after reboot.

**Solution:**
```bash
# Scan for arrays
sudo mdadm --assemble --scan

# Or manually assemble
sudo mdadm --assemble /dev/md0 /dev/sdd1 /dev/sde1

# Check status
cat /proc/mdstat

# Make sure config is saved
sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
sudo update-initramfs -u
```

---

### Partition table not updated

**Problem:**
Created partition but not visible.

**Solution:**
```bash
# Force kernel to re-read partition table
sudo partprobe /dev/sdc

# Or reboot (guaranteed to work)
sudo reboot
```

---

### "Cannot create physical volume"

**Problem:**
```
Device /dev/sdc1 not found (or ignored by filtering)
```

**Solution:**
```bash
# Check if partition exists
lsblk /dev/sdc

# If no partition, create it
sudo parted /dev/sdc mklabel gpt
sudo parted /dev/sdc mkpart primary 0% 100%
sudo parted /dev/sdc set 1 lvm on
sudo partprobe

# Try again
sudo pvcreate /dev/sdc1
```

---

### Filesystem full but df shows space

**Problem:**
```
No space left on device
```
But `df -h` shows available space.

**Solution:**
```bash
# Check inodes
df -i

# If inodes at 100%, too many small files
# Delete unnecessary files or create new filesystem

# Check for large deleted files still held by processes
lsof | grep deleted

# Kill process holding deleted files to free space
```

---

### SMART: "UNAVAILABLE"

**Problem:**
```
SMART support is: Unavailable - device lacks SMART capability
```

**Solution:**
This is normal for:
- Virtual disks (VirtualBox, VMware)
- Loop devices
- Some USB drives

For real hardware, SMART should work. If not:
```bash
# Enable SMART
sudo smartctl -s on /dev/sda

# Check again
sudo smartctl -a /dev/sda
```

---

### Test 4: Production Monitoring (systemd)

```bash
# 1. Check if monitoring is installed
ls -l /usr/local/bin/disk-monitor.sh
ls -l /etc/systemd/system/disk-monitor.*

# 2. Check systemd timer status
systemctl status disk-monitor.timer

# 3. List when timer will run next
systemctl list-timers disk-monitor.timer
# Expected output:
# NEXT                         LEFT       LAST  PASSED  UNIT                   ACTIVATES
# Sat 2025-10-11 13:30:00 UTC  15min left n/a   n/a     disk-monitor.timer     disk-monitor.service

# 4. Manually trigger monitoring (test without waiting)
sudo systemctl start disk-monitor.service

# 5. View monitoring logs
sudo journalctl -u disk-monitor.service -n 50

# 6. View timer logs
sudo journalctl -u disk-monitor.timer -n 20

# 7. Simulate high disk usage to trigger alert
sudo dd if=/dev/zero of=/mnt/databases/testfile bs=1M count=50000
# (adjust count to reach 90% usage)

# 8. Trigger monitoring manually
sudo systemctl start disk-monitor.service

# 9. Check logs for CRITICAL alert
sudo journalctl -u disk-monitor.service -n 20 | grep CRITICAL
# Should see: "CRITICAL: /mnt/databases is XX% full"

# 10. Cleanup test file
sudo rm /mnt/databases/testfile

# 11. Verify timer is enabled (starts on boot)
systemctl is-enabled disk-monitor.timer
# Expected: enabled

# 12. Test systemd calendar syntax (when does it run?)
systemd-analyze calendar "*:0/30"
# Shows next 5 run times for "every 30 minutes"
```

**Expected results:**
- ✅ Timer runs every 30 minutes
- ✅ Alerts sent when disk usage ≥ 90%
- ✅ Logs visible in journalctl
- ✅ Timer survives reboot (if enabled)

---

## 💡 Pro Tips

### 1. Always Test Backups

```bash
# Create test file
echo "test data" > /mnt/data/test.txt

# Backup
sudo tar czf /tmp/backup.tar.gz -C /mnt/data .

# Verify backup
tar tzf /tmp/backup.tar.gz | grep test.txt

# Test restore
sudo tar xzf /tmp/backup.tar.gz -C /tmp/restore_test/
cat /tmp/restore_test/test.txt
```

---

### 2. LVM Snapshots

```bash
# Create snapshot
sudo lvcreate -L 1G -s -n lv_data_snap /dev/vg_data/lv_data

# Mount snapshot
sudo mkdir /mnt/snapshot
sudo mount /dev/vg_data/lv_data_snap /mnt/snapshot

# Browse old data while live volume continues working
ls /mnt/snapshot

# Remove snapshot when done
sudo umount /mnt/snapshot
sudo lvremove /dev/vg_data/lv_data_snap
```

---

### 3. Monitor Disk Performance

```bash
# Real-time I/O
iostat -x 1

# Per-process I/O
sudo iotop

# Disk latency
sudo ioping /mnt/data
```

---

### 4. Disk Space Usage Analysis

```bash
# Find large directories
du -h /mnt/data | sort -rh | head -20

# Find large files
find /mnt/data -type f -size +100M -exec ls -lh {} \;

# Disk usage by file type
find /mnt/data -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

---

### 5. systemd Timer Troubleshooting

```bash
# Timer not running?
# 1. Check if timer is loaded
systemctl list-unit-files | grep disk-monitor

# 2. Check for errors in timer
systemctl status disk-monitor.timer

# 3. Check service can run manually
sudo systemctl start disk-monitor.service
sudo journalctl -u disk-monitor.service -n 20

# 4. Check OnCalendar syntax is valid
systemd-analyze calendar "*:0/30"

# 5. Reload if you edited timer
sudo systemctl daemon-reload
sudo systemctl restart disk-monitor.timer

# 6. View all active timers
systemctl list-timers --all
```

---

## 📚 Useful Commands Reference

### Disk Information
```bash
lsblk                    # Tree of block devices
fdisk -l                 # All disks and partitions
parted -l                # GPT partition info
blkid                    # UUIDs and labels
df -h                    # Mounted filesystems
du -sh /path             # Directory size
smartctl -a /dev/sda     # SMART data
iostat -x                # I/O statistics
```

### LVM
```bash
# Physical Volumes
pvcreate /dev/sda1
pvdisplay
pvs

# Volume Groups
vgcreate vg_name /dev/sda1
vgextend vg_name /dev/sdb1
vgdisplay
vgs

# Logical Volumes
lvcreate -L 10G -n lv_name vg_name
lvresize -L +5G /dev/vg_name/lv_name
lvdisplay
lvs

# Snapshots
lvcreate -L 2G -s -n lv_snap /dev/vg_name/lv_name
```

### RAID
```bash
# Create
mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sda1 /dev/sdb1

# Status
cat /proc/mdstat
mdadm --detail /dev/md0

# Manage
mdadm --fail /dev/md0 /dev/sda1     # Mark failed
mdadm --remove /dev/md0 /dev/sda1   # Remove
mdadm --add /dev/md0 /dev/sdc1      # Add new/spare

# Config
mdadm --detail --scan >> /etc/mdadm/mdadm.conf
```

### Filesystems
```bash
# Create
mkfs.ext4 /dev/vg_data/lv_data
mkfs.xfs /dev/vg_data/lv_logs

# Check
fsck /dev/sda1

# Resize
resize2fs /dev/vg_data/lv_data    # ext4
xfs_growfs /mnt/logs              # xfs

# Info
tune2fs -l /dev/sda1              # ext4
xfs_info /mnt/logs                # xfs
```

### Mount
```bash
# Mount
mount /dev/vg_data/lv_data /mnt/data
mount -o ro /dev/sdb1 /mnt/old    # Read-only

# Unmount
umount /mnt/data

# Remount
mount -o remount,rw /mnt/data

# Show mounts
mount | column -t
```

---

## 🛡️ Safety Best Practices

1. **Always backup before disk operations**
   ```bash
   sudo rsync -av /source /backup
   ```

2. **Use read-only mounts for old data**
   ```bash
   sudo mount -o ro /dev/old_disk /mnt/old
   ```

3. **Verify checksums after migration**
   ```bash
   md5sum file1 file2 file3
   ```

4. **Test in VM first** before production

5. **Monitor SMART regularly**
   ```bash
   sudo smartctl -H /dev/sda
   ```

6. **Keep spare drives** for RAID arrays

7. **Test restore procedures** (don't just backup!)

8. **Document your LVM/RAID setup** for future reference

---

## ✅ Episode 11 Success Criteria

You've successfully completed Episode 11 if:

- [x] Can check disk health with SMART
- [x] Can create GPT partitions
- [x] Can set up complete LVM stack (PV → VG → LV)
- [x] Can migrate data safely with verification
- [x] Can configure RAID1 for redundancy
- [x] Can optimize filesystem mount options
- [x] Generated comprehensive audit report
- [x] Understand when to use LVM vs RAID

---

**Kristjan Tamm:**
*"e-Estonia works because we never lose data. LVM gives flexibility. RAID gives redundancy. Backups give peace of mind."*

**Liisa Kask:**
*"I test restore every month. Untested backup = no backup."*

**LILITH:**
*"Диски умирают. Это факт. Вопрос не 'если', а 'когда'. Будь готов."*

---

**Next:** Episode 12 - Logs & Monitoring (still in Tallinn 🇪🇪)


