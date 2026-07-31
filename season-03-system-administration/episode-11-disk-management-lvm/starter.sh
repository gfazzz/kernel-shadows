#!/bin/bash
################################################################################
# KERNEL SHADOWS - Episode 11: Disk Management & LVM
# Season 3: System Administration
# Starter Script Template
################################################################################
#
# Mission: Production-Ready Disk Management with LVM & Monitoring
# Location: Tallinn, Estonia 🇪🇪
# Mentors: Kristjan Tamm (e-Gov architect), Liisa Kask (backup specialist)
#
# Your tasks:
#   1. Disk health check (SMART monitoring)
#   2. Partitioning (GPT)
#   3. LVM setup (PV, VG, LV)
#   4. Filesystems & /etc/fstab configuration
#   5. Data migration (optional - from failing disk)
#   6. Production monitoring (systemd service + timer)
#   7. Generate audit report
#
# Hints:
#   - Use lsblk, fdisk, parted for disk inspection
#   - LVM: pvcreate, vgcreate, lvcreate
#   - Always use UUID in /etc/fstab (not device paths!)
#   - SMART: smartctl for disk health
#   - systemd timers for automated monitoring
#
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NEW_DISK="/dev/sdc"
VG_NAME="vg_data"
LV_DATABASES="lv_databases"
LV_LOGS="lv_logs"
LV_BACKUPS="lv_backups"
MOUNT_DATABASES="/mnt/databases"
MOUNT_LOGS="/mnt/logs"
MOUNT_BACKUPS="/mnt/backups"
REPORT_FILE="/var/operations/disk_audit_ep11.txt"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  KERNEL SHADOWS - Episode 11${NC}"
echo -e "${BLUE}  Disk Management & LVM${NC}"
echo -e "${BLUE}========================================${NC}"
echo

################################################################################
# Task 1: Disk Health Check (SMART Monitoring)
################################################################################

disk_health_check() {
    echo -e "${YELLOW}=== Task 1: Disk Health Check (SMART) ===${NC}"
    echo

    # TODO: List all block devices
    # Hint: lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL

    # TODO: Check SMART status for all disks
    # Hint: smartctl -H /dev/sdX
    # Hint: smartctl -A /dev/sdX | grep -E "Reallocated|Pending|Uncorrectable"

    # TODO: Check for disk errors in kernel log
    # Hint: dmesg | grep -i "error\|fail" | grep "sd[a-z]"

    # TODO: Check I/O statistics (if iostat installed)
    # Hint: iostat -x 1 3

    echo "TODO: Implement disk health check"
    echo "      Check README.md Cycle 2 for hints"
    echo
}

################################################################################
# Task 2: Partitioning (GPT)
################################################################################

create_partition() {
    echo -e "${YELLOW}=== Task 2: Create GPT Partition ===${NC}"
    echo

    local disk="$NEW_DISK"

    # TODO: Check if disk exists
    # Hint: if [[ ! -b "$disk" ]]; then echo "Disk not found"; return 1; fi

    # TODO: Create GPT partition table
    # Hint: sudo parted $disk mklabel gpt

    # TODO: Create partition (use full disk)
    # Hint: sudo parted $disk mkpart primary 0% 100%

    # TODO: Set LVM partition type
    # Hint: sudo parted $disk set 1 lvm on

    # TODO: Update kernel partition table
    # Hint: sudo partprobe $disk

    # TODO: Verify partition created
    # Hint: sudo parted $disk print

    echo "TODO: Implement GPT partitioning"
    echo "      Check README.md Cycle 1 for hints"
    echo
}

################################################################################
# Task 3: LVM Setup (PV → VG → LV)
################################################################################

