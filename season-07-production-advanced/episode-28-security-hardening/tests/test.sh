#!/bin/bash
# test.sh - Automated tests for Episode 28: Security Hardening
# KERNEL SHADOWS - Season 7

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_test() {
    local test_name=$1
    echo -e "${BLUE}[TEST]${NC} $test_name"
}

print_pass() {
    local message=$1
    echo -e "${GREEN}  ✅ PASS:${NC} $message"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

print_fail() {
    local message=$1
    echo -e "${RED}  ❌ FAIL:${NC} $message"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

print_skip() {
    local message=$1
    echo -e "${YELLOW}  ⏭️  SKIP:${NC} $message"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# ============================================================================
# TESTS
# ============================================================================

test_security_audit_script_exists() {
    print_test "Security audit script exists"
    
    if [ -f "security_audit.sh" ]; then
        print_pass "security_audit.sh found"
    else
        print_fail "security_audit.sh not found"
        return 1
    fi
    
    if [ -x "security_audit.sh" ]; then
        print_pass "security_audit.sh is executable"
    else
        print_fail "security_audit.sh is not executable (run: chmod +x security_audit.sh)"
        return 1
    fi
}

test_security_audit_runs() {
    print_test "Security audit script runs without errors"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    if ./security_audit.sh &>/dev/null; then
        print_pass "Script executed successfully"
    else
        print_fail "Script execution failed"
        return 1
    fi
}

test_selinux_check_implemented() {
    print_test "SELinux check implemented"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    output=$(./security_audit.sh 2>&1 || true)
    
    if echo "$output" | grep -q "=== SELINUX STATUS ==="; then
        print_pass "SELinux section found"
    else
        print_fail "SELinux section not found"
        return 1
    fi
}

test_auditd_check_implemented() {
    print_test "auditd check implemented"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    output=$(./security_audit.sh 2>&1 || true)
    
    if echo "$output" | grep -q "=== AUDITD STATUS ==="; then
        print_pass "auditd section found"
    else
        print_fail "auditd section not found"
        return 1
    fi
}

test_fail2ban_check_implemented() {
    print_test "fail2ban check implemented"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    output=$(./security_audit.sh 2>&1 || true)
    
    if echo "$output" | grep -q "=== FAIL2BAN STATUS ==="; then
        print_pass "fail2ban section found"
    else
        print_fail "fail2ban section not found"
        return 1
    fi
}

test_ssh_config_check_implemented() {
    print_test "SSH config check implemented"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    output=$(./security_audit.sh 2>&1 || true)
    
    if echo "$output" | grep -q "=== SSH CONFIGURATION ==="; then
        print_pass "SSH config section found"
    else
        print_fail "SSH config section not found"
        return 1
    fi
}

test_sysctl_security_check_implemented() {
    print_test "sysctl security check implemented"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    output=$(./security_audit.sh 2>&1 || true)
    
    if echo "$output" | grep -q "=== SYSCTL SECURITY PARAMETERS ==="; then
        print_pass "sysctl security section found"
    else
        print_fail "sysctl security section not found"
        return 1
    fi
}

test_firewall_check_implemented() {
    print_test "Firewall check implemented"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    output=$(./security_audit.sh 2>&1 || true)
    
    if echo "$output" | grep -q "=== FIREWALL STATUS ==="; then
        print_pass "Firewall section found"
    else
        print_fail "Firewall section not found"
        return 1
    fi
}

test_colored_output() {
    print_test "Script uses colored status indicators"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    if grep -q "🟢\|🟡\|🔴" "security_audit.sh"; then
        print_pass "Colored status indicators present (🟢/🟡/🔴)"
    else
        print_fail "Colored status indicators not found"
    fi
}

test_generates_report() {
    print_test "Script generates report file"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    # Run script
    ./security_audit.sh &>/dev/null || true
    
    # Check if report file was created
    report_files=(security_audit_*.txt)
    if [ -f "${report_files[0]}" ]; then
        print_pass "Report file generated: ${report_files[0]}"
        
        # Check file size
        size=$(stat -f%z "${report_files[0]}" 2>/dev/null || stat -c%s "${report_files[0]}" 2>/dev/null || echo 0)
        if [ "$size" -gt 100 ]; then
            print_pass "Report file has content ($size bytes)"
        else
            print_fail "Report file is too small or empty"
        fi
    else
        print_fail "No report file generated"
        return 1
    fi
}

test_script_best_practices() {
    print_test "Script follows bash best practices"
    
    if [ ! -f "security_audit.sh" ]; then
        print_skip "security_audit.sh not found"
        return 0
    fi
    
    # Check for shebang
    if head -1 "security_audit.sh" | grep -q "^#!/bin/bash"; then
        print_pass "Shebang present"
    else
        print_fail "Shebang missing or incorrect"
    fi
    
    # Check for set -e
    if grep -q "set -e" "security_audit.sh"; then
        print_pass "Error handling enabled (set -e)"
    else
        print_fail "No error handling (missing set -e)"
    fi
    
    # Check for functions
    if grep -q "^[a-z_]*() {" "security_audit.sh"; then
        print_pass "Functions defined"
    else
        print_fail "No functions found"
    fi
}

test_sysctl_config_exists() {
    print_test "sysctl security configuration exists"
    
    if [ -f "artifacts/99-security-hardening.conf" ]; then
        print_pass "sysctl config found in artifacts/"
    else
        print_fail "sysctl config not found"
        return 1
    fi
    
    # Check for critical security parameters
    if grep -q "net.ipv4.ip_forward" "artifacts/99-security-hardening.conf"; then
        print_pass "Contains network security parameters"
    fi
    
    if grep -q "kernel.randomize_va_space" "artifacts/99-security-hardening.conf"; then
        print_pass "Contains kernel security parameters"
    fi
}

test_artifacts_documented() {
    print_test "Artifacts are documented"
    
    if [ -f "artifacts/README.md" ]; then
        print_pass "artifacts/README.md exists"
    else
        print_fail "artifacts/README.md not found"
        return 1
    fi
}

test_selinux_knowledge() {
    print_test "SELinux knowledge check (system availability)"
    
    if command_exists getenforce; then
        status=$(getenforce)
        echo "  SELinux detected: $status"
        
        if [ "$status" == "Enforcing" ]; then
            print_pass "SELinux in Enforcing mode (secure)"
        elif [ "$status" == "Permissive" ]; then
            print_skip "SELinux in Permissive mode (should be Enforcing in production)"
        else
            print_skip "SELinux Disabled (consider enabling for production)"
        fi
    elif command_exists aa-status; then
        print_skip "AppArmor detected (Ubuntu alternative to SELinux)"
    else
        print_skip "Neither SELinux nor AppArmor detected"
    fi
}

test_fail2ban_knowledge() {
    print_test "fail2ban knowledge check (system availability)"
    
    if command_exists fail2ban-client; then
        if systemctl is-active --quiet fail2ban 2>/dev/null; then
            jails=$(sudo fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2 | sed 's/,/ /g' | wc -w || echo 0)
            print_pass "fail2ban active with $jails jail(s)"
        else
            print_skip "fail2ban installed but not running"
        fi
    else
        print_skip "fail2ban not installed (install for brute-force protection)"
    fi
}

test_ssh_hardening_knowledge() {
    print_test "SSH configuration security check"
    
    if [ ! -f "/etc/ssh/sshd_config" ]; then
        print_skip "SSH not installed"
        return 0
    fi
    
    # Check PermitRootLogin
    if grep "^PermitRootLogin no" /etc/ssh/sshd_config >/dev/null 2>&1; then
        print_pass "SSH: PermitRootLogin disabled (secure)"
    else
        print_skip "SSH: PermitRootLogin should be 'no' for max security"
    fi
    
    # Check PasswordAuthentication
    if grep "^PasswordAuthentication no" /etc/ssh/sshd_config >/dev/null 2>&1; then
        print_pass "SSH: PasswordAuthentication disabled (key-based only)"
    else
        print_skip "SSH: Consider disabling PasswordAuthentication"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo "========================================"
    echo " EPISODE 28 - SECURITY HARDENING TESTS"
    echo " KERNEL SHADOWS - Season 7"
    echo "========================================"
    echo ""
    
    # Run tests
    test_security_audit_script_exists || true
    test_security_audit_runs || true
    test_selinux_check_implemented || true
    test_auditd_check_implemented || true
    test_fail2ban_check_implemented || true
    test_ssh_config_check_implemented || true
    test_sysctl_security_check_implemented || true
    test_firewall_check_implemented || true
    test_colored_output || true
    test_generates_report || true
    test_script_best_practices || true
    test_sysctl_config_exists || true
    test_artifacts_documented || true
    test_selinux_knowledge || true
    test_fail2ban_knowledge || true
    test_ssh_hardening_knowledge || true
    
    # Summary
    echo ""
    echo "========================================"
    echo " TEST SUMMARY"
    echo "========================================"
    echo -e "Total tests:  $TESTS_TOTAL"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
        echo ""
        echo "🎉 Episode 28 complete! Security hardened."
        echo ""
        echo "🔒 SEASON 7 COMPLETE!"
        echo "   ✅ Episode 25: Kubernetes deployed"
        echo "   ✅ Episode 26: Monitoring active"
        echo "   ✅ Episode 27: Performance optimized"
        echo "   ✅ Episode 28: Security hardened"
        echo ""
        echo "🚀 Infrastructure ready for Season 8: FINAL OPERATION"
        echo "   Next: 72 hours, global attack, everything tested."
        return 0
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo ""
        echo "Hints:"
        echo "1. Implement missing checks in security_audit.sh"
        echo "2. Add all security sections (SELinux, auditd, fail2ban, SSH, sysctl)"
        echo "3. Use colored output (🟢/🟡/🔴)"
        echo "4. Generate report file"
        echo "5. Follow bash best practices"
        return 1
    fi
}

# Change to episode directory if tests are run from tests/
if [ "$(basename $(pwd))" = "tests" ]; then
    cd ..
fi

main "$@"

