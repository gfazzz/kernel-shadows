# Episode 23: IoT Security & MQTT

> *"MQTT — это нервная система IoT. Sensors публикуют. Servers подписываются. Broker координирует. Без безопасности — хаос."* — Li Wei

```
Season 6: Embedded Linux & IoT Security
Episode 23 of 32
Локация: Шэньчжэнь 🇨🇳, Китай (IoT Factory)
Дни: 45-46 операции KERNEL SHADOWS
Длительность: 4-5 часов
Сложность: ⭐⭐⭐⭐⭐
Тип: IoT Configuration (Type B - MQTT setup)
```

---

## 📋 Обзор эпизода

### Что вы изучите

В этом эпизоде вы построите **защищённую IoT sensor сеть** на MQTT:

**Технологии:**
- 📡 **MQTT Protocol** — lightweight messaging для IoT
- 🔄 **Pub/Sub Pattern** — издатель/подписчик архитектура
- 🛡️ **MQTT Security** — TLS, authentication, ACL
- 📊 **Mosquitto Broker** — популярный MQTT сервер
- 🌡️ **IoT Sensors** — temperature, motion, door sensors
- 🐍 **Python MQTT** — paho-mqtt библиотека

**Навыки:**
- Понимание MQTT протокола и pub/sub
- Настройка Mosquitto broker (базовая + secure)
- Программирование MQTT clients на Python
- IoT sensor data publishing/subscribing
- Реализация MQTT security (TLS + ACL)
- Построение IoT sensor networks

**Важно:** MQTT != HTTP! Это event-driven, асинхронный протокол для IoT где bandwidth и энергия критичны.

---

## 🎬 Сюжет: Сеть IoT датчиков

### День 45, раннее утро — Шэньчжэнь, IoT фабрика

**Li Wei** ведёт Макса через огромную фабрику. Конвейеры. Роботы. Тысячи крошечных плат.

**Li Wei:** *"Здесь собирают 3 миллиона IoT датчиков в месяц. Temperature sensors для холодильников. Motion detectors для сигнализаций. Door sensors для умных домов. Всё на MQTT."*

**Макс:** *"Три миллиона в месяц?!"*

**Li Wei:** *"Шэньчжэнь — IoT столица мира. 80% мировых IoT устройств делают в радиусе 50км отсюда. Видишь ту линию? DHT22 temperature sensors. $0.80 за штуку. Продают миллионами."*

Он указывает на огромный склад:

```
Warehouse Inventory (real-time):
├─ Temperature Sensors (DHT22): 450,000 units
├─ Motion Detectors (PIR): 280,000 units
├─ Door Sensors (Reed): 320,000 units
├─ ESP32 Controllers: 180,000 units
└─ MQTT Brokers running: 2,500+ instances
```

**Li Wei:** *"HTTP для IoT? Представь: батарейка-powered sensor. TCP handshake каждые 60 секунд. JSON overhead. HTTP headers 200-500 байт. MQTT headers — 2 байта. Батарея умрёт за день против месяца. IoT нужен minimalism."*

---

### Миссия

**Виктор (видеозвонок):**

*"Episodes 21-22 — камера и дрон. Хорошо. Но нужна полная sensor сеть. Temperature, motion, doors. Real-time alerts. MQTT."*

**Дмитрий:** *"Если Крылов появляется — мы должны знать МГНОВЕННО. Motion detection, door открывается. Все sensors в одну систему."*

**Алекс (security warning):**

*"IoT — самое слабое звено. October 2016 помнишь? Mirai botnet. 600,000 IoT devices взломаны. Использовали для DDoS на DNS. Half of internet упал на 11 часов. All because IoT без безопасности."*

**Li Wei кивает:**

*"Mirai был wake-up call. Default passwords. No encryption. Telnet открыт. Китайские DVR cameras стали zombie army. 1Tbps DDoS attack. Крупнейший на тот момент."*

**LILITH (активируется):**

*"Mirai code опубликован. Теперь каждый скрипт-кидди может запустить IoT botnet. Shodan.io показывает 20+ миллионов незащищённых IoT devices СЕЙЧАС. Твоя задача — не попасть в эту статистику."*

---

### Цель

**Миссия:** Защищённая IoT sensor сеть на MQTT

**Требования:**
1. Настроить Mosquitto MQTT broker
2. Настроить IoT sensors (Python publishers)
3. Создать data aggregator (Python subscriber)
4. Применить MQTT security (TLS + auth + ACL)
5. Реализовать real-time monitoring
6. Тестирование и production deployment

**Сроки:** 4-5 часов

**Li Wei:** *"MQTT появился в 1999. IBM создали для нефтепроводов в Сахаре. Satellite connectivity, low bandwidth, unreliable. Нужен был протокол который работает в худших условиях. Они создали. Теперь это стандарт для IoT."*

**Макс:** *"Почему не HTTP? REST API?"*

**Li Wei смеётся:**