setup_lvm() {
    echo -e "${YELLOW}=== Task 3: LVM Setup (PV → VG → LV) ===${NC}"
    echo

    local partition="${NEW_DISK}1"

    # TODO: Step 1 - Create Physical Volume (PV)
    # Hint: sudo pvcreate $partition
    # Hint: sudo pvdisplay $partition

    # TODO: Step 2 - Create Volume Group (VG)
    # Hint: sudo vgcreate $VG_NAME $partition
    # Hint: sudo vgdisplay $VG_NAME

    # TODO: Step 3 - Create Logical Volumes (LV)
    # Hint: Create 3 LVs:
    #   - lv_databases (200GB, xfs)
    #   - lv_logs (100GB, ext4)
    #   - lv_backups (50GB, ext4)
    # Hint: sudo lvcreate -L 200G -n $LV_DATABASES $VG_NAME
    # Hint: sudo lvcreate -L 100G -n $LV_LOGS $VG_NAME
    # Hint: sudo lvcreate -L 50G -n $LV_BACKUPS $VG_NAME

    # TODO: Verify LVM structure
    # Hint: sudo pvs
    # Hint: sudo vgs
    # Hint: sudo lvs

    echo "TODO: Implement LVM setup"
    echo "      Check README.md Cycles 3-4 for hints"
    echo
}

################################################################################
# Task 4: Filesystems & /etc/fstab Configuration
################################################################################

setup_filesystems() {
    echo -e "${YELLOW}=== Task 4: Filesystems & /etc/fstab ===${NC}"
    echo

    # TODO: Step 1 - Create filesystems
    # Hint: XFS for databases (high performance):
    #   sudo mkfs.xfs -L DATABASES /dev/$VG_NAME/$LV_DATABASES
    # Hint: ext4 for logs and backups:
    #   sudo mkfs.ext4 -L LOGS /dev/$VG_NAME/$LV_LOGS
    #   sudo mkfs.ext4 -L BACKUPS /dev/$VG_NAME/$LV_BACKUPS

    # TODO: Step 2 - Create mount points
    # Hint: sudo mkdir -p $MOUNT_DATABASES $MOUNT_LOGS $MOUNT_BACKUPS

    # TODO: Step 3 - Mount filesystems (temporary)
    # Hint: sudo mount /dev/$VG_NAME/$LV_DATABASES $MOUNT_DATABASES
    # Hint: sudo mount /dev/$VG_NAME/$LV_LOGS $MOUNT_LOGS
    # Hint: sudo mount /dev/$VG_NAME/$LV_BACKUPS $MOUNT_BACKUPS

    # TODO: Step 4 - Get UUIDs for /etc/fstab
    # Hint: sudo blkid /dev/$VG_NAME/$LV_DATABASES
    # Hint: sudo blkid /dev/$VG_NAME/$LV_LOGS
    # Hint: sudo blkid /dev/$VG_NAME/$LV_BACKUPS

    # TODO: Step 5 - Add to /etc/fstab (CRITICAL: Backup first!)
    # Hint: sudo cp /etc/fstab /etc/fstab.backup.$(date +%Y%m%d)
    # Hint: Add entries like:
    #   UUID=... /mnt/databases xfs  defaults,noatime,nofail 0 2
    #   UUID=... /mnt/logs      ext4 defaults,noatime,nofail 0 2
    #   UUID=... /mnt/backups   ext4 defaults,noatime,nofail 0 2

    # TODO: Step 6 - Test /etc/fstab (BEFORE REBOOT!)
    # Hint: sudo umount $MOUNT_DATABASES $MOUNT_LOGS $MOUNT_BACKUPS
    # Hint: sudo mount -a
    # Hint: df -h | grep -E "databases|logs|backups"

    echo "TODO: Implement filesystems & fstab configuration"
    echo "      Check README.md Cycle 5 for hints"
    echo "      ⚠️  CRITICAL: Always backup /etc/fstab before editing!"
    echo "      ⚠️  CRITICAL: Test with 'mount -a' before reboot!"
    echo
}

################################################################################
# Task 5: Data Migration (Optional - if migrating from failing disk)
################################################################################

