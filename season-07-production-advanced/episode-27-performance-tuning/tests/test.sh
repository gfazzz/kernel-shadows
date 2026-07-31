#!/bin/bash
# test.sh - Automated tests for Episode 27: Performance Tuning
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

test_performance_audit_script_exists() {
    print_test "Performance audit script exists"

    if [ -f "performance_audit.sh" ]; then
        print_pass "performance_audit.sh found"
    else
        print_fail "performance_audit.sh not found"
        return 1
    fi

    if [ -x "performance_audit.sh" ]; then
        print_pass "performance_audit.sh is executable"
    else
        print_fail "performance_audit.sh is not executable (run: chmod +x performance_audit.sh)"
        return 1
    fi
}

test_performance_audit_runs() {
    print_test "Performance audit script runs without errors"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    if ./performance_audit.sh &>/dev/null; then
        print_pass "Script executed successfully"
    else
        print_fail "Script execution failed"
        return 1
    fi
}

test_performance_audit_generates_report() {
    print_test "Performance audit generates report file"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    # Run script
    ./performance_audit.sh &>/dev/null || true

    # Check if report file was created
    report_files=(performance_audit_*.txt)
    if [ -f "${report_files[0]}" ]; then
        print_pass "Report file generated: ${report_files[0]}"

        # Check file size (should not be empty)
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

test_cpu_check_implemented() {
    print_test "CPU check is implemented"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    # Run and check output
    output=$(./performance_audit.sh 2>&1 || true)

    if echo "$output" | grep -q "=== CPU PERFORMANCE ==="; then
        print_pass "CPU section found"
    else
        print_fail "CPU section not found"
        return 1
    fi

    if echo "$output" | grep -iq "load"; then
        print_pass "CPU load check present"
    else
        print_fail "CPU load check not implemented"
    fi
}

test_memory_check_implemented() {
    print_test "Memory check is implemented"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    output=$(./performance_audit.sh 2>&1 || true)

    if echo "$output" | grep -q "=== MEMORY PERFORMANCE ==="; then
        print_pass "Memory section found"
    else
        print_fail "Memory section not found"
        return 1
    fi

    if echo "$output" | grep -iq "memory\|mem\|ram"; then
        print_pass "Memory check present"
    else
        print_fail "Memory check not implemented"
    fi
}

test_disk_io_check() {
    print_test "Disk I/O check (if iostat available)"

    if ! command_exists iostat; then
        print_skip "iostat not installed (install sysstat package for full test)"
        return 0
    fi

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    output=$(./performance_audit.sh 2>&1 || true)

    if echo "$output" | grep -q "=== DISK I/O PERFORMANCE ==="; then
        print_pass "Disk I/O section found"
    else
        print_fail "Disk I/O section not found"
    fi
}

test_database_check() {
    print_test "Database check (if database running)"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    output=$(./performance_audit.sh 2>&1 || true)

    if echo "$output" | grep -q "=== DATABASE PERFORMANCE ==="; then
        print_pass "Database section found"
    else
        print_fail "Database section not found"
    fi
}

test_cache_check() {
    print_test "Cache check (if Redis available)"

    if ! command_exists redis-cli; then
        print_skip "Redis not installed"
        return 0
    fi

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    output=$(./performance_audit.sh 2>&1 || true)

    if echo "$output" | grep -q "=== CACHE PERFORMANCE ==="; then
        print_pass "Cache section found"
    else
        print_fail "Cache section not found"
    fi
}

test_sysctl_check() {
    print_test "sysctl settings check"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    output=$(./performance_audit.sh 2>&1 || true)

    if echo "$output" | grep -q "=== SYSCTL SETTINGS ==="; then
        print_pass "sysctl section found"
    else
        print_fail "sysctl section not found"
    fi
}

test_colored_output() {
    print_test "Script uses colored status indicators"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    # Check for emoji or colored output
    if grep -q "🟢\|🟡\|🔴" "performance_audit.sh"; then
        print_pass "Colored status indicators present (🟢/🟡/🔴)"
    else
        print_fail "Colored status indicators not found"
    fi
}

test_threshold_checks() {
    print_test "Script has threshold checks"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    # Check for threshold variables
    if grep -q "THRESHOLD\|threshold" "performance_audit.sh"; then
        print_pass "Threshold checks present"
    else
        print_fail "No threshold checks found"
    fi
}

test_output_formatting() {
    print_test "Output is well formatted"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    output=$(./performance_audit.sh 2>&1 || true)

    # Check for section headers
    section_count=$(echo "$output" | grep -c "===" || echo 0)
    if [ "$section_count" -ge 5 ]; then
        print_pass "Multiple sections found ($section_count sections)"
    else
        print_fail "Insufficient sections ($section_count found, expected >= 5)"
    fi
}

test_script_best_practices() {
    print_test "Script follows bash best practices"

    if [ ! -f "performance_audit.sh" ]; then
        print_skip "performance_audit.sh not found"
        return 0
    fi

    # Check for shebang
    if head -1 "performance_audit.sh" | grep -q "^#!/bin/bash"; then
        print_pass "Shebang present"
    else
        print_fail "Shebang missing or incorrect"
    fi

    # Check for set -euo pipefail (or at least set -e)
    if grep -q "set -e" "performance_audit.sh"; then
        print_pass "Error handling enabled (set -e)"
    else
        print_fail "No error handling (missing set -e)"
    fi

    # Check for functions
    if grep -q "^[a-z_]*() {" "performance_audit.sh"; then
        print_pass "Functions defined"
    else
        print_fail "No functions found"
    fi
}

test_system_tools_available() {
    print_test "Required system tools availability"

    local tools=("top" "free" "uptime" "sysctl")
    local missing=0

    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            print_pass "$tool available"
        else
            print_fail "$tool not found"
            ((missing++))
        fi
    done

    if [ $missing -gt 0 ]; then
        return 1
    fi
}

test_optional_tools() {
    print_test "Optional performance tools"

    local tools=("iostat" "vmstat" "perf" "htop" "iotop")
    local installed=0

    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            echo -e "  ${GREEN}✓${NC} $tool available"
            ((installed++))
        else
            echo -e "  ${YELLOW}!${NC} $tool not installed (optional)"
        fi
    done

    if [ $installed -gt 0 ]; then
        print_pass "$installed optional tools available"
    else
        print_skip "No optional tools installed (install sysstat, linux-tools-generic packages)"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo "========================================"
    echo " EPISODE 27 - PERFORMANCE TUNING TESTS"
    echo " KERNEL SHADOWS - Season 7"
    echo "========================================"
    echo ""

    # Run tests
    test_performance_audit_script_exists || true
    test_performance_audit_runs || true
    test_performance_audit_generates_report || true
    test_cpu_check_implemented || true
    test_memory_check_implemented || true
    test_disk_io_check || true
    test_database_check || true
    test_cache_check || true
    test_sysctl_check || true
    test_colored_output || true
    test_threshold_checks || true
    test_output_formatting || true
    test_script_best_practices || true
    test_system_tools_available || true
    test_optional_tools || true

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
        echo "🎉 Episode 27 complete! Performance audit script готов."
        echo "   Next: Episode 28 - Security Hardening"
        return 0
    else
        echo -e "${RED}❌ SOME TESTS FAILED${NC}"
        echo ""
        echo "Hints:"
        echo "1. Implement missing checks in performance_audit.sh"
        echo "2. Make sure script is executable: chmod +x performance_audit.sh"
        echo "3. Add colored output (🟢/🟡/🔴) for status indicators"
        echo "4. Use functions for each check"
        echo "5. Add threshold checks and comparisons"
        return 1
    fi
}

# Change to episode directory if tests are run from tests/
if [ "$(basename $(pwd))" = "tests" ]; then
    cd ..
fi

main "$@"

