# Solution — Episode 23: IoT Security & MQTT

Production-ready IoT sensor network с MQTT.

## Содержимое

- `python/iot_sensor.py` — Sensor publisher (production)
- `python/iot_aggregator.py` — Data aggregator
- `configs/` — Secure broker configs
- `scripts/setup_broker.sh` — Auto broker setup

## Запуск

```bash
# Setup broker
sudo bash scripts/setup_broker.sh

# Run sensors
python3 python/iot_sensor.py

# Run aggregator
python3 python/iot_aggregator.py
```