migrate_data() {
    echo -e "${YELLOW}=== Task 5: Data Migration (Optional) ===${NC}"
    echo

    local old_disk="/dev/sdb1"  # Adjust to your failing disk
    local old_mount="/mnt/old_data"

    # TODO: Step 1 - Mount old disk READ-ONLY (safety!)
    # Hint: sudo mkdir -p $old_mount
    # Hint: sudo mount -o ro $old_disk $old_mount

    # TODO: Step 2 - Check available space
    # Hint: du -sh $old_mount
    # Hint: df -h $MOUNT_DATABASES

    # TODO: Step 3 - Copy data with rsync (safe, resumable)
    # Hint: sudo rsync -avh --progress $old_mount/ $MOUNT_DATABASES/
    # Options:
    #   -a: archive mode (preserve permissions, timestamps)
    #   -v: verbose
    #   -h: human-readable sizes
    #   --progress: show progress bar

    # TODO: Step 4 - Verify data integrity
    # Hint: Compare file counts:
    #   find $old_mount -type f | wc -l
    #   find $MOUNT_DATABASES -type f | wc -l
    # Hint: Or use diff:
    #   diff -r $old_mount/ $MOUNT_DATABASES/

    # TODO: Step 5 - Unmount old disk
    # Hint: sudo umount $old_mount

    echo "TODO: Implement data migration (if needed)"
    echo "      Check README.md Cycle 6 for hints"
    echo "      NOTE: Skip this task if no data to migrate"
    echo
}

################################################################################
# Task 6: Production Monitoring (systemd service + timer)
################################################################################

setup_monitoring() {
    echo -e "${YELLOW}=== Task 6: Production Monitoring ===${NC}"
    echo

    # TODO: Step 1 - Copy monitoring script to /usr/local/bin/
    # Hint: sudo cp solution/scripts/disk-monitor.sh /usr/local/bin/
    # Hint: sudo chmod +x /usr/local/bin/disk-monitor.sh

    # TODO: Step 2 - Test script manually
    # Hint: sudo /usr/local/bin/disk-monitor.sh

    # TODO: Step 3 - Copy systemd service and timer
    # Hint: sudo cp solution/configs/disk-monitor.service /etc/systemd/system/
    # Hint: sudo cp solution/configs/disk-monitor.timer /etc/systemd/system/

    # TODO: Step 4 - Reload systemd daemon
    # Hint: sudo systemctl daemon-reload

    # TODO: Step 5 - Enable and start timer
    # Hint: sudo systemctl enable disk-monitor.timer
    # Hint: sudo systemctl start disk-monitor.timer

    # TODO: Step 6 - Verify timer is active
    # Hint: sudo systemctl status disk-monitor.timer
    # Hint: systemctl list-timers disk-monitor.timer

    # TODO: Step 7 - Check logs
    # Hint: sudo journalctl -u disk-monitor.service -n 20

    echo "TODO: Implement production monitoring setup"
    echo "      Check README.md Cycle 8 for hints"
    echo "      Files needed:"
    echo "        - solution/scripts/disk-monitor.sh"
    echo "        - solution/configs/disk-monitor.service"
    echo "        - solution/configs/disk-monitor.timer"
    echo
}

################################################################################
# Task 7: Generate Audit Report
################################################################################

generate_report() {
    echo -e "${YELLOW}=== Task 7: Generate Disk Audit Report ===${NC}"
    echo

    # TODO: Create report directory
    # Hint: sudo mkdir -p $(dirname $REPORT_FILE)

    # TODO: Generate comprehensive report including:
    # 1. System information
    #    Hint: echo "Hostname: $(hostname)" >> $REPORT_FILE
    #    Hint: echo "Date: $(date)" >> $REPORT_FILE

    # 2. Disk health status (all disks)
    #    Hint: lsblk >> $REPORT_FILE
    #    Hint: for disk in /dev/sd?; do smartctl -H $disk; done >> $REPORT_FILE

    # 3. LVM configuration
    #    Hint: pvs >> $REPORT_FILE
    #    Hint: vgs >> $REPORT_FILE
    #    Hint: lvs >> $REPORT_FILE

    # 4. Mounted filesystems
    #    Hint: df -h >> $REPORT_FILE

    # 5. /etc/fstab entries
    #    Hint: grep -v "^#" /etc/fstab | grep -v "^$" >> $REPORT_FILE

    # 6. Disk space usage per mount point
    #    Hint: du -sh /mnt/* >> $REPORT_FILE

    # 7. Monitoring status
    #    Hint: systemctl status disk-monitor.timer >> $REPORT_FILE

    # 8. Recommendations
    #    Hint: Add manual recommendations based on findings

    # TODO: Set correct permissions
    # Hint: sudo chmod 640 $REPORT_FILE
    # Hint: sudo chown root:adm $REPORT_FILE (or appropriate group)

    echo "TODO: Implement report generation"
    echo "      Expected output: $REPORT_FILE"
    echo
}

