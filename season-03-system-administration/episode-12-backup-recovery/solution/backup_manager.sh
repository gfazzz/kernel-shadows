#!/bin/bash
################################################################################
# EPISODE 12: BACKUP & RECOVERY - COMPLETE SOLUTION
# Season 3: System Administration | Tallinn, Estonia 🇪🇪
# Liisa Kask (backup engineer, ex-Skype)
################################################################################

set -euo pipefail

# Configuration
BACKUP_BASE_DIR="/backup"
FULL_BACKUP_DIR="${BACKUP_BASE_DIR}/full"
INCREMENTAL_BACKUP_DIR="${BACKUP_BASE_DIR}/incremental"
OFFSITE_BACKUP_DIR="${BACKUP_BASE_DIR}/offsite"
SOURCE_DATA_DIR="/home/student/data"
REMOTE_BACKUP_USER="backup"
REMOTE_BACKUP_HOST="remote-server"
REMOTE_BACKUP_PATH="/backup/student"
FULL_BACKUP_RETENTION=30
INCREMENTAL_BACKUP_RETENTION=7
LOG_FILE="/var/log/backup.log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_message() {
    local message="$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" | tee -a "$LOG_FILE"
}

backup_full() {
    echo -e "${GREEN}=== TASK 1: Full Backup ===${NC}"
    log_message "Starting full backup..."

    mkdir -p "$FULL_BACKUP_DIR"
    local backup_file="${FULL_BACKUP_DIR}/backup-full-$(date +%Y%m%d-%H%M%S).tar.gz"

    if [[ ! -d "$SOURCE_DATA_DIR" ]]; then
        echo -e "${RED}ERROR: Source directory not found: $SOURCE_DATA_DIR${NC}"
        log_message "ERROR: Source directory not found"
        return 1
    fi

    echo "Creating backup: $backup_file"
    if tar -czf "$backup_file" "$SOURCE_DATA_DIR" 2>&1 | tee -a "$LOG_FILE"; then
        echo "Calculating checksum..."
        sha256sum "$backup_file" > "${backup_file}.sha256"
        local size=$(du -h "$backup_file" | cut -f1)
        echo -e "${GREEN}✓ Full backup created: $size${NC}"
        log_message "Full backup completed: $backup_file ($size)"
        return 0
    else
        echo -e "${RED}✗ Full backup failed${NC}"
        log_message "ERROR: Full backup failed"
        return 1
    fi
}

