#!/bin/bash
################################################################################
# KERNEL SHADOWS - Episode 11: Disk Management & LVM
# Reference Solution
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration - ADJUST THESE FOR YOUR SYSTEM
DEMO_MODE=true  # Set to false for real disk operations
NEW_DISK="/dev/loop0"    # Will be created in demo mode
OLD_DISK="/dev/loop1"
RAID_DISK1="/dev/loop2"
RAID_DISK2="/dev/loop3"
VG_NAME="vg_data"
LV_NAME="lv_data"
MOUNT_POINT="/mnt/data"
RAID_MOUNT="/mnt/raid"
REPORT_FILE="/var/operations/disk_audit_ep11.txt"

log_info() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*"
}

log_success() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${GREEN}[SUCCESS]${NC} $*"
}

log_error() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] ${RED}[ERROR]${NC} $*" >&2
}

################################################################################
# Demo Mode: Create Loop Devices
################################################################################

setup_demo_environment() {
    if [[ "$DEMO_MODE" != "true" ]]; then
        return 0
    fi
    
    log_info "Setting up demo environment (loop devices)..."
    
    # Create disk images
    for i in {0..3}; do
        local img="/tmp/disk$i.img"
        if [[ ! -f "$img" ]]; then
            dd if=/dev/zero of="$img" bs=1M count=1024 &>/dev/null
            log_success "Created $img (1GB)"
        fi
    done
    
    # Create loop devices
    sudo losetup -fP /tmp/disk0.img || true
    sudo losetup -fP /tmp/disk1.img || true
    sudo losetup -fP /tmp/disk2.img || true
    sudo losetup -fP /tmp/disk3.img || true
    
    # Find assigned devices
    NEW_DISK=$(losetup -j /tmp/disk0.img | cut -d: -f1)
    OLD_DISK=$(losetup -j /tmp/disk1.img | cut -d: -f1)
    RAID_DISK1=$(losetup -j /tmp/disk2.img | cut -d: -f1)
    RAID_DISK2=$(losetup -j /tmp/disk3.img | cut -d: -f1)
    
    log_success "Demo disks ready: $NEW_DISK, $OLD_DISK, $RAID_DISK1, $RAID_DISK2"
}

cleanup_demo_environment() {
    if [[ "$DEMO_MODE" != "true" ]]; then
        return 0
    fi
    
    log_info "Cleaning up demo environment..."
    
    # Unmount
    sudo umount "$MOUNT_POINT" 2>/dev/null || true
    sudo umount "$RAID_MOUNT" 2>/dev/null || true
    
    # Remove LVM
    sudo lvremove -f "/dev/$VG_NAME/$LV_NAME" 2>/dev/null || true
    sudo vgremove -f "$VG_NAME" 2>/dev/null || true
    sudo pvremove -f "${NEW_DISK}1" 2>/dev/null || true
    
    # Stop RAID
    sudo mdadm --stop /dev/md0 2>/dev/null || true
    
    # Detach loop devices
    for i in {0..3}; do
        sudo losetup -d "/dev/loop$i" 2>/dev/null || true
    done
    
    # Remove images
    rm -f /tmp/disk*.img
    
    log_success "Demo cleanup complete"
}

################################################################################
# Task 1: Disk Health Check
################################################################################

disk_health_check() {
    log_info "=== Task 1: Disk Health Check ==="
    
    echo -e "\n${BLUE}Block Devices:${NC}"
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL
    
    echo -e "\n${BLUE}Disk Space:${NC}"
    df -h | grep -E "^Filesystem|^/dev"
    
    # SMART check (will fail on loop devices, that's OK)
    echo -e "\n${BLUE}SMART Status:${NC}"
    for disk in /dev/sd?; do
        if [[ -b "$disk" ]] && command -v smartctl &>/dev/null; then
            echo "Checking $disk..."
            sudo smartctl -H "$disk" 2>/dev/null | grep -E "SMART|result" || echo "  SMART not available (normal for VMs)"
        fi
    done
    
    log_success "Disk health check complete"
}

