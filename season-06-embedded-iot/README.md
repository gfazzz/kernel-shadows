# Season 6: Embedded Linux & IoT Security

> *"Hardware — это где software встречает реальность. И там всё сложнее."*

```
Локация: 🇨🇳 Шэньчжэнь, Китай
Дни операции: 41-48 (8 дней)
Время прохождения: 18-22 часа
Сложность: ⭐⭐⭐⭐⭐
```

---

## 📋 Обзор сезона

**Season 6** — самый технически продвинутый сезон курса. Погружение в **embedded Linux, IoT security, hardware hacking**. От Raspberry Pi до дронов, от GPIO до firmware reverse engineering.

**Контекст:**
Viktor: *"Нужна разведка. Дроны. Летишь в Шэньчжэнь — hardware Silicon Valley мира."*

Max в Китае. Huaqiangbei electronics market — можно купить ВСЁ. Li Wei (ex-DJI engineer) обучает embedded Linux + IoT security. Сборка дронов, kernel modules, hardware protocols, real-time systems.

**ОПАСНОСТЬ:** Крылов пытается перехватить drone через UART exploitation. Китайская слежка. Firmware backdoors в чипах. Быстрый выезд после миссии.

---

## 🌍 Локация: Шэньчжэнь

### Huaqiangbei Electronics Market
- **Крупнейший electronics рынок мира**
- Можно купить: Raspberry Pi, sensors, drones, chips, всё
- 10-этажные здания электроники
- Li Wei: *"Здесь делают 90% мировых дронов"*

### DJI Headquarters
- Мировой лидер дронов
- Li Wei — бывший инженер
- Доступ к advanced UAV tech

### Shenzhen Maker Spaces
- Hardware hacking labs
- 3D printing, PCB assembly
- IoT протotyping
- *"От идеи до prototype за 24 часа"*

**Атмосфера:** Неоновый киберпанк IRL. Рынки × technology. Китайская surveillance everywhere. Быстрый темп. Everything manufactured here.

---

## 🆕 v2.0: пересборка в атомарные серии (в работе)

Season 6 мигрирует с монолитных `episode-NN` (1314–1571 строк) на атомарные серии
`sNNeNN`: один концепт — одна задача, README 180–280 строк, воспроизводимый тест
без root и без железа. План — [`V2.0_UPGRADE_PLAN.md`](../V2.0_UPGRADE_PLAN.md), этап 6.

**Дробление 4 эпизодов → 12 серий:**

| Серия | Из ep | Концепт | Артефакт | Type | Статус |
|-------|-------|---------|----------|------|--------|
| s06e01 | 21 | что это за плата: `/proc/cpuinfo`, device-tree, архитектура | `board_report.txt` | **C** | ✅ 24 |
| s06e02 | 21 | GPIO через sysfs: включить и не сжечь | `gpio_ctl.sh` | **A** | ✅ 32 |
| s06e03 | 21 | загрузка платы: `config.txt`, `cmdline.txt` | `config.txt` + `cmdline.txt` | **B** | ✅ 24 |
| s06e04 | 21 | устройство без диска: overlayfs, износ SD | `fstab` | **B** | ✅ 28 |
| s06e05 | 22 | телеметрия дрона: разбор потока MAVLink | `telemetry_report.txt` | **C** | ✅ 27 |
| s06e06 | 22 | план миссии: валидатор маршрута до вылета | `check_mission.sh` | **A** | ✅ 22 |
| s06e07 | 22 | отказоустойчивость: failsafe, RTL, геозона | `failsafe.params` | **B** | план |
| s06e08 | 23 | MQTT: топики, QoS, retained — разбор дампа | `mqtt_report.txt` | **C** | план |
| s06e09 | 23 | брокер: `mosquitto.conf`, ACL, TLS | `mosquitto.conf` + ACL | **B** | план |
| s06e10 | 23 | клиент-датчик на Python | `sensor.py` | **D** | план |
| s06e11 | 24 | модуль ядра: сборка, загрузка, параметры | `shadow_mod.c` | **D** | план |
| s06e12 | 24 | символьное устройство (финал сезона) | `shadow_dev.c` | **D** | план |

Целевой баланс по §2A: 2 × Type A, 4 × Type B, 3 × Type C, **3 × Type D**. Здесь
Type D появляется впервые в курсе: до сих пор студент писал скрипты и правил
конфигурации, теперь пишет программу на языке общего назначения — и отвечает
за её **поведение**, а не за текст.

