#!/bin/bash

################################################################################
# EPISODE 12: BACKUP & RECOVERY
# Season 3: System Administration | Tallinn, Estonia 🇪🇪
#
# Mission: Create production-ready backup & disaster recovery system
# Персонаж: Liisa Kask (backup engineer, ex-Skype)
#
# "Untested backup = no backup. Test restore every month." — Liisa Kask
################################################################################

set -euo pipefail  # Strict mode: exit on error, undefined vars, pipe failures

# ============================================================================
# CONFIGURATION
# ============================================================================

# TODO Task 1: Configure backup paths
BACKUP_BASE_DIR="/backup"
FULL_BACKUP_DIR="${BACKUP_BASE_DIR}/full"
INCREMENTAL_BACKUP_DIR="${BACKUP_BASE_DIR}/incremental"
OFFSITE_BACKUP_DIR="${BACKUP_BASE_DIR}/offsite"

# Source data to backup
SOURCE_DATA_DIR="/home/student/data"

# Remote backup (change to your remote server)
REMOTE_BACKUP_USER="backup"
REMOTE_BACKUP_HOST="remote-server"
REMOTE_BACKUP_PATH="/backup/student"

# Backup retention (days)
FULL_BACKUP_RETENTION=30
INCREMENTAL_BACKUP_RETENTION=7

# Logs
LOG_FILE="/var/log/backup.log"

# ============================================================================
# TASK 1: FULL BACKUP
# ============================================================================
# Create complete backup of source directory
# Requirements:
# - Use tar with gzip compression
# - Include timestamp in filename
# - Calculate checksum (sha256sum)
# - Log to LOG_FILE
# ============================================================================

backup_full() {
    echo "=== TASK 1: Full Backup ==="

    # TODO: Implement full backup
    # 1. Create FULL_BACKUP_DIR if not exists
    # 2. Create filename with date: backup-full-YYYYMMDD-HHMMSS.tar.gz
    # 3. Create tar.gz archive of SOURCE_DATA_DIR
    # 4. Calculate sha256sum and save to .sha256 file
    # 5. Log success/failure to LOG_FILE

    echo "TODO: Implement backup_full()"

    # Example structure:
    # local backup_file="${FULL_BACKUP_DIR}/backup-full-$(date +%Y%m%d-%H%M%S).tar.gz"
    # tar -czf "$backup_file" "$SOURCE_DATA_DIR" 2>&1 | tee -a "$LOG_FILE"
    # sha256sum "$backup_file" > "${backup_file}.sha256"
}

# ============================================================================
# TASK 2: INCREMENTAL BACKUP
# ============================================================================
# Create incremental backup using rsync with hard links
# Requirements:
# - Use rsync with --link-dest to previous backup
# - Only changed files are copied
# - Unchanged files use hard links (save space)
# ============================================================================

backup_incremental() {
    echo "=== TASK 2: Incremental Backup ==="

    # TODO: Implement incremental backup
    # 1. Find previous backup directory (most recent in INCREMENTAL_BACKUP_DIR)
    # 2. Create new backup directory with timestamp
    # 3. Use rsync with --link-dest pointing to previous backup
    # 4. Log to LOG_FILE

    echo "TODO: Implement backup_incremental()"

    # Example structure:
    # local previous_backup=$(ls -td "${INCREMENTAL_BACKUP_DIR}"/*/ 2>/dev/null | head -1)
    # local new_backup="${INCREMENTAL_BACKUP_DIR}/incremental-$(date +%Y%m%d-%H%M%S)"
    #
    # if [[ -n "$previous_backup" ]]; then
    #     rsync -av --link-dest="$previous_backup" "$SOURCE_DATA_DIR/" "$new_backup/"
    # else
    #     rsync -av "$SOURCE_DATA_DIR/" "$new_backup/"
    # fi
}

# ============================================================================
# TASK 3: REMOTE BACKUP (OFFSITE)
# ============================================================================
# Sync backup to remote server via SSH
# Requirements:
# - Use rsync over SSH
# - SSH key authentication (no password)
# - Preserve permissions and timestamps
# ============================================================================