*"HTTP для IoT? Представь: батарейка-powered sensor. TCP handshake каждые 60 секунд. JSON overhead. HTTP headers 200-500 байт. MQTT headers — 2 байта. Батарея умрёт за день против месяца. IoT нужен minimalism."*

**Li Wei:** *"Episode 21 — GPIO hardware. Episode 22 — дроны. Теперь Episode 23 — IoT networks. От одного устройства к distributed system. Ready?"*

**LILITH:** *"IoT Security — это oxymoron. Internet of Things = Internet of Threats. Каждый sensor — attack vector. Default credentials, outdated firmware, no encryption. Recipe for disaster. Твоя миссия — prove me wrong."*

---

## 🎓 Структура эпизода: 6 микро-циклов

Каждый цикл = 25-35 минут:
- 🎬 Сюжет (2-3 мин)
- 📚 Теория (12-18 мин)
- 💻 Практика (8-12 мин)
- 🤔 Проверка понимания (2 мин)

**Общее время:** ~2.5 часа теории + 2 часа практики = 4-5 часов

---

## 🔄 Цикл 1: Протокол MQTT и Pub/Sub Pattern (30 мин)

### 🎬 Сюжет

**Li Wei открывает старый ноутбук IBM ThinkPad:**

*"1999 год. Andy Stanford-Clark (IBM) и Arlen Nipper (Arcom) летят в Сахару. Oil pipeline мониторинг. Satellite link — 9600 baud. Постоянные обрывы. HTTP не подходит. Они придумали MQTT."*

**Макс:** *"MQ... что?"*

**Li Wei:** *"Message Queue Telemetry Transport. Изначально для IBM MQ messaging. Потом адаптировали. 2013 — OASIS standard. 2016 — Mirai показал что security критичен. 2025 — миллиарды devices."*

Он показывает graph на экране:

```
MQTT Evolution:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1999: IBM создаёт для oil pipelines (proprietary)
2010: Royalty-free open spec
2013: OASIS standard (v3.1.1)
2014: Eclipse Mosquitto becomes популярным
2016: MIRAI BOTNET → wake-up call security!
2019: MQTT 5.0 (новые features)
2025: 15+ billion IoT devices используют MQTT
```

**Li Wei:** *"Сейчас MQTT везде. Facebook Messenger использует (mobile app messaging). AWS IoT Core — MQTT. Azure IoT Hub — MQTT. Alibaba Cloud — MQTT. Стандарт де-факто."*

### 📚 Теория: Протокол MQTT

#### Что такое MQTT?

**MQTT (Message Queuing Telemetry Transport):**
- Легковесный pub/sub протокол
- Создан IBM в 1999 для нефтепроводов
- Стал стандартом для IoT (2013)
- Минимальный overhead (2 байта заголовок!)
- Работает через TCP/IP

**Li Wei:** *"Минимализм — это философия MQTT. Каждый байт на счету. Satellite link 1999 года стоил $10 per kilobyte. Они не могли тратить bandwidth на JSON и HTTP headers. Нужен был efficient protocol. И создали."*

**Зачем MQTT для IoT?**

```
Сравнение протоколов:

HTTP:
- Request/Response (клиент инициирует)
- TCP handshake каждый раз
- Headers ~200-500 байт
- Для web, не для IoT

MQTT:
- Pub/Sub (асинхронно)
- Постоянное соединение
- Headers ~2 байта
- Создан для IoT
```

#### 🏠 Метафора: Почтовая служба

**MQTT = современная почтовая служба:**

**Издатель (Publisher) = отправитель письма:**
```
Датчик temperature: "Публикую в topic 'sensors/temp': 22°C"
Как человек отправляет письмо в почтовый ящик
Не знает кто получит
Просто кладёт в ящик
```

**Broker = почтовое отделение:**
```
Получает все письма
Сортирует по адресам (topics)
Доставляет подписчикам
```

**Подписчик (Subscriber) = получатель:**
```
Aggregator: "Подписан на 'sensors/#'" (все sensors)
Как подписка на журнал
Автоматически получаешь каждый выпуск
Не нужно спрашивать
```

**Li Wei:** *"HTTP = лично спросить у каждого 'есть новости?' каждые 5 секунд (polling). MQTT = подписаться один раз, broker доставляет когда есть (push). Для IoT с тысячами sensors HTTP = безумие."*

**LILITH:** *"Pub/Sub = decoupling. Publisher не знает Subscriber. Subscriber не знает Publisher. Broker координирует. Это как Tor network — anonymous communication. Но здесь для efficiency, не privacy. Один broker падает — вся система слепая. Single point of failure. Clustering brokers критичен в production."*

#### Pub/Sub Pattern

**Архитектура:**

```
        Publishers               Broker              Subscribers

Sensor 1: temp  ──┐                                ┌──> Dashboard
Sensor 2: temp  ──┼──→  [Topic: sensors/temp]  ───┼──> Data Logger
Sensor 3: motion──┼──→  [Topic: sensors/motion]───┼──> Alert System
Sensor 4: door  ──┘                                └──> Mobile App
```

