# Starter Files — Episode 23: IoT Security & MQTT

Starter templates для построения защищённой IoT sensor сети на MQTT.

## Файлы

- `configs/mosquitto.conf.example` — Базовая MQTT broker конфигурация
- `configs/mosquitto-secure.conf.example` — Production конфиг с TLS
- `python/iot_sensor.py` — Sensor publisher template (TODO)
- `python/iot_monitor.py` — Monitoring dashboard template (TODO)

## Setup

```bash
# Install dependencies
pip3 install paho-mqtt

# Install Mosquitto broker
sudo apt install -y mosquitto mosquitto-clients

# Configure broker
sudo cp configs/mosquitto.conf.example /etc/mosquitto/conf.d/iot.conf
sudo systemctl restart mosquitto
```

## Usage

```bash
# Complete TODOs in sensor code
nano python/iot_sensor.py

# Run sensor
python3 python/iot_sensor.py

# Run monitor
python3 python/iot_monitor.py
```