backup_offsite() {
    echo "=== TASK 3: Offsite Backup ==="

    # TODO: Implement offsite backup
    # 1. Check if SSH key exists (~/.ssh/backup_key)
    # 2. Sync latest full backup to remote server
    # 3. Use rsync with -e ssh
    # 4. Log to LOG_FILE

    echo "TODO: Implement backup_offsite()"

    # Example structure:
    # local ssh_key="$HOME/.ssh/backup_key"
    # if [[ ! -f "$ssh_key" ]]; then
    #     echo "ERROR: SSH key not found: $ssh_key"
    #     return 1
    # fi
    #
    # rsync -av -e "ssh -i $ssh_key" \
    #     "${FULL_BACKUP_DIR}/" \
    #     "${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST}:${REMOTE_BACKUP_PATH}/" \
    #     2>&1 | tee -a "$LOG_FILE"
}

# ============================================================================
# TASK 4: RESTORE FROM BACKUP
# ============================================================================
# Restore data from backup archive
# Requirements:
# - Extract tar.gz to specified directory
# - Verify checksum before restore
# - Create restore directory if not exists
# ============================================================================

restore_from_backup() {
    local backup_file="$1"
    local restore_dir="${2:-/tmp/restore-$(date +%s)}"

    echo "=== TASK 4: Restore from Backup ==="
    echo "Backup file: $backup_file"
    echo "Restore to: $restore_dir"

    # TODO: Implement restore
    # 1. Check if backup_file exists
    # 2. Verify checksum (compare with .sha256 file)
    # 3. Create restore_dir if not exists
    # 4. Extract tar.gz to restore_dir
    # 5. Log success/failure

    echo "TODO: Implement restore_from_backup()"

    # Example structure:
    # if [[ ! -f "$backup_file" ]]; then
    #     echo "ERROR: Backup file not found: $backup_file"
    #     return 1
    # fi
    #
    # # Verify checksum
    # if [[ -f "${backup_file}.sha256" ]]; then
    #     cd "$(dirname "$backup_file")"
    #     sha256sum -c "$(basename "${backup_file}.sha256")" || {
    #         echo "ERROR: Checksum verification failed!"
    #         return 1
    #     }
    # fi
    #
    # mkdir -p "$restore_dir"
    # tar -xzf "$backup_file" -C "$restore_dir"
}

# ============================================================================
# TASK 5: BACKUP HEALTH CHECK
# ============================================================================
# Monitor backup health and generate alerts
# Requirements:
# - Check if backup exists
# - Check backup age (warn if > 48 hours)
# - Check backup size (warn if unexpected)
# - Return exit code: 0=OK, 1=WARNING, 2=CRITICAL
# ============================================================================

check_backup_health() {
    echo "=== TASK 5: Backup Health Check ==="

    # TODO: Implement health check
    # 1. Find latest backup file
    # 2. Check age (seconds since creation)
    # 3. Check size (compare with previous backups)
    # 4. Return appropriate exit code

    echo "TODO: Implement check_backup_health()"

    local max_age_hours=48
    local latest_backup

    # Example structure:
    # latest_backup=$(find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2)
    #
    # if [[ -z "$latest_backup" ]]; then
    #     echo "CRITICAL: No backup found!"
    #     return 2
    # fi
    #
    # local age_seconds=$(( $(date +%s) - $(stat -c %Y "$latest_backup") ))
    # local age_hours=$(( age_seconds / 3600 ))
    #
    # if (( age_hours > max_age_hours )); then
    #     echo "WARNING: Backup is $age_hours hours old (max: $max_age_hours)"
    #     return 1
    # fi
    #
    # echo "OK: Latest backup is $age_hours hours old"
    # return 0
}

# ============================================================================
# TASK 6: CLEANUP OLD BACKUPS
# ============================================================================
# Remove old backups based on retention policy
# Requirements:
# - Keep full backups for FULL_BACKUP_RETENTION days
# - Keep incremental backups for INCREMENTAL_BACKUP_RETENTION days
# - Log deleted backups
# ============================================================================

cleanup_old_backups() {
    echo "=== TASK 6: Cleanup Old Backups ==="

    # TODO: Implement cleanup
    # 1. Find backups older than retention period
    # 2. Delete old backups
    # 3. Log deleted files

    echo "TODO: Implement cleanup_old_backups()"

    # Example structure:
    # echo "Cleaning up full backups older than $FULL_BACKUP_RETENTION days..."
    # find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$FULL_BACKUP_RETENTION -delete -print | tee -a "$LOG_FILE"
    #
    # echo "Cleaning up incremental backups older than $INCREMENTAL_BACKUP_RETENTION days..."
    # find "$INCREMENTAL_BACKUP_DIR" -type d -mtime +$INCREMENTAL_BACKUP_RETENTION -exec rm -rf {} + 2>&1 | tee -a "$LOG_FILE"
}