**Преимущества:**
```
✅ Decoupling: Publisher не знает Subscriber
✅ Scalability: +1000 sensors = без изменений
✅ Flexibility: Subscribe/Unsubscribe динамически
✅ Efficiency: Broker фильтрует, не client
```

#### Topics (темы/топики)

**Topics = адрес сообщения:**

```
Иерархия (как filesystem):

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
```

**Wildcards (подстановочные знаки):**

```
+ = один уровень
# = все уровни

sensors/+/room_01      → sensors/temperature/room_01 ✅
                       → sensors/motion/room_01 ✅
                       → sensors/temperature/room_02 ✗

sensors/temperature/#  → sensors/temperature/room_01 ✅
                       → sensors/temperature/outdoor ✅
                       → sensors/motion/entrance ✗

sensors/#              → ВСЕ sensors ✅
```

**💡 "Aha!" момент: Почему # эффективнее чем отдельные подписки?**

<details>
<summary>Откройте чтобы понять</summary>

**Плохой способ (без wildcards):**
```
Subscribecode:
client.subscribe("sensors/temperature/room_01")
client.subscribe("sensors/temperature/room_02")
client.subscribe("sensors/temperature/outdoor")
client.subscribe("sensors/motion/entrance")
... (50+ отдельных subscriptions)

Проблемы:
❌ 50+ network messages к broker
❌ Broker держит 50+ subscription записей
❌ Добавить sensor = код изменить
```

**Хороший способ (с wildcards):**
```
client.subscribe("sensors/#")

Преимущества:
✅ 1 network message
✅ Broker держит 1 subscription
✅ Новый sensor = автоматически получаешь
✅ Фильтрация на стороне broker (эффективно!)
```

**Аналогия:**
```
Плохо: Сказать почтальону "доставь мне письма от:
       - Вася, Петя, Маша, ...(100 имён)"

Хорошо: "Доставь мне ВСЮ почту по этому адресу"
```

**Li Wei:** *"На IoT фабрике 10,000 sensors. Без wildcards = 10,000 subscriptions = broker падает. С wildcards = 1 subscription = работает. Broker оптимизирован для pattern matching, не для тысяч exact matches."*

**LILITH:** *"Wildcards = power и опасность. Subscribe на '#' = получаешь ВСЁ. Видел как junior dev подписал dashboard на '#'. 10,000 messages/sec. Browser crash. Server crash. Всё упало. Always используй specific patterns. '#' = ядерная опция."*

</details>

#### QoS (Quality of Service)

**Уровни гарантии доставки:**

```
QoS 0 (At most once): Пожарил и забыл
- Отправил и всё
- Может потеряться
- Самый быстрый

QoS 1 (At least once): Минимум один раз
- Отправил → ждёт ACK
- Может дублироваться
- Баланс скорости/надёжности

QoS 2 (Exactly once): Ровно один раз
- 4-way handshake
- Никогда не дублируется
- Самый медленный
```

**Когда что использовать?**

```
QoS 0: Temperature каждые 60 сек
       → Потеряли одно значение? Следующее через минуту

QoS 1: Motion detection alert
       → Должны получить! Дубликат обработаем

QoS 2: Command "Unlock door"
       → Ровно один раз! Дубликат = проблема
```

---

### 💻 Практика: MQTT Basics

**Задание:**

1. **Установить Mosquitto:**
```bash
sudo apt update
sudo apt install -y mosquitto mosquitto-clients

# Запустить broker
sudo systemctl start mosquitto
sudo systemctl enable mosquitto
```

2. **Тест pub/sub (2 терминала):**
```bash
# Терминал 1: Subscribe
mosquitto_sub -h localhost -t "test/topic" -v

# Терминал 2: Publish
mosquitto_pub -h localhost -t "test/topic" -m "Hello MQTT!"
```

3. **Тест wildcards:**
```bash
# Terminal 1: Subscribe to all sensors
mosquitto_sub -h localhost -t "sensors/#" -v

# Terminal 2: Publish to different topics
mosquitto_pub -t "sensors/temperature/room_01" -m "22.5"
mosquitto_pub -t "sensors/motion/entrance" -m "detected"
```

4. **QoS test:**
```bash
# QoS 0 (fire and forget)
mosquitto_pub -t "test/qos" -m "QoS 0" -q 0

# QoS 1 (at least once)
mosquitto_pub -t "test/qos" -m "QoS 1" -q 1

# QoS 2 (exactly once)
mosquitto_pub -t "test/qos" -m "QoS 2" -q 2
```

---

### 🤔 Проверка понимания

**LILITH:** *"MQTT Broker хранит все сообщения навсегда как база данных. Правда или ложь?"*

<details>
<summary>🤔 MQTT persistence</summary>

**Ответ:** **ЛОЖЬ! (с нюансами)**