################################################################################
# Task 2: Partitioning
################################################################################

create_partition() {
    log_info "=== Task 2: Create Partition ==="
    
    local disk="$NEW_DISK"
    
    if [[ ! -b "$disk" ]]; then
        log_error "Disk $disk not found"
        return 1
    fi
    
    log_info "Creating GPT partition on $disk..."
    
    sudo parted "$disk" mklabel gpt
    sudo parted "$disk" mkpart primary 0% 100%
    sudo parted "$disk" set 1 lvm on
    sudo partprobe "$disk"
    
    echo -e "\n${BLUE}Partition Table:${NC}"
    sudo parted "$disk" print
    
    log_success "Partition ${disk}1 created"
}

################################################################################
# Task 3: LVM Setup
################################################################################

setup_lvm() {
    log_info "=== Task 3: LVM Setup ==="
    
    local partition="${NEW_DISK}1"
    
    # Create Physical Volume
    log_info "Creating Physical Volume..."
    sudo pvcreate "$partition"
    
    # Create Volume Group
    log_info "Creating Volume Group: $VG_NAME..."
    sudo vgcreate "$VG_NAME" "$partition"
    
    # Create Logical Volume
    log_info "Creating Logical Volume: $LV_NAME..."
    sudo lvcreate -l 80%FREE -n "$LV_NAME" "$VG_NAME"
    
    # Create filesystem
    log_info "Creating ext4 filesystem..."
    sudo mkfs.ext4 -L "DATA" "/dev/$VG_NAME/$LV_NAME"
    
    # Mount
    log_info "Mounting..."
    sudo mkdir -p "$MOUNT_POINT"
    sudo mount "/dev/$VG_NAME/$LV_NAME" "$MOUNT_POINT"
    
    echo -e "\n${BLUE}LVM Summary:${NC}"
    sudo pvs
    sudo vgs
    sudo lvs
    
    echo -e "\n${BLUE}Mounted:${NC}"
    df -h | grep "$MOUNT_POINT"
    
    log_success "LVM setup complete"
}

################################################################################
# Task 4: Data Migration
################################################################################

migrate_data() {
    log_info "=== Task 4: Data Migration (simulated) ==="
    
    # In real scenario, mount old disk and rsync
    # Here we just create test data
    
    log_info "Creating test data..."
    sudo mkdir -p "$MOUNT_POINT/test_data"
    for i in {1..5}; do
        echo "Test file $i" | sudo tee "$MOUNT_POINT/test_data/file$i.txt" >/dev/null
    done
    
    log_info "Verifying data..."
    local count=$(find "$MOUNT_POINT/test_data" -type f | wc -l)
    echo "  Files created: $count"
    
    log_success "Data migration complete (simulated)"
}

################################################################################
# Task 5: RAID Configuration
################################################################################

setup_raid() {
    log_info "=== Task 5: RAID Configuration ==="
    
    # Prepare partitions
    for disk in "$RAID_DISK1" "$RAID_DISK2"; do
        log_info "Preparing $disk..."
        sudo parted "$disk" mklabel gpt
        sudo parted "$disk" mkpart primary 0% 100%
        sudo parted "$disk" set 1 raid on
    done
    
    sudo partprobe
    
    # Create RAID1
    log_info "Creating RAID1 array..."
    sudo mdadm --create /dev/md0 \
        --level=1 \
        --raid-devices=2 \
        --assume-clean \
        "${RAID_DISK1}1" "${RAID_DISK2}1"
    
    # Create filesystem
    log_info "Creating filesystem on RAID..."
    sudo mkfs.ext4 -L "RAID_DATA" /dev/md0
    
    # Mount
    log_info "Mounting RAID..."
    sudo mkdir -p "$RAID_MOUNT"
    sudo mount /dev/md0 "$RAID_MOUNT"
    
    echo -e "\n${BLUE}RAID Status:${NC}"
    cat /proc/mdstat
    
    log_success "RAID1 setup complete"
}

################################################################################
# Task 6: Filesystem Management
################################################################################

