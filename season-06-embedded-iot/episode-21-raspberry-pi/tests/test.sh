#!/bin/bash

# Episode 21: Raspberry Pi & GPIO - Tests
# KERNEL SHADOWS

EPISODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0
FAIL=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Episode 21: Raspberry Pi & GPIO - Tests"
echo "=========================================="
echo ""

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((PASS++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((FAIL++))
}

warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

## Test 1: Files exist
echo "Test 1: Episode Files"
if [[ -f "$EPISODE_DIR/README.md" ]]; then
    pass "README.md exists"
else
    fail "README.md not found"
fi

## Test 2: Artifacts
echo ""
echo "Test 2: Artifacts"
if [[ -f "$EPISODE_DIR/artifacts/configs/config.txt" ]]; then
    pass "RPi config.txt exists"
else
    fail "config.txt missing"
fi

if [[ -f "$EPISODE_DIR/artifacts/examples/gpio_blink.c" ]]; then
    pass "GPIO example exists"
else
    fail "GPIO example missing"
fi

## Test 3: Starter files
echo ""
echo "Test 3: Starter Templates"
if [[ -f "$EPISODE_DIR/starter/c-code/gpio_control.c" ]]; then
    # Check for TODOs
    if grep -q "TODO" "$EPISODE_DIR/starter/c-code/gpio_control.c"; then
        pass "Starter C code with TODOs"
    else
        fail "Starter should have TODOs for student"
    fi
else
    fail "Starter gpio_control.c missing"
fi

if [[ -f "$EPISODE_DIR/starter/c-code/Makefile" ]]; then
    pass "Makefile exists"
else
    fail "Makefile missing"
fi

## Test 4: Solution
echo ""
echo "Test 4: Solution Code"
if [[ -f "$EPISODE_DIR/solution/c-code/gpio_control.c" ]]; then
    # Solution should NOT have TODOs
    if grep -q "TODO" "$EPISODE_DIR/solution/c-code/gpio_control.c"; then
        fail "Solution should not have TODOs"
    else
        pass "Solution C code complete"
    fi
else
    fail "Solution gpio_control.c missing"
fi

if [[ -f "$EPISODE_DIR/solution/camera_stream.sh" ]] && [[ -x "$EPISODE_DIR/solution/camera_stream.sh" ]]; then
    pass "Camera stream script executable"
else
    fail "Camera stream script missing or not executable"
fi

## Test 5: C Code quality
echo ""
echo "Test 5: C Code Quality"

if [[ -f "$EPISODE_DIR/solution/c-code/gpio_control.c" ]]; then
    # Check for includes
    if grep -q "#include <gpiod.h>" "$EPISODE_DIR/solution/c-code/gpio_control.c"; then
        pass "Uses libgpiod library"
    else
        fail "Should use libgpiod library"
    fi
    
    # Check for error handling
    if grep -q "perror" "$EPISODE_DIR/solution/c-code/gpio_control.c"; then
        pass "Has error handling"
    else
        warn "Could use better error handling"
    fi
    
    # Check for cleanup
    if grep -q "gpiod_line_release" "$EPISODE_DIR/solution/c-code/gpio_control.c"; then
        pass "Proper GPIO cleanup"
    else
        fail "Should release GPIO resources"
    fi
fi

## Test 6: Compilation (if on appropriate system)
echo ""
echo "Test 6: Compilation Test"

if command -v gcc &>/dev/null; then
    if command -v pkg-config &>/dev/null && pkg-config --exists libgpiod; then
        cd "$EPISODE_DIR/solution/c-code" || exit
        if make clean &>/dev/null && make &>/dev/null; then
            pass "Solution compiles successfully"
            make clean &>/dev/null
        else
            fail "Solution compilation failed"
        fi
    else
        warn "libgpiod not available, skipping compilation test"
    fi
else
    warn "gcc not available, skipping compilation test"
fi

## Test 7: systemd service
echo ""
echo "Test 7: Production Setup"
if [[ -f "$EPISODE_DIR/solution/configs/systemd/surveillance.service" ]]; then
    pass "systemd service for autostart"
else
    warn "systemd service missing (bonus)"
fi

## Summary
echo ""
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo -e "${GREEN}Passed:${NC} $PASS"
echo -e "${RED}Failed:${NC} $FAIL"

if [[ $FAIL -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Episode 21 Ready! 🤖"
    echo ""
    echo "Raspberry Pi surveillance system:"
    echo "  - GPIO LED control ✓"
    echo "  - Camera streaming ✓"  
    echo "  - Production configs ✓"
    echo ""
    echo "Next: Deploy to actual Raspberry Pi!"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some tests failed${NC}"
    echo "Review the output above and fix issues"
    exit 1
fi