**Обычные сообщения:**
```
Publish → Broker → Deliver → УДАЛЕНО
Broker НЕ хранит историю
Как live radio: пропустил — потерял
```

**Retained messages (исключение):**
```
Publish с флагом retained=true
Broker хранит ПОСЛЕДНЕЕ сообщение
Новый subscriber получает last value

Пример:
sensors/temperature/room_01 [retained]: "22.5°C"
Новый dashboard подключается
→ СРАЗУ получает последнюю temperature
→ Не ждёт следующей публикации
```

**Persistent sessions (ещё один нюанс):**
```
Client с clean_session=false
Broker хранит:
- Subscriptions
- QoS 1/2 сообщения (не доставленные)

НО: только пока client offline
После reconnect → доставка → удаление
```

**Вывод:**
```
MQTT ≠ Database
MQTT = Message Bus

Для истории используй:
- Time-series DB (InfluxDB)
- Message queue (Kafka для длительного хранения)
- MQTT только для real-time delivery
```

**Li Wei:** *"На IoT фабрике видел ошибку: developer думал Broker = storage. 1 год данных. 50GB in-memory. Broker crash. Lost всё. MQTT не для хранения. MQTT для транспорта. Store в proper DB."*

**LILITH:** *"Mirai botnet использовал это. Devices публиковали credentials в topics. No retention = after reboot исчезли. Attackers не сохранили. Lost access к 30% infected devices. Их же ошибка спасла часть жертв. Irony."*

</details>

---

[Продолжение следует...]

*Part 1/3 of Episode 23 README.md*
*Циклы 2-6 + финал в следующей части*
## 🔄 Цикл 2: Mosquitto Broker Configuration (30 мин)

### 🎬 Сюжет

**Li Wei открывает конфиг файл:**

```
# mosquitto.conf
listener 1883
allow_anonymous true  ← ОПАСНО!
```

**Li Wei:** *"Это default config. Любой может подключиться. Любой может публиковать куда угодно. Mirai именно так работал. Default credentials, no auth."*

**Макс:** *"А как правильно?"*

**Li Wei:** *"TLS для encryption. Username/password для auth. ACL для permissions. Три слоя защиты."*

### 📚 Теория: Mosquitto Broker Setup

#### Базовая конфигурация

**Минимальный mosquitto.conf:**
```
# Listener
listener 1883
protocol mqtt

# Anonymous access (только для тестирования!)
allow_anonymous true

# Logging
log_dest file /var/log/mosquitto/mosquitto.log
log_type all

# Persistence
persistence true
persistence_location /var/lib/mosquitto/
```

**Li Wei:** *"Это работает, но в production это suicide. Порт 1883 открыт миру. No encryption. No auth. Shodan.io находит 100,000+ таких brokers. Free access для attackers."*

#### Production конфигурация

**Security best practices:**

```
# TLS Listener (шифрование!)
listener 8883
protocol mqtt

# Authentication (обязательно!)
allow_anonymous false
password_file /etc/mosquitto/passwd

# Access Control List
acl_file /etc/mosquitto/acl.conf

# TLS Certificates
cafile /etc/mosquitto/ca.crt
certfile /etc/mosquitto/server.crt
keyfile /etc/mosquitto/server.key
tls_version tlsv1.2

# Connection limits
max_connections 1000
max_queued_messages 10000

# Persistence
persistence true
persistence_location /var/lib/mosquitto/
autosave_interval 300

# QoS Settings
max_inflight_messages 20
upgrade_outgoing_qos false

# Security
require_certificate false  # Client cert опционально
use_identity_as_username false
```

**Изменения:**
- `1883` → `8883` (TLS port)
- `allow_anonymous true` → `false` (auth required!)
- Добавлены: TLS, password file, ACL

**Li Wei:** *"Это minimum для production. Episode 20 hardening помнишь? Те же принципы. Defense in depth."*

#### 🏠 Метафора 2: Ночной клуб

**Небезопасный broker = Клуб без security:**
```
Вход открыт (port 1883)
Любой входит (allow_anonymous)
Никто не проверяет (no auth)
Все слышат всё (no encryption)
→ Chaos!
```

**Безопасный broker = Клуб с VIP защитой:**
```
VIP вход (port 8883)
Лицо в списке? (authentication)
Правильная секция? (ACL permissions)
Приватный разговор (TLS encryption)
→ Controlled access!
```

**LILITH:** *"IoT без security = unlocked nightclub selling drugs. Welcome attackers! Mirai proof. 600k devices с telnet:telnet credentials. Публичный list. Script kiddies downloaded, ran, botnet ready. Zero effort attack because zero security."*

#### Authentication (Username/Password)

**Password file создание:**
```bash
# Создать password file
mosquitto_passwd -c /etc/mosquitto/passwd admin

# Добавить ещё пользователей
mosquitto_passwd /etc/mosquitto/passwd iot_device
mosquitto_passwd /etc/mosquitto/passwd dashboard

# Формат файла:
# username:hashed_password
```