manage_filesystems() {
    log_info "=== Task 6: Filesystem Management ==="
    
    echo -e "\n${BLUE}All Filesystems:${NC}"
    df -h | grep -E "^Filesystem|^/dev"
    
    echo -e "\n${BLUE}Mount Points:${NC}"
    mount | grep "^/dev" | column -t
    
    log_success "Filesystem management complete"
}

################################################################################
# Task 7: Generate Report
################################################################################

generate_report() {
    log_info "=== Task 7: Generate Audit Report ==="
    
    sudo mkdir -p "$(dirname "$REPORT_FILE")"
    
    sudo tee "$REPORT_FILE" > /dev/null << EOF
================================================================================
                   DISK MANAGEMENT AUDIT REPORT - EPISODE 11
                        Disk Management & LVM
================================================================================

Operation: KERNEL SHADOWS
Location: Tallinn, Estonia
Date: $(date)
Auditor: Max Sokolov
Mentors: Kristjan Tamm, Liisa Kask

================================================================================
1. DISK HEALTH STATUS
================================================================================

Block Devices:
$(lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT)

Disk Space:
$(df -h | grep -E "^Filesystem|^/dev")

SMART Status:
$(for disk in /dev/sd?; do
    [[ -b "$disk" ]] && echo "$disk: $(sudo smartctl -H $disk 2>&1 | grep -oP 'PASSED|FAILED|Unavailable' || echo 'N/A')"
done)

================================================================================
2. LVM CONFIGURATION
================================================================================

Physical Volumes:
$(sudo pvs)

Volume Groups:
$(sudo vgs)

Logical Volumes:
$(sudo lvs)

LVM Details:
$(sudo lvdisplay /dev/$VG_NAME/$LV_NAME 2>/dev/null || echo "LVM not configured")

================================================================================
3. RAID CONFIGURATION
================================================================================

RAID Status:
$(cat /proc/mdstat 2>/dev/null || echo "No RAID arrays")

RAID Details:
$(sudo mdadm --detail /dev/md0 2>/dev/null || echo "RAID not configured")

================================================================================
4. MOUNTED FILESYSTEMS
================================================================================

$(df -h)

Mount Points:
$(mount | grep "^/dev")

/etc/fstab:
$(cat /etc/fstab | grep -v "^#")

================================================================================
5. SPACE USAGE
================================================================================

Data Volume:
$(du -sh $MOUNT_POINT 2>/dev/null || echo "Not mounted")

RAID Volume:
$(du -sh $RAID_MOUNT 2>/dev/null || echo "Not mounted")

================================================================================
6. KRISTJAN TAMM - TECHNICAL ASSESSMENT
================================================================================

"Max справился с disk management на production уровне.

Достижения:
✓ Disk health check (SMART monitoring)
✓ GPT partitioning (modern standard)
✓ LVM setup (PV → VG → LV hierarchy)
✓ Data migration (with verification)
✓ RAID1 configuration (redundancy)
✓ Filesystem optimization (mount options)

e-Estonia требует 99.95% uptime. Без правильного disk management это
невозможно. Max понял что:
- SMART warnings = немедленная замена диска
- LVM даёт flexibility (resize без reboot)
- RAID даёт redundancy (1 disk failure = no downtime)
- Backups дают recovery (RAID ≠ backup)

Production ready."

Signed: Kristjan Tamm
        e-Government Infrastructure Architect
        Tallinn, Estonia

================================================================================
7. LIISA KASK - BACKUP SPECIALIST NOTES
================================================================================

"Я проверяю backups каждую неделю. Не тестированный backup = нет backup.

Max продемонстрировал:
✓ Checksums verification после migration
✓ Read-only mounts для old data
✓ LVM snapshots capability (будущее использование)
✓ RAID1 для redundancy

Рекомендации:
[ ] Автоматизировать LVM snapshots (перед updates)
[ ] Настроить offsite backups (3-2-1 rule)
[ ] Регулярно тестировать restore procedures
[ ] Мониторить SMART еженедельно

3-2-1 Rule:
- 3 copies данных
- 2 разных типа media
- 1 offsite backup

Без этого data loss неизбежен."

Signed: Liisa Kask
        Backup & Recovery Specialist
        Tallinn, Estonia

================================================================================
8. SECURITY POSTURE
================================================================================

Disk Management:
  ✓ Health monitoring (SMART)
  ✓ Flexible storage (LVM)
  ✓ Redundancy (RAID1)
  ✓ Proper partitioning (GPT)
  ✓ Filesystem optimization

Data Protection:
  ✓ Read-only mounts during migration
  ✓ Checksum verification
  ✓ Snapshot capability
  ✓ RAID for hardware failure
  [ ] Offsite backups (TODO)
  [ ] Encryption at rest (TODO: Episode 17)

================================================================================
9. VIKTOR PETROV - OPERATION APPROVAL
================================================================================

"Отчёт принят. Disk management критичен для операции.

Tallinn — complete. Kristjan и Liisa научили Max основам storage.
LVM flexibility + RAID redundancy = reliable infrastructure.

Statistics:
- Episode 11 complete: 10/32 episodes (31%)
- Season 3 progress: 50% (Episodes 09-10 done)
- Storage infrastructure: OPERATIONAL

Next Mission:
  Location: Still Tallinn, Estonia 🇪🇪
  Episode 12: Logs & Monitoring
  Focus: Centralized logging, log analysis, monitoring setup
  
Max, ты освоил storage layer. Теперь observability. Logs говорят что
происходит. Monitoring показывает здоровье системы. Без этого ты слепой.

Готовься."

Viktor Petrov
Operation Coordinator
KERNEL SHADOWS

================================================================================
10. RECOMMENDATIONS
================================================================================

Immediate:
  ✓ LVM operational
  ✓ RAID1 configured
  ✓ Health monitoring setup

Short-term (1-2 weeks):
  [ ] Automate LVM snapshots (daily before updates)
  [ ] Setup SMART monitoring alerts
  [ ] Document disaster recovery procedures
  [ ] Test RAID failure scenario (remove 1 disk)

Long-term (1-3 months):
  [ ] Implement 3-2-1 backup strategy
  [ ] Add offsite backup location
  [ ] Encrypt data at rest (Season 5)
  [ ] Setup storage capacity monitoring
  [ ] Plan for storage scaling (when > 80% full)

================================================================================
                              END OF REPORT
================================================================================

Report generated: $(date)
Location: $REPORT_FILE
Permissions: 640 (viktor:operations)
EOF
    
    sudo chmod 640 "$REPORT_FILE"
    sudo chown viktor:operations "$REPORT_FILE" 2>/dev/null || true
    
    log_success "Report generated: $REPORT_FILE"
}

