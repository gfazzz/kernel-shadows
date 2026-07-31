# Episode 22: Artifacts — Drones & UAV Control

## 📦 Содержимое

Эта директория содержит **configurations** и **mission plans** для drone control.

## 📁 Директории

### 1. configs/

ArduPilot параметры и settings:

**ardupilot_params.txt** — Critical parameters для безопасного полёта
**mavlink_settings.json** — MAVLink connection config
**safety_limits.txt** — Geofence и failsafe settings

### 2. examples/

Example MAVLink commands и scripts:

**mavlink_basics.py** — Simple MAVLink connection example
**telemetry_read.py** — Read GPS, battery, altitude
**command_examples.txt** — Common MAVLink commands reference

### 3. mission-plans/

Pre-defined mission waypoints:

**simple_square.waypoints** — Simple square flight pattern
**surveillance_grid.waypoints** — Grid search pattern
**rtl_test.waypoints** — Return-to-launch test

---

## 🎯 Использование

### Шаг 1: ArduPilot Setup

```bash
# Check ArduPilot params
cat configs/ardupilot_params.txt

# Key parameters:
# ARMING_CHECK=1  # All pre-arm checks
# FENCE_ENABLE=1  # Geofence active
# FS_GCS_ENABLE=1 # Failsafe on GCS loss
```

### Шаг 2: MAVLink Connection

```bash
# Install pymavlink
pip3 install pymavlink

# Test connection
python3 examples/mavlink_basics.py
```

### Шаг 3: Mission Upload

```bash
# Upload mission to drone
# (requires MAVProxy or Mission Planner)
mavproxy.py --master=/dev/ttyUSB0 --load-module=mission
mission load mission-plans/simple_square.waypoints
```

---

## 🚨 Safety Notice

**CRITICAL:**
- **Always test в симуляторе first!**
- Props OFF при тестировании на столе
- Geofence настроен и active
- Emergency stop готов (DISARM)
- Open space для полёта (no obstacles)

> **Li Wei:** *"Drone crash — это не software bug. Это $10,000 убытков и possible injuries. Safety first. Always."*