**Формат файла (/etc/mosquitto/passwd):**
```
admin:$7$101$l8gPBVx...  # Bcrypt hashed
iot_device:$7$101$2fK9...
dashboard:$7$101$9xPq...
```

**Li Wei:** *"Bcrypt hashing. Cost factor 12 (2^12 iterations). Rainbow tables бесполезны. Даже если password file украден, brute-force займёт годы для strong passwords."*

**В mosquitto.conf:**
```conf
password_file /etc/mosquitto/passwd
allow_anonymous false
```

**Connect с authentication:**
```bash
# Publish с auth
mosquitto_pub -h localhost -p 8883 \
  --cafile ca.crt \
  -u iot_device -P password \
  -t "sensors/temp" -m "22.5"

# Subscribe с auth
mosquitto_sub -h localhost -p 8883 \
  --cafile ca.crt \
  -u dashboard -P password \
  -t "sensors/#" -v
```

#### Access Control List (ACL)

**Контроль доступа к topics:**

```
# Admin (полный доступ)
user admin
topic readwrite #

# IoT devices (только публикация в sensors)
user iot_device
topic write sensors/#
topic read commands/#

# Dashboard (только чтение)
user dashboard
topic read sensors/#
topic read status/#
```

**💡 "Aha!" момент: Почему ACL критичен?**

<details>
<summary>Реальный сценарий атаки</summary>

**Без ACL:**
```
Атакующий подключается как любой client
Публикует в commands/door/unlock
Door sensor получает команду
Дверь открывается
→ Физический доступ!
```

**С ACL:**
```
user attacker
topic read sensors/#  ← только чтение

attacker пытается:
PUBLISH commands/door/unlock
→ Broker: DENIED (нет write permissions)
→ Команда не доставлена
→ Дверь остаётся закрытой
```

**Pattern-based ACL:**
```
# Каждый sensor может писать только свой topic
pattern write sensors/%u/#
# %u = username

Sensor temp_01:
  sensors/temp_01/data ✅ разрешено
  sensors/temp_02/data ✗ запрещено
```

**Статистика:**
- 80,000 vulnerable brokers найдено
- 50,000 без ACL → compromised
- 30,000 с ACL → protected
- ACL saved 30k networks!

**Li Wei:** *"ACL — это не паранойя. Это необходимость. Даже если credentials украдены, ACL ограничивает damage. Principle of least privilege. Episode 20 concept applied to MQTT."*

</details>

---

### 💻 Практика: Secure Broker Setup

**Задание:**

1. **Создать password file:**
```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd admin
sudo mosquitto_passwd /etc/mosquitto/passwd iot_sensor
```

2. **Создать ACL:**
```bash
sudo nano /etc/mosquitto/acl.conf

# Добавить:
user admin
topic readwrite #

user iot_sensor
topic write sensors/#
```

3. **Применить конфигурацию:**
```bash
sudo nano /etc/mosquitto/conf.d/security.conf

# Добавить:
allow_anonymous false
password_file /etc/mosquitto/passwd
acl_file /etc/mosquitto/acl.conf

# Перезапустить
sudo systemctl restart mosquitto
```

4. **Тест authentication:**
```bash
# Без пароля (должно отклониться)
mosquitto_pub -h localhost -t "test" -m "fail"

# С паролем (должно работать)
mosquitto_pub -h localhost -u iot_sensor -P password -t "sensors/temp" -m "22.5"
```

---

## 🔄 Цикл 3: Python MQTT Clients (paho-mqtt) (35 мин)

### 🎬 Сюжет

**Li Wei пишет код:**

```python
import paho.mqtt.client as mqtt

client = mqtt.Client("sensor_01")
client.connect("localhost", 1883)
client.publish("sensors/temp", "22.5")
```

**Li Wei:** *"Три строки. Sensor готов. Paho-mqtt — стандартная библиотека. Поддерживает всё: QoS, retained, TLS, callbacks. Production ready."*

### 📚 Теория: paho-mqtt Library

#### Publisher (Издатель)

**Базовый publisher:**

```python
import paho.mqtt.client as mqtt

# Create client
client = mqtt.Client("publisher_id")

# Connect
client.connect("localhost", 1883)

# Publish
client.publish("sensors/temperature", "22.5")

# Disconnect
client.disconnect()
```

**Production publisher (с reconnection):**

```python
import paho.mqtt.client as mqtt
import time

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected!")
    else:
        print(f"Failed: {rc}")

def on_disconnect(client, userdata, rc):
    if rc != 0:
        print("Unexpected disconnect. Reconnecting...")

client = mqtt.Client("sensor")
client.on_connect = on_connect
client.on_disconnect = on_disconnect

# Credentials
client.username_pw_set("iot_sensor", "password")

# Connect с retry
client.connect("localhost", 1883, keepalive=60)

# Loop (обрабатывает reconnection)
client.loop_start()

while True:
    client.publish("sensors/temp", "22.5", qos=1)
    time.sleep(60)
```

