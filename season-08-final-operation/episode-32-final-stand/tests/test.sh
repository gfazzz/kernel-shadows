#!/bin/bash
# Episode 32 Tests - FINALE

set -e
EPISODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$EPISODE_DIR"

RED='\033[0;31m'; GREEN='\033[0;32m'; BLUE='\033[0;34m'; NC='\033[0m'
TOTAL_TESTS=0; PASSED_TESTS=0; FAILED_TESTS=0

test_case() {
    local desc="$1"; local cmd="$2"
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    printf "  Testing: %-50s " "$desc"
    if eval "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}PASS${NC}"; PASSED_TESTS=$((PASSED_TESTS + 1)); return 0
    else
        echo -e "${RED}FAIL${NC}"; FAILED_TESTS=$((FAILED_TESTS + 1)); return 1
    fi
}

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE} Episode 32: FINALE — TEST SUITE${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo "[1] File Structure Tests"
echo "───────────────────────────────────────────────────────────"
test_case "README exists" "test -f README.md"
test_case "Starter exists" "test -f starter/ultimate_defense.sh"
test_case "Solution exists" "test -f solution/ultimate_defense.sh"
test_case "Starter executable" "test -x starter/ultimate_defense.sh"
test_case "Solution executable" "test -x solution/ultimate_defense.sh"

echo ""
echo "[2] Artifacts Tests"
echo "───────────────────────────────────────────────────────────"
test_case "Artifacts README exists" "test -f artifacts/README.md"
test_case "Kernel rootkit evidence" "test -f artifacts/kernel/rootkit_memory_dump.txt"
test_case "Rootkit data present" "grep -q 'krylov_final' artifacts/kernel/rootkit_memory_dump.txt"

echo ""
echo "[3] README Content Tests"
echo "───────────────────────────────────────────────────────────"
test_case "README mentions Day 60" "grep -q 'День 60\|Day 60' README.md"
test_case "README mentions finale" "grep -q 'FINALE\|ФИНАЛ\|финал' README.md"
test_case "README has 7 seasons" "grep -q 'Season 1.*Season 7' README.md"
test_case "README mentions Krylov" "grep -q 'Крылов\|Krylov' README.md"
test_case "README mentions rootkit" "grep -q 'rootkit' README.md"

echo ""
echo "[4] Solution Script Tests"
echo "───────────────────────────────────────────────────────────"
test_case "Solution has shebang" "head -1 solution/ultimate_defense.sh | grep -q '^#!/bin/bash'"
test_case "Solution has 7 seasons" "grep -c 'Season [1-7]' solution/ultimate_defense.sh | grep -q '[7-9]'"
test_case "Solution has logging" "grep -q 'log(' solution/ultimate_defense.sh"

echo ""
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
    echo -e "${GREEN}✅ EXCELLENT!${NC} Episode 32 готов."
    echo ""
    echo "*'60 days. 32 episodes. MISSION ACCOMPLISHED.'*"
    echo "— LILITH v8.0"
else
    echo -e "${RED}❌ NEEDS WORK${NC}"
    exit 1
fi
echo "═══════════════════════════════════════════════════════════"
exit 0
