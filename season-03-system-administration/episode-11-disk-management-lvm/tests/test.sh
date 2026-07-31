#!/bin/bash
################################################################################
# KERNEL SHADOWS - Episode 11: Disk Management & LVM
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

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Episode 11 Test Suite${NC}"
echo -e "${BLUE}  Disk Management & LVM${NC}"
echo -e "${BLUE}========================================${NC}"
echo

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}Warning: Tests require root privileges${NC}"
    echo -e "${YELLOW}Run with: sudo ./test.sh${NC}"
    exit 1
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

################################################################################
# Category 1: File Structure Tests
################################################################################

test_starter_exists() {
    [[ -f "../starter.sh" ]] && echo "    starter.sh exists"
}

test_readme_exists() {
    [[ -f "../README.md" ]] && echo "    README.md exists"
}

test_artifacts_readme_exists() {
    [[ -f "../artifacts/README.md" ]] && echo "    artifacts/README.md exists"
}

################################################################################
# Category 2: Command Availability Tests
################################################################################

test_lsblk_available() {
    command -v lsblk &>/dev/null && echo "    lsblk available"
}

test_lvm_available() {
    command -v pvcreate &>/dev/null && echo "    LVM tools available"
}

test_mdadm_available() {
    if command -v mdadm &>/dev/null; then
        echo "    mdadm available"
        return 0
    else
        echo "    mdadm not installed (install: apt install mdadm)"
        return 1
    fi
}

test_smartctl_available() {
    if command -v smartctl &>/dev/null; then
        echo "    smartctl available"
        return 0
    else
        echo "    smartctl not installed (install: apt install smartmontools)"
        return 1
    fi
}

################################################################################
# Category 3: LVM Tests (if configured)
################################################################################

test_pvs_command() {
    if pvs &>/dev/null; then
        local pv_count=$(pvs --noheadings | wc -l)
        echo "    Physical Volumes found: $pv_count"
        return 0
    else
        echo "    No Physical Volumes (LVM not configured yet)"
        return 1
    fi
}

test_vgs_command() {
    if vgs &>/dev/null; then
        local vg_count=$(vgs --noheadings | wc -l)
        echo "    Volume Groups found: $vg_count"
        return 0
    else
        echo "    No Volume Groups"
        return 1
    fi
}

test_lvs_command() {
    if lvs &>/dev/null; then
        local lv_count=$(lvs --noheadings | wc -l)
        echo "    Logical Volumes found: $lv_count"
        return 0
    else
        echo "    No Logical Volumes"
        return 1
    fi
}

################################################################################
# Category 4: RAID Tests (if configured)
################################################################################

test_raid_status() {
    if [[ -f /proc/mdstat ]]; then
        if grep -q "md" /proc/mdstat 2>/dev/null; then
            echo "    RAID arrays found:"
            cat /proc/mdstat | grep "^md"
            return 0
        else
            echo "    No active RAID arrays"
            return 1
        fi
    else
        echo "    /proc/mdstat not available"
        return 1
    fi
}

################################################################################
# Category 5: Filesystem Tests
################################################################################

test_mounted_filesystems() {
    local count=$(df -h | grep "^/dev" | wc -l)
    echo "    Mounted filesystems: $count"
    [[ $count -gt 0 ]]
}

test_fstab_syntax() {
    if mount -a -f 2>/dev/null; then
        echo "    /etc/fstab syntax valid"
        return 0
    else
        echo "    /etc/fstab has errors"
        return 1
    fi
}

################################################################################
# Category 6: Disk Health Tests
################################################################################

test_disk_listing() {
    if lsblk &>/dev/null; then
        local disk_count=$(lsblk -d -n -o NAME | grep -c "^sd\|^nvme\|^vd" || echo "0")
        echo "    Block devices found: $disk_count"
        [[ $disk_count -gt 0 ]]
    else
        return 1
    fi
}

test_smart_capability() {
    local has_smart=false
    for disk in $(lsblk -d -n -o NAME | grep "^sd\|^nvme"); do
        if smartctl -i /dev/$disk 2>/dev/null | grep -q "SMART support is: Available"; then
            has_smart=true
            echo "    /dev/$disk: SMART available"
            break
        fi
    done
    $has_smart
}

################################################################################
# Category 7: Production Monitoring Tests (systemd)
################################################################################

