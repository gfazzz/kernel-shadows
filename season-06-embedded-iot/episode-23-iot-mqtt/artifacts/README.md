# Episode 23: Artifacts — IoT Security & MQTT

## 📦 Содержимое

Эта директория содержит **конфигурации MQTT** и **примеры IoT датчиков** для построения защищённой сенсорной сети.

## 📁 Директории

### 1. configs/

Конфигурации MQTT broker (Mosquitto):

**mosquitto.conf** — Базовая конфигурация broker
**mosquitto-secure.conf** — Production конфиг с TLS + authentication
**mosquitto-auth.conf** — Password file конфигурация
**acl.conf** — Access Control List для topics

### 2. sensors/

Примеры данных от IoT датчиков:

**temperature_data.json** — Показания температурных сенсоров
**motion_events.json** — События детекции движения
**door_status.json** — Статусы дверных датчиков
**sensor_metadata.json** — Метаданные всех сенсоров

### 3. examples/

Примеры MQTT скриптов:

**mqtt_publish.py** — Простая публикация в topic
**mqtt_subscribe.py** — Подписка и обработка сообщений
**mqtt_tls_example.py** — Secure connection с TLS

---

## 🎯 Использование

### Шаг 1: Mosquitto Broker Setup

```bash
# Установить Mosquitto
sudo apt install -y mosquitto mosquitto-clients

# Скопировать конфигурацию
sudo cp configs/mosquitto.conf /etc/mosquitto/conf.d/

# Перезапустить broker
sudo systemctl restart mosquitto
```

### Шаг 2: Тест подключения

```bash
# Терминал 1: Subscribe
mosquitto_sub -h localhost -t "test/topic" -v

# Терминал 2: Publish
mosquitto_pub -h localhost -t "test/topic" -m "Hello MQTT!"
```

### Шаг 3: Python MQTT Client

```bash
# Установить paho-mqtt
pip3 install paho-mqtt

# Запустить пример
python3 examples/mqtt_publish.py
python3 examples/mqtt_subscribe.py
```

---

## 🔐 Security Features

**Authentication:**
```bash
# Создать password file
mosquitto_passwd -c /etc/mosquitto/passwd iot_user

# Применить в config:
# password_file /etc/mosquitto/passwd
```

**TLS Encryption:**
```bash
# Сгенерировать сертификаты
openssl req -new -x509 -days 365 -extensions v3_ca \
  -keyout ca.key -out ca.crt

# Применить в config:
# cafile /etc/mosquitto/ca.crt
# certfile /etc/mosquitto/server.crt
# keyfile /etc/mosquitto/server.key
```

**Access Control (ACL):**
```
# acl.conf
user iot_user
topic readwrite sensors/#
topic read status/#
```

---

## 📊 Topic Structure

```
sensors/
  ├─ temperature/
  │  ├─ room_01
  │  ├─ room_02
  │  └─ outdoor
  ├─ motion/
  │  ├─ entrance
  │  └─ corridor
  └─ door/
     ├─ main_door
     └─ back_door

status/
  ├─ online
  └─ health

commands/
  └─ control
```

---

> **Li Wei:** *"MQTT — это нервная система IoT. Sensors публикуют данные. Servers подписываются. Broker координирует. Без безопасности — любой может читать ваши данные или отправлять команды. TLS + auth обязательны в production."*
