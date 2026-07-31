#!/bin/bash
# Episode 23 Tests

EPISODE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=0; FAIL=0

pass() { echo "✓ $1"; ((PASS++)); }
fail() { echo "✗ $1"; ((FAIL++)); }

echo "=========================================="
echo "Episode 23: IoT Security & MQTT - Tests"
echo "=========================================="

# Test 1: Files exist
[[ -f "$EPISODE_DIR/README.md" ]] && pass "README.md exists" || fail "README.md missing"

# Test 2: Artifacts
[[ -f "$EPISODE_DIR/artifacts/configs/mosquitto.conf" ]] && pass "Mosquitto config exists" || fail "Config missing"
[[ -f "$EPISODE_DIR/artifacts/sensors/temperature_data.json" ]] && pass "Sensor data exists" || fail "Sensor data missing"

# Test 3: Solution
[[ -f "$EPISODE_DIR/solution/python/iot_sensor.py" ]] && pass "Solution sensor exists" || fail "Solution missing"

# Test 4: Python syntax
if command -v python3 &>/dev/null; then
    python3 -m py_compile "$EPISODE_DIR/solution/python/iot_sensor.py" 2>/dev/null && pass "Python syntax valid" || fail "Syntax errors"
fi

echo ""
echo "=========================================="
echo "Passed: $PASS | Failed: $FAIL"
echo "=========================================="

[[ $FAIL -eq 0 ]] && echo "✓ Episode 23 Ready! 🌐" && exit 0 || exit 1