test_monitoring_script_exists() {
    if [[ -f "/usr/local/bin/disk-monitor.sh" ]]; then
        echo "    Monitoring script installed: /usr/local/bin/disk-monitor.sh"
        return 0
    else
        echo "    Monitoring script not found (not installed yet)"
        return 1
    fi
}

test_monitoring_service_exists() {
    if [[ -f "/etc/systemd/system/disk-monitor.service" ]]; then
        echo "    disk-monitor.service file exists"
        return 0
    else
        echo "    disk-monitor.service not found"
        return 1
    fi
}

test_monitoring_timer_exists() {
    if [[ -f "/etc/systemd/system/disk-monitor.timer" ]]; then
        echo "    disk-monitor.timer file exists"
        return 0
    else
        echo "    disk-monitor.timer not found"
        return 1
    fi
}

test_monitoring_timer_active() {
    if systemctl is-active disk-monitor.timer &>/dev/null; then
        echo "    disk-monitor.timer is ACTIVE"
        return 0
    else
        echo "    disk-monitor.timer not active (enable with: systemctl enable --now disk-monitor.timer)"
        return 1
    fi
}

test_monitoring_timer_enabled() {
    if systemctl is-enabled disk-monitor.timer &>/dev/null; then
        echo "    disk-monitor.timer is ENABLED (starts on boot)"
        return 0
    else
        echo "    disk-monitor.timer not enabled"
        return 1
    fi
}

################################################################################
# Category 8: Report Test
################################################################################

test_report_exists() {
    if [[ -f "/var/operations/disk_audit_ep11.txt" ]]; then
        echo "    Report exists: /var/operations/disk_audit_ep11.txt"
        return 0
    else
        echo "    Report not found (run solution to generate)"
        return 1
    fi
}

################################################################################
# Run all tests
################################################################################

echo -e "${BLUE}=== Category 1: File Structure ===${NC}"
run_test "starter.sh exists" test_starter_exists
run_test "README.md exists" test_readme_exists
run_test "artifacts/README.md exists" test_artifacts_readme_exists
echo

echo -e "${BLUE}=== Category 2: Command Availability ===${NC}"
run_test "lsblk available" test_lsblk_available
run_test "LVM tools available" test_lvm_available
run_test "mdadm available" test_mdadm_available
run_test "smartctl available" test_smartctl_available
echo

echo -e "${BLUE}=== Category 3: LVM Configuration ===${NC}"
run_test "Physical Volumes" test_pvs_command
run_test "Volume Groups" test_vgs_command
run_test "Logical Volumes" test_lvs_command
echo

echo -e "${BLUE}=== Category 4: RAID Configuration ===${NC}"
run_test "RAID status" test_raid_status
echo

echo -e "${BLUE}=== Category 5: Filesystems ===${NC}"
run_test "Mounted filesystems" test_mounted_filesystems
run_test "/etc/fstab syntax" test_fstab_syntax
echo

echo -e "${BLUE}=== Category 6: Disk Health ===${NC}"
run_test "Disk listing" test_disk_listing
run_test "SMART capability" test_smart_capability
echo

echo -e "${BLUE}=== Category 7: Production Monitoring ===${NC}"
run_test "Monitoring script installed" test_monitoring_script_exists
run_test "systemd service file exists" test_monitoring_service_exists
run_test "systemd timer file exists" test_monitoring_timer_exists
run_test "Timer is active" test_monitoring_timer_active
run_test "Timer is enabled" test_monitoring_timer_enabled
echo

echo -e "${BLUE}=== Category 8: Report ===${NC}"
run_test "Audit report exists" test_report_exists
echo

################################################################################
# Final Summary
################################################################################

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Test Results Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo
echo "Total tests: $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"
echo

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED!${NC}"
    echo
    echo -e "${BLUE}Kristjan Tamm:${NC} 'Disk management на уровне. Данные в безопасности.'"
    echo -e "${YELLOW}Liisa Kask:${NC} 'LVM и RAID настроены правильно. Молодец.'"
    exit 0
else
    echo -e "${YELLOW}⚠ SOME TESTS FAILED${NC}"
    echo
    echo "Note: Some tests may fail if:"
    echo "  - LVM/RAID not configured yet (normal during learning)"
    echo "  - Running in VM without SMART support"
    echo "  - Using loop devices instead of real disks"
    echo
    echo "This is OK for learning! Real hardware tests would show different results."
    exit 1
fi