#### Subscriber (Подписчик)

**Базовый subscriber:**

```python
import paho.mqtt.client as mqtt

def on_message(client, userdata, msg):
    print(f"{msg.topic}: {msg.payload.decode()}")

client = mqtt.Client("subscriber_id")
client.on_message = on_message

client.connect("localhost", 1883)
client.subscribe("sensors/#")

client.loop_forever()  # Блокирует
```

**Filtered processing:**

```python
def on_message(client, userdata, msg):
    topic = msg.topic
    payload = msg.payload.decode()

    if "temperature" in topic:
        temp = float(payload)
        if temp > 25:
            print(f"⚠️ High temp: {temp}°C")

    elif "motion" in topic:
        if payload == "detected":
            print("🚨 Motion detected!")
```

#### Callbacks (обратные вызовы)

**Основные callbacks:**

```python
# Connection events
def on_connect(client, userdata, flags, rc):
    # rc = return code (0 = success)
    if rc == 0:
        client.subscribe("sensors/#")  # Subscribe после connect!

def on_disconnect(client, userdata, rc):
    # rc != 0 = unexpected disconnect
    pass

# Message events
def on_message(client, userdata, msg):
    # Все сообщения (если нет topic-specific callback)
    pass

def on_message_filtered(client, userdata, msg):
    # Только specific topic
    pass

# Специфичные topic callbacks
client.message_callback_add("sensors/temp/#", on_temperature)
client.message_callback_add("sensors/motion/#", on_motion)

# Publish events
def on_publish(client, userdata, mid):
    # mid = message ID
    print(f"Published: {mid}")

# Subscribe events
def on_subscribe(client, userdata, mid, granted_qos):
    print(f"Subscribed with QoS: {granted_qos}")
```

---

### 💻 Практика: IoT Sensor Programming

**Задание:**

1. **Install paho-mqtt:**
```bash
pip3 install paho-mqtt
```

2. **Create temperature sensor:**
```bash
cd ~/kernel-shadows/season-06-embedded-iot/episode-23-iot-mqtt/starter/python

# Edit iot_sensor.py (complete TODOs)
nano iot_sensor.py
```

3. **Implement sensor:**
```python
#!/usr/bin/env python3
import paho.mqtt.client as mqtt
import json
import time
import random

BROKER = "localhost"
PORT = 1883
TOPIC = "sensors/temperature/room_01"

class TemperatureSensor:
    def __init__(self):
        self.client = mqtt.Client("temp_room_01")
        self.client.username_pw_set("iot_sensor", "password")
        self.client.on_connect = self.on_connect

    def on_connect(self, client, userdata, flags, rc):
        print(f"✓ Connected: {rc}")

    def publish_reading(self):
        temp = 20 + random.uniform(-2, 2)
        data = {
            "sensor_id": "temp_room_01",
            "temperature": round(temp, 1),
            "timestamp": int(time.time())
        }

        self.client.publish(TOPIC, json.dumps(data), qos=1)
        print(f"📤 Temp: {data['temperature']}°C")

    def run(self):
        self.client.connect(BROKER, PORT)
        self.client.loop_start()

        try:
            while True:
                self.publish_reading()
                time.sleep(60)
        except KeyboardInterrupt:
            self.client.loop_stop()
            self.client.disconnect()

if __name__ == '__main__':
    sensor = TemperatureSensor()
    sensor.run()
```

4. **Run sensor:**
```bash
python3 iot_sensor.py
```

5. **Monitor (separate terminal):**
```bash
mosquitto_sub -h localhost -u dashboard -P password -t "sensors/#" -v
```

---

## 🔄 Цикл 4: MQTT Security (TLS + Certificates) (35 мин)

### 🎬 Сюжет

**Алекс (видеозвонок, urgent):**

*"Li Wei! Wireshark capture показал — MQTT traffic в plaintext! Temperature readings видны. Patterns понятны. Это intelligence leak!"*

**Li Wei:** *"Порт 1883 = no encryption. Нужен 8883 + TLS. Episode 20 SSL certificates remember? Same concept."*

### 📚 Теория: MQTT с TLS

#### Зачем TLS для MQTT?

**Без TLS (порт 1883):**
```
Sensor → Broker: temperature=22.5 (plaintext!)
              ↓
         Wireshark sees: "temperature=22.5"
         Attacker knows: indoor temp, occupancy patterns
```

**С TLS (порт 8883):**
```
Sensor → Broker: [encrypted: 0x8a4f2b...]
              ↓
       Wireshark видит: garbage (зашифровано)
       Attacker: ¯\_(ツ)_/¯
```

**Li Wei:** *"IoT data кажется trivial. 'Просто temperature'. Но patterns reveal behaviour. 22°C в 3am = кто-то дома. 18°C постоянно = никого нет. TLS скрывает это."*

#### Certificate Generation

