#!/bin/bash
# EPISODE 29 TESTS
# Automated testing for student solutions

set -e

EPISODE="Episode 29: The Storm Begins"
PASSED=0
FAILED=0
TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ═══════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════

test_case() {
    local name="$1"
    local command="$2"
    local expected_exit_code="${3:-0}"

    TOTAL=$((TOTAL + 1))

    echo -n "  Testing: $name ... "

    if eval "$command" &>/dev/null; then
        actual_exit_code=0
    else
        actual_exit_code=$?
    fi

    if [[ $actual_exit_code -eq $expected_exit_code ]]; then
        echo -e "${GREEN}PASS${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} (exit code: $actual_exit_code, expected: $expected_exit_code)"
        FAILED=$((FAILED + 1))
    fi
}

test_file_exists() {
    local file="$1"
    local description="$2"

    test_case "$description" "[[ -f '$file' ]]"
}

test_file_executable() {
    local file="$1"
    local description="$2"

    test_case "$description" "[[ -x '$file' ]]"
}

test_file_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"

    test_case "$description" "grep -q '$pattern' '$file'"
}

# ═══════════════════════════════════════════════════════════════
# TESTS
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo " $EPISODE — AUTOMATED TESTS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# ───────────────────────────────────────────────────────────────
echo "[1] Artifacts Tests"
echo "───────────────────────────────────────────────────────────"

test_file_exists "artifacts/README.md" "Artifacts README exists"
test_file_exists "artifacts/monitoring/lilith_alerts.txt" "LILITH alerts log exists"
test_file_exists "artifacts/forensics/backdoor_analysis.txt" "Backdoor analysis report exists"

test_file_contains "artifacts/monitoring/lilith_alerts.txt" "P1 CRITICAL" "LILITH alerts contain P1 CRITICAL"
test_file_contains "artifacts/monitoring/lilith_alerts.txt" "DDoS" "LILITH alerts mention DDoS"
test_file_contains "artifacts/monitoring/lilith_alerts.txt" "backdoor" "LILITH alerts mention backdoors"

test_file_contains "artifacts/forensics/backdoor_analysis.txt" "195.123.221.47" "Forensics report contains C2 IP"
test_file_contains "artifacts/forensics/backdoor_analysis.txt" "supply chain" "Forensics report mentions supply chain"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[2] Solution Tests"
echo "───────────────────────────────────────────────────────────"

test_file_exists "solution/night_shift_response.sh" "Night shift response script exists"
test_file_executable "solution/night_shift_response.sh" "Night shift script is executable"

test_file_contains "solution/night_shift_response.sh" "#!/bin/bash" "Script has shebang"
test_file_contains "solution/night_shift_response.sh" "set -e" "Script uses error handling"
test_file_contains "solution/night_shift_response.sh" "forensics" "Script includes forensics collection"
test_file_contains "solution/night_shift_response.sh" "iptables" "Script includes firewall blocking"
test_file_contains "solution/night_shift_response.sh" "kill" "Script includes process termination"
test_file_contains "solution/night_shift_response.sh" "log_decision" "Script includes decision logging"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[3] Integration Tests"
echo "───────────────────────────────────────────────────────────"

# Test: Can extract alerts by priority
test_case "Extract P1 alerts" "grep -q 'P1 CRITICAL' artifacts/monitoring/lilith_alerts.txt"

# Test: Can find backdoor PIDs
test_case "Find backdoor PIDs in forensics" "grep -E '8472|3291|9845' artifacts/forensics/backdoor_analysis.txt"

# Test: Can identify C2 server
test_case "Identify C2 server IP" "grep -q '195.123.221.47' artifacts/forensics/backdoor_analysis.txt"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[4] Concept Understanding Tests (README.md content)"
echo "───────────────────────────────────────────────────────────"

test_file_contains "README.md" "атак.*отказ" "README covers DDoS mitigation"
test_file_contains "README.md" "нулевого дня" "README covers zero-day response"
test_file_contains "README.md" "бэкдор" "README covers APT backdoors"
test_file_contains "README.md" "масштабирование" "README covers Kubernetes scaling"
test_file_contains "README.md" "координация" "README covers team coordination"

# Check for interleaving structure
test_file_contains "README.md" "ЧАСТЬ" "README uses part structure"
test_file_contains "README.md" "объясняет" "README includes story sections"
test_file_contains "README.md" "Команда" "README includes theory sections"
test_file_contains "README.md" "bash" "README includes practice sections"

# Check for LILITH voice
test_file_contains "README.md" "LILITH" "README includes LILITH character"

echo ""

# ───────────────────────────────────────────────────────────────
echo "[5] Best Practices Tests"
echo "───────────────────────────────────────────────────────────"

# Check solution script best practices
if [[ -f "solution/night_shift_response.sh" ]]; then
    # Shebang present
    test_case "Solution: Shebang present" "head -n1 solution/night_shift_response.sh | grep -q '^#!/bin/bash'"

    # Variables quoted
    test_case "Solution: Uses quoted variables" "grep -q '\"\$' solution/night_shift_response.sh"

    # Error handling
    test_case "Solution: Error handling (set -e)" "grep -q 'set -e' solution/night_shift_response.sh"

    # Comments present
    test_case "Solution: Has comments" "grep -q '^#' solution/night_shift_response.sh"
fi

echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo "═══════════════════════════════════════════════════════════"
echo " TEST SUMMARY"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "  Total tests: $TOTAL"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

PASS_RATE=$((PASSED * 100 / TOTAL))
echo "  Pass rate: $PASS_RATE%"
echo ""

if [[ $PASS_RATE -ge 90 ]]; then
    echo -e "${GREEN}✅ EXCELLENT!${NC} Episode 29 готов к использованию."
    echo ""
    echo "*'Infrastructure holding. Scripts working. Quality высокий.'*"
    echo "— LILITH v8.0"
elif [[ $PASS_RATE -ge 70 ]]; then
    echo -e "${YELLOW}⚠️  GOOD${NC}, но есть недочёты. Проверь failed tests."
    echo ""
    echo "*'Functional но не ideal. Fix warnings перед release.'*"
    echo "— LILITH v8.0"
else
    echo -e "${RED}❌ CRITICAL ISSUES${NC}. Требуется доработка."
    echo ""
    echo "*'Too many failures. Episode не готов. Debug required.'*"
    echo "— LILITH v8.0"
    exit 1
fi

echo "═══════════════════════════════════════════════════════════"

# Exit with appropriate code
if [[ $FAILED -eq 0 ]]; then
    exit 0
else
    exit 1
fi

