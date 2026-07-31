#!/bin/bash
################################################################################
# KERNEL SHADOWS - Episode 10: Processes & SystemD
# Automated Test Suite
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Expected paths
MONITOR_SCRIPT="/usr/local/bin/shadow-monitor.sh"
MONITOR_SERVICE="/etc/systemd/system/shadow-monitor.service"
BACKUP_SCRIPT="/usr/local/bin/shadow-backup.sh"
BACKUP_SERVICE="/etc/systemd/system/shadow-backup.service"
BACKUP_TIMER="/etc/systemd/system/shadow-backup.timer"
BACKUP_DIR="/var/backups/shadow"
REPORT_FILE="/var/operations/process_audit_ep10.txt"

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Episode 10 Test Suite${NC}"
echo -e "${BLUE}  Processes & SystemD${NC}"
echo -e "${BLUE}=======================================${NC}"
echo

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Tests should be run as root or with sudo${NC}"
    echo -e "${YELLOW}Some tests may fail without proper privileges${NC}"
    echo
fi

################################################################################
# Test helper functions
################################################################################

run_test() {
    local test_name="$1"
    local test_function="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -e "${BLUE}[TEST $TESTS_TOTAL]${NC} $test_name"
    
    if $test_function; then
        echo -e "${GREEN}  ✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAILED${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
    echo
}

assert_file_exists() {
    local file="$1"
    if [[ -f "$file" ]]; then
        echo "    File exists: $file"
        return 0
    else
        echo "    File NOT found: $file"
        return 1
    fi
}

assert_file_executable() {
    local file="$1"
    if [[ -x "$file" ]]; then
        echo "    File is executable: $file"
        return 0
    else
        echo "    File NOT executable: $file"
        return 1
    fi
}

assert_service_exists() {
    local service="$1"
    if systemctl list-unit-files "$service" &>/dev/null; then
        echo "    Service exists: $service"
        return 0
    else
        echo "    Service NOT found: $service"
        return 1
    fi
}

assert_service_active() {
    local service="$1"
    if systemctl is-active "$service" &>/dev/null; then
        echo "    Service is active: $service"
        return 0
    else
        echo "    Service NOT active: $service"
        return 1
    fi
}

assert_service_enabled() {
    local service="$1"
    if systemctl is-enabled "$service" &>/dev/null; then
        echo "    Service is enabled: $service"
        return 0
    else
        echo "    Service NOT enabled: $service"
        return 1
    fi
}

assert_command_exists() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        echo "    Command available: $cmd"
        return 0
    else
        echo "    Command NOT found: $cmd"
        return 1
    fi
}

################################################################################
# Category 1: File Structure Tests
################################################################################

test_monitor_script_exists() {
    assert_file_exists "$MONITOR_SCRIPT"
}

test_monitor_script_executable() {
    assert_file_executable "$MONITOR_SCRIPT"
}

test_monitor_service_exists() {
    assert_file_exists "$MONITOR_SERVICE"
}

test_backup_script_exists() {
    assert_file_exists "$BACKUP_SCRIPT"
}

test_backup_script_executable() {
    assert_file_executable "$BACKUP_SCRIPT"
}

test_backup_service_exists() {
    assert_file_exists "$BACKUP_SERVICE"
}

test_backup_timer_exists() {
    assert_file_exists "$BACKUP_TIMER"
}

test_backup_directory_exists() {
    if [[ -d "$BACKUP_DIR" ]]; then
        echo "    Backup directory exists: $BACKUP_DIR"
        return 0
    else
        echo "    Backup directory NOT found: $BACKUP_DIR"
        return 1
    fi
}

################################################################################
# Category 2: Script Content Tests
################################################################################

test_monitor_script_has_shebang() {
    local first_line=$(head -1 "$MONITOR_SCRIPT" 2>/dev/null)
    if [[ "$first_line" == "#!/bin/bash" ]]; then
        echo "    Correct shebang: $first_line"
        return 0
    else
        echo "    Missing or incorrect shebang: $first_line"
        return 1
    fi
}