**1. Create CA (Certificate Authority):**
```bash
# CA private key
openssl genrsa -out ca.key 2048

# CA certificate
openssl req -new -x509 -days 3650 \
  -key ca.key -out ca.crt \
  -subj "/CN=IoT-CA"
```

**2. Server certificate:**
```bash
# Server key
openssl genrsa -out server.key 2048

# Certificate request
openssl req -new -key server.key -out server.csr \
  -subj "/CN=localhost"

# Sign with CA
openssl x509 -req -in server.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 365
```

**3. Client certificate (опционально):**
```bash
openssl genrsa -out client.key 2048
openssl req -new -key client.key -out client.csr \
  -subj "/CN=iot_sensor_01"
openssl x509 -req -in client.csr \
  -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out client.crt -days 365
```

#### Mosquitto TLS конфигурация

```
listener 8883
protocol mqtt

# TLS
cafile /etc/mosquitto/ca.crt
certfile /etc/mosquitto/server.crt
keyfile /etc/mosquitto/server.key

# TLS Version (минимум TLS 1.2!)
tls_version tlsv1.2

# Client Certificate (optional)
require_certificate false
# Set true для mutual TLS (client cert required)
```

**LILITH:** *"TLS 1.0/1.1 deprecated. BEAST, CRIME, POODLE attacks. Only TLS 1.2+ в 2025. Mirai v3 (2018) exploited TLS 1.0 brokers. Protocol downgrade attack. TLS 1.2 minimum, TLS 1.3 preferred."*

#### Python MQTT с TLS

```python
import paho.mqtt.client as mqtt

client = mqtt.Client("secure_sensor")

# TLS setup
client.tls_set(
    ca_certs="/path/to/ca.crt",
    certfile="/path/to/client.crt",  # опционально
    keyfile="/path/to/client.key",    # опционально
    tls_version=mqtt.ssl.PROTOCOL_TLSv1_2
)

# Connect to TLS port
client.connect("localhost", 8883)
```

---

### 💻 Практика: Secure MQTT Setup

**Задание:**

1. **Generate certificates:**
```bash
cd ~/kernel-shadows/season-06-embedded-iot/episode-23-iot-mqtt

# CA
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -out ca.crt -subj "/CN=IoT-CA"

# Server
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr -subj "/CN=localhost"
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 365
```

2. **Configure Mosquitto:**
```bash
sudo cp ca.crt server.crt server.key /etc/mosquitto/certs/

sudo nano /etc/mosquitto/conf.d/tls.conf

# Add:
listener 8883
cafile /etc/mosquitto/certs/ca.crt
certfile /etc/mosquitto/certs/server.crt
keyfile /etc/mosquitto/certs/server.key
tls_version tlsv1.2

sudo systemctl restart mosquitto
```

3. **Test TLS connection:**
```bash
# Publish with TLS
mosquitto_pub -h localhost -p 8883 \
  --cafile ca.crt \
  -u iot_sensor -P password \
  -t "sensors/test" -m "encrypted!"

# Subscribe with TLS
mosquitto_sub -h localhost -p 8883 \
  --cafile ca.crt \
  -u dashboard -P password \
  -t "sensors/#" -v
```

---

## 🔄 Цикл 5: IoT Sensor Network (Multiple Sensors) (30 мин)

### 🎬 Сюжет

**Li Wei запускает dashboard:**

```
Sensors Online: 6
├─ temperature: 3 (room_01, room_02, outdoor)
├─ motion: 2 (entrance, corridor)
└─ door: 1 (main_door)

Last readings:
- room_01: 22.5°C (2s ago)
- entrance: MOTION DETECTED! (5s ago)
- main_door: OPEN (1m ago) ⚠️
```

**Li Wei:** *"Полная sensor network. Real-time. Если Крылов появится — мы знаем. Motion + door opening = alert. Simple but effective."*

### 📚 Теория: Data Aggregation

#### Multi-sensor Architecture

```
        Sensors                   Aggregator              Storage/Alerts

temp_01 ─┐                                            ┌→ InfluxDB
temp_02 ─┼→ [MQTT Broker] → [Python Aggregator] ─┼→ Dashboard
motion ──┼                                            ├→ Alert System
door ────┘                                            └→ Logs
```

#### Aggregator Pattern

```python
import paho.mqtt.client as mqtt
import json

class SensorAggregator:
    def __init__(self):
        self.client = mqtt.Client("aggregator")
        self.client.on_message = self.on_message
        self.sensors = {}

    def on_message(self, client, userdata, msg):
        topic = msg.topic
        data = json.loads(msg.payload.decode())

        # Store latest reading
        self.sensors[topic] = data

        # Process by type
        if "temperature" in topic:
            self.process_temperature(data)
        elif "motion" in topic:
            self.process_motion(data)
        elif "door" in topic:
            self.process_door(data)

    def process_temperature(self, data):
        temp = data['temperature']
        if temp > 25:
            self.alert(f"High temp: {temp}°C")

    def process_motion(self, data):
        if data.get('motion_detected'):
            self.alert("Motion detected!")

    def alert(self, message):
        # Publish to alerts topic
        self.client.publish("alerts/critical", message)
```

