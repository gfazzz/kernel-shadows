#!/bin/bash

################################################################################
# DISK SPACE MONITORING SCRIPT — Episode 11: Disk Management & LVM
# KERNEL SHADOWS Operation
#
# Purpose: Monitor disk space usage and send alerts when threshold exceeded
# Usage: Run manually or via systemd timer
#
# Features:
# - Checks all mounted filesystems
# - Sends alerts via Slack, email, syslog
# - Configurable threshold
# - Production-ready logging
#
################################################################################

set -e

# ============================================================================
# Configuration
# ============================================================================
THRESHOLD=90              # Alert if disk usage >= 90%
WARNING_THRESHOLD=80      # Warning if disk usage >= 80%
EMAIL="admin@example.com"
SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
LOG_FILE="/var/log/disk-monitor.log"

# Colors (for terminal output)
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================================================
# Function: Log to file and stdout
# ============================================================================
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

log_info() {
    log "INFO" "$*"
}

log_warning() {
    echo -e "${YELLOW}[$timestamp] [WARNING] $*${NC}" | tee -a "$LOG_FILE"
}

log_critical() {
    echo -e "${RED}[$timestamp] [CRITICAL] $*${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[$timestamp] [SUCCESS] $*${NC}" | tee -a "$LOG_FILE"
}

# ============================================================================
# Function: Check disk usage for a mount point
# ============================================================================
check_disk_usage() {
    local mount_point="$1"
    local threshold="$2"
    
    # Check if mount point exists and is mounted
    if ! mountpoint -q "$mount_point" 2>/dev/null; then
        log_warning "$mount_point is not mounted, skipping"
        return 0
    fi
    
    # Get disk usage (percentage without % sign)
    local usage
    usage=$(df -h "$mount_point" | tail -1 | awk '{print $5}' | sed 's/%//')
    
    # Check if usage is a valid number
    if ! [[ "$usage" =~ ^[0-9]+$ ]]; then
        log_warning "Cannot determine usage for $mount_point"
        return 0
    fi
    
    # Evaluate usage level
    if [[ $usage -ge $threshold ]]; then
        log_critical "$mount_point is ${usage}% full (threshold: ${threshold}%)"
        send_alert "$mount_point" "$usage" "CRITICAL"
        return 1
    elif [[ $usage -ge $WARNING_THRESHOLD ]]; then
        log_warning "$mount_point is ${usage}% full (warning threshold: ${WARNING_THRESHOLD}%)"
        send_alert "$mount_point" "$usage" "WARNING"
        return 0
    else
        log_info "$mount_point is ${usage}% full — OK"
        return 0
    fi
}

# ============================================================================
# Function: Send alert (Slack, Email, Syslog)
# ============================================================================
send_alert() {
    local mount_point="$1"
    local usage="$2"
    local severity="$3"
    
    local hostname
    hostname=$(hostname)
    local message
    
    if [[ "$severity" == "CRITICAL" ]]; then
        message="🚨 DISK SPACE CRITICAL: $mount_point is ${usage}% full on $hostname"
    else
        message="⚠️ DISK SPACE WARNING: $mount_point is ${usage}% full on $hostname"
    fi
    
    # Slack notification
    if [[ -n "$SLACK_WEBHOOK" && "$SLACK_WEBHOOK" != "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" ]]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$SLACK_WEBHOOK" 2>/dev/null || log_warning "Failed to send Slack alert"
    fi
    
    # Email notification (requires mail command)
    if command -v mail &> /dev/null; then
        echo "$message" | mail -s "[$severity] Disk Space Alert — $hostname" "$EMAIL" 2>/dev/null || \
            log_warning "Failed to send email alert"
    fi
    
    # Syslog (always log to syslog)
    logger -t disk-monitor -p user.warning "$message"
    
    log_info "Alert sent: $message"
}

# ============================================================================
# Function: Check all critical mount points
# ============================================================================
check_all_disks() {
    log_info "=========================================="
    log_info "Disk Space Monitoring Started"
    log_info "Threshold: ${THRESHOLD}% | Warning: ${WARNING_THRESHOLD}%"
    log_info "=========================================="
    
    local exit_code=0
    
    # Check root filesystem (always)
    check_disk_usage "/" "$THRESHOLD" || exit_code=1
    
    # Check /var (if separate partition)
    if mountpoint -q "/var" 2>/dev/null; then
        check_disk_usage "/var" "$THRESHOLD" || exit_code=1
    fi
    
    # Check /home (if separate partition)
    if mountpoint -q "/home" 2>/dev/null; then
        check_disk_usage "/home" "$THRESHOLD" || exit_code=1
    fi
    
    # Check LVM mount points from Episode 11
    for mount in /mnt/databases /mnt/logs /mnt/backups; do
        if mountpoint -q "$mount" 2>/dev/null; then
            check_disk_usage "$mount" "$THRESHOLD" || exit_code=1
        fi
    done
    
    # Check any other mounted LVM volumes
    while IFS= read -r line; do
        local mount_point
        mount_point=$(echo "$line" | awk '{print $6}')
        if [[ "$mount_point" =~ ^/mnt/ || "$mount_point" =~ ^/srv/ ]]; then
            check_disk_usage "$mount_point" "$THRESHOLD" || exit_code=1
        fi
    done < <(df -h | grep '^/dev/mapper/')
    
    log_info "=========================================="
    log_info "Monitoring Complete"
    log_info "=========================================="
    
    return $exit_code
}

# ============================================================================
# Function: Generate summary report
# ============================================================================
generate_report() {
    log_info "Disk Usage Summary:"
    log_info "------------------------------------------"
    df -h | grep -E "^/dev/(sd|nvme|mapper)" | while read -r line; do
        log_info "$line"
    done
    log_info "------------------------------------------"
}

# ============================================================================
# Main Execution
# ============================================================================
main() {
    # Ensure log directory exists
    sudo mkdir -p "$(dirname "$LOG_FILE")"
    sudo touch "$LOG_FILE"
    
    # Run checks
    check_all_disks
    local exit_code=$?
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    if [[ $exit_code -eq 0 ]]; then
        log_success "All disks within safe limits"
        exit 0
    else
        log_critical "One or more disks exceed threshold!"
        exit 1
    fi
}

# Run main function
main "$@"

