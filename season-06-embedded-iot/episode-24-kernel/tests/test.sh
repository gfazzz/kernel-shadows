#!/bin/bash
# Episode 24 Tests

EPISODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0

pass() { echo "✓ $1"; ((PASS++)); }
fail() { echo "✗ $1"; ((FAIL++)); }

echo "=========================================="
echo "Episode 24: Kernel Modules - Tests"
echo "=========================================="

# Test 1: Files exist
[[ -f "$EPISODE_DIR/README.md" ]] && pass "README.md exists" || fail "README.md missing"

# Test 2: Artifacts
[[ -f "$EPISODE_DIR/artifacts/examples/hello_kernel.c" ]] && pass "Hello kernel exists" || fail "Hello kernel missing"
[[ -f "$EPISODE_DIR/artifacts/examples/Makefile" ]] && pass "Makefile exists" || fail "Makefile missing"

# Test 3: Starter
[[ -f "$EPISODE_DIR/starter/c-code/hello_module.c" ]] && pass "Starter module exists" || fail "Starter missing"

# Test 4: Solution
[[ -f "$EPISODE_DIR/solution/modules/hello_complete.c" ]] && pass "Solution exists" || fail "Solution missing"

# Test 5: Kernel headers check
if [[ -d "/lib/modules/$(uname -r)/build" ]]; then
    pass "Kernel headers installed"
else
    fail "Kernel headers missing (install: linux-headers-$(uname -r))"
fi

# Test 6: C syntax check (basic)
if command -v gcc &>/dev/null; then
    gcc -fsyntax-only -I/lib/modules/$(uname -r)/build/include \
        "$EPISODE_DIR/artifacts/examples/hello_kernel.c" 2>/dev/null && \
        pass "C syntax valid" || fail "C syntax errors"
fi

echo ""
echo "=========================================="
echo "Passed: $PASS | Failed: $FAIL"
echo "=========================================="

[[ $FAIL -eq 0 ]] && echo "✓ Episode 24 Ready! 🔧" && exit 0 || exit 1