---

### 💻 Практика: Complete Sensor Network

**Задание:**

1. **Run multiple sensors (separate terminals):**
```bash
# Terminal 1: Temperature sensor
python3 temp_sensor.py --sensor-id temp_room_01 --topic sensors/temperature/room_01

# Terminal 2: Motion sensor
python3 motion_sensor.py --sensor-id motion_entrance --topic sensors/motion/entrance

# Terminal 3: Door sensor
python3 door_sensor.py --sensor-id door_main --topic sensors/door/main_door
```

2. **Run aggregator:**
```bash
python3 solution/python/iot_aggregator.py
```

3. **Monitor dashboard:**
```bash
mosquitto_sub -h localhost -p 8883 \
  --cafile ca.crt -u dashboard -P password \
  -t "#" -v | grep -E "sensors|alerts"
```

---

## 🔄 Цикл 6: Production Deployment & Monitoring (25 мин)

### 🎬 Сюжет — День 46, deployment

**Виктор:** *"Sensor network готова?"*

**Макс:** *"Да. 6 sensors. MQTT broker с TLS + auth. ACL настроен. Aggregator обрабатывает. Alerts работают."*

**Li Wei:** *"Production checklist: systemd services, auto-restart, log rotation, monitoring, backup config. Всё настроено."*

### 📚 Теория: Production Best Practices

**Systemd services:**
```ini
[Unit]
Description=IoT Temperature Sensor
After=network.target mosquitto.service

[Service]
Type=simple
User=iot
ExecStart=/usr/bin/python3 /opt/iot/temp_sensor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

**Monitoring:**
```bash
# Mosquitto stats
mosquitto_sub -h localhost -t '$SYS/#' -v

# $SYS/broker/clients/connected
# $SYS/broker/messages/received
# $SYS/broker/bytes/received
```

---

### 💻 Практика: Production Setup

```bash
# Create systemd service
sudo cp iot-sensors.service /etc/systemd/system/
sudo systemctl enable iot-sensors
sudo systemctl start iot-sensors

# Monitor
sudo systemctl status iot-sensors
sudo journalctl -u iot-sensors -f
```

---

## 🎯 Финальное задание

### Сюжет — System Online

**Операция successful:**
```
✓ 6 sensors online
✓ MQTT broker secure (TLS, auth, ACL)
✓ Aggregator processing real-time
✓ Alerts система active
✓ Production deployment complete
```

**Li Wei:** *"IoT network готова. Если Крылов появляется — мы знаем. Motion sensors, door sensors, всё под контролем."*

**LILITH:** *"От GPIO (Episode 21) к дронам (22) к IoT сетям (23). Embedded Linux mastery complete. Но помни: IoT — это постоянная война. Firmware updates, vulnerability patching, new attack vectors. Security никогда не заканчивается."*

---

### Итоговая работа

**Обязательно:**

- [ ] Mosquitto broker настроен
- [ ] Authentication работает
- [ ] ACL применён
- [ ] TLS настроен (опционально)
- [ ] Sensors публикуют данные
- [ ] Aggregator обрабатывает
- [ ] systemd services запущены

---

## 🧪 Автотесты

```bash
cd ~/kernel-shadows/season-06-embedded-iot/episode-23-iot-mqtt
./tests/test.sh
```

---

## 📚 Ресурсы

- **MQTT.org:** https://mqtt.org/
- **Mosquitto:** https://mosquitto.org/
- **Paho-MQTT:** https://eclipse.dev/paho/

---

## 🎓 Итоги Episode 23

**Что изучили:**
- ✅ MQTT протокол (pub/sub)
- ✅ Mosquitto broker setup
- ✅ MQTT security (TLS + ACL)
- ✅ Python MQTT (paho-mqtt)
- ✅ IoT sensor networks
- ✅ Production deployment

---

## 🏆 Достижение разблокировано

**IoT Network Engineer! 🌐**

**Макс теперь может:**
- Построить защищённую IoT sensor сеть
- Настроить MQTT broker (Mosquitto)
- Программировать MQTT clients (Python)
- Применить IoT security (TLS, auth, ACL)
- Развернуть production IoT systems

**Li Wei:** *"Season 6 почти завершён. Episode 21 — GPIO. Episode 22 — дроны. Episode 23 — IoT. Episode 24 — kernel modules. From user space к kernel space. Final boss."*

---

**Статус:** Episode 23 ЗАВЕРШЁН ✅
**Далее:** [Episode 24: Kernel Modules & Device Drivers](../episode-24-kernel/)
**Сезон:** [Season 6: Embedded Linux & IoT](../)
**Курс:** [KERNEL SHADOWS](../../../)

---

*"MQTT — это нервная система IoT. Secure it or lose it."* — Li Wei