backup_incremental() {
    echo -e "${GREEN}=== TASK 2: Incremental Backup ===${NC}"
    log_message "Starting incremental backup..."

    mkdir -p "$INCREMENTAL_BACKUP_DIR"
    local previous_backup=$(ls -td "${INCREMENTAL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)
    local new_backup="${INCREMENTAL_BACKUP_DIR}/incremental-$(date +%Y%m%d-%H%M%S)"

    if [[ ! -d "$SOURCE_DATA_DIR" ]]; then
        echo -e "${RED}ERROR: Source directory not found${NC}"
        return 1
    fi

    echo "Creating incremental backup: $new_backup"

    if [[ -n "$previous_backup" ]]; then
        echo "Using previous backup for hard links: $previous_backup"
        rsync -av --link-dest="$previous_backup" "$SOURCE_DATA_DIR/" "$new_backup/" 2>&1 | tee -a "$LOG_FILE"
    else
        echo "No previous backup found, creating full copy"
        rsync -av "$SOURCE_DATA_DIR/" "$new_backup/" 2>&1 | tee -a "$LOG_FILE"
    fi

    local size=$(du -sh "$new_backup" | cut -f1)
    echo -e "${GREEN}✓ Incremental backup created: $size${NC}"
    log_message "Incremental backup completed: $new_backup ($size)"
}

backup_offsite() {
    echo -e "${GREEN}=== TASK 3: Offsite Backup ===${NC}"
    log_message "Starting offsite backup..."

    local ssh_key="$HOME/.ssh/backup_key"

    if [[ ! -f "$ssh_key" ]]; then
        echo -e "${YELLOW}WARNING: SSH key not found: $ssh_key${NC}"
        echo "Generating new SSH key..."
        ssh-keygen -t ed25519 -f "$ssh_key" -N "" -C "backup@$(hostname)"
        echo "Copy this key to remote server:"
        echo "ssh-copy-id -i ${ssh_key}.pub ${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST}"
        return 1
    fi

    echo "Syncing to ${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST}:${REMOTE_BACKUP_PATH}"

    if rsync -av -e "ssh -i $ssh_key -o StrictHostKeyChecking=no" \
        "${FULL_BACKUP_DIR}/" \
        "${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST}:${REMOTE_BACKUP_PATH}/" \
        2>&1 | tee -a "$LOG_FILE"; then
        echo -e "${GREEN}✓ Offsite backup completed${NC}"
        log_message "Offsite backup completed"
    else
        echo -e "${RED}✗ Offsite backup failed${NC}"
        log_message "ERROR: Offsite backup failed"
        return 1
    fi
}

restore_from_backup() {
    local backup_file="$1"
    local restore_dir="${2:-/tmp/restore-$(date +%s)}"

    echo -e "${GREEN}=== TASK 4: Restore from Backup ===${NC}"
    echo "Backup file: $backup_file"
    echo "Restore to: $restore_dir"

    if [[ ! -f "$backup_file" ]]; then
        echo -e "${RED}ERROR: Backup file not found: $backup_file${NC}"
        return 1
    fi

    if [[ -f "${backup_file}.sha256" ]]; then
        echo "Verifying checksum..."
        cd "$(dirname "$backup_file")"
        if sha256sum -c "$(basename "${backup_file}.sha256")" 2>&1 | grep -q "OK"; then
            echo -e "${GREEN}✓ Checksum verified${NC}"
        else
            echo -e "${RED}✗ Checksum verification failed!${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}WARNING: No checksum file found${NC}"
    fi

    echo "Extracting backup..."
    mkdir -p "$restore_dir"

    if tar -xzf "$backup_file" -C "$restore_dir"; then
        echo -e "${GREEN}✓ Restore completed to: $restore_dir${NC}"
        log_message "Restore completed: $backup_file → $restore_dir"
        ls -lh "$restore_dir"
    else
        echo -e "${RED}✗ Restore failed${NC}"
        return 1
    fi
}

check_backup_health() {
    echo -e "${GREEN}=== TASK 5: Backup Health Check ===${NC}"

    local max_age_hours=48
    local latest_backup

    latest_backup=$(find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2)

    if [[ -z "$latest_backup" ]]; then
        echo -e "${RED}CRITICAL: No backup found!${NC}"
        log_message "CRITICAL: No backup found"
        return 2
    fi

    local age_seconds=$(( $(date +%s) - $(stat -c %Y "$latest_backup") ))
    local age_hours=$(( age_seconds / 3600 ))
    local size=$(du -h "$latest_backup" | cut -f1)

    echo "Latest backup: $latest_backup"
    echo "Age: $age_hours hours"
    echo "Size: $size"

    if (( age_hours > max_age_hours )); then
        echo -e "${YELLOW}WARNING: Backup is $age_hours hours old (max: $max_age_hours)${NC}"
        log_message "WARNING: Backup age exceeds threshold: $age_hours hours"
        return 1
    fi

    echo -e "${GREEN}OK: Backup age is acceptable ($age_hours hours)${NC}"
    log_message "Backup health check: OK"
    return 0
}

cleanup_old_backups() {
    echo -e "${GREEN}=== TASK 6: Cleanup Old Backups ===${NC}"

    echo "Cleaning full backups older than $FULL_BACKUP_RETENTION days..."
    local full_count=$(find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$FULL_BACKUP_RETENTION | wc -l)

    if (( full_count > 0 )); then
        find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$FULL_BACKUP_RETENTION -delete -print | tee -a "$LOG_FILE"
        find "$FULL_BACKUP_DIR" -name "*.sha256" -type f -mtime +$FULL_BACKUP_RETENTION -delete
        echo -e "${GREEN}✓ Deleted $full_count old full backups${NC}"
    else
        echo "No old full backups to delete"
    fi

    echo "Cleaning incremental backups older than $INCREMENTAL_BACKUP_RETENTION days..."
    local inc_count=$(find "$INCREMENTAL_BACKUP_DIR" -type d -mindepth 1 -mtime +$INCREMENTAL_BACKUP_RETENTION | wc -l)

    if (( inc_count > 0 )); then
        find "$INCREMENTAL_BACKUP_DIR" -type d -mindepth 1 -mtime +$INCREMENTAL_BACKUP_RETENTION -exec rm -rf {} + 2>&1 | tee -a "$LOG_FILE"
        echo -e "${GREEN}✓ Deleted $inc_count old incremental backups${NC}"
    else
        echo "No old incremental backups to delete"
    fi

    log_message "Cleanup completed: $full_count full, $inc_count incremental backups removed"
}

disaster_recovery_test() {
    echo -e "${GREEN}=== TASK 7: Disaster Recovery Test ===${NC}"

    local test_dir="/tmp/disaster-test-$$"
    local test_data_dir="${test_dir}/data"
    local test_backup_file="${test_dir}/backup.tar.gz"

    echo "1. Creating test data..."
    mkdir -p "$test_data_dir"
    for i in {1..100}; do
        echo "Test file $i - $(date) - Random: $RANDOM" > "${test_data_dir}/file${i}.txt"
    done

    echo "2. Generating checksums..."
    cd "$test_data_dir"
    sha256sum * > checksums.txt
    echo -e "${GREEN}✓ Created 100 test files${NC}"

    echo "3. Creating backup..."
    tar -czf "$test_backup_file" -C "$test_dir" data
    local backup_size=$(du -h "$test_backup_file" | cut -f1)
    echo -e "${GREEN}✓ Backup created: $backup_size${NC}"

    echo "4. DISASTER SIMULATION! Deleting data..."
    rm -rf "$test_data_dir"
    echo -e "${RED}✗ Data destroyed!${NC}"

    sleep 1

    echo "5. Restoring from backup..."
    tar -xzf "$test_backup_file" -C "$test_dir"
    echo -e "${GREEN}✓ Data restored${NC}"

    echo "6. Verifying data integrity (checksums)..."
    cd "$test_data_dir"
    if sha256sum -c checksums.txt > /dev/null 2>&1; then
        echo -e "${GREEN}✓ All checksums verified! Data integrity confirmed!${NC}"
        local verified_count=$(wc -l < checksums.txt)
        echo "Verified: $verified_count files"
    else
        echo -e "${RED}✗ Checksum verification failed!${NC}"
        rm -rf "$test_dir"
        return 1
    fi

    echo "7. Cleanup test environment..."
    rm -rf "$test_dir"

    echo
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  DISASTER RECOVERY TEST: SUCCESSFUL ✓${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════${NC}"
    log_message "Disaster recovery test: PASSED"
}

generate_backup_report() {
    local report_file="${1:-/tmp/backup-report-$(date +%Y%m%d-%H%M%S).txt}"

    echo -e "${GREEN}=== TASK 8: Generate Backup Report ===${NC}"
    echo "Report file: $report_file"

    {
        echo "========================================================================="
        echo "                    BACKUP STATUS REPORT"
        echo "========================================================================="
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')"
        echo "Host: $(hostname)"
        echo "User: $(whoami)"
        echo "========================================================================="
        echo

        echo "--- FULL BACKUPS ---"
        if ls "$FULL_BACKUP_DIR"/*.tar.gz >/dev/null 2>&1; then
            find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f -printf '%TY-%Tm-%Td %TH:%TM  %12s bytes  %f\n' | sort -r | head -10
            local full_count=$(find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f | wc -l)
            echo "Total full backups: $full_count"
        else
            echo "No full backups found"
        fi
        echo

        echo "--- INCREMENTAL BACKUPS (last 7 days) ---"
        if ls -d "$INCREMENTAL_BACKUP_DIR"/*/ >/dev/null 2>&1; then
            find "$INCREMENTAL_BACKUP_DIR" -type d -mindepth 1 -mtime -7 -printf '%TY-%Tm-%Td %TH:%TM  %p\n' | sort -r
            local inc_count=$(find "$INCREMENTAL_BACKUP_DIR" -type d -mindepth 1 | wc -l)
            echo "Total incremental backups: $inc_count"
        else
            echo "No incremental backups found"
        fi
        echo

        echo "--- STORAGE USAGE ---"
        df -h "$BACKUP_BASE_DIR" 2>/dev/null || df -h /
        echo
        du -sh "$FULL_BACKUP_DIR" "$INCREMENTAL_BACKUP_DIR" 2>/dev/null || echo "N/A"
        echo

        echo "--- BACKUP HEALTH CHECK ---"
        check_backup_health 2>&1 || true
        echo

        echo "--- SYSTEM INFO ---"
        echo "Uptime: $(uptime)"
        echo "Load average: $(uptime | awk -F'load average:' '{ print $2 }')"
        echo

        echo "========================================================================="
        echo "                     END OF REPORT"
        echo "========================================================================="

    } > "$report_file"

    cat "$report_file"
    echo
    echo -e "${GREEN}✓ Report saved to: $report_file${NC}"
    log_message "Backup report generated: $report_file"
}

main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║        EPISODE 12: BACKUP & RECOVERY (SOLUTION)               ║"
    echo "║        Tallinn, Estonia 🇪🇪 | Liisa Kask                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    echo -e "${YELLOW}Liisa: 'Untested backup = no backup. Let's do this right.'${NC}"
    echo
    echo "Available operations:"
    echo "  1) Full backup"
    echo "  2) Incremental backup"
    echo "  3) Offsite backup (remote)"
    echo "  4) Restore from backup"
    echo "  5) Health check"
    echo "  6) Cleanup old backups"
    echo "  7) Disaster recovery test"
    echo "  8) Generate report"
    echo "  9) Run all tasks"
    echo "  0) Exit"
    echo
    read -rp "Choose operation [0-9]: " choice

    case "$choice" in
        1) backup_full ;;
        2) backup_incremental ;;
        3) backup_offsite ;;
        4)
            read -rp "Backup file path: " backup_file
            read -rp "Restore to (default=/tmp/restore): " restore_dir
            restore_from_backup "$backup_file" "${restore_dir:-/tmp/restore}"
            ;;
        5) check_backup_health ;;
        6) cleanup_old_backups ;;
        7) disaster_recovery_test ;;
        8)
            read -rp "Report file (default=/tmp/backup-report.txt): " report_file
            generate_backup_report "${report_file:-/tmp/backup-report.txt}"
            ;;
        9)
            echo "Running all tasks sequentially..."
            backup_full && backup_incremental && check_backup_health && cleanup_old_backups && disaster_recovery_test && generate_backup_report
            echo
            echo -e "${GREEN}✓✓✓ All tasks completed! ✓✓✓${NC}"
            ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
}

mkdir -p "$FULL_BACKUP_DIR" "$INCREMENTAL_BACKUP_DIR" "$OFFSITE_BACKUP_DIR"
touch "$LOG_FILE"

if [[ $# -eq 0 ]]; then
    main
else
    "$@"
fi