**Сквозной артефакт сезона — `shadow_mesh`:** сеть наблюдения, которая собирается
по сериям. Плата опознаётся и настраивается (`s06e01`–`s06e04`), дрон летает по
проверенному маршруту (`s06e05`–`s06e07`), датчики сдают телеметрию через брокер
(`s06e08`–`s06e10`), а в финале появляется своё ядро-устройство, отдающее данные
без посредников (`s06e11`–`s06e12`).

**Чем проверяется без железа и без root.** Платы, дрона и брокера у студента нет,
поэтому предмет проверки — снимки в `data/` (`/proc/cpuinfo`, дерево устройств,
поток телеметрии, дамп MQTT) и конфигурации как текст. GPIO мокается каталогом
`sysfs` во временной папке: интерфейс ядра здесь — это обычные файлы, и запись в
них проверяется без единого провода.

**Как тестируется Type D.** Логика выносится из «ядерной» обвязки в отдельный
файл и проверяется настоящими юнит-тестами через `gcc` в пользовательском
пространстве — кольцевой буфер, разбор параметров, границы записи. Исходник
модуля дополнительно проверяется структурно (`module_init`/`module_exit`,
`MODULE_LICENSE`, освобождение ресурсов на пути ошибки). Сборка настоящего `.ko`
и его загрузка — отдельная цель `make test-integration`, которая требует Linux с
заголовками ядра и правами; основной прогон остаётся зелёным везде.

Прогнать тесты сезона: `make test SEASON=season-06-embedded-iot`.

---

## 📚 Эпизоды

### Episode 21: Raspberry Pi & GPIO Programming
**Время:** 4-5 часов  
**Тип:** Embedded Basics (Type B + C programming)  
**Локация:** Шэньчжэнь

**Чему научитесь:**
- Embedded Linux architecture
- Raspberry Pi setup и GPIO control
- C programming для hardware (не MOONLIGHT уровень!)
- Device Tree и bootloaders (U-Boot)
- Remote access и camera streaming

**Инструменты:**
- Raspberry Pi 4/5
- GPIO libraries (WiringPi, gpiod)
- C compiler (cross-compilation)
- SSH, camera tools

**Сюжет:**
Dmitry Orlov: *"Нам нужна камера наблюдения. Raspberry Pi + Ubuntu."* Viktor: *"Установи у здания Крылова. Скрытно."* Скрытая surveillance система на базе RPi. Live stream × stealth mode.

---

### Episode 22: Drones & UAV Control
**Время:** 5-6 часов  
**Тип:** UAV Programming (Type B)  
**Локация:** Шэньчжэнь (DJI)

**Чему научитесь:**
- UAV (Unmanned Aerial Vehicle) architecture
- MAVLink protocol
- ArduPilot/PX4 autopilots
- Autonomous flight programming
- Command encryption (UART security)

**Инструменты:**
- ArduPilot на Linux board
- MAVLink protocol
- Python для drone control
- GPS/IMU telemetry

**Сюжет:**
Li Wei (ex-DJI): *"Дрон для разведки. Но Крылов может перехватить команды через UART. Шифруй всё."* Autonomous drone для surveillance. Encryption для защиты от hijacking.

---

### Episode 23: IoT Security & MQTT
**Время:** 4-5 часов  
**Тип:** IoT Configuration (Type B)  
**Локация:** Шэньчжэнь

**Чему научитесь:**
- IoT architecture и protocols
- MQTT broker setup (Mosquitto)
- TLS encryption для MQTT
- Sensor networks
- Firmware security basics

**Инструменты:**
- MQTT (Mosquitto broker)
- TLS certificates
- IoT sensors (temperature, motion)
- Python MQTT clients

**Сюжет:**
Zhang Mei (IoT architect): *"50 sensors. Вся инфраструктура. MQTT — standard. Но без TLS — это open book для Крылова."* Secure IoT sensor network. Encrypted communication. Real-time monitoring.

---

### Episode 24: Kernel Modules & Device Drivers
**Время:** 5-6 часов  
**Тип:** Advanced C (Type B)  
**Локация:** Шэньчжэнь

**Чему научитесь:**
- Linux kernel modules
- Device drivers basics
- Character devices
- Hardware interrupts
- Real-time Linux (PREEMPT_RT)

**Инструменты:**
- Kernel development tools
- Module compilation
- Device driver frameworks
- Real-time patches

