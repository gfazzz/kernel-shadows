#!/bin/bash

# ═══════════════════════════════════════════════════════════
# KERNEL SHADOWS - Season 8, Episode 30
# Test Suite: Eye of the Storm
# ═══════════════════════════════════════════════════════════

set -e

EPISODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$EPISODE_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test function
test_case() {
    local description="$1"
    local command="$2"
    local expected_exit="${3:-0}"

    TOTAL_TESTS=$((TOTAL_TESTS + 1))

    printf "  Testing: %-50s " "$description"

    if eval "$command" >/dev/null 2>&1; then
        actual_exit=0
    else
        actual_exit=$?
    fi

    if [[ $actual_exit -eq $expected_exit ]]; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "${RED}FAIL${NC} (exit code: $actual_exit, expected: $expected_exit)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

test_file_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    test_case "$description" "grep -q '$pattern' '$file'"
}

test_file_exists() {
    local file="$1"
    local description="$2"

    test_case "$description" "test -f '$file'"
}

# ═══════════════════════════════════════════════════════════
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Episode 30: Eye of the Storm — TEST SUITE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ───────────────────────────────────────────────────────────────
echo "[1] File Structure Tests"
echo "───────────────────────────────────────────────────────────"

test_file_exists "README.md" "README exists"
test_file_exists "starter.sh" "Starter script exists"
test_file_exists "solution/security_audit_day58.sh" "Solution script exists"
test_file_exists "artifacts/README.md" "Artifacts README exists"
test_file_exists "tests/test.sh" "Test script exists"

test_case "Starter is executable" "test -x starter.sh"
test_case "Solution is executable" "test -x solution/security_audit_day58.sh"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[2] Artifacts Tests"
echo "───────────────────────────────────────────────────────────"

test_file_exists "artifacts/forensics/aide_anomalies.txt" "AIDE anomalies file exists"
test_file_exists "artifacts/docker/compromised_images.txt" "Compromised images list exists"
test_file_exists "artifacts/docker/official_digests.txt" "Official digests file exists"
test_file_exists "artifacts/threat_intel/suspicious_ips.txt" "Suspicious IPs file exists"
test_file_exists "artifacts/threat_intel/ip_classification.txt" "IP classification file exists"
test_file_exists "artifacts/threat_intel/c2_server.txt" "C2 server file exists"
test_file_exists "artifacts/logs/selinux_violations.log" "SELinux violations log exists"
test_file_exists "artifacts/logs/fail2ban_banned_ips.txt" "Fail2ban banned IPs file exists"

# Check artifact contents
test_file_contains "artifacts/docker/compromised_images.txt" "viktor/crypto-toolkit" "Compromised image listed"
test_file_contains "artifacts/threat_intel/c2_server.txt" "195.123.221.47" "C2 server IP present"
test_file_contains "artifacts/threat_intel/ip_classification.txt" "TOR\|Botnet\|VPN" "IP classifications present"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[3] Solution Script Tests"
echo "───────────────────────────────────────────────────────────"

test_case "Solution has shebang" "head -1 solution/security_audit_day58.sh | grep -q '^#!/bin/bash'"
test_file_contains "solution/security_audit_day58.sh" "check_docker_integrity" "Docker integrity function exists"
test_file_contains "solution/security_audit_day58.sh" "check_aide" "AIDE check function exists"
test_file_contains "solution/security_audit_day58.sh" "check_selinux_violations" "SELinux check function exists"
test_file_contains "solution/security_audit_day58.sh" "check_fail2ban_stats" "Fail2ban stats function exists"
test_file_contains "solution/security_audit_day58.sh" "aggregate_threat_intel" "Threat intel function exists"
test_file_contains "solution/security_audit_day58.sh" "generate_final_report" "Report generation function exists"
test_file_contains "solution/security_audit_day58.sh" "set -e" "Error handling present"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[4] README Content Tests"
echo "───────────────────────────────────────────────────────────"

test_file_contains "README.md" "День 58" "README mentions Day 58"
test_file_contains "README.md" "Око бури" "README has episode title"
test_file_contains "README.md" "LILITH" "README includes LILITH character"
test_file_contains "README.md" "Anna Kovaleva" "README mentions Anna"
test_file_contains "README.md" "Marcus Weber" "README mentions Marcus Weber case"
test_file_contains "README.md" "Docker.*supply chain\|цепочка поставок" "README covers supply chain attack"
test_file_contains "README.md" "AIDE" "README covers AIDE"
test_file_contains "README.md" "SELinux" "README covers SELinux"
test_file_contains "README.md" "Fail2ban" "README covers Fail2ban"
test_file_contains "README.md" "The Architect\|Архитектор" "README mentions The Architect"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[5] Integration Test (Solution Execution)"
echo "───────────────────────────────────────────────────────────"

# Create temporary test environment
TEST_LOG="/tmp/episode30_test_audit.log"
TEST_REPORT="/tmp/episode30_test_report.md"
rm -f "$TEST_LOG" "$TEST_REPORT"

# Override solution paths for testing
export LOG_FILE="$TEST_LOG"
export REPORT_FILE="$TEST_REPORT"

test_case "Solution executes without errors" "./solution/security_audit_day58.sh"
test_case "Log file created" "test -f reports/day58_security_audit.md"
test_case "Report file created" "test -f reports/day58_security_audit.md"

if [[ -f "reports/day58_security_audit.md" ]]; then
    test_file_contains "reports/day58_security_audit.md" "Security Audit Report" "Report has title"
    test_file_contains "reports/day58_security_audit.md" "Docker Image Integrity" "Report has Docker section"
    test_file_contains "reports/day58_security_audit.md" "AIDE.*Scan\|Integrity" "Report has AIDE section"
    test_file_contains "reports/day58_security_audit.md" "SELinux" "Report has SELinux section"
    test_file_contains "reports/day58_security_audit.md" "Fail2ban" "Report has Fail2ban section"
    test_file_contains "reports/day58_security_audit.md" "Threat Intelligence" "Report has threat intel section"
    test_file_contains "reports/day58_security_audit.md" "Recommendations\|Day 59" "Report has recommendations"
fi

echo ""

# ═══════════════════════════════════════════════════════════
echo "═══════════════════════════════════════════════════════════"
echo " TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Total tests: $TOTAL_TESTS"
echo -e "  ${GREEN}Passed: $PASSED_TESTS${NC}"
echo -e "  ${RED}Failed: $FAILED_TESTS${NC}"
echo ""

PASS_RATE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
echo "  Pass rate: $PASS_RATE%"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    echo -e "${GREEN}✅ EXCELLENT!${NC} Episode 30 готов к использованию."
    echo ""
    echo "*'Investigation complete. Infrastructure hardened. Ready for Day 59.'*"
    echo "— LILITH v8.0"
elif [[ $PASS_RATE -ge 80 ]]; then
    echo -e "${YELLOW}⚠️  GOOD${NC}, но есть недочёты. Проверь failed tests."
    echo ""
    echo "*'Most systems operational. Review failures before Day 59.'*"
    echo "— LILITH v8.0"
else
    echo -e "${RED}❌ NEEDS WORK${NC}. Критические проблемы обнаружены."
    echo ""
    echo "*'Critical issues detected. Fix before proceeding.'*"
    echo "— LILITH v8.0"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"

exit 0

