# Starter Files — Episode 22: Drones & UAV Control

## 📁 Содержимое

Эта директория содержит **starter templates** для drone control programming.

**Файлы:**
- `python/drone_control.py` — Drone control skeleton (TODOs!)
- `python/autonomous_mission.py` — Autonomous flight template
- `configs/flight_params.json` — Flight parameters config

## 🚀 Как использовать

### 1. Setup

```bash
# Install pymavlink
pip3 install pymavlink

# (Optional) Install dronekit for easier API
pip3 install dronekit
```

### 2. Simulator Setup (Recommended!)

```bash
# Install ArduPilot SITL
pip3 install MAVProxy

# Run simulator
sim_vehicle.py -v ArduCopter --console --map

# Drone simulator запустится на udp:127.0.0.1:14550
```

### 3. Complete Starter Code

```bash
cd python/

# Edit drone_control.py (complete TODOs)
nano drone_control.py

# Test with simulator
python3 drone_control.py
```

---

## 📝 Drone Control Tips

**MAVLink Connection:**
```python
from pymavlink import mavutil

# Connect
master = mavutil.mavlink_connection('udp:127.0.0.1:14550')
master.wait_heartbeat()

# Arm
master.arducopter_arm()
# or
master.mav.command_long_send(...)

# Takeoff
master.mav.command_long_send(
    master.target_system,
    master.target_component,
    mavutil.mavlink.MAV_CMD_NAV_TAKEOFF,
    0, 0, 0, 0, 0, 0, 0, 10  # 10m altitude
)
```

**Safety First:**
- ALWAYS test в simulator first
- Props OFF при bench testing
- Emergency stop ready (DISARM)
- Geofence active
- Battery monitoring

---

> **Li Wei:** *"Дрон в воздухе — это летающий компьютер с пропеллерами. One bug = crash. Test everything в симуляторе. Twice."*
