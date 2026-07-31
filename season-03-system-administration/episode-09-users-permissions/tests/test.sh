#!/bin/bash

################################################################################
# EPISODE 09: USERS & PERMISSIONS - AUTOMATED TESTS
# Season 3: System Administration
#
# This script tests the implementation of Episode 09
################################################################################

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Expected configuration
TEAM_USERS=("viktor" "alex" "anna" "dmitry")
SHARED_DIR="/var/operations/shared"
REPORT_FILE="/var/operations/security_audit_ep09.txt"

################################################################################
# Helper Functions
################################################################################

pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((TESTS_PASSED++))
    ((TESTS_TOTAL++))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((TESTS_FAILED++))
    ((TESTS_TOTAL++))
}

skip() {
    echo -e "${YELLOW}⊘ SKIP${NC}: $1"
}

section() {
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

################################################################################
# Test Category 1: File Structure
################################################################################

test_file_structure() {
    section "Test Category 1: File Structure"

    # Check if starter.sh exists
    if [[ -f "../starter.sh" ]]; then
        pass "starter.sh exists"
    else
        fail "starter.sh not found"
    fi

    # Check if solution exists
    if [[ -f "../solution/user_management.sh" ]]; then
        pass "solution/user_management.sh exists"
    else
        fail "solution/user_management.sh not found"
    fi

    # Check if artifacts exist
    if [[ -d "../artifacts" ]]; then
        pass "artifacts/ directory exists"
    else
        fail "artifacts/ directory not found"
    fi

    # Check if scripts are executable
    if [[ -x "../starter.sh" ]] || [[ -x "../solution/user_management.sh" ]]; then
        pass "Scripts have execute permission"
    else
        fail "Scripts are not executable"
    fi

    # Check shebang
    if grep -q "^#!/bin/bash" "../starter.sh"; then
        pass "starter.sh has correct shebang"
    else
        fail "starter.sh missing or incorrect shebang"
    fi
}

################################################################################
# Test Category 2: User Creation
################################################################################

test_user_creation() {
    section "Test Category 2: User Creation"

    for user in "${TEAM_USERS[@]}"; do
        if id "$user" &>/dev/null; then
            pass "User $user exists"

            # Check home directory
            local home_dir=$(getent passwd "$user" | cut -d: -f6)
            if [[ -d "$home_dir" ]]; then
                pass "Home directory exists for $user: $home_dir"
            else
                fail "Home directory missing for $user"
            fi

            # Check shell
            local user_shell=$(getent passwd "$user" | cut -d: -f7)
            if [[ "$user_shell" == "/bin/bash" ]]; then
                pass "Correct shell for $user: /bin/bash"
            else
                fail "Wrong shell for $user: $user_shell (expected /bin/bash)"
            fi
        else
            skip "User $user does not exist (run solution first)"
        fi
    done

    # Check for suspicious UID 0 accounts
    local suspicious=$(awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd)
    if [[ -z "$suspicious" ]]; then
        pass "No suspicious UID 0 accounts found"
    else
        fail "Suspicious UID 0 accounts found: $suspicious"
    fi
}

################################################################################
# Test Category 3: Groups & Membership
################################################################################

test_groups() {
    section "Test Category 3: Groups & Membership"

    # Expected groups
    local groups=("operations" "security" "forensics" "devops" "netadmin")

    for group in "${groups[@]}"; do
        if getent group "$group" &>/dev/null; then
            pass "Group $group exists"
        else
            skip "Group $group does not exist (run solution first)"
        fi
    done

    # Check group memberships (if users exist)
    if id "viktor" &>/dev/null; then
        if groups viktor | grep -q "operations"; then
            pass "Viktor is member of operations group"
        else
            fail "Viktor not in operations group"
        fi
    fi

    if id "alex" &>/dev/null; then
        if groups alex | grep -q "security" && groups alex | grep -q "netadmin"; then
            pass "Alex is member of security and netadmin groups"
        else
            fail "Alex missing required group memberships"
        fi
    fi

    if id "anna" &>/dev/null; then
        if groups anna | grep -q "security" && groups anna | grep -q "forensics"; then
            pass "Anna is member of security and forensics groups"
        else
            fail "Anna missing required group memberships"
        fi
    fi

    if id "dmitry" &>/dev/null; then
        if groups dmitry | grep -q "operations" && groups dmitry | grep -q "devops"; then
            pass "Dmitry is member of operations and devops groups"
        else
            fail "Dmitry missing required group memberships"
        fi
    fi
}

################################################################################
# Test Category 4: Shared Directory Permissions
################################################################################

test_shared_directory() {
    section "Test Category 4: Shared Directory Permissions"

    if [[ -d "$SHARED_DIR" ]]; then
        pass "Shared directory exists: $SHARED_DIR"

        # Check owner and group
        local owner=$(stat -c '%U' "$SHARED_DIR" 2>/dev/null)
        local group=$(stat -c '%G' "$SHARED_DIR" 2>/dev/null)

        if [[ "$owner" == "viktor" ]]; then
            pass "Correct owner: viktor"
        else
            fail "Wrong owner: $owner (expected viktor)"
        fi

        if [[ "$group" == "operations" ]]; then
            pass "Correct group: operations"
        else
            fail "Wrong group: $group (expected operations)"
        fi

        # Check permissions
        local perms=$(stat -c '%a' "$SHARED_DIR" 2>/dev/null)
        if [[ "$perms" == "3770" ]]; then
            pass "Correct permissions: 3770 (sticky bit + SGID)"
        else
            fail "Wrong permissions: $perms (expected 3770)"
        fi

        # Check sticky bit
        if [[ -k "$SHARED_DIR" ]]; then
            pass "Sticky bit is set (T)"
        else
            fail "Sticky bit not set"
        fi

        # Check SGID
        local ls_output=$(ls -ld "$SHARED_DIR")
        if [[ "$ls_output" =~ "rws" ]]; then
            pass "SGID bit is set (s)"
        else
            fail "SGID bit not set"
        fi
    else
        skip "Shared directory does not exist (run solution first)"
    fi
}

################################################################################
# Test Category 5: sudo Configuration (Alex)
################################################################################

test_sudo_alex() {
    section "Test Category 5: sudo Configuration (Alex)"

    local sudoers_file="/etc/sudoers.d/alex"

    if [[ -f "$sudoers_file" ]]; then
        pass "sudo configuration file exists for Alex"

        # Check permissions (should be 440 or 640)
        local perms=$(stat -c '%a' "$sudoers_file" 2>/dev/null)
        if [[ "$perms" == "440" ]] || [[ "$perms" == "640" ]]; then
            pass "Correct permissions on sudoers file: $perms"
        else
            fail "Wrong permissions on sudoers file: $perms"
        fi

        # Check syntax
        if sudo visudo -c -f "$sudoers_file" &>/dev/null; then
            pass "sudoers file syntax is valid"
        else
            fail "sudoers file has syntax errors"
        fi

        # Check if file contains NETCMDS or network commands
        if sudo grep -q "NETCMDS\|ip.*ss.*iptables" "$sudoers_file"; then
            pass "Network commands configured for Alex"
        else
            fail "Network commands not found in Alex's sudo config"
        fi

        # Check for NOPASSWD
        if sudo grep -q "NOPASSWD" "$sudoers_file"; then
            pass "NOPASSWD configured for Alex"
        else
            fail "NOPASSWD not configured"
        fi
    else
        skip "sudo configuration file for Alex does not exist (run solution first)"
    fi
}

################################################################################
# Test Category 6: ACL Configuration (Anna)
################################################################################

test_acl_anna() {
    section "Test Category 6: ACL Configuration (Anna)"

    # Check if ACL tools are installed
    if ! command -v getfacl &>/dev/null; then
        skip "ACL tools not installed (install with: sudo apt-get install acl)"
        return
    fi

    # Check ACL on /var/log
    if getfacl /var/log 2>/dev/null | grep -q "user:anna:r"; then
        pass "ACL set for Anna on /var/log"
    else
        skip "ACL for Anna not set on /var/log (run solution first)"
    fi

    # Check ACL on specific log files
    local logs=("/var/log/auth.log" "/var/log/syslog")

    for log_file in "${logs[@]}"; do
        if [[ -f "$log_file" ]]; then
            if getfacl "$log_file" 2>/dev/null | grep -q "user:anna:r"; then
                pass "ACL set for Anna on $log_file"
            else
                skip "ACL for Anna not set on $log_file (run solution first)"
            fi
        else
            skip "$log_file does not exist"
        fi
    done
}

################################################################################
# Test Category 7: Security Audit (SUID/SGID)
################################################################################

test_security_audit() {
    section "Test Category 7: Security Audit (SUID/SGID)"

    # Check if SUID audit was performed
    if [[ -f "/tmp/suid_sgid_audit.txt" ]]; then
        pass "SUID/SGID audit file exists"

        # Check if file has content
        if [[ -s "/tmp/suid_sgid_audit.txt" ]]; then
            pass "SUID/SGID audit file has content"
        else
            fail "SUID/SGID audit file is empty"
        fi
    else
        skip "SUID/SGID audit file not found (run solution first)"
    fi

    # Find SUID files in suspicious locations
    local suspicious_suid=$(find /tmp /home -perm -4000 -type f 2>/dev/null)
    if [[ -z "$suspicious_suid" ]]; then
        pass "No suspicious SUID files in /tmp or /home"
    else
        fail "Suspicious SUID files found: $suspicious_suid"
    fi
}

################################################################################
# Test Category 8: Final Security Report
################################################################################

test_security_report() {
    section "Test Category 8: Final Security Report"

    if [[ -f "$REPORT_FILE" ]]; then
        pass "Security audit report exists"

        # Check if file is not empty
        if [[ -s "$REPORT_FILE" ]]; then
            pass "Security audit report has content"
        else
            fail "Security audit report is empty"
        fi

        # Check permissions
        local perms=$(stat -c '%a' "$REPORT_FILE" 2>/dev/null)
        if [[ "$perms" == "640" ]]; then
            pass "Correct permissions on report: 640"
        else
            fail "Wrong permissions on report: $perms (expected 640)"
        fi

        # Check owner and group
        local owner=$(stat -c '%U' "$REPORT_FILE" 2>/dev/null)
        local group=$(stat -c '%G' "$REPORT_FILE" 2>/dev/null)

        if [[ "$owner" == "viktor" ]] || [[ "$owner" == "root" ]]; then
            pass "Report owner is viktor or root"
        else
            fail "Report owner is $owner (expected viktor)"
        fi

        if [[ "$group" == "operations" ]] || [[ "$group" == "root" ]]; then
            pass "Report group is operations or root"
        else
            fail "Report group is $group (expected operations)"
        fi

        # Check report content
        local required_sections=(
            "USERS CREATED"
            "GROUPS"
            "SUDO CONFIGURATION"
            "ACL CONFIGURATION"
            "SHARED DIRECTORY"
            "SUID/SGID"
            "RECOMMENDATIONS"
        )

        for section_name in "${required_sections[@]}"; do
            if grep -q "$section_name" "$REPORT_FILE"; then
                pass "Report contains section: $section_name"
            else
                fail "Report missing section: $section_name"
            fi
        done
    else
        skip "Security audit report not found (run solution first)"
    fi
}

################################################################################
# Test Category 9: Script Execution
################################################################################

test_script_execution() {
    section "Test Category 9: Script Execution"

    # Test starter.sh syntax
    if bash -n "../starter.sh" 2>/dev/null; then
        pass "starter.sh has valid Bash syntax"
    else
        fail "starter.sh has syntax errors"
    fi

    # Test solution syntax
    if bash -n "../solution/user_management.sh" 2>/dev/null; then
        pass "solution/user_management.sh has valid Bash syntax"
    else
        fail "solution/user_management.sh has syntax errors"
    fi

    # Check for set -e (exit on error)
    if grep -q "set -e" "../solution/user_management.sh"; then
        pass "Solution uses 'set -e' (exit on error)"
    else
        fail "Solution does not use 'set -e'"
    fi
}

################################################################################
# Test Category 10: README & Documentation
################################################################################

test_documentation() {
    section "Test Category 10: README & Documentation"

    # Check README exists
    if [[ -f "../README.md" ]]; then
        pass "README.md exists"

        # Check README size (should be substantial)
        local readme_size=$(wc -l < "../README.md" 2>/dev/null)
        if [[ $readme_size -gt 500 ]]; then
            pass "README.md is comprehensive ($readme_size lines)"
        else
            fail "README.md is too short ($readme_size lines)"
        fi

        # Check for key sections
        local sections=(
            "Сюжет"
            "Задания"
            "Теория"
            "LILITH"
        )

        for section in "${sections[@]}"; do
            if grep -q "$section" "../README.md"; then
                pass "README contains section: $section"
            else
                fail "README missing section: $section"
            fi
        done
    else
        fail "README.md not found"
    fi

    # Check artifacts README
    if [[ -f "../artifacts/README.md" ]]; then
        pass "artifacts/README.md exists"
    else
        fail "artifacts/README.md not found"
    fi
}

################################################################################
# Integration Tests
################################################################################

test_integration() {
    section "Integration Tests"

    # Test 1: Can Alex run network commands via sudo? (simulation)
    if [[ -f "/etc/sudoers.d/alex" ]] && id "alex" &>/dev/null; then
        if sudo -u alex sudo -l 2>/dev/null | grep -q "ip\|ss\|iptables"; then
            pass "Alex can run network commands via sudo"
        else
            skip "Unable to verify Alex's sudo access (may require actual user session)"
        fi
    fi

    # Test 2: Can Anna read logs? (ACL simulation)
    if command -v getfacl &>/dev/null && id "anna" &>/dev/null; then
        if getfacl /var/log 2>/dev/null | grep -q "user:anna"; then
            pass "Anna has ACL access to logs"
        else
            skip "Anna's ACL access not configured"
        fi
    fi

    # Test 3: Shared directory group inheritance (SGID)
    if [[ -d "$SHARED_DIR" ]]; then
        local ls_output=$(ls -ld "$SHARED_DIR")
        if [[ "$ls_output" =~ "rws" ]]; then
            pass "Shared directory SGID ensures group inheritance"
        else
            fail "Shared directory SGID not set"
        fi
    fi
}

################################################################################
# Main Test Runner
################################################################################

main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  EPISODE 09: USERS & PERMISSIONS - TEST SUITE             ║${NC}"
    echo -e "${BLUE}║  Running automated tests...                                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo

    # Run all test categories
    test_file_structure
    test_user_creation
    test_groups
    test_shared_directory
    test_sudo_alex
    test_acl_anna
    test_security_audit
    test_security_report
    test_script_execution
    test_documentation
    test_integration

    # Final summary
    echo
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}TEST SUMMARY${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo
    echo "Total tests run: $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo

    # Calculate percentage
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        local percentage=$((TESTS_PASSED * 100 / TESTS_TOTAL))
        echo "Success rate: $percentage%"
        echo

        if [[ $TESTS_FAILED -eq 0 ]]; then
            echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${GREEN}║  ALL TESTS PASSED! 🎉                                      ║${NC}"
            echo -e "${GREEN}║                                                            ║${NC}"
            echo -e "${GREEN}║  Andrei Volkov: 'Отлично, Макс. Permissions настроены     ║${NC}"
            echo -e "${GREEN}║  правильно. Root access — это ответственность.'            ║${NC}"
            echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
            exit 0
        elif [[ $percentage -ge 80 ]]; then
            echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${YELLOW}║  GOOD PROGRESS! Most tests passed.                         ║${NC}"
            echo -e "${YELLOW}║  Fix the failing tests and try again.                      ║${NC}"
            echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}"
            exit 1
        else
            echo -e "${RED}╔════════════════════════════════════════════════════════════╗${NC}"
            echo -e "${RED}║  NEEDS IMPROVEMENT!                                        ║${NC}"
            echo -e "${RED}║  Review the README and fix the failing tests.              ║${NC}"
            echo -e "${RED}╚════════════════════════════════════════════════════════════╝${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}No tests executed.${NC}"
        exit 1
    fi
}

# Run main function
main "$@"