test_monitor_script_has_loop() {
    if grep -q "while true" "$MONITOR_SCRIPT" 2>/dev/null; then
        echo "    Contains monitoring loop (while true)"
        return 0
    else
        echo "    No monitoring loop found"
        return 1
    fi
}

test_monitor_script_uses_logger() {
    if grep -q "logger" "$MONITOR_SCRIPT" 2>/dev/null; then
        echo "    Uses logger for logging"
        return 0
    else
        echo "    Warning: Not using logger (logs might not appear in journal)"
        return 1
    fi
}

test_backup_script_has_shebang() {
    local first_line=$(head -1 "$BACKUP_SCRIPT" 2>/dev/null)
    if [[ "$first_line" == "#!/bin/bash" ]]; then
        echo "    Correct shebang: $first_line"
        return 0
    else
        echo "    Missing or incorrect shebang: $first_line"
        return 1
    fi
}

test_backup_script_creates_backup() {
    if grep -q "tar" "$BACKUP_SCRIPT" 2>/dev/null; then
        echo "    Uses tar for backup"
        return 0
    else
        echo "    No tar command found (how does it backup?)"
        return 1
    fi
}

################################################################################
# Category 3: SystemD Service Unit Tests
################################################################################

test_monitor_service_registered() {
    assert_service_exists "shadow-monitor.service"
}

test_monitor_service_unit_structure() {
    local has_unit=false
    local has_service=false
    local has_install=false
    
    if grep -q "\[Unit\]" "$MONITOR_SERVICE" 2>/dev/null; then
        has_unit=true
    fi
    
    if grep -q "\[Service\]" "$MONITOR_SERVICE" 2>/dev/null; then
        has_service=true
    fi
    
    if grep -q "\[Install\]" "$MONITOR_SERVICE" 2>/dev/null; then
        has_install=true
    fi
    
    if $has_unit && $has_service && $has_install; then
        echo "    Unit file structure correct: [Unit], [Service], [Install]"
        return 0
    else
        echo "    Unit file structure incomplete:"
        echo "      [Unit]: $has_unit"
        echo "      [Service]: $has_service"
        echo "      [Install]: $has_install"
        return 1
    fi
}

test_monitor_service_has_execstart() {
    if grep -q "ExecStart=" "$MONITOR_SERVICE" 2>/dev/null; then
        local execstart=$(grep "ExecStart=" "$MONITOR_SERVICE")
        echo "    Has ExecStart: $execstart"
        return 0
    else
        echo "    Missing ExecStart directive"
        return 1
    fi
}

test_monitor_service_has_restart() {
    if grep -q "Restart=" "$MONITOR_SERVICE" 2>/dev/null; then
        local restart=$(grep "Restart=" "$MONITOR_SERVICE")
        echo "    Has Restart policy: $restart"
        return 0
    else
        echo "    Warning: No Restart policy (service won't auto-restart on failure)"
        return 1
    fi
}

test_monitor_service_logs_to_journal() {
    local has_stdout=false
    local has_stderr=false
    
    if grep -q "StandardOutput=journal" "$MONITOR_SERVICE" 2>/dev/null; then
        has_stdout=true
    fi
    
    if grep -q "StandardError=journal" "$MONITOR_SERVICE" 2>/dev/null; then
        has_stderr=true
    fi
    
    if $has_stdout && $has_stderr; then
        echo "    Logs to journal (StandardOutput & StandardError)"
        return 0
    else
        echo "    Warning: May not log to journal properly"
        return 1
    fi
}

################################################################################
# Category 4: SystemD Timer Tests
################################################################################

test_backup_timer_registered() {
    assert_service_exists "shadow-backup.timer"
}

