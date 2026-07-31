#!/bin/bash

# Episode 22: Drones & UAV Control - Tests
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
echo "Episode 22: Drones & UAV Control - Tests"
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
if [[ -f "$EPISODE_DIR/artifacts/configs/ardupilot_params.txt" ]]; then
    pass "ArduPilot params exists"
else
    fail "ArduPilot params missing"
fi

if [[ -f "$EPISODE_DIR/artifacts/examples/mavlink_basics.py" ]]; then
    pass "MAVLink example exists"
else
    fail "MAVLink example missing"
fi

if [[ -f "$EPISODE_DIR/artifacts/mission-plans/simple_square.waypoints" ]]; then
    pass "Mission plan exists"
else
    fail "Mission plan missing"
fi

## Test 3: Starter files
echo ""
echo "Test 3: Starter Templates"
if [[ -f "$EPISODE_DIR/starter/python/drone_control.py" ]]; then
    # Check for TODOs
    if grep -q "TODO" "$EPISODE_DIR/starter/python/drone_control.py"; then
        pass "Starter Python with TODOs"
    else
        fail "Starter should have TODOs"
    fi
else
    fail "Starter drone_control.py missing"
fi

## Test 4: Solution
echo ""
echo "Test 4: Solution Code"
if [[ -f "$EPISODE_DIR/solution/python/drone_control.py" ]]; then
    # Solution should NOT have TODOs
    if grep -q "TODO" "$EPISODE_DIR/solution/python/drone_control.py"; then
        fail "Solution should not have TODOs"
    else
        pass "Solution drone_control.py complete"
    fi
else
    fail "Solution missing"
fi

if [[ -f "$EPISODE_DIR/solution/python/autonomous_mission.py" ]] && [[ -x "$EPISODE_DIR/solution/python/autonomous_mission.py" ]]; then
    pass "Autonomous mission script executable"
else
    fail "Autonomous mission missing or not executable"
fi

if [[ -f "$EPISODE_DIR/solution/python/encrypted_commands.py" ]]; then
    pass "Encryption script exists (Season 5 callback!)"
else
    warn "Encryption script missing (bonus feature)"
fi

## Test 5: Python code quality
echo ""
echo "Test 5: Python Code Quality"

if [[ -f "$EPISODE_DIR/solution/python/drone_control.py" ]]; then
    # Check for pymavlink
    if grep -q "from pymavlink import mavutil" "$EPISODE_DIR/solution/python/drone_control.py"; then
        pass "Uses pymavlink library"
    else
        fail "Should use pymavlink"
    fi
    
    # Check for logging
    if grep -q "import logging" "$EPISODE_DIR/solution/python/drone_control.py"; then
        pass "Has logging"
    else
        warn "Could use logging for production"
    fi
    
    # Check for safety
    if grep -q "arm\|disarm\|land" "$EPISODE_DIR/solution/python/drone_control.py"; then
        pass "Has ARM/DISARM/LAND safety commands"
    else
        fail "Should have safety commands"
    fi
fi

## Test 6: Python syntax check
echo ""
echo "Test 6: Python Syntax"

if command -v python3 &>/dev/null; then
    # Check solution syntax
    if python3 -m py_compile "$EPISODE_DIR/solution/python/drone_control.py" 2>/dev/null; then
        pass "Solution Python syntax valid"
    else
        fail "Solution has syntax errors"
    fi
    
    # Check starter syntax
    if python3 -m py_compile "$EPISODE_DIR/starter/python/drone_control.py" 2>/dev/null; then
        pass "Starter Python syntax valid"
    else
        warn "Starter has syntax issues (expected with TODOs)"
    fi
else
    warn "Python3 not available, skipping syntax check"
fi

## Test 7: Safety configs
echo ""
echo "Test 7: Safety Features"
if [[ -f "$EPISODE_DIR/artifacts/configs/safety_limits.txt" ]]; then
    pass "Safety limits documented"
    
    # Check for critical safety items
    if grep -q "GEOFENCE\|BATTERY\|FAILSAFE" "$EPISODE_DIR/artifacts/configs/safety_limits.txt"; then
        pass "Safety config includes geofence/battery/failsafe"
    fi
else
    fail "Safety limits missing"
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
    echo "Episode 22 Ready! 🚁"
    echo ""
    echo "Drone surveillance system:"
    echo "  - MAVLink communication ✓"
    echo "  - Autonomous missions ✓"
    echo "  - Command encryption ✓"
    echo "  - Safety features ✓"
    echo ""
    echo "⚠️  CRITICAL: Test with SITL simulator first!"
    echo "    sim_vehicle.py -v ArduCopter --console --map"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}✗ Some tests failed${NC}"
    echo "Review the output above and fix issues"
    exit 1
fi
