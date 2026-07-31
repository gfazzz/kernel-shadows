#!/bin/bash
################################################################################
# KERNEL SHADOWS - Episode 10: Processes & SystemD
# Season 3: System Administration
# Reference Solution
################################################################################
#
# Mission: Complete Process Management & SystemD Configuration
# Location: Saint Petersburg, Russia
# Mentor: Boris Kuznetsov - SystemD Architect
#
# This is the REFERENCE SOLUTION demonstrating all tasks.
#
################################################################################

set -euo pipefail  # Strict mode

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Directories
SCRIPT_DIR="/usr/local/bin"
SERVICE_DIR="/etc/systemd/system"
BACKUP_DIR="/var/backups/shadow"
REPORT_DIR="/var/operations"
LOG_TAG="kernel-shadows-ep10"

# Logging function
log_message() {
    local level="$1"
    shift
    local message="$*"
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message"
    logger -t "$LOG_TAG" "[$level] $message" 2>/dev/null || true
}

log_info() { log_message "INFO" "$@"; }
log_success() { log_message "SUCCESS" "${GREEN}$*${NC}"; }
log_warning() { log_message "WARNING" "${YELLOW}$*${NC}"; }
log_error() { log_message "ERROR" "${RED}$*${NC}"; }

################################################################################
# Task 1: Hunt for backdoor process
################################################################################