test_backup_timer_unit_structure() {
    local has_unit=false
    local has_timer=false
    local has_install=false
    
    if grep -q "\[Unit\]" "$BACKUP_TIMER" 2>/dev/null; then
        has_unit=true
    fi
    
    if grep -q "\[Timer\]" "$BACKUP_TIMER" 2>/dev/null; then
        has_timer=true
    fi
    
    if grep -q "\[Install\]" "$BACKUP_TIMER" 2>/dev/null; then
        has_install=true
    fi
    
    if $has_unit && $has_timer && $has_install; then
        echo "    Timer structure correct: [Unit], [Timer], [Install]"
        return 0
    else
        echo "    Timer structure incomplete:"
        echo "      [Unit]: $has_unit"
        echo "      [Timer]: $has_timer"
        echo "      [Install]: $has_install"
        return 1
    fi
}

test_backup_timer_has_oncalendar() {
    if grep -q "OnCalendar=" "$BACKUP_TIMER" 2>/dev/null; then
        local oncalendar=$(grep "OnCalendar=" "$BACKUP_TIMER")
        echo "    Has OnCalendar: $oncalendar"
        return 0
    else
        echo "    Missing OnCalendar directive"
        return 1
    fi
}

test_backup_timer_has_persistent() {
    if grep -q "Persistent=true" "$BACKUP_TIMER" 2>/dev/null; then
        echo "    Has Persistent=true (will run if missed)"
        return 0
    else
        echo "    Warning: Persistent not set (missed runs won't execute)"
        return 1
    fi
}

test_backup_timer_targets_timers() {
    if grep -q "WantedBy=timers.target" "$BACKUP_TIMER" 2>/dev/null; then
        echo "    Correctly targets timers.target"
        return 0
    else
        echo "    Warning: Should target timers.target"
        return 1
    fi
}

test_backup_service_is_oneshot() {
    if grep -q "Type=oneshot" "$BACKUP_SERVICE" 2>/dev/null; then
        echo "    Correct Type=oneshot (required for timers)"
        return 0
    else
        echo "    Warning: Service should be Type=oneshot for timer use"
        return 1
    fi
}

################################################################################
# Category 5: Service Runtime Tests
################################################################################

test_monitor_service_active() {
    assert_service_active "shadow-monitor.service"
}

test_monitor_service_enabled() {
    assert_service_enabled "shadow-monitor.service"
}

test_monitor_service_has_process() {
    if pgrep -f "shadow-monitor" &>/dev/null; then
        local pid=$(pgrep -f "shadow-monitor")
        echo "    Process running: PID $pid"
        return 0
    else
        echo "    No shadow-monitor process found"
        return 1
    fi
}

test_backup_timer_active() {
    assert_service_active "shadow-backup.timer"
}

test_backup_timer_enabled() {
    assert_service_enabled "shadow-backup.timer"
}

test_backup_timer_scheduled() {
    if systemctl list-timers shadow-backup.timer | grep -q "shadow-backup.timer"; then
        echo "    Timer is scheduled"
        local next=$(systemctl list-timers shadow-backup.timer --no-pager | grep shadow-backup | awk '{print $1, $2}')
        echo "    Next run: $next"
        return 0
    else
        echo "    Timer not in schedule"
        return 1
    fi
}

################################################################################
# Category 6: Logging Tests
################################################################################

test_monitor_service_has_logs() {
    if journalctl -u shadow-monitor.service --no-pager 2>/dev/null | grep -q "."; then
        echo "    Service has journal entries"
        local lines=$(journalctl -u shadow-monitor.service --no-pager 2>/dev/null | wc -l)
        echo "    Log lines: $lines"
        return 0
    else
        echo "    No journal entries (service may not have started yet)"
        return 1
    fi
}

test_backup_service_has_logs() {
    if journalctl -u shadow-backup.service --no-pager 2>/dev/null | grep -q "."; then
        echo "    Backup service has journal entries"
        local lines=$(journalctl -u shadow-backup.service --no-pager 2>/dev/null | wc -l)
        echo "    Log lines: $lines"
        return 0
    else
        echo "    No journal entries (service may not have run yet)"
        echo "    Try: sudo systemctl start shadow-backup.service"
        return 1
    fi
}