**Сюжет:**
Li Wei: *"Custom hardware. Нужен driver. Kernel module. C programming hardcore."* Chen Xiaoming: *"Real-time constraints. Миллисекунды matter."* Custom driver для proprietary sensor. Kernel-level programming. **МАКСИМАЛЬНАЯ СЛОЖНОСТЬ.**

---

## 🎓 Результаты обучения

После прохождения Season 6 вы сможете:

**Embedded Linux:**
- ✅ Настраивать Raspberry Pi для production
- ✅ Программировать GPIO на C
- ✅ Понимать Device Tree и bootloaders
- ✅ Cross-compilation для ARM

**UAV/Drones:**
- ✅ Управлять дронами через MAVLink
- ✅ Программировать autonomous flight
- ✅ Шифровать команды управления
- ✅ Работать с telemetry (GPS, IMU)

**IoT Security:**
- ✅ Настраивать MQTT broker с TLS
- ✅ Создавать secure sensor networks
- ✅ Понимать firmware security
- ✅ Защищать IoT от UART/I2C attacks

**Kernel Development:**
- ✅ Писать kernel modules
- ✅ Создавать device drivers
- ✅ Работать с hardware interrupts
- ✅ Настраивать Real-time Linux

---

## 🛠️ Технологии сезона

### Languages
- **C/C++** — GPIO, kernel modules, drivers (hardcore!)
- **Python** — IoT automation, drone control
- **Shell scripts** — startup automation

### Hardware
- **Raspberry Pi** — embedded Linux platform
- **Drones** — UAV control, ArduPilot
- **Sensors** — GPIO, I2C, SPI
- **Custom hardware** — device drivers

### Protocols
- **GPIO** — hardware pins control
- **UART/I2C/SPI** — hardware communication
- **MAVLink** — drone protocol
- **MQTT** — IoT messaging

### Security
- **Firmware security** — reverse engineering, backdoor detection
- **MQTT TLS** — encrypted IoT
- **Secure boot** — защита от tampering
- **UART encryption** — защита hardware protocols

---

## ⚖️ Баланс Type A vs Type B

Season 6 фокус на embedded и IoT:

- **Episode 21** (Type B + C): Embedded basics — Raspberry Pi, GPIO programming
- **Episode 22** (Type B): UAV control — Drones, MAVLink, Python
- **Episode 23** (Type B): IoT — MQTT, TLS, sensor networks
- **Episode 24** (Type B + Advanced C): Kernel — modules, drivers, real-time

**Ratio:** 90% configuration + C programming, 10% bash scripts

**Философия:** Embedded Linux — это не scripting. Это C programming + hardware understanding + security.

---

## 🎭 Персонажи

### Li Wei (Episodes 21-22, 24)
- Ex-DJI drone engineer
- Embedded Linux expert
- Философия: *"Hardware — это где bugs могут убить. Literally. Дрон падает — люди гибнут. Code quality критична."*
- Обучает: GPIO, drones, kernel modules

### Chen Xiaoming (Episode 22, 24)
- ArduPilot core developer
- Real-time systems expert
- Философия: *"Real-time — это не 'быстро'. Это 'гарантированно вовремя'. Миллисекунда опоздания = failure."*
- Обучает: UAV control, real-time Linux

### Zhang Mei (Episode 23)
- IoT architect
- MQTT и firmware security expert
- Философия: *"IoT без security — это миллионы ботнетов. Mirai DDos было только начало."*
- Обучает: MQTT, IoT security, firmware

### Antagonists
- **Крылов (ФСБ):** Пытается перехватить drone через UART
- **Китайская слежка:** Surveillance за Max в Шэньчжэне
- **"Новая Эра":** Firmware backdoors в китайских чипах

---

## 🚨 Ключевые моменты сезона

### Episode 21: Surveillance начинается
Raspberry Pi камера установлена у здания Крылова. Live stream работает. Скрытая surveillance.

### Episode 22: Drone hijacking attempt
Крылов пытается перехватить drone через UART. Li Wei: *"Шифруй команды. AES."* Атака отражена. Autonomous flight успешен.

### Episode 23: IoT backdoor найден
Zhang Mei находит backdoor в китайском IoT chip. Firmware reverse engineering. Vulnerability патчнута.

### Episode 24: Custom driver (КУЛЬМИНАЦИЯ)
Kernel module для proprietary sensor. **МАКСИМАЛЬНАЯ СЛОЖНОСТЬ.** C programming на kernel level. Real-time constraints. Драйвер работает. Sensor online.