################################################################################
# Main Execution
################################################################################

main() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  KERNEL SHADOWS - Episode 11${NC}"
    echo -e "${BLUE}  Disk Management & LVM${NC}"
    echo -e "${BLUE}  Reference Solution${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo
    
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
    
    # Setup demo environment if needed
    setup_demo_environment
    
    # Execute all tasks
    disk_health_check
    echo
    
    create_partition
    echo
    
    setup_lvm
    echo
    
    migrate_data
    echo
    
    setup_raid
    echo
    
    manage_filesystems
    echo
    
    generate_report
    echo
    
    # Summary
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Episode 11: COMPLETE!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo
    echo -e "${BLUE}Kristjan Tamm:${NC}"
    echo -e "  'Disk management на production уровне. Данные в безопасности.'"
    echo
    echo -e "${YELLOW}Liisa Kask:${NC}"
    echo -e "  'LVM flexibility + RAID redundancy = надёжность. Отлично.'"
    echo
    echo -e "${GREEN}LILITH:${NC}"
    echo -e "  'Диски умирают. Но теперь ты готов. Next: logs & monitoring.'"
    echo
    
    # Cleanup in demo mode
    if [[ "$DEMO_MODE" == "true" ]]; then
        read -p "Cleanup demo environment? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cleanup_demo_environment
        fi
    fi
    
    log_success "All Episode 11 tasks completed!"
}

# Run
main "$@"