test_journalctl_commands_work() {
    local errors=0
    
    # Test basic journalctl
    if ! journalctl --no-pager -n 1 &>/dev/null; then
        echo "    journalctl basic query failed"
        ((errors++))
    fi
    
    # Test unit filtering
    if ! journalctl -u shadow-monitor.service -n 1 --no-pager &>/dev/null; then
        echo "    journalctl -u filtering failed"
        ((errors++))
    fi
    
    # Test time filtering
    if ! journalctl --since "1 hour ago" -n 1 --no-pager &>/dev/null; then
        echo "    journalctl --since filtering failed"
        ((errors++))
    fi
    
    # Test priority filtering
    if ! journalctl -p err -n 1 --no-pager &>/dev/null; then
        echo "    journalctl -p filtering failed"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo "    All journalctl commands work"
        return 0
    else
        echo "    Some journalctl commands failed ($errors errors)"
        return 1
    fi
}

################################################################################
# Category 7: Backup Tests
################################################################################

test_backup_directory_writable() {
    if [[ -w "$BACKUP_DIR" ]] || sudo test -w "$BACKUP_DIR"; then
        echo "    Backup directory is writable"
        return 0
    else
        echo "    Backup directory not writable"
        return 1
    fi
}

test_backup_files_created() {
    if sudo ls "$BACKUP_DIR"/config_*.tar.gz &>/dev/null; then
        local count=$(sudo ls -1 "$BACKUP_DIR"/config_*.tar.gz 2>/dev/null | wc -l)
        echo "    Backup files exist: $count file(s)"
        sudo ls -lh "$BACKUP_DIR"/config_*.tar.gz 2>/dev/null | tail -3
        return 0
    else
        echo "    No backup files found (run: sudo systemctl start shadow-backup.service)"
        return 1
    fi
}

test_backup_file_permissions() {
    local latest=$(sudo ls -t "$BACKUP_DIR"/config_*.tar.gz 2>/dev/null | head -1)
    if [[ -n "$latest" ]]; then
        local perms=$(sudo stat -c "%a" "$latest")
        if [[ "$perms" == "600" ]] || [[ "$perms" == "640" ]]; then
            echo "    Backup permissions correct: $perms"
            return 0
        else
            echo "    Backup permissions too open: $perms (should be 600 or 640)"
            return 1
        fi
    else
        echo "    No backup files to check permissions"
        return 1
    fi
}

################################################################################
# Category 8: Process Management Tests
################################################################################

test_ps_command_works() {
    if ps aux &>/dev/null; then
        echo "    ps aux works"
        return 0
    else
        echo "    ps aux failed"
        return 1
    fi
}

test_pgrep_command_works() {
    if pgrep -a init &>/dev/null || pgrep -a systemd &>/dev/null; then
        echo "    pgrep works"
        return 0
    else
        echo "    pgrep failed"
        return 1
    fi
}

test_top_command_available() {
    assert_command_exists "top"
}

test_kill_command_available() {
    assert_command_exists "kill"
}

test_systemctl_command_available() {
    assert_command_exists "systemctl"
}

################################################################################
# Category 9: Report Tests
################################################################################

test_report_file_exists() {
    assert_file_exists "$REPORT_FILE"
}

test_report_has_content() {
    if [[ -f "$REPORT_FILE" ]]; then
        local lines=$(wc -l < "$REPORT_FILE")
        if [[ $lines -gt 100 ]]; then
            echo "    Report has substantial content: $lines lines"
            return 0
        else
            echo "    Report exists but seems incomplete: $lines lines"
            return 1
        fi
    else
        echo "    Report file not found"
        return 1
    fi
}