################################################################################
# Bonus Task: RAID Configuration (Optional - Advanced)
################################################################################

setup_raid_bonus() {
    echo -e "${BLUE}=== BONUS: RAID Configuration (Optional) ===${NC}"
    echo

    # NOTE: RAID is covered in README.md Cycle 7 as theory
    # This is an OPTIONAL bonus task for advanced users

    local raid_disk1="/dev/sdd"
    local raid_disk2="/dev/sde"
    local raid_mount="/mnt/raid"

    # TODO: Check if disks exist
    # Hint: for disk in $raid_disk1 $raid_disk2; do
    #           if [[ ! -b "$disk" ]]; then
    #               echo "Disk $disk not found"
    #               return 1
    #           fi
    #       done

    # TODO: Create RAID1 array (mirroring)
    # Hint: sudo mdadm --create /dev/md0 --level=1 --raid-devices=2 ${raid_disk1} ${raid_disk2}

    # TODO: Check RAID status
    # Hint: cat /proc/mdstat
    # Hint: sudo mdadm --detail /dev/md0

    # TODO: Create filesystem on RAID
    # Hint: sudo mkfs.ext4 /dev/md0

    # TODO: Mount RAID
    # Hint: sudo mkdir -p $raid_mount
    # Hint: sudo mount /dev/md0 $raid_mount

    # TODO: Save RAID configuration
    # Hint: sudo mdadm --detail --scan | sudo tee -a /etc/mdadm/mdadm.conf
    # Hint: sudo update-initramfs -u

    # TODO: Add to /etc/fstab
    # Hint: Get UUID: sudo blkid /dev/md0
    # Hint: Add: UUID=... /mnt/raid ext4 defaults 0 2

    echo "BONUS: RAID configuration (optional)"
    echo "       Check README.md Cycle 7 for theory"
    echo "       Skip if you don't have 2+ extra disks"
    echo
}

################################################################################
# Main execution
################################################################################

main() {
    # Check if running with appropriate privileges
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}Warning: Many operations require root privileges.${NC}"
        echo -e "${YELLOW}Will use sudo where necessary.${NC}"
        echo
    fi

    echo -e "${BLUE}Kristjan Tamm:${NC}"
    echo "'e-Estonia работает на доверии к данным."
    echo " Если диск умирает — доверие умирает.'"
    echo
    echo -e "${BLUE}Liisa Kask:${NC}"
    echo "'Disk management без monitoring — это chaos."
    echo " Automation — это key to reliability.'"
    echo

    # Execute tasks
    disk_health_check
    
    create_partition
    
    setup_lvm
    
    setup_filesystems
    
    # Optional: Only if migrating from failing disk
    # migrate_data
    
    setup_monitoring
    
    generate_report
    
    # Bonus: Advanced users only
    # setup_raid_bonus

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Episode 11 tasks outlined!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Implement each TODO section"
    echo "  2. Test with: sudo ./starter.sh"
    echo "  3. Run tests: cd tests && sudo ./test.sh"
    echo "  4. Compare with solution/ if stuck"
    echo
    echo -e "${BLUE}LILITH:${NC}"
    echo "'Disk management — это foundation Linux SysAdmin."
    echo " LVM для flexibility. Monitoring для reliability."
    echo " /etc/fstab для persistence. Всё вместе — production ready.'"
    echo
    echo -e "${YELLOW}IMPORTANT NOTES:${NC}"
    echo "  ⚠️  ALWAYS backup /etc/fstab before editing"
    echo "  ⚠️  ALWAYS test fstab with 'mount -a' before reboot"
    echo "  ⚠️  Use UUID in fstab (not device paths)"
    echo "  ⚠️  Use 'noatime' mount option for performance"
    echo "  ⚠️  SMART warnings = replace disk immediately"
    echo "  ✅  systemd timers для automated monitoring"
    echo "  ✅  RAID — это redundancy, НЕ backup!"
    echo
}

# Run main function
main "$@"