**Результат:** Вся surveillance infrastructure готова. Дроны. Камеры. Sensors. Всё зашифровано. Готово к финалу.

---

## 📊 Статистика сезона

- **Эпизоды:** 4
- **Время:** 18-22 часа
- **C lines написано:** 500+
- **Kernel modules:** 2
- **Дронов собрано:** 1 (autonomous)
- **IoT sensors deployed:** 50+
- **MQTT messages encrypted:** 1000s
- **Firmware backdoors найдено:** 1
- **UART hijacking attempts blocked:** 1
- **Китайская слежка:** Постоянная

---

## 🔗 Связь с другими сезонами

**Prerequisites:**
- Season 1-5 обязательны
- **MOONLIGHT C knowledge** (если есть) — огромный плюс для Episodes 21, 24

**Season 6 подготавливает к:**
- **Season 7:** Production monitoring (Prometheus для IoT)
- **Season 8:** Финальная битва (все системы используются)

**Интеграция навыков:**
- C (MOONLIGHT) → GPIO programming, kernel modules
- Python (MOONLIGHT S4) → drone control, MQTT
- Security (S5) → IoT security, firmware analysis
- Networking (S2) → MQTT, UART protocols

---

## 💡 Философия Season 6

### Hardware Reality Check

Li Wei: *"Software bugs — crash. Hardware bugs — physical damage. Drone падает — $10,000 убытков. Medical device fails — люди гибнут. Embedded programming — это ответственность."*

### Real-time Constraints

Chen Xiaoming: *"Real-time Linux — это не про скорость. Это про predictability. Лучше медленно но гарантированно, чем быстро но непредсказуемо."*

### IoT Security Crisis

Zhang Mei: *"Каждый IoT device — это potential botnet member. Mirai было 100,000 devices. Сейчас миллиарды IoT. One misconfiguration — millions compromised."*

### Embedded Mindset

LILITH: *"Embedded Linux — это Linux без safety net. No GUI. No forgiveness. Direct hardware access. One pointer error — hardware damage. Think twice. Code once."*

---

## 🎯 Финал сезона

**День 48, вечер. Шэньчжэнь. Lab.**

Viktor (видеозвонок): *"Surveillance infrastructure ready?"*

Max: *"Да. Raspberry Pi камеры — online. Drone autonomous flight — tested. 50 IoT sensors — encrypted MQTT. Kernel driver — работает. Всё готово."*

Li Wei: *"Firmware backdoors найдены и удалены. Китайские чипы — чисты. UART encryption — active. Крылов не перехватит."*

Zhang Mei: *"MQTT TLS configured. Real-time monitoring. Если что-то двигается — мы знаем."*

**Анна (Interpol, видеозвонок):** *"Surveillance данные получаю. Excellent work. Episode 19 forensics + Episode 21-24 hardware = complete intelligence system."*

**Chen Xiaoming:** *"Макс, ты за 8 дней прошёл путь от Linux sysadmin до embedded engineer. GPIO, drones, IoT, kernel modules. Impressive. Если захочешь работать в DJI — рекомендую."*

**LILITH:** *"Embedded Linux освоен. Hardware hacking понят. IoT security — на практике. Season 7 — production deployment, Kubernetes, monitoring всей этой инфраструктуры. Готов?"*

**Макс смотрит на стол. Raspberry Pi. Drone. Sensors. Oscilloscope. Kernel logs на экране.**

**Макс:** *"Готов. Везём это всё в Исландию."*

**Viktor:** *"Season 7 — Reykjavik. Deployment в production. Финальная подготовка. Season 8 — война. Но сейчас — отдохни. Earned it."*

---

## ➡️ Что дальше?

**Season 7: Advanced Topics & Production**  
Локация: Рейкьявик, Исландия 🇮🇸  
Технологии: Kubernetes, Prometheus, Grafana, advanced networking

---

> **"Hardware — это реальность. Software — это абстракция. Embedded Linux — это где они встречаются. И там всё становится по-настоящему интересно."** — Li Wei

---

**Season 6 Status:** структурно 4/4 эпизода на месте (ep21–24). Открытые долги v2.0: достроить ep24 (готовый `.ko` вместо заглушки) и ep23; обновить CURRICULUM (ep23/24); см. [STATUS.md](../STATUS.md).
**Первый эпизод:** [Episode 21: Raspberry Pi & GPIO Programming](./episode-21-raspberry-pi/)