test_report_has_sections() {
    if [[ ! -f "$REPORT_FILE" ]]; then
        echo "    Report file not found"
        return 1
    fi
    
    local missing=0
    local sections=(
        "BACKDOOR PROCESS"
        "SYSTEMD.*SERVICE"
        "TIMER"
        "JOURNALCTL"
        "SYSTEM HEALTH"
    )
    
    for section in "${sections[@]}"; do
        if ! grep -qiE "$section" "$REPORT_FILE"; then
            echo "    Missing section: $section"
            ((missing++))
        fi
    done
    
    if [[ $missing -eq 0 ]]; then
        echo "    All key sections present"
        return 0
    else
        echo "    $missing section(s) missing from report"
        return 1
    fi
}

test_report_permissions() {
    if [[ -f "$REPORT_FILE" ]]; then
        local perms=$(stat -c "%a" "$REPORT_FILE")
        if [[ "$perms" == "640" ]] || [[ "$perms" == "644" ]] || [[ "$perms" == "600" ]]; then
            echo "    Report permissions appropriate: $perms"
            return 0
        else
            echo "    Report permissions: $perms"
            return 1
        fi
    else
        echo "    Report file not found"
        return 1
    fi
}

################################################################################
# Category 10: Integration Tests
################################################################################

test_monitor_service_restart() {
    echo "    Testing service restart..."
    if sudo systemctl restart shadow-monitor.service 2>/dev/null; then
        sleep 2
        if systemctl is-active shadow-monitor.service &>/dev/null; then
            echo "    Service restart successful"
            return 0
        else
            echo "    Service failed to restart"
            return 1
        fi
    else
        echo "    Failed to restart service"
        return 1
    fi
}

test_backup_service_manual_trigger() {
    echo "    Triggering manual backup..."
    if sudo systemctl start shadow-backup.service 2>/dev/null; then
        sleep 2
        if sudo ls "$BACKUP_DIR"/config_*.tar.gz &>/dev/null; then
            echo "    Manual backup successful"
            return 0
        else
            echo "    Backup triggered but no file created"
            return 1
        fi
    else
        echo "    Failed to trigger backup"
        return 1
    fi
}

test_system_health_check() {
    local errors=0
    
    # Load average
    if ! uptime &>/dev/null; then
        echo "    uptime command failed"
        ((errors++))
    fi
    
    # Memory
    if ! free -h &>/dev/null; then
        echo "    free command failed"
        ((errors++))
    fi
    
    # Processes
    if ! ps aux --sort=-%cpu | head -1 &>/dev/null; then
        echo "    ps sorting failed"
        ((errors++))
    fi
    
    # Services
    if ! systemctl --failed --no-pager &>/dev/null; then
        echo "    systemctl --failed check failed"
        ((errors++))
    fi
    
    if [[ $errors -eq 0 ]]; then
        echo "    System health monitoring commands work"
        return 0
    else
        echo "    Some health check commands failed ($errors errors)"
        return 1
    fi
}

################################################################################
# Run all tests
################################################################################

echo -e "${CYAN}=== Category 1: File Structure ===${NC}"
run_test "Monitor script exists" test_monitor_script_exists
run_test "Monitor script executable" test_monitor_script_executable
run_test "Monitor service unit exists" test_monitor_service_exists
run_test "Backup script exists" test_backup_script_exists
run_test "Backup script executable" test_backup_script_executable
run_test "Backup service unit exists" test_backup_service_exists
run_test "Backup timer unit exists" test_backup_timer_exists
run_test "Backup directory exists" test_backup_directory_exists
echo

echo -e "${CYAN}=== Category 2: Script Content ===${NC}"
run_test "Monitor script has shebang" test_monitor_script_has_shebang
run_test "Monitor script has loop" test_monitor_script_has_loop
run_test "Monitor script uses logger" test_monitor_script_uses_logger
run_test "Backup script has shebang" test_backup_script_has_shebang
run_test "Backup script creates backup" test_backup_script_creates_backup
echo

