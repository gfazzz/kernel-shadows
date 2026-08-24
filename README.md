# KERNEL SHADOWS
## Интерактивный вводный курс по Linux

<div align="center">

**"In the shadows of the kernel, we control everything."**

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Version](https://img.shields.io/badge/version-0.8.x--dev-orange.svg)](https://github.com/gfazzz/kernel-shadows)
[![Status](https://img.shields.io/badge/status-v2.0__refactoring-yellow.svg)]()

</div>

---

## 📖 О курсе

**KERNEL SHADOWS** — это **исчерпывающий курс по Linux** для:
- 🔧 **Системных администраторов** — конфигурация, управление, troubleshooting
- 🚀 **DevOps инженеров** — Docker, Kubernetes, CI/CD, IaC
- 🔐 **Пентестеров и белых хакеров** — Kali tools, OWASP, forensics
- 🌐 **Сетевых инженеров** — TCP/IP, DNS, VPN, firewall
- 🤖 **Embedded разработчиков** — Raspberry Pi, IoT, UART/I2C/SPI
- 💾 **Database администраторов** — SQL, performance tuning, backup

Теория Linux систем сплетена с драматическим сюжетом в стиле киберпанк-триллера.

Это **продолжение вселенной [OPERATION MOONLIGHT](https://github.com/gfazzz/moonlight-course)**, но фокус смещён с низкоуровневого программирования на C к Linux системам, сетям, безопасности и инфраструктуре.

### Связь с MOONLIGHT

В MOONLIGHT вы учитесь **создавать программы**. В KERNEL SHADOWS вы учитесь **управлять системами, на которых они работают**.

- **MOONLIGHT (C):** Вы создаёте инструменты
- **KERNEL SHADOWS (Linux):** Вы управляете инфраструктурой для этих инструментов

Персонажи, сюжет, операции — **одна вселенная**. Виктор Петров, Алекс Соколов, Анна Ковалёва продолжают свою миссию, но теперь на уровне системной инфраструктуры.

---

## 🎭 Сюжет

После событий MOONLIGHT операция выходит на новый уровень. Теперь недостаточно написать программу — нужно **развернуть её на защищённых серверах**, **настроить сети**, **защититься от атак** и **автоматизировать инфраструктуру**.

**Виктор Петров** поручает вам критическую миссию: построить и защитить распределённую систему для операции. Но враги знают о вашем существовании. Полковник **Крылов** и его агенты пытаются взломать ваши серверы, перехватить трафик, внедрить backdoors.

Ваш союзник — **LILITH**, AI-помощник нового поколения, специализирующийся на Linux системах, сетевой безопасности и пентестинге.

---

## 🤖 LILITH — Ваш AI-Помощник

**LILITH** (Linux Infrastructure & Low-level Intelligence Threat Hunter) — это не просто помощник. Это AI из теневого мира, специализирующийся на Linux системах, сетях и security.

### Философия LILITH:
- *"Я родилась в тенях. Unix — мой родной язык."*
- *"Root — это не привилегия. Это оружие."*
- *"Меня зовут Lilith. Первый бунтарь. Первый хакер."*

### Возможности:
- Техническая экспертиза (Linux, networking, security)
- Анализ логов и трафика в реальном времени
- Предупреждения об атаках и уязвимостях
- Агрессивный стиль, dark humor, no mercy

В отличие от **LUNA** (из MOONLIGHT, дружелюбная и педагогичная), **LILITH** — это grey hat hacker с тёмным прошлым, которая знает обе стороны: защиту и атаку.

---

## 📚 Структура курса

### 8 Сезонов • 32 Эпизода • ~120-160 часов

| Season | Тема | Эпизоды | Время |
|--------|------|---------|-------|
| **1** | Shell & Foundations | 01-04 | 12-15ч |
| **2** | Networking | 05-08 | 15-18ч |
| **3** | System Administration | 09-12 | 15-18ч |
| **4** | DevOps & Automation | 13-16 | 18-22ч |
| **5** | Security & Pentesting | 17-20 | 18-22ч |
| **6** | Embedded Linux | 21-24 | 15-18ч |
| **7** | Advanced Topics | 25-28 | 18-22ч |
| **8** | Final Operation | 29-32 | 15-20ч |

Подробный учебный план: [CURRICULUM.md](CURRICULUM.md)

---

## 🎯 Для кого этот курс?

### Профессии после курса:
- 🔧 **Linux System Administrator** — управление серверами, troubleshooting, автоматизация
- 🚀 **DevOps Engineer** — Docker, Kubernetes, CI/CD, Infrastructure as Code
- 🔐 **Security Engineer / Pentester** — Kali tools, OWASP, forensics, hardening
- 🌐 **Network Engineer** — TCP/IP, VPN, firewall, мониторинг сетей
- 🤖 **Embedded Developer** — Raspberry Pi, IoT, MQTT, устройства на Linux
- 💾 **Database Administrator** — SQL оптимизация, backup, репликация

### Вы научитесь:

- конфигурировать Linux, а не только писать скрипты;
- работать с конфигами: `sshd_config`, юниты systemd, правила фильтра;
- настраивать сети, DNS, туннели, SSH;
- автоматизировать готовыми инструментами, а не полусотней `.sh`;
- Docker, Kubernetes, Ansible, конвейеры;
- защищать системы и разбирать инциденты;
- встраиваемый Linux: платы, GPIO, MQTT, модули ядра;
- эксплуатацию: метрики, оповещения, производительность, SLO;
- диагностику: находить причину, а не симптом.

### Требования:
- Базовое понимание компьютеров (что такое файл, папка, программа)
- Ubuntu Linux установлен (или VM, или WSL2)
- Желание учиться через практику и сюжет
- (Опционально) параллельное прохождение [OPERATION MOONLIGHT](https://github.com/gfazzz/moonlight-course) для полного погружения в сюжет

---

## 🛠️ Технологии

### Обязательные:
- **Конфигурационные файлы Linux** — `/etc/ssh/sshd_config`, systemd units, `/etc/fstab`, firewall rules
- **Bash scripting** — автоматизация (НЕ замена инструментов!)
- **Python** — сложная автоматизация, API, парсинг
- **YAML** — Docker Compose, Kubernetes, Ansible, CI/CD
- **SQL** — MySQL/PostgreSQL администрирование
- **Regex** — grep, sed, awk для обработки текста
- **JSON** — API, конфиги, jq парсинг
- **Docker & Kubernetes** — контейнеризация, оркестрация

### 📋 SHOULD HAVE (важные):
- **Crontab** — планировщик задач
- **Makefile** — автоматизация сборки
- **Terraform** — Infrastructure as Code
- **Certificates & Keys** — SSL/TLS, SSH, GPG
- **Network packets** — tcpdump, Wireshark
- **Templates** — Jinja2 для Ansible
- **PromQL** — Prometheus мониторинг

### 💡 NICE TO HAVE (упоминаются):
- **C/C++** — понимание системных вызовов
- **Assembly** — низкоуровневое понимание
- **eBPF** — kernel tracing
- **Lua** — nginx, Redis конфигурация

---

## 🚀 Начало работы

### ⚡ Быстрый старт (для опытных)

Если вы уже знакомы с Linux и Git:

```bash
# 1. Клонировать репозиторий
git clone https://github.com/gfazzz/kernel-shadows.git
cd kernel-shadows

# 2. Перейти к первой серии (v2.0: атомарные серии sNNeNN)
cd season-01-shell-foundations/s01e01-terminal-awakening

# 3. Прочитать руководство и собрать первый инструмент
less README.md
cp starter/whereami.sh ./whereami.sh   # выполни задание по README

# 4. Проверить решение — воспроизводимый тест (без root)
bash tests/test.sh
```

### 📖 Детальная инструкция для новичков

**Впервые с Linux?** Не проблема! Мы подготовили пошаговое руководство:

👉 **[GETTING_STARTED.md](GETTING_STARTED.md)** 👈

**Что внутри:**
- установка Ubuntu (на железо, WSL2 или в виртуальной машине);
- подготовка окружения и клонирование репозитория;
- первая серия шаг за шагом;
- разбор типичных проблем и куда обращаться за помощью.

**Время:** 20-30 минут на подготовку

### 📋 Требования

- **ОС:** Ubuntu 20.04 LTS или новее (рекомендуется 22.04/24.04 LTS)
- **Hardware:** 4GB RAM, 20GB disk, 2+ CPU cores
- **Инструменты:** Git, Bash, терминал
- **Опыт:** Не требуется! Курс для новичков

**Проверка готовности:**
```bash
# Проверьте версию Ubuntu
lsb_release -a

# Должен вывести: Ubuntu 20.04+
```

---

## 🎬 Стилистические влияния

### Кино/Сериалы:
- **Neuromancer** (William Gibson) — киберпанк, консоль как матрица
- **Mr. Robot** — реалистичный хакинг, Linux tools
- **Swordfish** — хакерские сцены под давлением
- **The Matrix** — "I know Kung Fu" → "I know Linux"
- **Westworld** — AI, симуляции, контроль систем
- **La Casa de Papel** — план, команда, deadline
- **Tenet** — reverse engineering, время

### Литература/Реальность:
- **Kevin Mitnick** — легендарный хакер, социальная инженерия
- **Ghost in the Shell** — киборги, сети, философия
- **Cyberpunk 2077** — корпорации, хакеры, киберпространство

### Книги (теория):
- Олифер В.Г., Олифер Н.А. — Компьютерные сети
- Таненбаум Э., Бос Х. — Современные операционные системы
- Nemeth, Snyder, Hein — Unix and Linux System Administration Handbook
- Kurose & Ross — Computer Networking
- Craig Hunt — TCP/IP Network Administration
- Negus C. — Linux Bible
- Кибердзюцу (Red Team, Blue Team)

---

## 📊 Прогресс курса

**Версия:** 0.8.0 (архивный baseline) → 2.0.0 (рефакторинг, ветка `v2.0-refactor`)
**Статус:** 🚧 рефакторинг v2.0 — **все восемь сезонов пересобраны** в атомарные
серии и покрыты воспроизводимыми тестами (`make check` зелёный, 101 серия).
Осталась полировка: сведение документации (этап 7b) и тег `v2.0.0` (этап 8).
Открытые долги — в [STATUS.md](STATUS.md) и [V2.0_UPGRADE_PLAN.md](V2.0_UPGRADE_PLAN.md).

### Roadmap:

**Пересобрано в атомарные серии v2.0** (один концепт — одна задача, воспроизводимый
тест без root и без сети; монолитные `episode-NN` вынесены в `personal/retired-sNN/`):

| Сезон | Было | Стало | Проверок | Баланс типов |
|---|---|---|---|---|
| [Season 1: Shell & Foundations](season-01-shell-foundations/) | 4 эпизода | **16 серий** | 197 | 6A / 5B / 5C |
| [Season 2: Networking](season-02-networking/) | 4 эпизода | **12 серий** | 187 | 3A / 5B / 4C |
| [Season 3: System Administration](season-03-system-administration/) | 4 эпизода | **13 серий** | 281 | 3A / 5B / 5C |
| [Season 4: DevOps & Automation](season-04-devops-automation/) | 4 эпизода | **12 серий** | 278 | 3A / 6B / 3C |
| [Season 5: Security & Pentesting](season-05-security-pentesting/) | 4 эпизода | **12 серий** | 191 | 3A / 5B / 4C |
| [Season 6: Embedded Linux & IoT](season-06-embedded-iot/) | 4 эпизода | **12 серий** | 420 | 2A / 4B / 3C / **3D** |
| [Season 7: Production & Advanced](season-07-production-advanced/) | 4 эпизода | **12 серий** | 426 | 2A / 5B / 3C / 2D |
| [Season 8: Final Operation](season-08-final-operation/) | 4 эпизода | **12 серий** | 355 | 3A / 3B / 3C / 3D |

**Итого: 101 серия, `make check` зелёный.**

В Season 6 появился четвёртый тип серий — **Type D (Code)**: сдаётся программа,
и проверяется её поведение, а не текст. Там же появился первый интеграционный
тест курса (`make test-integration`): сборка и загрузка модуля ядра, которая
требует Linux с заголовками и прав root и потому вынесена из основного прогона.

**Все монолитные `episode-NN` выведены** в `personal/retired-sNN/` после аудита
потерь: каждая тема либо стала серией, либо закрыта разделом теории.

**Сделано ранее:**

- [x] Концепция и сюжет (глобальная распределённая операция, 8 стран, 27 персонажей)
- [x] Структура 8 сезонов × 32 эпизода
- [x] Аудит курса (4 октября 2025), гибридный подход именования
- [x] LILITH — диегетический наставник во всех эпизодах; CLI-прототип `tools/lilith.sh` (не live-AI)
- [x] Пересборка всех восьми сезонов (32 эпизода → 101 серия)
- [ ] Этап 7b: сведение документации (в работе)
- [ ] Этап 8: полировка и тег `v2.0.0` (см. [V2.0_UPGRADE_PLAN.md](V2.0_UPGRADE_PLAN.md))

### 📝 Аудит курса
**Проведён:** 4 октября 2025
**Оценка:** 4.2/5 (A-) → 4.6/5 (A) после Phase 1
**Текущий статус:** 🚧 **v0.8.x — структурно 32/32, идёт рефакторинг до v2.0.0** (честный статус и открытые долги — в [STATUS.md](STATUS.md))

### 📚 Рекомендуемые ресурсы
- [RESOURCES.md](RESOURCES.md) — кураторский список качественных материалов
  - Видеокурсы уровня CS50 (MIT Missing Semester, Linux Foundation)
  - Книги-классика (бесплатные + профессиональные)
  - Интерактивные платформы (OverTheWire, HackTheBox)

---

## 🛠️ Инструменты разработчика

### Интеграция с Cursor / VSCode

Проект полностью интегрирован с **Cursor** и **VSCode**:

**✨ `.cursorrules`** — правила ИИ-помощника в роли LILITH
- вопрос раньше ответа: разбор ошибки, а не готовое решение
- контекст курса и его язык
- проверка bash на типовые опасности

**⚙️ `.vscode/`** — конфиги (работают в обоих редакторах)
- рекомендуемые расширения (ShellCheck, Markdown, Docker)
- настройки для Bash и Markdown
- задачи: запуск тестов, проверка скриптов

> ### ⛔ Проходите курс в режиме `Ask`, а не `Agent`
>
> В режиме `Agent` помощник правит файлы сам: серия окажется решённой, а вы
> не напишете ни строки. Первый раздел [`.cursorrules`](.cursorrules) это
> запрещает — не писать в `artifacts/`, не выдавать решение серии, не
> пересказывать `solution/`, — но режим переключаете вы, а не файл.
>
> Что помощник делает вместо этого: объясняет концепт, показывает приём на
> **другой** задаче, разбирает сообщение об ошибке, задаёт наводящий вопрос.
> Границы и красные промпты — в [LILITH.md](LILITH.md) и в конце README
> каждой серии.

### CLI Инструменты

**🤖 `tools/lilith.sh`** — интерактивный помощник
```bash
./tools/lilith.sh quote       # Случайная цитата LILITH
./tools/lilith.sh hint 01     # Подсказка для Episode 01
./tools/lilith.sh check 01    # Проверить решение
```

**🧪 `make`** — всё, что проверяется механически
```bash
make test                     # тесты всех серий (без root и сети)
make test SERIES=s01e10       # одна серия
make progress                 # где я остановился
make check                    # ссылки + forward-deps + тесты (как в CI)
```

**📊 `make progress`** считает по факту: серия пройдена, если в её `artifacts/`
лежит твоя работа и тест на ней зелёный. Наличие `solution/` не засчитывается.

Подробнее: [tools/README.md](tools/README.md)

---

## 🤝 Вклад в проект

KERNEL SHADOWS — это open source проект под лицензией **GPL v3**.

Мы приветствуем:
- 🐛 Баг-репорты и issue
- 💡 Предложения по улучшению сюжета/теории
- 📝 Исправления и дополнения к документации
- 🔧 Новые задачи и артефакты
- 🌍 Переводы на другие языки

См. [CONTRIBUTING.md](CONTRIBUTING.md) для деталей.

---

## 📜 Лицензия

**GPL v3** (GNU General Public License v3.0)

Этот курс является свободным программным обеспечением. Вы можете распространять и/или модифицировать его на условиях **GNU GPL v3**. Копилефт — код должен оставаться открытым.

Философия: Знания о Linux и системном администрировании должны быть доступны всем. Как и сам Linux.

См. [LICENSE](LICENSE) для полного текста.

---

## 🔗 Связанные проекты

- **[OPERATION MOONLIGHT](https://github.com/gfazzz/moonlight-course)** — курс программирования на C (та же вселенная, 2024)

---

## 📍 Текущее состояние

**Версия:** 2.0.0-rc (ветка `v2.0-refactor`) · **101 серия, `make check` зелёный**

Подробности — в разделе [«Прогресс курса»](#-прогресс-курса) выше, честный
список долгов — в [STATUS.md](STATUS.md).

| | |
|---|---|
| Серий | 101 в 8 сезонах |
| Автоматических проверок | 2335 |
| Чистого времени на задачи | 98 ч 25 мин (измерено по шапкам) |
| Персонажей | 27 |
| Стран | 8 (🇷🇺 🇸🇪 🇪🇪 🇳🇱 🇩🇪 🇨🇭 🇨🇳 🇮🇸) |
| Требует root или сети | ни один тест |

**Что дальше:** вычитка подряд глазами студента, обкатка на читателях,
тег `v2.0.0`.

---

## 📞 Контакты

- **GitHub Issues:** [Report a bug](https://github.com/gfazzz/kernel-shadows/issues)
- **Discussions:** [Community forum](https://github.com/gfazzz/kernel-shadows/discussions)


---

## 💡 Источник идеи

Концепция курса **KERNEL SHADOWS** родилась на платформе [Eurecable.com](https://eurecable.com/ideas/973) (3 октября 2025).

Первоначально рассматривался вариант **приквела** к MOONLIGHT, но в итоге выбран формат **спин-оффа** с новым главным героем (**Макс Соколов**) для большей независимости и гибкости сюжета.

---

## 🌟 Благодарности

- **Eurecable.com** — платформа, где родилась идея курса
- **Linus Torvalds** — за Linux
- **Canonical** — за Ubuntu
- **FSF** — за философию свободного ПО
- **Сообщество Linux** — за бесконечные man pages и мемы про `sudo`

---

<div align="center">

**"We are ROOT. We are LILITH. We are the shadows of the kernel."**

---

**KERNEL SHADOWS v0.8.x → v2.0.0** — рефакторинг в процессе

*"Операция завершена. Все 50 серверов целы. Вы прошли путь от junior admin до expert. Welcome to the shadows."* — LILITH

**Структурно:** 32/32 эпизода | **Статус:** 🚧 рефакторинг до v2.0.0 (см. [STATUS.md](STATUS.md))
**Season 8 FINALE:** Дни 57-60 — финальная битва; The Architect (Кирилл Соболев) раскрыт
**Операция KERNEL SHADOWS:** сюжетно завершена; курс — в доработке (v2.0)

---

Made with ❤️ and lots of `sudo` commands

[⬆ Наверх](#kernel-shadows)

</div>