# ============================================================================
# TASK 7: DISASTER RECOVERY TEST
# ============================================================================
# Simulate disaster and test recovery procedures
# Requirements:
# - Create test data
# - Backup test data
# - "Destroy" test data (simulate disaster)
# - Restore from backup
# - Verify data integrity (checksums)
# ============================================================================

disaster_recovery_test() {
    echo "=== TASK 7: Disaster Recovery Test ==="

    local test_dir="/tmp/disaster-test-$$"
    local test_data_dir="${test_dir}/data"
    local test_backup_file="${test_dir}/backup.tar.gz"
    local restore_dir="${test_dir}/restore"

    # TODO: Implement disaster recovery test
    # 1. Create test data (100 files with random content)
    # 2. Generate checksums for test data
    # 3. Create backup
    # 4. Delete test data (simulate disaster)
    # 5. Restore from backup
    # 6. Verify checksums
    # 7. Cleanup test directory

    echo "TODO: Implement disaster_recovery_test()"

    # Example structure:
    # echo "1. Creating test data..."
    # mkdir -p "$test_data_dir"
    # for i in {1..100}; do
    #     echo "Test file $i - $(date)" > "${test_data_dir}/file${i}.txt"
    # done
    #
    # echo "2. Generating checksums..."
    # cd "$test_data_dir"
    # sha256sum * > checksums.txt
    #
    # echo "3. Creating backup..."
    # tar -czf "$test_backup_file" -C "$test_dir" data
    #
    # echo "4. DISASTER! Deleting data..."
    # rm -rf "$test_data_dir"
    #
    # echo "5. Restoring from backup..."
    # tar -xzf "$test_backup_file" -C "$test_dir"
    #
    # echo "6. Verifying checksums..."
    # cd "$test_data_dir"
    # sha256sum -c checksums.txt
    #
    # echo "7. Cleanup..."
    # rm -rf "$test_dir"
}

# ============================================================================
# TASK 8: GENERATE BACKUP REPORT
# ============================================================================
# Generate comprehensive backup status report
# Requirements:
# - List all backups with size and age
# - Show backup health status
# - Display storage usage
# - Save report to file
# ============================================================================

generate_backup_report() {
    local report_file="${1:-/tmp/backup-report-$(date +%Y%m%d-%H%M%S).txt}"

    echo "=== TASK 8: Backup Report ==="
    echo "Generating report: $report_file"

    # TODO: Implement report generation
    # 1. Header with date/time
    # 2. List all full backups (size, age)
    # 3. List recent incremental backups
    # 4. Backup health status
    # 5. Storage usage (df -h)
    # 6. Save to report_file

    echo "TODO: Implement generate_backup_report()"

    # Example structure:
    # {
    #     echo "========================================="
    #     echo "BACKUP STATUS REPORT"
    #     echo "Generated: $(date)"
    #     echo "========================================="
    #     echo
    #     echo "FULL BACKUPS:"
    #     find "$FULL_BACKUP_DIR" -name "*.tar.gz" -type f -printf '%TY-%Tm-%Td %TH:%TM  %10s bytes  %p\n' | sort -r
    #     echo
    #     echo "INCREMENTAL BACKUPS (last 7 days):"
    #     find "$INCREMENTAL_BACKUP_DIR" -type d -mtime -7 -printf '%TY-%Tm-%Td %TH:%TM  %p\n' | sort -r
    #     echo
    #     echo "STORAGE USAGE:"
    #     df -h "$BACKUP_BASE_DIR"
    #     echo
    #     echo "HEALTH CHECK:"
    #     check_backup_health
    # } > "$report_file"
    #
    # cat "$report_file"
}

# ============================================================================
# MAIN MENU
# ============================================================================

main() {
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║             EPISODE 12: BACKUP & RECOVERY                      ║"
    echo "║             Tallinn, Estonia 🇪🇪                               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo
    echo "Liisa Kask: 'Untested backup = no backup. Let's test yours.'"
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
            echo "Running all tasks..."
            backup_full
            backup_incremental
            check_backup_health
            cleanup_old_backups
            disaster_recovery_test
            generate_backup_report
            echo
            echo "✓ All tasks completed!"
            ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
}

# ============================================================================
# ENTRY POINT
# ============================================================================

# Create necessary directories
mkdir -p "$FULL_BACKUP_DIR" "$INCREMENTAL_BACKUP_DIR" "$OFFSITE_BACKUP_DIR"
touch "$LOG_FILE"

# Run main menu if no arguments provided
if [[ $# -eq 0 ]]; then
    main
else
    # Allow running specific functions from command line
    "$@"
fi