echo -e "${CYAN}=== Category 3: SystemD Service Units ===${NC}"
run_test "Monitor service registered" test_monitor_service_registered
run_test "Monitor service unit structure" test_monitor_service_unit_structure
run_test "Monitor service has ExecStart" test_monitor_service_has_execstart
run_test "Monitor service has Restart" test_monitor_service_has_restart
run_test "Monitor service logs to journal" test_monitor_service_logs_to_journal
echo

echo -e "${CYAN}=== Category 4: SystemD Timer ===${NC}"
run_test "Backup timer registered" test_backup_timer_registered
run_test "Backup timer unit structure" test_backup_timer_unit_structure
run_test "Backup timer has OnCalendar" test_backup_timer_has_oncalendar
run_test "Backup timer has Persistent" test_backup_timer_has_persistent
run_test "Backup timer targets timers.target" test_backup_timer_targets_timers
run_test "Backup service is oneshot" test_backup_service_is_oneshot
echo

echo -e "${CYAN}=== Category 5: Service Runtime ===${NC}"
run_test "Monitor service is active" test_monitor_service_active
run_test "Monitor service is enabled" test_monitor_service_enabled
run_test "Monitor service has process" test_monitor_service_has_process
run_test "Backup timer is active" test_backup_timer_active
run_test "Backup timer is enabled" test_backup_timer_enabled
run_test "Backup timer is scheduled" test_backup_timer_scheduled
echo

echo -e "${CYAN}=== Category 6: Logging ===${NC}"
run_test "Monitor service has logs" test_monitor_service_has_logs
run_test "Backup service has logs" test_backup_service_has_logs
run_test "Journalctl commands work" test_journalctl_commands_work
echo

echo -e "${CYAN}=== Category 7: Backups ===${NC}"
run_test "Backup directory writable" test_backup_directory_writable
run_test "Backup files created" test_backup_files_created
run_test "Backup file permissions" test_backup_file_permissions
echo

echo -e "${CYAN}=== Category 8: Process Management ===${NC}"
run_test "ps command works" test_ps_command_works
run_test "pgrep command works" test_pgrep_command_works
run_test "top command available" test_top_command_available
run_test "kill command available" test_kill_command_available
run_test "systemctl command available" test_systemctl_command_available
echo

echo -e "${CYAN}=== Category 9: Report ===${NC}"
run_test "Report file exists" test_report_file_exists
run_test "Report has content" test_report_has_content
run_test "Report has sections" test_report_has_sections
run_test "Report permissions" test_report_permissions
echo

echo -e "${CYAN}=== Category 10: Integration ===${NC}"
run_test "Monitor service can restart" test_monitor_service_restart
run_test "Backup service manual trigger" test_backup_service_manual_trigger
run_test "System health check commands" test_system_health_check
echo

################################################################################
# Final Summary
################################################################################

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}  Test Results Summary${NC}"
echo -e "${BLUE}=======================================${NC}"
echo
echo "Total tests: $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}Episode 10 implementation is correct!${NC}"
    echo
    echo -e "${BLUE}Boris Kuznetsov:${NC} 'Отлично! SystemD mastery подтверждён.'"
    echo -e "${CYAN}Anna Kovaleva:${NC} 'Мониторинг работает. Логи чистые.'"
    echo -e "${YELLOW}Viktor Petrov:${NC} 'Принято. Следующая миссия: Tallinn.'"
    echo
    exit 0
else
    echo -e "${YELLOW}⚠ SOME TESTS FAILED${NC}"
    echo "Check the failed tests above and fix the issues."
    echo
    echo "Common issues:"
    echo "  - Services not started: sudo systemctl start servicename"
    echo "  - Services not enabled: sudo systemctl enable servicename"
    echo "  - Permissions: Run script with sudo"
    echo "  - Backup not triggered: sudo systemctl start shadow-backup.service"
    echo
    echo "Debugging commands:"
    echo "  systemctl status shadow-monitor.service"
    echo "  journalctl -u shadow-monitor.service -n 50"
    echo "  systemctl list-timers shadow-backup.timer"
    echo
    exit 1
fi

