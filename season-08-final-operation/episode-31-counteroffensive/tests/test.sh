#!/bin/bash

# ═══════════════════════════════════════════════════════════
# KERNEL SHADOWS - Season 8, Episode 31
# Test Suite: Counteroffensive
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
echo -e "${BLUE} Episode 31: Counteroffensive — TEST SUITE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# ───────────────────────────────────────────────────────────────
echo "[1] File Structure Tests"
echo "───────────────────────────────────────────────────────────"

test_file_exists "README.md" "README exists"
test_file_exists "starter/offensive_report_day59.sh" "Starter script exists"
test_file_exists "solution/offensive_report_day59.sh" "Solution script exists"
test_file_exists "artifacts/README.md" "Artifacts README exists"
test_file_exists "tests/test.sh" "Test script exists"

test_case "Starter is executable" "test -x starter/offensive_report_day59.sh"
test_case "Solution is executable" "test -x solution/offensive_report_day59.sh"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[2] Artifacts Tests"
echo "───────────────────────────────────────────────────────────"

test_file_exists "artifacts/offensive/c2_nmap_scan.txt" "nmap scan exists"
test_file_exists "artifacts/offensive/hydra_bruteforce.log" "Hydra log exists"
test_file_exists "artifacts/offensive/database_schema.sql" "Database schema exists"
test_file_exists "artifacts/offensive/botnet_cleanup.log" "Botnet cleanup log exists"

# Check artifact contents
test_file_contains "artifacts/offensive/c2_nmap_scan.txt" "195.123.221.47" "nmap has target IP"
test_file_contains "artifacts/offensive/c2_nmap_scan.txt" "5432.*postgresql" "PostgreSQL detected"
test_file_contains "artifacts/offensive/hydra_bruteforce.log" "Architect2025" "Password found"
test_file_contains "artifacts/offensive/database_schema.sql" "Кирилл Соболев" "The Architect in schema"
test_file_contains "artifacts/offensive/botnet_cleanup.log" "4,892" "Botnet cleanup stats"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[3] Solution Script Tests"
echo "───────────────────────────────────────────────────────────"

test_case "Solution has shebang" "head -1 solution/offensive_report_day59.sh | grep -q '^#!/bin/bash'"
test_file_contains "solution/offensive_report_day59.sh" "generate_c2_report" "C2 report function exists"
test_file_contains "solution/offensive_report_day59.sh" "generate_botnet_report" "Botnet report function exists"
test_file_contains "solution/offensive_report_day59.sh" "generate_infrastructure_report" "Infrastructure report function"
test_file_contains "solution/offensive_report_day59.sh" "generate_ethical_disclosure_checklist" "Ethical checklist function"
test_file_contains "solution/offensive_report_day59.sh" "generate_lessons_learned" "Lessons learned function"
test_file_contains "solution/offensive_report_day59.sh" "set -e" "Error handling present"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[4] README Content Tests"
echo "───────────────────────────────────────────────────────────"

test_file_contains "README.md" "День 59\|Day 59" "README mentions Day 59"
test_file_contains "README.md" "Контрнаступление\|Counteroffensive" "README has episode title"
test_file_contains "README.md" "LILITH" "README includes LILITH"
test_file_contains "README.md" "Alex Sokolov" "README mentions Alex"
test_file_contains "README.md" "Кирилл Соболев" "README mentions The Architect"
test_file_contains "README.md" "nmap" "README covers nmap"
test_file_contains "README.md" "hydra\|bruteforce\|брутфорс" "README covers bruteforce"
test_file_contains "README.md" "PostgreSQL" "README covers PostgreSQL"
test_file_contains "README.md" "ботнет\|botnet" "README covers botnet"
test_file_contains "README.md" "Ansible" "README covers Ansible"
test_file_contains "README.md" "этич\|ethical\|responsible disclosure" "README covers ethics"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[5] Integration Test (Solution Execution)"
echo "───────────────────────────────────────────────────────────"

# Clean previous test results
rm -rf reports/day59 2>/dev/null || true

test_case "Solution executes without errors" "./solution/offensive_report_day59.sh"
test_case "Report file created" "test -f reports/day59/offensive_operation_day59.md"

if [[ -f "reports/day59/offensive_operation_day59.md" ]]; then
    REPORT="reports/day59/offensive_operation_day59.md"
    test_file_contains "$REPORT" "Offensive Operations Report" "Report has title"
    test_file_contains "$REPORT" "C2 Server Penetration" "Report has C2 section"
    test_file_contains "$REPORT" "Botnet Neutralization" "Report has botnet section"
    test_file_contains "$REPORT" "Infrastructure Shutdown" "Report has infrastructure section"
    test_file_contains "$REPORT" "Ethical Disclosure" "Report has ethics section"
    test_file_contains "$REPORT" "Lessons Learned" "Report has lessons section"
    test_file_contains "$REPORT" "195.123.221.47" "Report mentions target IP"
    test_file_contains "$REPORT" "Кирилл Соболев" "Report mentions The Architect"
    test_file_contains "$REPORT" "4,892" "Report has botnet stats"
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
    echo -e "${GREEN}✅ EXCELLENT!${NC} Episode 31 готов к использованию."
    echo ""
    echo "*'Offensive operations documented. Evidence secured. Ready for Day 60.'*"
    echo "— Alex Sokolov"
elif [[ $PASS_RATE -ge 80 ]]; then
    echo -e "${YELLOW}⚠️  GOOD${NC}, но есть недочёты. Проверь failed tests."
    echo ""
    echo "*'Most evidence collected. Review failures before final stand.'*"
    echo "— Alex Sokolov"
else
    echo -e "${RED}❌ NEEDS WORK${NC}. Критические проблемы обнаружены."
    echo ""
    echo "*'Insufficient evidence. Fix before Day 60 confrontation.'*"
    echo "— Alex Sokolov"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"

exit 0