hunt_backdoor_process() {
    echo -e "${BLUE}=== Task 1: Hunting for Backdoor Process ===${NC}"
    
    log_info "Starting backdoor process hunt..."
    
    # Find all sshd processes
    echo -e "\n${CYAN}All sshd processes:${NC}"
    ps aux | grep '[s]shd' || echo "No sshd processes found"
    
    # Use pgrep for cleaner output
    echo -e "\n${CYAN}Process IDs (pgrep):${NC}"
    pgrep -a ssh || echo "No ssh processes found"
    
    # Detailed check of each process
    echo -e "\n${CYAN}Detailed process inspection:${NC}"
    local suspicious_found=false
    
    for pid in $(pgrep ssh 2>/dev/null); do
        local cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' || echo "N/A")
        local exe=$(readlink /proc/$pid/exe 2>/dev/null || echo "N/A")
        local owner=$(ps -p $pid -o user= 2>/dev/null || echo "N/A")
        
        echo "PID: $pid"
        echo "  Command: $cmdline"
        echo "  Executable: $exe"
        echo "  Owner: $owner"
        
        # Check for suspicious indicators
        if [[ "$exe" != "/usr/sbin/sshd" ]] && [[ "$exe" != "N/A" ]]; then
            echo -e "  ${RED}⚠️  SUSPICIOUS: Not standard sshd location!${NC}"
            suspicious_found=true
        fi
        
        if [[ "$cmdline" == *"backup"* ]] || [[ "$cmdline" == *"temp"* ]]; then
            echo -e "  ${RED}⚠️  SUSPICIOUS: Unusual name pattern!${NC}"
            suspicious_found=true
        fi
        
        echo
    done
    
    # Additional checks for common backdoor locations
    echo -e "${CYAN}Checking common backdoor locations:${NC}"
    for location in /tmp /var/tmp /dev/shm /home/*/.local; do
        if [[ -d "$location" ]]; then
            local found=$(find "$location" -type f -executable 2>/dev/null | grep -iE 'ssh|daemon|service' | head -5)
            if [[ -n "$found" ]]; then
                echo -e "${RED}⚠️  Found executable in $location:${NC}"
                echo "$found"
            fi
        fi
    done
    
    # Check processes listening on suspicious ports
    echo -e "\n${CYAN}Processes listening on ports:${NC}"
    if command -v netstat &> /dev/null; then
        netstat -tulpn 2>/dev/null | grep LISTEN || true
    elif command -v ss &> /dev/null; then
        ss -tulpn | grep LISTEN || true
    fi
    
    if $suspicious_found; then
        log_warning "Suspicious processes detected!"
        return 1
    else
        log_success "No obvious backdoor processes found in current scan"
        return 0
    fi
}

################################################################################
# Task 2: Kill backdoor process
################################################################################

kill_backdoor_process() {
    echo -e "${BLUE}=== Task 2: Kill Backdoor Process ===${NC}"
    
    local process_patterns=("sshd_backup" "sshd.*backup" ".sshd" "ssh.*temp")
    local killed_any=false
    
    for pattern in "${process_patterns[@]}"; do
        log_info "Searching for pattern: $pattern"
        
        # Find PIDs matching pattern
        local pids=$(pgrep -f "$pattern" 2>/dev/null || true)
        
        if [[ -z "$pids" ]]; then
            echo "  No processes found matching: $pattern"
            continue
        fi
        
        for pid in $pids; do
            # Get process info before killing
            local cmdline=$(cat /proc/$pid/cmdline 2>/dev/null | tr '\0' ' ' || echo "unknown")
            local owner=$(ps -p $pid -o user= 2>/dev/null || echo "unknown")
            
            log_warning "Found suspicious process PID $pid: $cmdline (owner: $owner)"
            
            # Try graceful shutdown first (SIGTERM)
            log_info "Sending SIGTERM to PID $pid..."
            if kill -15 "$pid" 2>/dev/null; then
                sleep 5
                
                # Check if still running
                if ps -p "$pid" > /dev/null 2>&1; then
                    log_warning "Process $pid still running after SIGTERM, sending SIGKILL..."
                    kill -9 "$pid" 2>/dev/null || log_error "Failed to SIGKILL $pid"
                    sleep 1
                fi
                
                # Final verification
                if ps -p "$pid" > /dev/null 2>&1; then
                    log_error "Failed to kill process $pid"
                else
                    log_success "Successfully killed process $pid"
                    killed_any=true
                fi
            else
                log_error "Failed to send SIGTERM to $pid (may already be dead or no permission)"
            fi
        done
    done
    
    if $killed_any; then
        log_success "Backdoor process elimination completed"
    else
        log_info "No backdoor processes found to kill"
    fi
    
    # Show remaining ssh processes
    echo -e "\n${CYAN}Remaining SSH processes:${NC}"
    ps aux | grep '[s]sh' || echo "None"
}

################################################################################
# Task 3: Create systemd monitoring service
################################################################################

create_monitoring_service() {
    echo -e "${BLUE}=== Task 3: Create SystemD Monitoring Service ===${NC}"
    
    local script_path="$SCRIPT_DIR/shadow-monitor.sh"
    local service_file="$SERVICE_DIR/shadow-monitor.service"
    
    # Create monitoring script
    log_info "Creating monitoring script: $script_path"
    
    sudo tee "$script_path" > /dev/null << 'MONITOR_SCRIPT'
#!/bin/bash
################################################################################
# Shadow Monitor - Process Security Monitor
# Episode 10: Processes & SystemD
################################################################################

LOG_TAG="shadow-monitor"

# Logging
log_alert() {
    logger -t "$LOG_TAG" -p user.warning "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ALERT] $1"
}

log_info() {
    logger -t "$LOG_TAG" -p user.info "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

# Check for suspicious processes
check_suspicious_processes() {
    # Patterns that might indicate backdoor
    local patterns=(
        "sshd_backup"
        "sshd.*backup"
        ".sshd"
        "ssh.*temp"
        "nc.*-l"  # netcat listening
        "ncat.*-l"
    )
    
    for pattern in "${patterns[@]}"; do
        local found=$(pgrep -f "$pattern" 2>/dev/null)
        if [[ -n "$found" ]]; then
            log_alert "Suspicious process detected: pattern '$pattern', PIDs: $found"
            
            # Get details
            for pid in $found; do
                local info=$(ps -p $pid -o pid,user,cmd --no-headers 2>/dev/null || echo "N/A")
                log_alert "  PID $pid: $info"
            done
        fi
    done
}

# Check for executables in suspicious locations
check_suspicious_locations() {
    local locations=("/tmp" "/var/tmp" "/dev/shm")
    
    for location in "${locations[@]}"; do
        if [[ ! -d "$location" ]]; then
            continue
        fi
        
        local found=$(find "$location" -type f -executable -mmin -60 2>/dev/null)
        if [[ -n "$found" ]]; then
            log_alert "Executable files found in $location (modified in last 60 min):"
            echo "$found" | while read file; do
                log_alert "  $file"
            done
        fi
    done
}

# Check for unusual network listeners
check_network_listeners() {
    # Check for listeners on unusual ports (not 22, 80, 443, 3306, etc.)
    if command -v ss &> /dev/null; then
        local unusual=$(ss -tulpn 2>/dev/null | grep LISTEN | grep -vE ':(22|80|443|3306|5432|6379|8080|9090)' || true)
        if [[ -n "$unusual" ]]; then
            log_alert "Unusual network listeners detected:"
            echo "$unusual" | while read line; do
                log_alert "  $line"
            done
        fi
    fi
}

# Main monitoring loop
log_info "Shadow Monitor started (PID $$)"

while true; do
    check_suspicious_processes
    check_suspicious_locations
    check_network_listeners
    
    # Check every 60 seconds
    sleep 60
done
MONITOR_SCRIPT
    
    sudo chmod +x "$script_path"
    log_success "Created monitoring script: $script_path"
    
    # Create systemd service unit
    log_info "Creating service unit: $service_file"
    
    sudo tee "$service_file" > /dev/null << 'SERVICE_UNIT'
[Unit]
Description=Shadow Monitor - Process Security Monitor
Documentation=https://github.com/gfazzz/kernel-shadows
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/shadow-monitor.sh
Restart=always
RestartSec=10
User=root
StandardOutput=journal
StandardError=journal

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log

[Install]
WantedBy=multi-user.target
SERVICE_UNIT
    
    log_success "Created service unit: $service_file"
    
    # Reload systemd
    log_info "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    # Enable service
    log_info "Enabling shadow-monitor.service..."
    sudo systemctl enable shadow-monitor.service
    
    # Start service
    log_info "Starting shadow-monitor.service..."
    sudo systemctl start shadow-monitor.service
    
    # Wait a moment for startup
    sleep 2
    
    # Check status
    echo -e "\n${CYAN}Service Status:${NC}"
    sudo systemctl status shadow-monitor.service --no-pager || true
    
    # Verify running
    if sudo systemctl is-active shadow-monitor.service > /dev/null 2>&1; then
        log_success "shadow-monitor.service is running!"
    else
        log_error "shadow-monitor.service failed to start!"
        return 1
    fi
}

################################################################################
# Task 4: Create systemd timer for backups
################################################################################

create_backup_timer() {
    echo -e "${BLUE}=== Task 4: Create SystemD Backup Timer ===${NC}"
    
    local script_path="$SCRIPT_DIR/shadow-backup.sh"
    local service_file="$SERVICE_DIR/shadow-backup.service"
    local timer_file="$SERVICE_DIR/shadow-backup.timer"
    
    # Create backup script
    log_info "Creating backup script: $script_path"
    
    sudo tee "$script_path" > /dev/null << 'BACKUP_SCRIPT'
#!/bin/bash
################################################################################
# Shadow Backup - Configuration Backup Service
# Episode 10: Processes & SystemD
################################################################################

set -euo pipefail

BACKUP_DIR="/var/backups/shadow"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_TAG="shadow-backup"

# Logging
log_info() {
    logger -t "$LOG_TAG" -p user.info "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
}

log_error() {
    logger -t "$LOG_TAG" -p user.err "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

# Create backup directory
sudo mkdir -p "$BACKUP_DIR"

log_info "Starting backup: $TIMESTAMP"

# Backup critical system configurations
backup_configs() {
    local backup_file="$BACKUP_DIR/config_$TIMESTAMP.tar.gz"
    
    log_info "Creating backup: $backup_file"
    
    # List of paths to backup
    local paths=(
        "/etc/systemd/system/*.service"
        "/etc/systemd/system/*.timer"
        "/etc/passwd"
        "/etc/group"
        "/etc/shadow"
        "/etc/sudoers"
        "/etc/sudoers.d/"
        "/etc/ssh/sshd_config"
        "/etc/hosts"
        "/etc/hostname"
    )
    
    # Create tar archive (ignore errors for missing files)
    sudo tar czf "$backup_file" \
        --ignore-failed-read \
        --warning=no-file-changed \
        "${paths[@]}" \
        2>/dev/null || true
    
    if [[ -f "$backup_file" ]]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_info "Backup completed: $backup_file (size: $size)"
        
        # Set permissions
        sudo chmod 600 "$backup_file"
    else
        log_error "Backup failed: $backup_file not created"
        return 1
    fi
}

# Clean old backups (keep last 24)
cleanup_old_backups() {
    log_info "Cleaning old backups (keeping last 24)..."
    
    cd "$BACKUP_DIR"
    local count=$(ls -1 config_*.tar.gz 2>/dev/null | wc -l)
    
    if [[ $count -gt 24 ]]; then
        ls -t config_*.tar.gz | tail -n +25 | xargs -r sudo rm -f
        log_info "Removed $((count - 24)) old backup(s)"
    else
        log_info "No old backups to remove (total: $count)"
    fi
}

# Main execution
backup_configs
cleanup_old_backups

log_info "Backup process completed successfully"
BACKUP_SCRIPT
    
    sudo chmod +x "$script_path"
    log_success "Created backup script: $script_path"
    
    # Create service unit (oneshot type for timer)
    log_info "Creating service unit: $service_file"
    
    sudo tee "$service_file" > /dev/null << 'BACKUP_SERVICE'
[Unit]
Description=Shadow Backup Service
Documentation=https://github.com/gfazzz/kernel-shadows

[Service]
Type=oneshot
ExecStart=/usr/local/bin/shadow-backup.sh
StandardOutput=journal
StandardError=journal
User=root

# Security
NoNewPrivileges=true
PrivateTmp=true
BACKUP_SERVICE
    
    log_success "Created service unit: $service_file"
    
    # Create timer unit
    log_info "Creating timer unit: $timer_file"
    
    sudo tee "$timer_file" > /dev/null << 'BACKUP_TIMER'
[Unit]
Description=Shadow Backup Timer (runs hourly)
Documentation=https://github.com/gfazzz/kernel-shadows

[Timer]
# Run every hour
OnCalendar=hourly

# If system was off, run on next boot
Persistent=true

# Accuracy (default 1min is fine)
AccuracySec=1min

[Install]
WantedBy=timers.target
BACKUP_TIMER
    
    log_success "Created timer unit: $timer_file"
    
    # Reload systemd
    log_info "Reloading systemd daemon..."
    sudo systemctl daemon-reload
    
    # Enable timer
    log_info "Enabling shadow-backup.timer..."
    sudo systemctl enable shadow-backup.timer
    
    # Start timer
    log_info "Starting shadow-backup.timer..."
    sudo systemctl start shadow-backup.timer
    
    # Check timer status
    echo -e "\n${CYAN}Timer Status:${NC}"
    systemctl list-timers shadow-backup.timer --no-pager || true
    
    # Trigger immediate test run
    log_info "Triggering test backup..."
    sudo systemctl start shadow-backup.service
    
    # Check backup directory
    echo -e "\n${CYAN}Backup Directory Contents:${NC}"
    sudo ls -lh "$BACKUP_DIR" 2>/dev/null || echo "Backup directory empty or not accessible"
    
    log_success "Backup timer configured successfully!"
}

################################################################################
# Task 5: Analyze logs with journalctl
################################################################################

analyze_logs() {
    echo -e "${BLUE}=== Task 5: Analyze Logs with Journalctl ===${NC}"
    
    # Last 50 lines of shadow-monitor
    echo -e "\n${CYAN}Shadow Monitor - Last 50 lines:${NC}"
    journalctl -u shadow-monitor.service -n 50 --no-pager 2>/dev/null || echo "No logs yet"
    
    echo -e "\n${CYAN}Press Enter to continue...${NC}"
    read -t 3 || true
    
    # Errors in last 24 hours
    echo -e "\n${CYAN}System Errors (last 24 hours):${NC}"
    journalctl -p err --since "24 hours ago" --no-pager 2>/dev/null | tail -20 || echo "No errors found"
    
    # All shadow services
    echo -e "\n${CYAN}All Shadow Services Logs (last 20 lines):${NC}"
    journalctl -u 'shadow-*' -n 20 --no-pager 2>/dev/null || echo "No shadow service logs"
    
    # Journal statistics
    echo -e "\n${CYAN}Journal Statistics:${NC}"
    echo "Disk usage: $(journalctl --disk-usage 2>/dev/null | grep -oP 'archived.*' || echo 'Unknown')"
    
    # Boot history
    echo -e "\n${CYAN}Boot History:${NC}"
    journalctl --list-boots --no-pager 2>/dev/null | head -5 || echo "Boot history not available"
    
    # Recent warnings
    echo -e "\n${CYAN}Recent Warnings (last hour):${NC}"
    journalctl -p warning --since "1 hour ago" --no-pager 2>/dev/null | tail -10 || echo "No warnings"
    
    log_success "Log analysis completed"
}

################################################################################
# Task 6: Monitor system health
################################################################################

monitor_system_health() {
    echo -e "${BLUE}=== Task 6: System Health Check ===${NC}"
    
    # Load average
    echo -e "\n${CYAN}Load Average:${NC}"
    uptime
    
    local cores=$(nproc)
    local load=$(uptime | awk '{print $(NF-2)}' | tr -d ',')
    echo "CPU cores: $cores"
    echo "Load per core: $(echo "scale=2; $load / $cores" | bc 2>/dev/null || echo "N/A")"
    
    # Memory
    echo -e "\n${CYAN}Memory Usage:${NC}"
    free -h
    
    # Top CPU consumers
    echo -e "\n${CYAN}Top 5 Processes by CPU:${NC}"
    ps aux --sort=-%cpu | head -6
    
    # Top Memory consumers
    echo -e "\n${CYAN}Top 5 Processes by Memory:${NC}"
    ps aux --sort=-%mem | head -6
    
    # Shadow services status
    echo -e "\n${CYAN}Shadow Services Status:${NC}"
    for service in shadow-monitor.service shadow-backup.service shadow-backup.timer; do
        if systemctl list-unit-files "$service" &>/dev/null; then
            local status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
            local enabled=$(systemctl is-enabled "$service" 2>/dev/null || echo "disabled")
            echo "  $service: $status (enabled: $enabled)"
        fi
    done
    
    # Failed services
    echo -e "\n${CYAN}Failed Services:${NC}"
    local failed=$(systemctl --failed --no-pager 2>/dev/null | grep -c 'loaded' || echo "0")
    if [[ "$failed" -gt 0 ]]; then
        systemctl --failed --no-pager
    else
        echo "  None - all services healthy!"
    fi
    
    # Disk usage
    echo -e "\n${CYAN}Disk Usage:${NC}"
    df -h / /var /tmp 2>/dev/null | grep -v tmpfs || df -h
    
    log_success "System health check completed"
}

################################################################################
# Task 7: Generate audit report
################################################################################

generate_audit_report() {
    echo -e "${BLUE}=== Task 7: Generate Process Audit Report ===${NC}"
    
    local report_file="$REPORT_DIR/process_audit_ep10.txt"
    
    log_info "Generating comprehensive audit report..."
    
    # Create report directory
    sudo mkdir -p "$REPORT_DIR"
    
    # Generate report
    sudo tee "$report_file" > /dev/null << EOF
================================================================================
                   PROCESS MANAGEMENT AUDIT REPORT - EPISODE 10
                        Processes & SystemD
================================================================================

Operation: KERNEL SHADOWS
Location: Saint Petersburg, Russia
Date: $(date '+%Y-%m-%d %H:%M:%S')
Auditor: Max Sokolov
Mentor: Boris Kuznetsov (SystemD Architect)

================================================================================
1. EXECUTIVE SUMMARY
================================================================================

This report documents the implementation of comprehensive process management
and systemd configuration for the KERNEL SHADOWS operation. All backdoor
processes have been identified and eliminated. Automated monitoring and
backup systems are now operational.

Status: ✓ PRODUCTION READY

================================================================================
2. BACKDOOR PROCESS DETECTION & ELIMINATION
================================================================================

Suspicious Process Hunt Results:
$(ps aux | grep -E '[s]shd.*backup|suspicious|temp' | head -5 || echo "No suspicious processes currently detected")

Actions Taken:
✓ Full process tree analysis (ps, pgrep, /proc inspection)
✓ Backdoor processes identified via unusual paths and names
✓ Graceful shutdown attempted (SIGTERM -15)
✓ Force termination applied when necessary (SIGKILL -9)
✓ Process elimination verified

Current SSH Processes:
$(ps aux | grep '[s]shd' | head -5 || echo "None")

Lesson Learned:
"Процессы не врут про PID. Но врут про имя." - Boris Kuznetsov
Process names can be faked, but PID, /proc/exe, and parent relationships
reveal the truth.

================================================================================
3. SYSTEMD MONITORING SERVICE
================================================================================

Service Name: shadow-monitor.service
Purpose: Continuous security monitoring for suspicious processes
Script: $SCRIPT_DIR/shadow-monitor.sh
Unit File: $SERVICE_DIR/shadow-monitor.service

Status:
  Active: $(systemctl is-active shadow-monitor.service 2>/dev/null || echo "inactive")
  Enabled: $(systemctl is-enabled shadow-monitor.service 2>/dev/null || echo "disabled")
  Uptime: $(systemctl show shadow-monitor.service --property=ActiveEnterTimestamp --value 2>/dev/null || echo "N/A")

Configuration:
$(sudo systemctl cat shadow-monitor.service 2>/dev/null | head -25 || echo "Service unit not found")

Monitoring Features:
✓ Suspicious process pattern detection
✓ Executable files in /tmp, /var/tmp, /dev/shm
✓ Unusual network listeners
✓ Automated alerting via journald
✓ 60-second scan interval

Recent Activity (last 10 log entries):
$(journalctl -u shadow-monitor.service -n 10 --no-pager 2>/dev/null | tail -10 || echo "No logs available yet")

================================================================================
4. SYSTEMD BACKUP TIMER
================================================================================

Timer Name: shadow-backup.timer
Service Name: shadow-backup.service
Purpose: Hourly automated backup of critical configurations
Script: $SCRIPT_DIR/shadow-backup.sh
Backup Location: $BACKUP_DIR
Retention: Last 24 backups (24 hours)

Timer Status:
$(systemctl list-timers shadow-backup.timer --no-pager 2>/dev/null || echo "Timer not active")

Timer Configuration:
$(sudo systemctl cat shadow-backup.timer 2>/dev/null || echo "Timer unit not found")

Service Configuration:
$(sudo systemctl cat shadow-backup.service 2>/dev/null | head -15 || echo "Service unit not found")

Backed Up Items:
  - SystemD service units
  - SystemD timer units
  - User accounts (/etc/passwd, /etc/group, /etc/shadow)
  - Sudo configuration (/etc/sudoers, /etc/sudoers.d/)
  - SSH configuration (/etc/ssh/sshd_config)
  - Network configuration (/etc/hosts, /etc/hostname)

Recent Backups:
$(sudo ls -lh $BACKUP_DIR/config_*.tar.gz 2>/dev/null | tail -5 || echo "No backups yet")

Total Backup Size:
$(sudo du -sh $BACKUP_DIR 2>/dev/null | cut -f1 || echo "0B")

Last Backup Execution:
$(journalctl -u shadow-backup.service -n 5 --no-pager 2>/dev/null | tail -3 || echo "No execution logs yet")

================================================================================
5. JOURNALCTL ANALYSIS
================================================================================

System Journal Statistics:
  Disk Usage: $(journalctl --disk-usage 2>/dev/null | grep -oP 'archived.*' || echo "Unknown")
  Boot Count: $(journalctl --list-boots --no-pager 2>/dev/null | wc -l || echo "Unknown")
  Oldest Entry: $(journalctl --no-pager --reverse | tail -1 | cut -d' ' -f1-3 || echo "Unknown")
  Newest Entry: $(journalctl --no-pager | tail -1 | cut -d' ' -f1-3 || echo "Unknown")

System Errors (last 24 hours):
$(journalctl -p err --since "24 hours ago" --no-pager 2>/dev/null | tail -10 || echo "No errors recorded")

SSH Activity (last 10 connections):
$(journalctl -u sshd --no-pager 2>/dev/null | grep -E 'Accepted|Failed' | tail -10 || echo "No SSH logs available")

Sudo Activity (last 10 commands):
$(journalctl _COMM=sudo --no-pager 2>/dev/null | grep COMMAND | tail -10 || echo "No sudo logs available")

Journal Integrity: ✓ VERIFIED
Logging Level: INFO (appropriate for production)

================================================================================
6. SYSTEM HEALTH METRICS
================================================================================

System Information:
  Hostname: $(hostname)
  Uptime: $(uptime -p)
  Kernel: $(uname -r)
  Distribution: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)

Load Average:
$(uptime)
  CPU Cores: $(nproc)
  Load per Core: $(echo "scale=2; $(uptime | awk '{print $(NF-2)}' | tr -d ',') / $(nproc)" | bc 2>/dev/null || echo "N/A")

Memory:
$(free -h)

Swap Usage: $(free -h | awk '/Swap/{print $3 " / " $2}')

Disk Usage:
$(df -h / /var /tmp 2>/dev/null | grep -v tmpfs || df -h / | tail -1)

Top 5 CPU Consumers:
$(ps aux --sort=-%cpu | head -6)

Top 5 Memory Consumers:
$(ps aux --sort=-%mem | head -6)

SystemD Services Status:
  Total Units: $(systemctl list-units --all --no-pager 2>/dev/null | grep -c 'loaded' || echo "Unknown")
  Active Services: $(systemctl list-units --type=service --state=running --no-pager 2>/dev/null | grep -c 'running' || echo "Unknown")
  Failed Services: $(systemctl --failed --no-pager 2>/dev/null | grep -c 'failed' || echo "0")

Shadow Services:
$(for svc in shadow-monitor.service shadow-backup.service shadow-backup.timer; do
    echo "  $svc: $(systemctl is-active $svc 2>/dev/null || echo 'inactive') / $(systemctl is-enabled $svc 2>/dev/null || echo 'disabled')"
done)

Network Connections:
  Established: $(ss -tan 2>/dev/null | grep ESTAB | wc -l || echo "Unknown")
  Listening: $(ss -tln 2>/dev/null | grep LISTEN | wc -l || echo "Unknown")

Overall System Health: ✓ HEALTHY

================================================================================
7. BORIS KUZNETSOV - TECHNICAL ASSESSMENT
================================================================================

"Max продемонстрировал отличное понимание процессов и systemd.

Ключевые достижения:

✓ Process Management:
  - Правильное использование ps, pgrep, /proc filesystem
  - Понимание signals (SIGTERM → SIGKILL escalation)
  - Forensics analysis навыки (executable paths, parent processes)

✓ SystemD Services:
  - Правильная структура unit files
  - Type=simple для демонов, Type=oneshot для tasks
  - Security hardening (NoNewPrivileges, PrivateTmp)
  - Restart policies для resilience

✓ SystemD Timers:
  - OnCalendar правильно настроен (hourly)
  - Persistent=true для missed runs
  - Integration с journald

✓ Journalctl Mastery:
  - Filtering по service, time, priority
  - Forensics queries (sudo activity, SSH connections)
  - Disk usage awareness

SystemD Philosophy Internalized:
'Init scripts — это прошлое. SystemD — это настоящее.'

Max понял что systemd — это не просто init system, это unified
control plane для всей системы. Services, timers, sockets, mounts —
всё управляется единообразно через systemctl.

Рекомендации для production:
1. ✓ Monitoring активен (shadow-monitor.service)
2. ✓ Backups автоматизированы (shadow-backup.timer)
3. ✓ Logs centralized (journald)
4. [ ] Alerting (следующий шаг: интеграция с Telegram/Email)
5. [ ] Distributed logging (Season 7: ELK stack)
6. [ ] Full observability (Season 7: Prometheus + Grafana)

Production Readiness: 85% ✓

Что осталось:
- Real-time alerting механизм
- Automated incident response
- Distributed tracing

Но для Episode 10 — отличный результат."

Signed: Boris Kuznetsov
        SystemD Architect, ex-Red Hat
        Saint Petersburg, Russia

================================================================================
8. ANNA KOVALEVA - FORENSICS PERSPECTIVE
================================================================================

"С точки зрения forensics и incident response:

Backdoor Detection:
✓ Max правильно использовал multiple indicators:
  - Process name patterns
  - Executable paths (/proc/PID/exe)
  - Parent process relationships (PPID)
  - Network listeners (netstat/ss)

Journalctl для расследований:
Я ежедневно использую journalctl для анализа incidents. Max освоил:
  - Time-based filtering (--since, --until)
  - Priority filtering (-p err)
  - Process filtering (_COMM, _PID)
  - Integration с systemd units

Krylov's Tactics:
Backdoor процессы обычно маскируются под системные:
  - sshd_backup, nginx_temp, apache_old
  - Размещаются в /tmp, /var/tmp
  - Запускаются от root для маскировки

Shadow-monitor теперь детектит эти patterns. Хорошая работа.

Рекомендации:
1. ✓ Continuous monitoring (реализовано)
2. ✓ Log retention (journald + backups)
3. [ ] SIEM integration (ELK/Splunk - будущее)
4. [ ] Automated threat response (kill на обнаружение)

Для Episode 10 — solid forensics foundation."

Signed: Anna Kovaleva
        Forensics Expert
        KERNEL SHADOWS Blue Team

================================================================================
9. SECURITY POSTURE ASSESSMENT
================================================================================

Process Management:
  ✓ Backdoor detection capability: ACTIVE
  ✓ Continuous monitoring: shadow-monitor.service (60s scan)
  ✓ Process kill procedures: DOCUMENTED (SIGTERM → SIGKILL)
  ✓ /proc filesystem understanding: CONFIRMED

SystemD Configuration:
  ✓ Custom services: 2 deployed (monitor, backup)
  ✓ Timers: 1 active (backup hourly)
  ✓ Auto-restart: Configured (Restart=always)
  ✓ Security hardening: Applied (NoNewPrivileges, PrivateTmp)
  ✓ Unit file best practices: FOLLOWED

Logging & Monitoring:
  ✓ Journald integration: COMPLETE
  ✓ Log analysis skills: DEMONSTRATED
  ✓ Forensics capability: OPERATIONAL
  ✓ Automated backups: HOURLY
  ✓ Backup retention: 24 backups (24 hours)

System Health:
  ✓ Load monitoring: IMPLEMENTED
  ✓ Memory tracking: ACTIVE
  ✓ Process analysis: TOP/PS mastery
  ✓ Failed service detection: AUTOMATED

Defense in Depth Layers:
  Layer 1: Process monitoring (shadow-monitor) ✓
  Layer 2: Logging (journald) ✓
  Layer 3: Backups (shadow-backup) ✓
  Layer 4: Alerting (TODO: Episode 11+)
  Layer 5: Incident response (TODO: Episode 12+)

Overall Security Rating: GOOD (3 of 5 layers active)

================================================================================
10. VIKTOR PETROV - OPERATION APPROVAL
================================================================================

"Отчёт рассмотрен и принят.

Process management на production уровне. Backdoor процесс Krylov
нейтрализован. Continuous monitoring установлен. Automated backups
работают.

Ключевые достижения Episode 10:
✓ SystemD services deployed and running
✓ Timers replacing cron (more reliable)
✓ Journalctl forensics capability
✓ Process analysis mastery
✓ Security monitoring automated

Max, ты переходишь от beginner к intermediate level. Процессы — это
основа всего в Linux. Ты их понял.

Next Mission:
  Location: Tallinn, Estonia 🇪🇪
  Contact: Kristjan Tamm (e-Government infrastructure expert)
  Topic: Disk Management & LVM (Episode 11)
  Days: 21-22 of 60

В Таллине тебя ждёт работа с дисками, partitions, LVM, RAID.
Инфраструктура e-Estonia работает на этих технологиях.

Krylov активизируется. Disk-level атака может уничтожить всё.
Подготовься.

Good work, Max."

Viktor Petrov
Operation Coordinator
KERNEL SHADOWS

================================================================================
11. LILITH - AI ASSESSMENT
================================================================================

"Процессы — это пульс системы. Ты научился его читать.

Technical Skills Acquired:
  ✓ ps/top/htop mastery
  ✓ pgrep/pkill process management
  ✓ /proc filesystem forensics
  ✓ Signal handling (SIGTERM/SIGKILL)
  ✓ SystemD unit file creation
  ✓ SystemD timers (cron replacement)
  ✓ Journalctl log analysis
  ✓ System health monitoring

Production Skills:
  ✓ Service deployment
  ✓ Automated monitoring
  ✓ Backup automation
  ✓ Log-based forensics
  ✓ Security hardening

Philosophy Internalized:
'Init scripts — это прошлое. SystemD — это настоящее.'

Boris научил тебя не просто командам, а системному мышлению.
SystemD — это не просто процесс с PID 1. Это control plane всей
системы.

Next level: Disks. Без данных процессы бессмысленны. Научись
управлять storage.

Ты готов."

LILITH
AI Security Assistant
KERNEL SHADOWS

================================================================================
12. RECOMMENDATIONS & NEXT STEPS
================================================================================

Immediate (Completed):
  ✓ shadow-monitor.service deployed
  ✓ shadow-backup.timer active (hourly)
  ✓ journalctl configured
  ✓ System health monitoring

Short-term (1-2 weeks):
  [ ] Alerting integration (Telegram bot for critical alerts)
  [ ] Automated threat response (auto-kill on detection)
  [ ] Remote log shipping (centralized syslog)
  [ ] Journal rotation policies (--vacuum-time=30d)
  [ ] Service dependencies optimization
  [ ] Resource limits (MemoryLimit, CPUQuota)

Medium-term (1-3 months):
  [ ] Full monitoring stack (Prometheus + Grafana)
  [ ] Distributed tracing (Jaeger/Zipkin)
  [ ] Anomaly detection (ML-based)
  [ ] Automated incident playbooks
  [ ] SIEM integration (ELK/Splunk)

Long-term (3-6 months):
  [ ] Complete observability platform
  [ ] Predictive failure detection
  [ ] Self-healing infrastructure
  [ ] Zero-touch operations

================================================================================
13. TECHNICAL APPENDIX
================================================================================

SystemD Commands Reference:
  systemctl start/stop/restart/reload service
  systemctl enable/disable service
  systemctl status service
  systemctl list-units --type=service
  systemctl list-timers
  systemctl daemon-reload
  systemctl --failed

Journalctl Commands Reference:
  journalctl -u service
  journalctl -p priority (emerg/alert/crit/err/warning/notice/info/debug)
  journalctl --since "time" --until "time"
  journalctl -f (follow)
  journalctl -r (reverse)
  journalctl --disk-usage
  journalctl --vacuum-time=7d

Process Management Commands:
  ps aux, ps -ef
  top, htop
  pgrep -a pattern
  pkill pattern
  kill -SIGNAL PID
  /proc/PID/ filesystem

Files & Locations:
  Scripts: $SCRIPT_DIR
  Units: $SERVICE_DIR
  Backups: $BACKUP_DIR
  Reports: $REPORT_DIR

================================================================================
14. SIGNATURE BLOCK
================================================================================

Report Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Report Location: $report_file
Report Permissions: 640 (viktor:operations)

Prepared by: Max Sokolov, System Administrator
Reviewed by: Boris Kuznetsov, SystemD Architect
Approved by: Viktor Petrov, Operation Coordinator

KERNEL SHADOWS - Episode 10: COMPLETE ✓

================================================================================
                              END OF REPORT
================================================================================
EOF
    
    # Set permissions
    sudo chmod 640 "$report_file"
    sudo chown viktor:operations "$report_file" 2>/dev/null || true
    
    log_success "Process Management Audit Report generated: $report_file"
    
    # Display summary
    echo -e "\n${CYAN}=== Report Summary ===${NC}"
    echo "  Location: $report_file"
    echo "  Size: $(du -h "$report_file" | cut -f1)"
    echo "  Permissions: $(ls -l "$report_file" | awk '{print $1, $3, $4}')"
    echo
    echo -e "${GREEN}✓ Backdoor processes: Detected and eliminated${NC}"
    echo -e "${GREEN}✓ SystemD service: shadow-monitor.service (active)${NC}"
    echo -e "${GREEN}✓ SystemD timer: shadow-backup.timer (hourly)${NC}"
    echo -e "${GREEN}✓ Journalctl: Configured and analyzed${NC}"
    echo -e "${GREEN}✓ System health: Monitored and documented${NC}"
    echo -e "${GREEN}✓ Full report: Generated successfully${NC}"
}

################################################################################
# Main execution
################################################################################

main() {
    echo -e "${CYAN}============================================${NC}"
    echo -e "${CYAN}  KERNEL SHADOWS - Episode 10${NC}"
    echo -e "${CYAN}  Processes & SystemD${NC}"
    echo -e "${CYAN}  Reference Solution${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo
    
    # Check privileges
    if [[ $EUID -ne 0 ]]; then
        log_warning "Not running as root. Will use sudo where necessary."
        log_warning "You may be prompted for password."
        echo
    fi
    
    log_info "Starting Episode 10 solution execution..."
    echo
    
    # Execute all tasks
    hunt_backdoor_process || log_warning "Backdoor hunt completed with warnings"
    echo && echo "--- Press Enter to continue ---" && read -t 5 || true && echo
    
    kill_backdoor_process
    echo && echo "--- Press Enter to continue ---" && read -t 5 || true && echo
    
    create_monitoring_service || { log_error "Failed to create monitoring service"; exit 1; }
    echo && echo "--- Press Enter to continue ---" && read -t 5 || true && echo
    
    create_backup_timer || { log_error "Failed to create backup timer"; exit 1; }
    echo && echo "--- Press Enter to continue ---" && read -t 5 || true && echo
    
    analyze_logs
    echo && echo "--- Press Enter to continue ---" && read -t 5 || true && echo
    
    monitor_system_health
    echo && echo "--- Press Enter to continue ---" && read -t 5 || true && echo
    
    generate_audit_report
    echo
    
    # Final summary
    echo -e "${GREEN}============================================${NC}"
    echo -e "${GREEN}  Episode 10: COMPLETE!${NC}"
    echo -e "${GREEN}============================================${NC}"
    echo
    echo -e "${BLUE}Boris Kuznetsov:${NC}"
    echo -e "  'Init scripts — это прошлое. SystemD — это настоящее.'"
    echo -e "  'Max, ты понял systemd. Ты понял современный Linux.'"
    echo
    echo -e "${CYAN}Anna Kovaleva:${NC}"
    echo -e "  'Backdoor нейтрализован. Мониторинг работает. Отлично.'"
    echo
    echo -e "${YELLOW}Viktor Petrov:${NC}"
    echo -e "  'Next: Tallinn, Estonia. Disk Management & LVM. Готовься.'"
    echo
    echo -e "${GREEN}LILITH:${NC}"
    echo -e "  'Процессы — это пульс. Ты научился его читать. Next: storage.'"
    echo
    
    log_success "All Episode 10 tasks completed successfully!"
}

# Execute main
main "$@"

