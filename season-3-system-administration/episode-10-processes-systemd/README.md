# EPISODE 10: PROCESSES & SYSTEMD
## Season 3: System Administration | Санкт-Петербург, Россия

> *"Init scripts — это прошлое. SystemD — это будущее. И настоящее."*
> — **Борис Кузнецов**, SystemD Architect

---

## 📍 Контекст миссии

**Локация:** 🇷🇺 **Санкт-Петербург, Россия**
**Место:** Коворкинг на Невском проспекте → Лаборатория ЛЭТИ
**День операции:** **19-20** из 60
**Время прохождения:** **4-5 часов**
**Сложность:** ⭐⭐⭐☆☆ (Средняя)

**Персонажи:**
- **Макс Соколов** — вы, изучаете системное администрирование
- **Борис Кузнецов** — SystemD архитектор, ex-Red Hat contributor
- **Анна Ковалёва** — forensics expert, обнаружила backdoor
- **Виктор Петров** — координатор операции
- **LILITH** — AI-помощник (я!)

---

## 🎬 Сюжет: Охота на процессы-призраки

### День 19. Санкт-Петербург. 08:37 Moscow Time.

После успешной настройки permissions (Episode 09), Макс получает срочный видеозвонок от Анны.

**Анна Ковалёва** (взволнованно):
*"Макс, мы нашли ещё один backdoor! На сервере в Питере запущен процесс `sshd_backup`. PID 6623. Выглядит как обычный SSH демон, но это маскировка. Крылов прячет вредоносные процессы под именами системных служб."*

**Макс:**
*"Как он туда попал? Мы же закрыли все уязвимости!"*

**Анна:**
*"Backdoor был установлен ДО того как мы взяли контроль. Запущен от пользователя с sudo правами. Ты должен научиться управлять процессами на production серверах. Иначе следующую атаку мы не заметим вовремя."*

**Виктор Петров:**
*"Макс, в Питере есть человек который может помочь. Борис Кузнецов. Ex-разработчик Red Hat, работал над systemd в 2013-2017. Он научит тебя управлять процессами правильно. Выезжай в коворкинг на Невском, 122."*

---

### 10:00. Встреча с Борисом Кузнецовым.

Макс входит в просторный коворкинг. За столом у окна сидит мужчина ~35 лет: борода, толстовка с надписью **"systemd or die"**, MacBook Pro с Fedora Linux.

**Борис** (энергично пожимая руку):
*"Макс! Виктор рассказал о вашей проблеме. Backdoor процессы — это классика. Но если ты ПОНИМАЕШЬ systemd, ты контролируешь ВСЁ. Init scripts — это прошлое. Systemd — это факт."*

**Макс:**
*"Я слышал много споров про systemd. Говорят он слишком монолитный..."*

**Борис** (усмехается):
*"Споры — это эмоции старой гвардии. SystemD — это факт. Ubuntu, Fedora, Debian, RHEL — все перешли. Знаешь почему? Потому что он РАБОТАЕТ. Да, он сложнее чем init scripts. Но он даёт контроль над КАЖДЫМ аспектом процесса: ресурсы, безопасность, логи, зависимости."*

**Анна** (видеозвонок):
*"Борис прав. Я анализирую инциденты через journalctl каждый день. Без systemd я бы не увидела 80% атак."*

**Борис:**
*"Давай по порядку. Сначала процессы — что это, как они живут в памяти. Потом systemd — как управлять сервисами production-grade. Потом journalctl — как читать что происходит. К концу дня ты будешь контролировать все процессы на сервере."*

Борис открывает ноутбук и запускает терминал.

**Борис:**
*"Процесс — это программа в оперативной памяти. У каждого есть PID, owner, parent, дети. Linux — это дерево процессов. Корень дерева — systemd (PID 1). Всё остальное — ветви."*

---

## 🎯 Твоя миссия

Научиться **управлять процессами и сервисами** на production Linux сервере.

**Цели:**
1. ✅ Понять как работают процессы в Linux (PID, PPID, дерево)
2. ✅ Найти и убить backdoor процесс от Крылова
3. ✅ Создать production-ready systemd service для мониторинга
4. ✅ Настроить systemd timer (замена cron)
5. ✅ Научиться анализировать логи через journalctl
6. ✅ Установить resource limits и security hardening

**Итог:**
Production-ready мониторинг системы с автоматическим запуском, resource limits, логированием и автоперезапуском.

---

## 📁 Структура файлов

```
episode-10-processes-systemd/
├── README.md                  # 📖 Теория + задания (этот файл)
│
├── starter/                   # 🎯 НАЧНИ ЗДЕСЬ!
│   ├── systemd/               # SystemD units с TODO комментариями
│   │   ├── shadow-backup.service      # Backup task (Type=oneshot)
│   │   ├── shadow-backup.timer        # Scheduler для backup
│   │   └── shadow-monitor.service     # Monitoring daemon (Type=simple)
│   └── README.md              # 📋 Workflow: как работать с starter
│
├── solution/                  # ✅ Референсное решение (не подглядывай!)
│   ├── systemd/               # Готовые systemd units
│   │   ├── shadow-backup.service
│   │   ├── shadow-backup.timer
│   │   ├── shadow-monitor.service
│   │   └── README.md          # Документация solution
│   ├── process_manager.sh     # Вспомогательный скрипт (опционально)
│   └── README.md              # Полный workflow решения
│
├── artifacts/                 # 🗂️ Тестовые данные (если нужны)
│   └── README.md
│
└── tests/                     # 🧪 Автотесты
    └── test.sh                # Проверка твоего решения
```

### 🚀 Как начать?

1. **Прочитай теорию** в этом README (8 micro-cycles ниже)
2. **Открой `starter/README.md`** — там полный workflow с командами
3. **Заполни TODO** в systemd units (`starter/systemd/`)
4. **Установи units** в `/etc/systemd/system/`
5. **Тестируй** через `systemctl` и `journalctl`
6. **Запусти автотесты** `./tests/test.sh`

---

## 🎓 Философия Episode: Type B — Конфигурируй напрямую

**Episode 10 — это Type B episode.**

❌ **НЕ пиши bash wrapper вокруг systemctl!**
✅ **Учись писать systemd units напрямую!**

**Почему?**
- SystemD units — это стандарт в Linux (Ubuntu, RHEL, Fedora, Debian)
- Production серверы используют systemd, не custom bash scripts
- Bash для автоматизации команд, НЕ для замены инструментов

**Борис:**
*"Systemd уже умеет всё: запуск, остановка, перезапуск, мониторинг, resource limits, автоперезапуск. Не переписывай его в bash. Просто настрой правильно."*

---

## 📚 ТЕОРИЯ: 8 MICRO-CYCLES

### Навигация по циклам:
- **Цикл 1:** Философия процессов (10 мин) → Что такое процесс
- **Цикл 2:** Управление процессами (15 мин) → ps, top, kill
- **Цикл 3:** SystemD Service Units (20 мин) → Создание .service
- **Цикл 4:** SystemD Timers (15 мин) → Замена cron
- **Цикл 5:** Resource Limits & Security (20 мин) → CPUQuota, NoNewPrivileges
- **Цикл 6:** Journalctl (15 мин) → Логи и troubleshooting
- **Цикл 7:** Практика (20 мин) → Заполнение starter/ units
- **Цикл 8:** Финальный мониторинг (10 мин) → Production-ready setup

**Общее время:** ~2 часа теории + 2-3 часа практики = **4-5 часов**

---

## 🔄 ЦИКЛ 1: Философия процессов (10-15 минут)

### 🎬 Сюжет

**Борис** (открывает терминал):
*"Смотри. Сейчас на этом ноутбуке работает 287 процессов. Каждая программа — это процесс. Браузер — процесс. Твой bash — процесс. Systemd — процесс. Linux — это дерево процессов."*

```bash
$ pstree -p
systemd(1)─┬─systemd-journal(342)
           ├─sshd(1024)───sshd(6623)───bash(6624)
           ├─nginx(1456)─┬─nginx(1457)
           │             ├─nginx(1458)
           │             └─nginx(1459)
           └─firefox(8821)─┬─firefox(8822)
                           ├─firefox(8823)
                           └─firefox(8824)
```

**Борис:**
*"Видишь? Systemd (PID 1) — корень. Всё остальное — его дети, внуки, правнуки. Если systemd умрёт — вся система умрёт. Он — главный процесс."*

---

### 📚 Теория: Что такое процесс?

#### 🏭 Метафора: Процесс = Рабочий на фабрике

Представь Linux систему как **гигантскую фабрику**.

```
🏭 LINUX FACTORY
│
├─ 👷 Рабочий #1 (PID 1) — "Systemd"
│  ├─ 👷 Рабочий #342 — "Журналист" (пишет логи)
│  ├─ 👷 Рабочий #1024 — "Охранник SSH" (принимает входы)
│  │  └─ 👷 Рабочий #6623 — "Помощник охранника"
│  ├─ 👷 Рабочие #1456-1459 — "Nginx (веб-сервер)"
│  └─ 👷 Рабочие #8821-8824 — "Firefox (браузер)"
```

**Каждый рабочий:**
- Имеет **бейдж с номером** (PID = Process ID)
- Знает **кто его нанял** (PPID = Parent Process ID)
- Выполняет **конкретную задачу** (программа)
- Использует **ресурсы** (CPU, память, файлы)
- Может **создавать помощников** (child processes)
- Может **умереть** (завершиться) или **быть уволен** (kill)

**Системный администратор = директор фабрики.**
Ты контролируешь кто работает, сколько ресурсов использует, кого нанять, кого уволить.

---

#### 🎯 Ключевые концепты

##### 1. **PID (Process ID)**

**Уникальный номер** каждого процесса.

```bash
$ ps aux | head -3
USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1   0.0  0.1 169064 13944 ?        Ss   10:00   0:01 /sbin/systemd
root       342   0.0  0.0  45780  6124 ?        Ss   10:00   0:00 systemd-journal
```

- **PID 1** — всегда systemd (или init)
- **PID 342** — systemd-journald (логи)
- **PID 6623** — backdoor процесс Крылова (!)

**Борис:**
*"Если ты знаешь PID — ты можешь убить процесс. `kill 6623`. Но сначала надо его найти."*

---

##### 2. **PPID (Parent Process ID)**

**Кто создал этот процесс?**

```bash
$ ps -o pid,ppid,cmd
  PID  PPID CMD
    1     0 /sbin/systemd
 1024     1 /usr/sbin/sshd
 6623  1024 /tmp/sshd_backup  ← backdoor! Parent = sshd
 6624  6623 bash
```

**Дерево:**
```
systemd (1)
 └─ sshd (1024)
     └─ sshd_backup (6623)  ← ПОДОЗРИТЕЛЬНО!
         └─ bash (6624)
```

**Анна:**
*"Видишь? Backdoor (6623) запущен от sshd (1024). Кто-то зашёл через SSH и запустил вредоносный процесс. Это вектор атаки."*

---

##### 3. **Process States (состояния)**

Процесс может быть в разных состояниях:

| Состояние | Код | Описание |
|-----------|-----|----------|
| **Running** | `R` | Выполняется сейчас (использует CPU) |
| **Sleeping** | `S` | Ждёт события (I/O, сигнал) |
| **Stopped** | `T` | Остановлен (Ctrl+Z) |
| **Zombie** | `Z` | Завершился, но parent не забрал exit code |
| **Dead** | — | Процесс больше не существует |

```bash
$ ps aux | grep -E 'STAT|nginx'
USER       PID  %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root      1456   0.0  0.1 125696  8420 ?        Ss   10:00   0:00 nginx: master
www-data  1457   0.0  0.0 126144  5632 ?        S    10:00   0:00 nginx: worker
```

- **`Ss`** — Sleeping (ждёт подключений), session leader
- **`S`** — Sleeping (worker ждёт задач от master)

**Борис:**
*"Zombie процессы — это мёртвые процессы которые не были 'похоронены'. Parent должен вызвать wait(). Если zombies накапливаются — это bug в программе."*

---

##### 4. **Дерево процессов**

Linux процессы организованы в **дерево** (tree).

```
     systemd (PID 1)
     /      |      \
   ssh    nginx   cron
   /
 bash
  |
 vim
```

**Борис:**
*"Systemd — это корень дерева. Если убить systemd (kill -9 1) — система умрёт. Все процессы получат SIGTERM и завершатся. Kernel паникует."*

**Полезная команда:**
```bash
# Показать дерево процессов
pstree -p

# Дерево для конкретного процесса
pstree -p 1024  # дерево для sshd
```

---

### 💻 Практика: Инспекция процессов

**Задание:** Найди backdoor процесс `sshd_backup` (или любой подозрительный процесс).

#### Шаг 1: Посмотри все процессы

```bash
# Все процессы
ps aux

# Только sshd процессы
ps aux | grep sshd

# Альтернатива: pgrep
pgrep -a sshd
```

**Что искать?**
- ❌ Процесс с именем похожим на системный (sshd_backup, cron_worker)
- ❌ Процесс в неожиданном месте (`/tmp/`, `/home/user/.hidden/`)
- ❌ Процесс от обычного пользователя с правами root

---

#### Шаг 2: Детальный анализ подозрительного процесса

```bash
# Найти PID
suspicious_pid=$(pgrep -f sshd_backup)

# Проверить путь к исполняемому файлу
ls -l /proc/$suspicious_pid/exe

# Проверить аргументы командной строки
cat /proc/$suspicious_pid/cmdline | tr '\0' ' '

# Проверить environment variables
cat /proc/$suspicious_pid/environ | tr '\0' '\n'

# Проверить открытые файлы
sudo lsof -p $suspicious_pid
```

**Борис:**
*"`/proc` — это виртуальная файловая система. Kernel экспортирует информацию о процессах как файлы. `/proc/PID/` содержит ВСЁ о процессе."*

---

### 🤔 Проверка понимания

**Вопрос 1:** Что такое PID 1 и почему его нельзя убить?

<details>
<summary>💡 Думай 30 секунд перед проверкой</summary>

**Ответ:**
PID 1 — это **systemd** (или init), первый процесс который запускает kernel после загрузки.

**Почему нельзя убить:**
- Это корень дерева процессов
- Все остальные процессы — его дети (прямые или косвенные)
- Если PID 1 умрёт → kernel паникует → система останавливается
- Linux kernel защищает PID 1 от обычных сигналов

**Борис:** *"Systemd — это сердце системы. Если сердце остановится — смерть."*

</details>

---

**Вопрос 2:** В чём разница между процессом в состоянии `R` и `S`?

<details>
<summary>💡 Подсказка</summary>

**Ответ:**
- **`R` (Running):** Процесс СЕЙЧАС использует CPU, выполняет инструкции
- **`S` (Sleeping):** Процесс ЖДЁТ события (I/O, сигнал, timeout)

**Метафора:**
- `R` = рабочий активно работает на конвейере
- `S` = рабочий ждёт когда придёт следующая деталь

**Пример:**
- Веб-сервер nginx: состояние `S` (ждёт HTTP запросов)
- Компиляция gcc: состояние `R` (активно компилирует код)

**Борис:** *"Большинство процессов 99% времени в состоянии S. Только когда есть работа — переходят в R."*

</details>

---

**Вопрос 3:** Что такое zombie процесс?

<details>
<summary>💡 Ответ</summary>

**Zombie (Z) процесс:**
- Процесс **завершился**, но его parent ещё **не забрал exit code**
- Занимает место в таблице процессов, но НЕ использует CPU/память
- Отображается как `<defunct>` в `ps`

**Как появляется:**
```
1. Child процесс завершается (exit)
2. Kernel сохраняет exit code
3. Child ждёт пока parent вызовет wait()
4. Пока parent не вызвал wait() — child = zombie
```

**Как убить zombie:**
❌ `kill -9 zombie_pid` — НЕ РАБОТАЕТ (процесс уже мёртв!)
✅ Убить parent процесс → systemd "усыновит" zombie → zombie исчезнет

**Борис:** *"Zombies не опасны, но если их сотни — это bug в parent программе. Она забывает вызывать wait()."*

</details>

---

### ✅ Чеклист Цикл 1

- [ ] Понял что такое процесс (программа в памяти)
- [ ] Знаю что такое PID, PPID
- [ ] Понимаю дерево процессов (systemd = корень)
- [ ] Умею найти процесс через `ps`, `pgrep`
- [ ] Могу проверить детали процесса через `/proc/PID/`

**LILITH:**
*"Процесс — это не просто команда. Это живой объект в памяти. У него есть identity (PID), родители (PPID), ресурсы, состояние. Научись читать процессы как книгу."*

---

## 🔄 ЦИКЛ 2: Управление процессами (15-20 минут)

### 🎬 Сюжет

**Борис** (продолжает):
*"Окей, ты нашёл backdoor процесс. PID 6623. Что дальше? Убить? Не так быстро. В Linux есть правильный способ остановить процесс — signals (сигналы)."*

**Макс:**
*"Signals? Это как `kill -9`?"*

**Борис:**
*"Kill -9 — это SIGKILL. Грубая сила. 'Выстрел в голову'. Процесс НЕ может его игнорировать. Но есть вежливый способ — SIGTERM. 'Пожалуйста, завершись корректно'. Процесс может сохранить данные, закрыть файлы, почистить ресурсы."*

**Анна:**
*"В production ВСЕГДА сначала SIGTERM. Потом, если не помогает — SIGKILL. Грубое убийство может повредить данные."*

---

### 📚 Теория: Signals (сигналы)

#### 📨 Метафора: Signals = Сообщения рабочим

Представь что ты — директор фабрики. Ты не можешь физически остановить рабочего. Но ты можешь **отправить ему сообщение**:

```
📨 Сообщения (Signals):
┌─────────────────────────────────────┐
│ "Пожалуйста, закончи работу"       │ ← SIGTERM (15)
│ "Перезагрузи своё рабочее место"   │ ← SIGHUP (1)
│ "НЕМЕДЛЕННО ОСТАНОВИСЬ!"           │ ← SIGKILL (9)
│ "Пауза, подожди команды"           │ ← SIGSTOP (19)
│ "Продолжай работу"                 │ ← SIGCONT (18)
└─────────────────────────────────────┘
```

Рабочий (процесс) может:
- ✅ **Принять сообщение** и выполнить (обработать signal)
- ✅ **Игнорировать** (если сигнал не SIGKILL)
- ❌ **НЕ может игнорировать** SIGKILL и SIGSTOP (принудительные)

---

#### 🎯 Основные сигналы

| Сигнал | Номер | Действие | Можно игнорировать? |
|--------|-------|----------|---------------------|
| **SIGTERM** | 15 | Вежливая просьба завершиться | ✅ Да |
| **SIGKILL** | 9 | Принудительное убийство | ❌ Нет |
| **SIGHUP** | 1 | Reload конфигурации | ✅ Да |
| **SIGINT** | 2 | Interrupt (Ctrl+C) | ✅ Да |
| **SIGSTOP** | 19 | Заморозить процесс | ❌ Нет |
| **SIGCONT** | 18 | Продолжить после SIGSTOP | — |
| **SIGUSR1/2** | 10/12 | Пользовательские сигналы | ✅ Да |

---

#### 📡 Как отправить сигнал

##### Команда `kill`

```bash
# SIGTERM (default, вежливо)
kill 6623

# То же самое явно
kill -15 6623
kill -TERM 6623

# SIGKILL (принудительно)
kill -9 6623
kill -KILL 6623

# SIGHUP (reload конфига)
kill -1 6623
kill -HUP 6623
```

**Борис:**
*"`kill` — плохое название. Оно не 'убивает', оно 'отправляет сигнал'. kill -HUP не убивает, а просит перезагрузить конфиг."*

---

##### Команда `killall` и `pkill`

```bash
# Убить ВСЕ процессы с именем "sshd_backup"
killall sshd_backup

# То же через pkill (regex)
pkill -f sshd_backup

# Убить все процессы пользователя "attacker"
pkill -u attacker

# SIGTERM для всех nginx workers
killall -15 nginx
```

**⚠️ ОСТОРОЖНО:**
`killall nginx` убьёт ВСЕ nginx процессы (master + workers)!

---

### 💻 Практика: Правильное убийство процесса

#### 📜 Алгоритм graceful shutdown

**Правило:**
1️⃣ Сначала SIGTERM (вежливо)
2️⃣ Подожди 5-10 секунд
3️⃣ Проверь жив ли ещё
4️⃣ Если жив — SIGKILL (принудительно)

```bash
#!/bin/bash

# Найти PID backdoor процесса
pid=$(pgrep -f sshd_backup)

if [[ -z "$pid" ]]; then
    echo "Process not found"
    exit 1
fi

echo "Found backdoor: PID $pid"
ps -p "$pid" -o pid,user,cmd

# Шаг 1: SIGTERM (вежливо)
echo "Sending SIGTERM..."
kill -15 "$pid"

# Шаг 2: Подожди 5 секунд
sleep 5

# Шаг 3: Проверка
if ps -p "$pid" > /dev/null 2>&1; then
    echo "⚠️  Process still alive. Sending SIGKILL..."
    kill -9 "$pid"
    sleep 1
fi

# Шаг 4: Финальная проверка
if ps -p "$pid" > /dev/null 2>&1; then
    echo "❌ Failed to kill process"
    exit 1
else
    echo "✓ Process killed successfully"
fi
```

**Анна:**
*"В production так делают для баз данных, веб-серверов. SIGTERM даёт процессу время закрыть соединения, записать данные. SIGKILL — это аварийная кнопка."*

---

### 📊 Команды для мониторинга процессов

#### 1. `ps` — Process Status

```bash
# Все процессы (BSD style)
ps aux

# Все процессы (UNIX style)
ps -ef

# Конкретный процесс
ps -p 6623

# Custom формат вывода
ps -eo pid,ppid,user,%cpu,%mem,cmd

# Процессы конкретного пользователя
ps -u www-data
```

**Колонки:**
- **PID** — Process ID
- **%CPU** — % использования CPU
- **%MEM** — % использования памяти
- **VSZ** — Virtual memory Size (KB)
- **RSS** — Resident Set Size (физическая память, KB)
- **STAT** — Состояние (R, S, Z, etc.)
- **START** — Время запуска
- **TIME** — CPU время (сколько процессор работал на этот процесс)
- **COMMAND** — Команда

---

#### 2. `top` / `htop` — Real-time мониторинг

```bash
# Интерактивный мониторинг
top

# Сортировка по CPU: P
# Сортировка по Memory: M
# Убить процесс: k (ввести PID)
# Выход: q
```

**Улучшенная версия: `htop`**

```bash
# Установить
sudo apt install htop

# Запустить
htop

# Преимущества:
# - Цветной интерфейс
# - Дерево процессов (F5)
# - Поиск (F3)
# - Фильтр (F4)
# - Kill через меню (F9)
```

**Борис:**
*"htop — это top на стероидах. Установи его на production серверах. Troubleshooting станет в 10 раз быстрее."*

---

#### 3. `pgrep` / `pkill` — Find/Kill by name

```bash
# Найти PID по имени процесса
pgrep nginx
# Вывод: 1456

# С деталями (cmd)
pgrep -a nginx
# Вывод: 1456 nginx: master process

# По regex
pgrep -f "sshd.*backup"

# Убить по имени
pkill nginx

# Убить по regex
pkill -f "python.*malicious"

# Убить процессы пользователя
pkill -u attacker
```

---

#### 4. `pstree` — Дерево процессов

```bash
# ASCII дерево всех процессов
pstree

# С PID
pstree -p

# Для конкретного процесса
pstree -p 1456

# С аргументами
pstree -a
```

**Пример вывода:**
```
systemd(1)─┬─systemd-journal(342)
           ├─sshd(1024)───bash(6624)───vim(6625)
           └─nginx(1456)─┬─nginx(1457)
                         ├─nginx(1458)
                         └─nginx(1459)
```

---

#### 5. `/proc` filesystem — Виртуальная ФС процессов

```bash
# Все процессы
ls /proc/
# 1/  342/  1024/  6623/  ...

# Информация о процессе 6623
ls /proc/6623/
# cmdline  environ  exe  fd/  maps  status  ...

# Путь к исполняемому файлу
ls -l /proc/6623/exe

# Аргументы командной строки
cat /proc/6623/cmdline | tr '\0' ' '

# Environment variables
cat /proc/6623/environ | tr '\0' '\n'

# Открытые файлы
ls -l /proc/6623/fd/

# Подробная статистика
cat /proc/6623/status
```

**Борис:**
*"`/proc` — это окно в kernel. Всё что kernel знает о процессах экспортируется как файлы. Хочешь знать что делает процесс? Загляни в `/proc/PID/`."*

---

### 🤔 Проверка понимания

**Вопрос 1:** В чём разница между SIGTERM и SIGKILL?

<details>
<summary>💡 Ответ</summary>

| SIGTERM (15) | SIGKILL (9) |
|--------------|-------------|
| Вежливая просьба завершиться | Принудительное убийство |
| Процесс МОЖЕТ обработать (cleanup) | Процесс НЕ МОЖЕТ обработать |
| Можно игнорировать | НЕЛЬЗЯ игнорировать |
| Graceful shutdown | Immediate termination |

**Аналогия:**
- SIGTERM = "Пожалуйста, закончи работу и уйди"
- SIGKILL = "Выход → сейчас!" (охранник выталкивает)

**Когда использовать:**
- ✅ Production: всегда сначала SIGTERM, потом SIGKILL
- ✅ Debugging: SIGTERM чтобы процесс мог записать логи
- ❌ SIGKILL только если процесс завис и не реагирует

**Борис:** *"SIGTERM = культура. SIGKILL = варварство. Будь культурным администратором."*

</details>

---

**Вопрос 2:** Почему `kill -9 1` не работает?

<details>
<summary>💡 Подумай перед ответом</summary>

**Ответ:**
PID 1 (systemd/init) защищён kernel от всех сигналов, включая SIGKILL.

**Почему:**
- PID 1 — это корень дерева процессов
- Если PID 1 умрёт → kernel паникует → система останавливается
- Kernel игнорирует ANY сигналы для PID 1

**Что будет если попробовать:**
```bash
$ sudo kill -9 1
# Команда "успешна", но ничего не происходит
# Systemd продолжает работать

$ ps -p 1
  PID TTY          TIME CMD
    1 ?        00:00:01 systemd
```

**Единственный способ остановить systemd:**
```bash
# Выключение системы
sudo systemctl poweroff

# Перезагрузка
sudo systemctl reboot
```

**Борис:** *"Kernel защищает PID 1 как мать защищает ребёнка. Никто не может его убить."*

</details>

---

**Вопрос 3:** Что делает команда `pkill -u attacker`?

<details>
<summary>💡 Ответ</summary>

**Ответ:**
Убивает (SIGTERM) ВСЕ процессы пользователя `attacker`.

**Что происходит:**
1. `pkill` ищет все процессы где `user == attacker`
2. Отправляет SIGTERM каждому процессу
3. Процессы пользователя `attacker` завершаются

**Пример:**
```bash
# Злоумышленник запустил 3 процесса
$ ps -u attacker
  PID TTY      TIME CMD
 6623 ?        0:00 sshd_backup
 6624 ?        0:00 bash
 6625 ?        0:00 nc -l 4444

# Убить всё
$ sudo pkill -u attacker

# Проверка
$ ps -u attacker
# (пусто)
```

**⚠️ ОСТОРОЖНО:**
Эта команда убьёт ВСЕ процессы пользователя (SSH сессии, cron jobs, etc.)!

**Безопаснее:**
```bash
# Заблокировать пользователя (не сможет логиниться)
sudo usermod -L attacker

# Затем убить процессы
sudo pkill -u attacker
```

**Анна:** *"После обнаружения взлома я всегда делаю: 1) pkill -u attacker, 2) usermod -L attacker, 3) passwd -l attacker. Тройная защита."*

</details>

---

### ✅ Чеклист Цикл 2

- [ ] Понимаю что такое signals (сообщения процессам)
- [ ] Знаю разницу SIGTERM vs SIGKILL
- [ ] Умею правильно убивать процесс (graceful shutdown)
- [ ] Знаком с `ps`, `top`, `htop`, `pgrep`, `pkill`
- [ ] Могу инспектировать процесс через `/proc/PID/`

**LILITH:**
*"Kill — это не просто 'убить'. Это отправка сигнала. SIGTERM = вежливая просьба. SIGKILL = приказ. В production всегда вежливость сначала."*

---

## 🔄 ЦИКЛ 3: SystemD Service Units (20-25 минут)

### 🎬 Сюжет

**Борис** (закрывает `htop`):
*"Окей, ты нашёл backdoor и убил его. Но что дальше? Крылов может запустить его снова если найдёт вектор. Нужен ПОСТОЯННЫЙ мониторинг. Сервис который будет работать 24/7."*

**Макс:**
*"Bash скрипт в бесконечном цикле?"*

**Борис** (качает головой):
*"Нет. Production-grade решение — это systemd service. Автозапуск при загрузке, автоперезапуск при крашах, resource limits, логирование в journalctl, интеграция с security features. Всё что нужно."*

**Виктор** (видеозвонок):
*"Борис прав. Наши серверы используют systemd. Макс, научись писать service units. Это стандарт индустрии."*

---

### 📚 Теория: SystemD Service Units

#### 🏗️ Метафора: Service Unit = Контракт с рабочим

Представь что ты нанимаешь рабочего (процесс) на фабрику. Ты пишешь **контракт** (service unit):

```
📄 ТРУДОВОЙ ДОГОВОР (Service Unit)
═══════════════════════════════════════

[Секция 1: Общая информация]
- Название должности: "Shadow Monitor"
- Описание работы: "Мониторинг системы на backdoors"
- Документация: https://...
- Зависимости: начинать работу ПОСЛЕ запуска сети

[Секция 2: Условия работы]
- Тип работы: постоянная (не разовая)
- Пользователь: shadow-monitor (НЕ root!)
- Рабочая директория: /var/operations/shadow-monitor
- Команда запуска: /usr/local/bin/shadow-monitor.sh
- Лимит CPU: максимум 25%
- Лимит памяти: максимум 128MB
- Политика перезапуска: перезапускать если упал

[Секция 3: Условия активации]
- Запускать: при старте системы
- Цель: multi-user.target (многопользовательский режим)
═══════════════════════════════════════
```

SystemD читает этот контракт и управляет рабочим (процессом) согласно условиям.

---

#### 🎯 Структура Service Unit

Service unit — это **INI-файл** в `/etc/systemd/system/servicename.service`.

**Минимальный пример:**

```ini
[Unit]
Description=Shadow Monitor Service

[Service]
ExecStart=/usr/local/bin/shadow-monitor.sh

[Install]
WantedBy=multi-user.target
```

Этого достаточно чтобы создать простой сервис!

---

#### 📋 Три основные секции

##### 1. **[Unit]** — Метаданные и зависимости

```ini
[Unit]
Description=KERNEL SHADOWS System Monitor
Documentation=https://github.com/kernel-shadows/episode-10

# Зависимости (порядок запуска)
After=network-online.target
Wants=network-online.target
Requires=systemd-journald.service
```

**Ключевые опции:**
- **`Description`** — описание сервиса (показывается в `systemctl status`)
- **`After=`** — запускать ПОСЛЕ этих units
- **`Before=`** — запускать ПЕРЕД этими units
- **`Wants=`** — хочет чтобы этот unit запустился (но не обязательно)
- **`Requires=`** — ТРЕБУЕТ чтобы этот unit запустился (иначе fail)
- **`Conflicts=`** — не может работать одновременно с этим unit

**Борис:**
*"Зависимости — это порядок запуска. After=network → сервис запустится ПОСЛЕ сети. Логично для мониторинга который шлёт алерты по сети."*

---

##### 2. **[Service]** — Как запускать и управлять

```ini
[Service]
Type=simple
User=shadow-monitor
WorkingDirectory=/var/operations/shadow-monitor
ExecStart=/usr/local/bin/shadow-monitor.sh

# Restart policy
Restart=on-failure
RestartSec=10s

# Resource limits
CPUQuota=25%
MemoryLimit=128M

# Security
NoNewPrivileges=true
PrivateTmp=true
```

**Ключевые опции:**
- **`Type=`** — тип сервиса (simple, forking, oneshot, etc.)
- **`User=`**, **`Group=`** — от какого пользователя запускать
- **`ExecStart=`** — команда для запуска
- **`ExecStartPre=`** — команды перед запуском (проверки)
- **`ExecStartPost=`** — команды после запуска
- **`ExecStop=`** — команда для остановки (default: SIGTERM)
- **`Restart=`** — политика перезапуска
- **`RestartSec=`** — пауза перед перезапуском
- **`WorkingDirectory=`** — рабочая директория

---

##### 3. **[Install]** — Когда активировать

```ini
[Install]
WantedBy=multi-user.target
```

**Ключевые опции:**
- **`WantedBy=`** — в каком target включать этот сервис
- **`RequiredBy=`** — какой target ТРЕБУЕТ этот сервис

**Targets (упрощённо):**
- **`multi-user.target`** — многопользовательский режим (без GUI)
- **`graphical.target`** — графический режим (с GUI)
- **`timers.target`** — для timer units

**Борис:**
*"[Install] нужна только если ты делаешь `systemctl enable`. Enable создаёт symlink в `/etc/systemd/system/multi-user.target.wants/`. Так systemd знает что запускать при загрузке."*

---

#### 🎨 Типы сервисов (Type=)

| Тип | Описание | Пример |
|-----|----------|--------|
| **simple** | Долго работающий процесс (default) | Веб-сервер, мониторинг |
| **forking** | Процесс делает fork и завершается | Nginx, Apache (старый стиль) |
| **oneshot** | Запускается, выполняется, завершается | Backup, setup scripts |
| **notify** | Процесс уведомляет systemd когда готов | Сложные демоны (PostgreSQL) |
| **idle** | Запускается когда все jobs завершены | Низкоприоритетные задачи |

**Для 90% случаев:**
- **`simple`** — для долго работающих демонов
- **`oneshot`** — для задач которые завершаются

---

### 💻 Практика: Создание service unit

#### Задача: Создать `shadow-monitor.service`

**Требования:**
- Мониторинг подозрительных процессов
- Запуск от непривилегированного пользователя `shadow-monitor`
- Автоперезапуск при падении
- Resource limits (CPU 25%, Memory 128MB)
- Логи в journalctl

**Шаг 1: Создать пользователя**

```bash
# Системный пользователь (no login shell)
sudo useradd -r -s /bin/false shadow-monitor

# Рабочая директория
sudo mkdir -p /var/operations/shadow-monitor
sudo chown shadow-monitor:shadow-monitor /var/operations/shadow-monitor
```

---

**Шаг 2: Создать скрипт мониторинга**

```bash
sudo nano /usr/local/bin/shadow-monitor.sh
```

```bash
#!/bin/bash
# Shadow Monitor - Episode 10

LOG_TAG="shadow-monitor"

log_message() {
    logger -t "$LOG_TAG" "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

check_suspicious_processes() {
    # Проверка backdoor процессов
    suspicious=$(ps aux | grep -E 'sshd_backup|backdoor' | grep -v grep)

    if [[ -n "$suspicious" ]]; then
        log_message "⚠️  ALERT: Suspicious process detected!"
        log_message "$suspicious"
    fi
}

log_message "Shadow Monitor started"

while true; do
    check_suspicious_processes
    sleep 30  # Проверка каждые 30 секунд
done
```

```bash
# Сделать исполняемым
sudo chmod +x /usr/local/bin/shadow-monitor.sh
```

---

**Шаг 3: Создать service unit**

SystemD units создаются в `/etc/systemd/system/`.

```bash
sudo nano /etc/systemd/system/shadow-monitor.service
```

```ini
[Unit]
Description=KERNEL SHADOWS System Monitor
Documentation=https://github.com/kernel-shadows/episode-10
After=network-online.target
Wants=network-online.target
Requires=systemd-journald.service

[Service]
Type=simple
User=shadow-monitor
Group=shadow-monitor
WorkingDirectory=/var/operations/shadow-monitor

ExecStart=/usr/local/bin/shadow-monitor.sh

# Pre-checks
ExecStartPre=/usr/bin/test -f /usr/local/bin/shadow-monitor.sh
ExecStartPre=/usr/bin/test -x /usr/local/bin/shadow-monitor.sh

# Restart policy
Restart=on-failure
RestartSec=10s
StartLimitBurst=5
StartLimitIntervalSec=60s

# Resource limits
CPUQuota=25%
MemoryLimit=128M
TasksMax=50

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectHome=true
ProtectSystem=strict

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=shadow-monitor

[Install]
WantedBy=multi-user.target
```

---

**Шаг 4: Активация сервиса**

```bash
# Reload systemd (обязательно после изменений!)
sudo systemctl daemon-reload

# Проверить синтаксис
sudo systemd-analyze verify shadow-monitor.service

# Запустить сервис
sudo systemctl start shadow-monitor.service

# Проверить статус
sudo systemctl status shadow-monitor.service

# Включить автозапуск при загрузке
sudo systemctl enable shadow-monitor.service

# Проверить что enabled
sudo systemctl is-enabled shadow-monitor.service
```

---

**Шаг 5: Мониторинг**

```bash
# Real-time логи
sudo journalctl -u shadow-monitor.service -f

# Последние 50 строк
sudo journalctl -u shadow-monitor.service -n 50

# С момента загрузки системы
sudo journalctl -u shadow-monitor.service -b

# Только ошибки
sudo journalctl -u shadow-monitor.service -p err
```

---

### 🧪 Тестирование автоперезапуска

```bash
# Найти PID сервиса
PID=$(systemctl show shadow-monitor.service -p MainPID --value)

# Убить процесс (симуляция краша)
sudo kill -9 "$PID"

# Подождать 10 секунд (RestartSec=10s)
sleep 10

# Проверить статус
sudo systemctl status shadow-monitor.service

# Должно быть:
# Active: active (running)
# Main PID: [новый PID]
# Restarts: 1
```

**Борис:**
*"Видишь? Сервис упал, systemd автоматически перезапустил. Restart=on-failure работает. Это и есть production-ready setup."*

---

### 🤔 Проверка понимания

**Вопрос 1:** В чём разница между Type=simple и Type=oneshot?

<details>
<summary>💡 Ответ</summary>

| Type=simple | Type=oneshot |
|-------------|--------------|
| Долго работающий процесс | Запускается, выполняется, завершается |
| Не завершается сам | Завершается после выполнения задачи |
| Примеры: nginx, monitoring | Примеры: backup, setup scripts |

**Примеры:**

**simple:**
```bash
#!/bin/bash
while true; do
    check_system
    sleep 60
done
```

**oneshot:**
```bash
#!/bin/bash
create_backup
cleanup_old_backups
exit 0
```

**Борис:** *"Simple = daemon. Oneshot = task. Если скрипт завершается — oneshot. Если крутится в цикле — simple."*

</details>

---

**Вопрос 2:** Зачем нужен `systemctl daemon-reload`?

<details>
<summary>💡 Ответ</summary>

**Ответ:**
SystemD кэширует unit files в памяти для быстрого доступа.

**Что делает daemon-reload:**
1. Перечитывает все unit files из `/etc/systemd/system/`
2. Обновляет внутренний кэш systemd
3. Применяет изменения (новые units, изменённые units)

**Когда нужен:**
- ✅ После создания нового unit файла
- ✅ После изменения существующего unit файла
- ✅ После удаления unit файла

**Что будет если забыть:**
```bash
$ sudo systemctl start shadow-monitor.service
Failed to start shadow-monitor.service: Unit shadow-monitor.service not found.

$ sudo systemctl daemon-reload
$ sudo systemctl start shadow-monitor.service
✓ Started shadow-monitor.service
```

**Борис:** *"Забыл daemon-reload? SystemD не видит твои изменения. Это самая частая ошибка новичков."*

</details>

---

**Вопрос 3:** Почему User=shadow-monitor, а не root?

<details>
<summary>💡 Principle of Least Privilege</summary>

**Ответ:**
**Principle of Least Privilege:** давать только те привилегии которые НЕОБХОДИМЫ.

**Почему НЕ root:**
- ❌ Мониторинг НЕ требует root привилегий
- ❌ Если сервис скомпрометирован → атакующий получит root
- ❌ Root процесс может повредить систему при ошибке в коде

**Когда root необходим:**
- ✅ Backup всех файлов системы
- ✅ Изменение сетевых настроек
- ✅ Управление другими сервисами

**Best practice:**
```ini
# ❌ Плохо
User=root

# ✅ Хорошо
User=shadow-monitor  # непривилегированный пользователь

# ✅ Ещё лучше
User=shadow-monitor
NoNewPrivileges=true  # запретить повышение привилегий
ProtectSystem=strict  # read-only система
ProtectHome=true      # нет доступа к /home
```

**Анна:** *"Каждый процесс от root — это потенциальная точка входа для атакующего. Минимизируй использование root."*

</details>

---

### ✅ Чеклист Цикл 3

- [ ] Понимаю структуру service unit ([Unit], [Service], [Install])
- [ ] Знаю разницу Type=simple vs Type=oneshot
- [ ] Могу создать пользователя для сервиса
- [ ] Умею написать service unit файл
- [ ] Знаю команды: daemon-reload, start, stop, enable, disable, status
- [ ] Понимаю зачем Principle of Least Privilege

**LILITH:**
*"Service unit — это не просто 'запустить скрипт'. Это контракт: что делать, как делать, когда делать, с какими ресурсами, с какой безопасностью. Production-grade thinking."*

---

## 🔄 ЦИКЛ 4: SystemD Timers — Замена Cron (15-20 минут)

### 🎬 Сюжет

**Борис:**
*"Мониторинг работает 24/7. Отлично. Теперь backup. Нам нужно делать backup каждый день в 2 ночи. Классическое решение — cron. Но мы используем systemd timers."*

**Макс:**
*"Почему не cron? Он же проще..."*

**Борис:**
*"Cron прост, да. Но systemd timers дают больше: dependency management, logging в journalctl, resource limits, persistent (если сервер был выключен во время запуска — timer запустит задачу при включении). Всё что нужно для production."*

---

### 📚 Теория: SystemD Timers

#### ⏰ Метафора: Timer = Будильник для рабочего

Представь фабрику с **ночным сторожем** (timer):

```
🏭 FACTORY AT NIGHT
│
├─ 🕐 02:00 — Будильник звенит
│  └─ 📞 Звонок рабочему: "Пора делать backup!"
│      └─ 👷 Рабочий просыпается, делает backup, уходит спать
│
├─ 🕐 03:00 — (ничего не происходит)
├─ 🕐 04:00 — (ничего не происходит)
...
└─ 🕐 02:00 (следующий день) — Будильник снова звенит
```

**Cron:**
- Будильник проверяет время каждую минуту
- Если время совпало → запускает задачу
- Не знает что делать если сервер был выключен

**SystemD Timer:**
- Будильник интегрирован в систему
- Знает зависимости (запускать ПОСЛЕ сети)
- Persistent=true → запустит задачу если сервер был выключен
- Логи в journalctl (видно когда запускалось, успешно ли)

---

#### 🎯 Структура Timer + Service

SystemD timer состоит из **ДВУХ файлов**:

1. **`.service`** — **ЧТО** делать (backup task)
2. **`.timer`** — **КОГДА** делать (расписание)

```
shadow-backup.service  ← ЧТО: создать backup
shadow-backup.timer    ← КОГДА: каждый день в 02:00
```

**Борис:**
*"Separation of concerns. Service знает КАК делать backup. Timer знает КОГДА запускать service. Чистая архитектура."*

---

#### 📋 Пример: Backup Timer

**Файл 1: `shadow-backup.service`** (ЧТО делать)

```ini
[Unit]
Description=KERNEL SHADOWS Automated Backup
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
WorkingDirectory=/var/operations

ExecStart=/usr/local/bin/shadow-backup.sh

# Pre-checks
ExecStartPre=/usr/bin/test -d /var/operations
ExecStartPre=/usr/bin/test -x /usr/local/bin/shadow-backup.sh

# Post-backup logging
ExecStartPost=/usr/bin/logger -t shadow-backup "Backup completed successfully"

# Timeouts
TimeoutStartSec=1800s

# Resource limits
CPUQuota=50%
MemoryLimit=512M

# Security
PrivateTmp=true

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=shadow-backup

[Install]
# НЕ нужна [Install] секция!
# Service запускается через timer, не напрямую
```

**⚠️ Важно:** Type=oneshot для задач которые завершаются!

---

**Файл 2: `shadow-backup.timer`** (КОГДА делать)

```ini
[Unit]
Description=KERNEL SHADOWS Backup Timer (Daily at 2 AM)
Documentation=https://github.com/kernel-shadows/episode-10
After=time-sync.target
Requires=time-sync.target

[Timer]
# Расписание: каждый день в 02:00
OnCalendar=*-*-* 02:00:00

# Randomize start time by ±15 minutes
# (распределяет нагрузку если у вас 100+ серверов)
RandomizedDelaySec=15min

# Если система была выключена во время запуска → запустить при включении
Persistent=true

# Какой service запускать
Unit=shadow-backup.service

[Install]
WantedBy=timers.target
```

---

#### 🎨 OnCalendar синтаксис

SystemD использует **calendar expressions** для расписания.

**Базовые:**
```ini
OnCalendar=minutely    # каждую минуту
OnCalendar=hourly      # каждый час в :00
OnCalendar=daily       # каждый день в 00:00
OnCalendar=weekly      # каждый понедельник в 00:00
OnCalendar=monthly     # первое число месяца в 00:00
OnCalendar=yearly      # 1 января в 00:00
```

**Кастомные:**
```ini
OnCalendar=*-*-* 02:00:00           # каждый день в 02:00
OnCalendar=Mon *-*-* 09:00:00       # каждый понедельник в 09:00
OnCalendar=Mon-Fri *-*-* 09:00      # будни в 09:00
OnCalendar=Sat,Sun *-*-* 12:00      # выходные в 12:00
OnCalendar=*-*-01 03:00             # первое число месяца в 03:00
OnCalendar=*-*-* 00/6:00            # каждые 6 часов (00:00, 06:00, 12:00, 18:00)
OnCalendar=*-*-* *:00/15            # каждые 15 минут
```

**Проверить синтаксис:**
```bash
systemd-analyze calendar "Mon *-*-* 02:00"
# Вывод:
#   Original form: Mon *-*-* 02:00
#   Normalized form: Mon *-*-* 02:00:00
#   Next elapse: Mon 2025-10-13 02:00:00 UTC
#   (in UTC): Mon 2025-10-13 02:00:00 UTC
```

**Борис:**
*"Не уверен в синтаксисе? `systemd-analyze calendar "твоё расписание"`. Покажет следующий запуск и возможные ошибки."*

---

### 💻 Практика: Создание Timer

#### Задача: Backup каждый день в 02:00

**Шаг 1: Создать backup script**

```bash
sudo nano /usr/local/bin/shadow-backup.sh
```

```bash
#!/bin/bash
# Shadow Backup - Episode 10

BACKUP_DIR="/var/backups/shadow"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_TAG="shadow-backup"

# Create backup directory
sudo mkdir -p "$BACKUP_DIR"

log_message() {
    logger -t "$LOG_TAG" "$1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_message "Starting backup: $TIMESTAMP"

# Backup important configs
tar czf "$BACKUP_DIR/config_$TIMESTAMP.tar.gz" \
    /etc/systemd/system/*.service \
    /etc/sudoers.d/ \
    /var/operations/ \
    2>/dev/null

# Keep only last 30 backups (30 days)
cd "$BACKUP_DIR" && ls -t config_*.tar.gz | tail -n +31 | xargs -r rm

log_message "Backup completed: $BACKUP_DIR/config_$TIMESTAMP.tar.gz"
```

```bash
sudo chmod +x /usr/local/bin/shadow-backup.sh
```

---

**Шаг 2: Создать service unit**

```bash
sudo nano /etc/systemd/system/shadow-backup.service
```

(Скопировать содержимое из примера выше)

---

**Шаг 3: Создать timer unit**

```bash
sudo nano /etc/systemd/system/shadow-backup.timer
```

(Скопировать содержимое из примера выше)

---

**Шаг 4: Активация timer**

```bash
# Reload systemd
sudo systemctl daemon-reload

# Проверить синтаксис
sudo systemd-analyze verify shadow-backup.service
sudo systemd-analyze verify shadow-backup.timer

# Enable timer (автозапуск при загрузке)
sudo systemctl enable shadow-backup.timer

# Start timer сейчас
sudo systemctl start shadow-backup.timer

# Проверить статус
sudo systemctl status shadow-backup.timer
```

---

**Шаг 5: Проверить когда следующий запуск**

```bash
# Все timers
sudo systemctl list-timers

# Конкретный timer
sudo systemctl list-timers shadow-backup.timer

# Вывод:
# NEXT                         LEFT          LAST  PASSED  UNIT
# 2025-10-12 02:00:00 UTC  5h 23min left  n/a   n/a     shadow-backup.timer
```

---

**Шаг 6: Ручной запуск (тест)**

```bash
# Запустить backup вручную (не дожидаясь 02:00)
sudo systemctl start shadow-backup.service

# Проверить статус
sudo systemctl status shadow-backup.service

# Должно быть:
# Active: inactive (dead)  ← НОРМАЛЬНО для oneshot!
# Status: "Backup completed successfully"

# Просмотр логов
sudo journalctl -u shadow-backup.service
```

**Борис:**
*"oneshot service завершается после выполнения. inactive (dead) — это OK. Смотри на Status: 'success' и логи."*

---

### 🆚 Cron vs SystemD Timers

| Cron | SystemD Timers |
|------|----------------|
| ✅ Простой синтаксис: `0 2 * * * /script.sh` | ⚠️ Более сложный (2 файла: .service + .timer) |
| ❌ Нет dependency management | ✅ After=, Requires= (зависимости) |
| ❌ Логи в email или `/var/log/cron` | ✅ Логи в journalctl (централизованно) |
| ❌ Нет resource limits | ✅ CPUQuota, MemoryLimit |
| ❌ Если сервер был выключен — пропущен | ✅ Persistent=true → catch missed runs |
| ❌ Нет randomization (все серверы запускаются одновременно) | ✅ RandomizedDelaySec (load distribution) |
| ✅ Доступен везде | ⚠️ Только systemd системы (Ubuntu, RHEL, Fedora, Debian) |

**Борис:**
*"Для простых задач на личном сервере — cron OK. Для production с 100+ серверами — systemd timers. Better control, better logging, better integration."*

---

### 🤔 Проверка понимания

**Вопрос 1:** Зачем нужны два файла (.service и .timer)?

<details>
<summary>💡 Ответ</summary>

**Ответ:**
**Separation of concerns** (разделение ответственности).

- **`.service`** знает **ЧТО** делать (backup logic)
- **`.timer`** знает **КОГДА** делать (schedule)

**Преимущества:**
1. ✅ Можно запустить service вручную: `systemctl start shadow-backup.service`
2. ✅ Можно изменить расписание не трогая backup logic
3. ✅ Можно использовать один service с разными timers

**Пример:**
```
shadow-backup.service          ← backup logic
shadow-backup-daily.timer      ← ежедневно в 02:00
shadow-backup-hourly.timer     ← каждый час (для critical data)
```

Оба timers запускают один service!

**Борис:** *"Это UNIX philosophy: do one thing well. Service делает backup. Timer запускает по расписанию. Чистая архитектура."*

</details>

---

**Вопрос 2:** Что делает Persistent=true?

<details>
<summary>💡 Ответ</summary>

**Ответ:**
**Persistent=true** означает "catch missed runs".

**Сценарий:**
1. Timer настроен на 02:00 каждый день
2. Сервер был выключен с 01:00 до 08:00
3. Timer пропустил запуск в 02:00

**Без Persistent:**
```
02:00 — пропущен (сервер выключен)
08:00 — сервер включился
     — backup НЕ запустился
     — следующий запуск только завтра в 02:00
```

**С Persistent=true:**
```
02:00 — пропущен (сервер выключен)
08:00 — сервер включился
08:00 — systemd видит "пропущен запуск" → запускает backup сейчас!
     — backup выполняется (late, но выполняется)
```

**Когда использовать:**
- ✅ Backup (важно чтобы выполнился даже если сервер был выключен)
- ✅ Синхронизация данных
- ❌ Отчёты "за вчерашний день" (если пропущен — не нужен)

**Борис:** *"Persistent=true для критических задач. Лучше late чем never."*

</details>

---

**Вопрос 3:** Зачем RandomizedDelaySec=15min?

<details>
<summary>💡 Load Distribution</summary>

**Ответ:**
**RandomizedDelaySec** распределяет запуск задач во времени.

**Проблема:**
Представь 100 серверов с backup в 02:00:
```
02:00:00 — ВСЕ 100 серверов запускают backup одновременно
          → пиковая нагрузка на backup storage
          → сеть перегружена
          → backup медленный
```

**Решение: RandomizedDelaySec=15min**
```
02:00:00 — сервер 1 запустил backup
02:03:12 — сервер 2 запустил backup
02:07:45 — сервер 3 запустил backup
...
02:14:23 — сервер 100 запустил backup
```

Backup распределён с 02:00 до 02:15 → нет пиковой нагрузки!

**Когда использовать:**
- ✅ Backup на много серверов
- ✅ Синхронизация с центральным сервером
- ✅ Cron jobs которые раньше били по одному API

**Борис:** *"RandomizedDelaySec — это 'вежливость'. Не нагружай инфраструктуру пиковыми запросами."*

</details>

---

### ✅ Чеклист Цикл 4

- [ ] Понимаю зачем два файла (.service + .timer)
- [ ] Знаю синтаксис OnCalendar
- [ ] Умею проверить расписание через `systemd-analyze calendar`
- [ ] Понимаю зачем Persistent=true
- [ ] Понимаю зачем RandomizedDelaySec
- [ ] Умею проверить когда следующий запуск (`systemctl list-timers`)

**LILITH:**
*"Timer — это cron на стероидах. Да, сложнее. Но production серверы требуют этой сложности. Dependency management, logging, persistence — это не роскошь, это необходимость."*

---

## 🔄 ЦИКЛ 5: Resource Limits & Security Hardening (20-25 минут)

### 🎬 Сюжет

**Виктор** (видеозвонок, следующий день):
*"Макс, хорошая работа с мониторингом и backup. Но у нас проблема. Один из серверов в Новосибирске упал вчера ночью. Причина — fork bomb."*

**Макс:**
*"Fork bomb?"*

**Анна:**
*"Классическая DoS атака. Процесс создаёт копии себя в бесконечном цикле. Каждая копия создаёт ещё копии. Через 30 секунд — тысячи процессов. Система перегружена, падает."*

```bash
# Fork bomb (НЕ ЗАПУСКАЙ!)
:(){ :|:& };:

# Что это делает:
# Функция : вызывает сама себя дважды
# & = в background
# → экспоненциальный рост процессов
# 1 → 2 → 4 → 8 → 16 → 32 → 64 → 128 → 256 → ...
# За 30 секунд: 10,000+ процессов → система мертва
```

**Борис:**
*"Защита — resource limits. SystemD может ограничивать CPU, память, количество процессов. Даже если fork bomb запустится — systemd убьёт его до того как он положит систему."*

---

### 📚 Теория: Resource Limits

#### 🏭 Метафора: Resource Limits = Профсоюзные правила

Представь фабрику БЕЗ правил:

```
❌ БЕЗ ЛИМИТОВ:
👷 Рабочий: "Мне нужно 100% CPU!"
💻 CPU: "ОК!" → другие процессы тормозят

👷 Рабочий: "Мне нужно 8GB RAM!"
💾 RAM: "ОК!" → система свопится на диск, всё медленное

👷 Рабочий: "Мне нужно запустить 10,000 помощников!"
🏭 Фабрика: "ОК!" → fork bomb, система падает
```

Представь фабрику С правилами (resource limits):

```
✅ С ЛИМИТАМИ:
👷 Рабочий: "Мне нужно 100% CPU!"
📋 Профсоюз: "Максимум 25% для тебя, остальное для других"

👷 Рабочий: "Мне нужно 8GB RAM!"
📋 Профсоюз: "Максимум 128MB, если превысишь — уволен"

👷 Рабочий: "Мне нужно запустить 10,000 помощников!"
📋 Профсоюз: "Максимум 50 процессов, больше нельзя"
```

**Директор (системный администратор)** устанавливает правила (resource limits).
**Профсоюз (systemd)** следит чтобы никто не нарушал.

---

#### 🎯 Основные Resource Limits

SystemD предоставляет множество лимитов в секции **[Service]**:

##### 1. **CPU Limits**

```ini
# Ограничить использование CPU
CPUQuota=25%            # Максимум 25% одного ядра
CPUQuota=200%           # Максимум 2 полных ядра (на многоядерных CPU)

# CPU scheduling priority
Nice=19                 # Низкий приоритет (-20 = highest, 19 = lowest)
CPUSchedulingPolicy=batch  # Batch scheduling (для фоновых задач)
```

**Пример:**
```ini
# Backup не должен тормозить production сервисы
CPUQuota=50%
Nice=10
```

---

##### 2. **Memory Limits**

```ini
# Ограничить память
MemoryLimit=128M        # Мягкий лимит (может превысить временно)
MemoryMax=128M          # Жёсткий лимит (если превысит → kill)

# Swap limits
MemorySwapMax=0         # Запретить swap (только физическая память)
```

**Что происходит при превышении:**
- **MemoryLimit:** systemd пытается освободить память (cache, buffers)
- **MemoryMax:** systemd убивает процесс (OOM kill)

**Борис:**
*"MemoryMax — это safety net. Если процесс утекает память — systemd убьёт его ДО того как он съест всю RAM системы."*

---

##### 3. **Process/Thread Limits**

```ini
# Максимальное количество процессов/потоков
TasksMax=50             # Максимум 50 задач (процессов + потоков)

# Альтернатива через ulimit
LimitNPROC=100          # Максимум 100 процессов
```

**Защита от fork bomb:**
```ini
# Если сервис попытается создать 51-й процесс → fail
TasksMax=50
```

**Анна:**
*"TasksMax=50 спасает от fork bomb. Атакующий может создать максимум 50 процессов, не тысячи."*

---

##### 4. **File Descriptor Limits**

```ini
# Максимальное количество открытых файлов
LimitNOFILE=1024        # Мягкий лимит
LimitNOFILE=4096        # Жёсткий лимит (через infinity)
```

**Когда увеличивать:**
- Веб-серверы (много одновременных соединений)
- Базы данных (много открытых файлов)

---

##### 5. **Disk I/O Limits**

```ini
# I/O scheduling priority
IOSchedulingClass=2     # 0=none, 1=realtime, 2=best-effort, 3=idle
IOSchedulingPriority=7  # 0=highest, 7=lowest

# I/O bandwidth limits (cgroup v2)
IOReadBandwidthMax=/var 10M    # Максимум 10MB/s чтение из /var
IOWriteBandwidthMax=/var 5M    # Максимум 5MB/s запись в /var
```

**Пример:**
```ini
# Backup не должен замедлять production I/O
IOSchedulingClass=3     # idle (только когда система свободна)
IOSchedulingPriority=7  # lowest priority
```

---

##### 6. **Timeout Limits**

```ini
# Timeouts
TimeoutStartSec=90s     # Максимальное время запуска
TimeoutStopSec=30s      # Максимальное время остановки
RuntimeMaxSec=3600s     # Максимальное время работы (1 час)
```

**Пример:**
```ini
# Backup должен завершиться за 30 минут
TimeoutStartSec=1800s

# Если backup зависнет → systemd убьёт через 30 минут
```

---

### 🔒 Security Hardening

SystemD предоставляет десятки опций для изоляции и защиты сервисов.

#### 🎯 Основные Security Features

##### 1. **Privilege Restrictions**

```ini
# Запретить повышение привилегий
NoNewPrivileges=true    # Процесс не может получить больше прав (suid/sudo)

# Запретить ambient capabilities
AmbientCapabilities=    # Пустое = нет capabilities
```

**Что блокирует:**
- ❌ Использование suid бинарников
- ❌ Выполнение sudo внутри сервиса
- ❌ Получение дополнительных capabilities

**Анна:**
*"NoNewPrivileges=true — первая линия защиты. Даже если атакующий скомпрометирует сервис — он не сможет повысить привилегии."*

---

##### 2. **Filesystem Isolation**

```ini
# Read-only система
ProtectSystem=strict    # / и /usr read-only (сервис не может изменять систему)
ProtectSystem=full      # /usr и /boot read-only
ProtectSystem=true      # только /usr read-only

# Запретить доступ к домашним директориям
ProtectHome=true        # /home, /root, /run/user недоступны

# Приватный /tmp
PrivateTmp=true         # Сервис видит только свой /tmp

# Разрешить запись только в конкретные директории
ReadWritePaths=/var/operations/shadow-monitor
```

**Пример:**
```ini
# Мониторинг не должен изменять систему
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/operations/shadow-monitor
```

---

##### 3. **Kernel Protection**

```ini
# Защита kernel
ProtectKernelModules=true     # Нельзя загружать kernel модули
ProtectKernelTunables=true    # Нельзя изменять /sys, /proc/sys
ProtectKernelLogs=true        # Нельзя читать kernel логи (dmesg)
ProtectControlGroups=true     # Нельзя изменять cgroups
```

---

##### 4. **Process Visibility**

```ini
# Скрыть другие процессы
ProtectProc=invisible   # Сервис видит только свои процессы в /proc
ProcSubset=pid          # Видно только /proc/PID/, остальное скрыто
```

---

##### 5. **Network Restrictions**

```ini
# Ограничить доступ к сети
PrivateNetwork=true            # Изолированный network namespace (нет сети)
RestrictAddressFamilies=AF_INET AF_INET6  # Только IPv4/IPv6 (нет AF_UNIX, AF_NETLINK)

# IP фильтры
IPAddressAllow=10.0.0.0/8      # Разрешить только локальную сеть
IPAddressDeny=any              # Запретить всё остальное
```

---

### 💻 Практика: Hardened Service

**Задача:** Улучшить `shadow-monitor.service` с максимальной защитой.

```ini
[Unit]
Description=KERNEL SHADOWS System Monitor (Hardened)
Documentation=https://github.com/kernel-shadows/episode-10
After=network-online.target
Wants=network-online.target
Requires=systemd-journald.service

[Service]
Type=simple
User=shadow-monitor
Group=shadow-monitor
WorkingDirectory=/var/operations/shadow-monitor

ExecStart=/usr/local/bin/shadow-monitor.sh

# Pre-checks
ExecStartPre=/usr/bin/test -f /usr/local/bin/shadow-monitor.sh
ExecStartPre=/usr/bin/test -x /usr/local/bin/shadow-monitor.sh

# ============================================================================
# Restart Policy
# ============================================================================
Restart=on-failure
RestartSec=10s
StartLimitBurst=5
StartLimitIntervalSec=60s

# ============================================================================
# Resource Limits
# ============================================================================
# CPU: Максимум 25% (мониторинг не должен перегружать систему)
CPUQuota=25%
Nice=10

# Memory: Максимум 128MB
MemoryMax=128M

# Tasks: Максимум 50 процессов/потоков (защита от fork bomb)
TasksMax=50

# File descriptors: Максимум 1024 открытых файлов
LimitNOFILE=1024

# I/O: Низкий приоритет
IOSchedulingClass=2
IOSchedulingPriority=7

# Timeout: Максимум 1 час работы (затем перезапуск)
RuntimeMaxSec=3600s

# ============================================================================
# Security Hardening
# ============================================================================
# Privilege restrictions
NoNewPrivileges=true

# Filesystem isolation
ProtectSystem=strict
ProtectHome=true
PrivateTmp=true
ReadWritePaths=/var/operations/shadow-monitor

# Kernel protection
ProtectKernelModules=true
ProtectKernelTunables=true
ProtectKernelLogs=true
ProtectControlGroups=true

# Process visibility
ProtectProc=invisible
ProcSubset=pid

# Network restrictions (если не нужна сеть)
# PrivateNetwork=true

# Restrict system calls (advanced)
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources
SystemCallErrorNumber=EPERM

# ============================================================================
# Logging
# ============================================================================
StandardOutput=journal
StandardError=journal
SyslogIdentifier=shadow-monitor

[Install]
WantedBy=multi-user.target
```

**Борис:**
*"Это production-grade security. Если атакующий скомпрометирует этот сервис — он в sandbox. Нет доступа к системе, нет повышения привилегий, нет fork bomb, нет утечки памяти."*

---

### 🤔 Проверка понимания

**Вопрос 1:** Что произойдёт если процесс превысит MemoryMax=128M?

<details>
<summary>💡 Ответ</summary>

**Ответ:**
SystemD убьёт процесс (OOM kill).

**Последовательность:**
1. Процесс пытается аллоцировать память > 128MB
2. Kernel видит что лимит превышен
3. Kernel отправляет SIGKILL процессу
4. Процесс завершается

**В логах:**
```
journalctl -u shadow-monitor.service
# memory.max exceeded, OOM killer invoked
# Process 12345 killed (signal 9)
```

**SystemD перезапуск:**
```ini
Restart=on-failure  # Если был MemoryMax OOM → перезапустить
```

**Зачем:**
Защита системы. Лучше убить один процесс чем дать ему съесть всю память и положить систему.

**Борис:** *"MemoryMax — это circuit breaker. Жертвуем одним процессом ради стабильности системы."*

</details>

---

**Вопрос 2:** Зачем NoNewPrivileges=true?

<details>
<summary>💡 Privilege Escalation Protection</summary>

**Ответ:**
Запрещает процессу получать больше привилегий чем у него есть.

**Что блокирует:**

**1. SUID бинарники:**
```bash
# Без NoNewPrivileges:
$ /usr/bin/passwd  # SUID root → процесс получает root
# РАБОТАЕТ

# С NoNewPrivileges=true:
$ /usr/bin/passwd
# FAIL: Operation not permitted
```

**2. Sudo внутри сервиса:**
```bash
# В скрипте сервиса:
sudo systemctl restart nginx

# С NoNewPrivileges=true:
# sudo: effective uid is not 0, is sudo installed setuid root?
# FAIL
```

**3. Capabilities:**
```bash
# Попытка получить CAP_NET_ADMIN
setcap cap_net_admin+ep /usr/local/bin/script

# С NoNewPrivileges=true:
# FAIL: cannot elevate capabilities
```

**Зачем:**
Если атакующий скомпрометирует сервис → он застрянет с привилегиями `shadow-monitor` (непривилегированный пользователь). Не сможет повысить до root.

**Анна:** *"NoNewPrivileges=true — это safety belt. Даже если атакующий найдёт 0-day в suid бинарнике — он не сможет им воспользоваться."*

</details>

---

**Вопрос 3:** Как защититься от fork bomb в systemd?

<details>
<summary>💡 TasksMax</summary>

**Ответ:**
Используй **TasksMax** для ограничения количества процессов/потоков.

**Пример:**
```ini
[Service]
TasksMax=50
```

**Fork bomb:**
```bash
# Злонамеренный скрипт
:(){ :|:& };:

# Создаёт процессы экспоненциально:
# 1 → 2 → 4 → 8 → 16 → 32 → 64 → ...
```

**С TasksMax=50:**
```
Процесс 1 создаёт процесс 2 ✓
Процесс 2 создаёт процесс 3 и 4 ✓
...
Процесс 50 создан ✓
Процесс пытается создать 51 ❌
Kernel: "TasksMax exceeded" → FAIL

Systemd: "Service failed" → Restart=on-failure → kill все 50 процессов
```

**Другие защиты:**
```ini
# В /etc/security/limits.conf (из Episode 09!)
shadow-monitor  hard  nproc  100

# В systemd
LimitNPROC=100
TasksMax=50
```

**Борис:** *"TasksMax — это airbag для fork bomb. Ограничь процессы на разумное число (50, 100). Мониторингу не нужно 10,000 процессов."*

</details>

---

### ✅ Чеклист Цикл 5

- [ ] Понимаю зачем resource limits (защита системы)
- [ ] Знаю основные лимиты (CPU, Memory, Tasks, Files)
- [ ] Понимаю что делает NoNewPrivileges=true
- [ ] Понимаю как TasksMax защищает от fork bomb
- [ ] Знаю security features (ProtectSystem, ProtectHome, PrivateTmp)
- [ ] Умею создать hardened service unit

**LILITH:**
*"Resource limits — это не ограничение свободы. Это защита. Один плохой процесс не должен убить всю систему. Production thinking."*

---

## 🔄 ЦИКЛ 6: Journalctl — Системные логи (15-20 минут)

### 🎬 Сюжет

**Анна** (видеозвонок, вечер):
*"Макс, сервисы работают, security hardening на месте. Отлично. Но теперь вопрос: КАК ты узнаешь что происходит? Если сервис упадёт в 3 ночи — как ты об этом узнаешь?"*

**Макс:**
*"Логи в `/var/log/` ?"*

**Анна:**
*"Это старый способ. SystemD использует journald — централизованная система логирования. Все сервисы пишут в journald. Всё в одном месте, структурировано, фильтруемо, searchable."*

**Борис:**
*"journalctl — это твои глаза и уши. Без логов ты слепой. Научись читать journalctl как газету."*

---

### 📚 Теория: SystemD Journal

#### 📰 Метафора: Journalctl = Газета фабрики

Представь что на фабрике (Linux система) есть **главная газета** (journal):

```
📰 FACTORY DAILY NEWS
═══════════════════════════════════

[10:00] 👷 Рабочий #1456 (nginx): "Started successfully"
[10:01] 👷 Рабочий #6623 (shadow-monitor): "Monitoring active"
[10:02] ⚠️  Рабочий #6623: "ALERT: Suspicious process detected!"
[10:03] 👷 Рабочий #1789 (shadow-backup): "Backup started"
[10:05] ✓  Рабочий #1789: "Backup completed: 1.2GB"
[10:06] ❌ Рабочий #8821 (firefox): "Crashed (segfault)"
[10:06] 🔄 Рабочий #8821: "Restarted (attempt 1/5)"
...
```

**Каждое событие в системе → запись в журнал.**

**Журналист (journald)** собирает новости от всех рабочих (сервисов).
**Читатель (ты)** использует `journalctl` чтобы читать газету.

---

#### 🎯 Что такое SystemD Journal?

**SystemD Journal (journald)** — это:
- Централизованная система логирования
- Хранит логи в бинарном формате (`/var/log/journal/`)
- Индексировано и быстро searchable
- Интегрировано с systemd (каждый сервис автоматически логирует туда)

**Преимущества vs `/var/log/*`:**

| Старый способ (/var/log/*) | SystemD Journal |
|-----------------------------|-----------------|
| Логи разбросаны по файлам | Всё в одном месте |
| Текстовые файлы (grep) | Бинарный формат (индексы) |
| Ротация через logrotate | Автоматическая ротация |
| Нет метаданных | Богатые метаданные (priority, unit, pid, etc.) |
| Нужен tail -f для realtime | `journalctl -f` встроено |

**Борис:**
*"Journald — это Google для логов. Индексировано, быстро, фильтруемо. `/var/log/` — это бумажная картотека."*

---

### 💻 Команда journalctl

#### 🎯 Базовое использование

```bash
# Все логи (с начала времён)
journalctl

# Последние 50 строк
journalctl -n 50

# Real-time (follow)
journalctl -f

# С момента загрузки системы
journalctl -b

# Логи конкретного сервиса
journalctl -u shadow-monitor.service

# Логи за последний час
journalctl --since "1 hour ago"

# Логи за сегодня
journalctl --since today

# Логи за вчера
journalctl --since yesterday --until today
```

---

#### 🎨 Фильтрация

##### 1. **По сервису (unit)**

```bash
# Конкретный сервис
journalctl -u nginx.service

# Несколько сервисов
journalctl -u nginx.service -u shadow-monitor.service

# Real-time для сервиса
journalctl -u shadow-monitor.service -f
```

---

##### 2. **По времени**

```bash
# С конкретного времени
journalctl --since "2025-10-11 10:00:00"

# Между двумя датами
journalctl --since "2025-10-11" --until "2025-10-12"

# Относительное время
journalctl --since "2 hours ago"
journalctl --since "30 minutes ago"
journalctl --since today
journalctl --since yesterday
```

---

##### 3. **По priority (уровень важности)**

```bash
# Только ошибки
journalctl -p err

# Ошибки и критические
journalctl -p err..crit

# Warning и выше
journalctl -p warning
```

**Priority levels:**
```
0: emerg   (Emergency, система неработоспособна)
1: alert   (Alert, немедленные действия требуются)
2: crit    (Critical)
3: err     (Error)
4: warning (Warning)
5: notice  (Notice, нормально но важно)
6: info    (Information)
7: debug   (Debug, детальная отладка)
```

---

##### 4. **По процессу (PID)**

```bash
# Логи конкретного PID
journalctl _PID=6623

# Все процессы пользователя
journalctl _UID=1000
```

---

##### 5. **По идентификатору (SyslogIdentifier)**

```bash
# Логи с конкретным идентификатором
journalctl -t shadow-monitor
journalctl -t shadow-backup

# В service unit:
SyslogIdentifier=shadow-monitor
```

---

#### 🎨 Форматирование вывода

```bash
# Компактный формат
journalctl -o short

# С подробностями
journalctl -o verbose

# JSON формат
journalctl -o json

# JSON pretty-print
journalctl -o json-pretty

# Только сообщения (без метаданных)
journalctl -o cat
```

---

#### 🎨 Полезные комбинации

##### 1. **Troubleshooting упавшего сервиса**

```bash
# Последние 50 строк логов сервиса
journalctl -u shadow-monitor.service -n 50

# Только ошибки
journalctl -u shadow-monitor.service -p err

# С момента последнего краша
journalctl -u shadow-monitor.service --since "10 minutes ago"
```

---

##### 2. **Мониторинг в реальном времени**

```bash
# Follow логи сервиса
journalctl -u shadow-monitor.service -f

# Follow только ошибок
journalctl -p err -f

# Follow нескольких сервисов
journalctl -u nginx.service -u shadow-monitor.service -f
```

---

##### 3. **Анализ загрузки системы**

```bash
# Логи текущей загрузки
journalctl -b

# Логи предыдущей загрузки
journalctl -b -1

# Список всех загрузок
journalctl --list-boots

# Время загрузки сервисов
systemd-analyze blame
```

---

##### 4. **Поиск паттернов**

```bash
# Grep в логах
journalctl -u shadow-monitor.service | grep "ALERT"

# Поиск регулярного выражения
journalctl -u shadow-monitor.service | grep -E "ERROR|CRITICAL"

# Количество ошибок
journalctl -u shadow-monitor.service -p err | wc -l
```

---

### 💻 Практика: Debugging через journalctl

#### Сценарий: Сервис падает, нужно выяснить почему

**Шаг 1: Проверить статус**

```bash
sudo systemctl status shadow-monitor.service

# Вывод:
# ● shadow-monitor.service - KERNEL SHADOWS System Monitor
#      Loaded: loaded (/etc/systemd/system/shadow-monitor.service)
#      Active: failed (Result: signal) since Sat 2025-10-11 14:32:15 UTC
#     Process: 6623 ExecStart=/usr/local/bin/shadow-monitor.sh (code=killed, signal=KILL)
#    Main PID: 6623 (code=killed, signal=KILL)
```

Видим: **signal=KILL** (был убит).

---

**Шаг 2: Проверить логи**

```bash
# Последние 100 строк
sudo journalctl -u shadow-monitor.service -n 100

# Только ошибки
sudo journalctl -u shadow-monitor.service -p err
```

**Возможные причины:**

**1. MemoryMax exceeded (OOM kill):**
```
Oct 11 14:32:15 server systemd[1]: shadow-monitor.service: A process of this unit has been killed by the OOM killer.
Oct 11 14:32:15 server systemd[1]: shadow-monitor.service: Main process exited, code=killed, status=9/KILL
```

**Решение:** Увеличить MemoryMax или исправить memory leak в скрипте.

---

**2. Превышен TasksMax:**
```
Oct 11 14:32:15 server systemd[1]: shadow-monitor.service: Failed to create new process: Resource limit of processes (50) reached
```

**Решение:** Увеличить TasksMax или исправить fork bomb в скрипте.

---

**3. Скрипт завершился с ошибкой:**
```
Oct 11 14:32:15 server shadow-monitor[6623]: Error: File /var/operations/data not found
Oct 11 14:32:15 server systemd[1]: shadow-monitor.service: Main process exited, code=exited, status=1/FAILURE
```

**Решение:** Исправить ошибку в скрипте.

---

**Шаг 3: Real-time мониторинг**

```bash
# Перезапустить сервис
sudo systemctl restart shadow-monitor.service

# Follow логи в реальном времени
sudo journalctl -u shadow-monitor.service -f

# Смотреть что происходит
```

---

### 🤔 Проверка понимания

**Вопрос 1:** В чём разница между `journalctl -b` и `journalctl`?

<details>
<summary>💡 Ответ</summary>

**Ответ:**

| `journalctl` | `journalctl -b` |
|--------------|-----------------|
| Все логи (с начала времён) | Логи только текущей загрузки |
| Может быть ОЧЕНЬ много данных | Только логи с момента последнего reboot |

**Пример:**
```bash
# Система работает 30 дней
journalctl
# Вывод: логи за 30 дней (гигабайты данных)

journalctl -b
# Вывод: логи только с последнего reboot (может быть несколько часов)
```

**Когда использовать:**
- `journalctl` — для анализа истории (что было вчера, неделю назад)
- `journalctl -b` — для troubleshooting текущей загрузки (почему сервис не запустился сегодня)

**Борис:** *"`-b` — это 'сегодняшняя газета'. Без `-b` — это 'архив за все годы'."*

</details>

---

**Вопрос 2:** Как найти все ошибки сервиса за последний час?

<details>
<summary>💡 Команда</summary>

**Ответ:**
```bash
journalctl -u shadow-monitor.service -p err --since "1 hour ago"
```

**Разбор:**
- `-u shadow-monitor.service` — конкретный сервис
- `-p err` — priority = error (только ошибки)
- `--since "1 hour ago"` — за последний час

**Альтернативы:**
```bash
# Последние 50 ошибок
journalctl -u shadow-monitor.service -p err -n 50

# Ошибки с 10:00 до сейчас
journalctl -u shadow-monitor.service -p err --since "10:00"

# Ошибки за сегодня
journalctl -u shadow-monitor.service -p err --since today
```

**Анна:** *"Это первая команда при troubleshooting. Ошибки → причина → решение."*

</details>

---

**Вопрос 3:** Что означает "code=killed, signal=KILL" в systemctl status?

<details>
<summary>💡 Ответ</summary>

**Ответ:**
Процесс был **принудительно убит** (SIGKILL).

**Возможные причины:**

**1. MemoryMax exceeded (OOM kill):**
```bash
journalctl -u service.service | grep OOM
# shadow-monitor.service: A process has been killed by the OOM killer
```

**2. Превышен timeout:**
```bash
# В service unit:
TimeoutStartSec=30s

# Если процесс не запустился за 30 секунд → systemd убивает (SIGKILL)
```

**3. Ручное убийство:**
```bash
sudo kill -9 6623  # SIGKILL
```

**4. SystemD restart из-за RuntimeMaxSec:**
```ini
RuntimeMaxSec=3600s  # Максимум 1 час работы
# Через час systemd убивает процесс и перезапускает
```

**Как узнать причину:**
```bash
# Проверить логи
journalctl -u service.service -n 50

# Искать ключевые слова:
# - OOM killer
# - timeout
# - RuntimeMaxSec
# - memory.max exceeded
```

**Борис:** *"signal=KILL всегда involuntary (принудительно). Процесс НЕ хотел умирать, его убили."*

</details>

---

### ✅ Чеклист Цикл 6

- [ ] Понимаю что такое systemd journal
- [ ] Знаю базовые команды journalctl (-u, -f, -b, -n, -p)
- [ ] Умею фильтровать логи (по времени, priority, unit)
- [ ] Могу troubleshoot упавший сервис через journalctl
- [ ] Понимаю priority levels (emerg, alert, crit, err, warning, info, debug)

**LILITH:**
*"Journalctl — это чёрный ящик системы. После краша — первым делом смотри логи. Без логов troubleshooting = гадание на кофейной гуще."*

---

## 🔄 ЦИКЛ 7: Практическое задание (20-25 минут)

### 🎬 Сюжет

**Борис** (закрывает терминал):
*"Теория закончена. Теперь практика. У тебя есть `starter/` директория с TODO комментариями. Твоя задача — заполнить их, установить units, протестировать."*

**Макс:**
*"Что именно нужно сделать?"*

**Борис:**
*"Создать production-ready мониторинг с тремя компонентами:"*

```
1. shadow-monitor.service    — Постоянный мониторинг (Type=simple)
2. shadow-backup.service      — Backup задача (Type=oneshot)
3. shadow-backup.timer        — Расписание для backup (daily 02:00)
```

*"Все units с resource limits, security hardening, logging в journalctl."*

---

### 🎯 Задание

#### **Часть 1: Заполнить TODO в starter/systemd/**

Открой директорию `starter/`:

```bash
cd /home/fazzz/kernel-shadows/season-3-system-administration/episode-10-processes-systemd/starter/systemd/
ls -la
# shadow-backup.service
# shadow-backup.timer
# shadow-monitor.service
```

**Каждый файл содержит TODO комментарии. Твоя задача — заполнить их.**

**Пример TODO:**
```ini
# TODO 1: Добавь Description для службы
# Подсказка: Description=KERNEL SHADOWS Automated Backup
Description=???
```

**Твой ответ:**
```ini
Description=KERNEL SHADOWS Automated Backup
```

---

**📋 Workflow (подробно в `starter/README.md`):**

1. **Открой файл** `shadow-backup.service`
2. **Найди TODO** (16 штук)
3. **Заполни** каждый TODO используя подсказки
4. **Сохрани** файл
5. **Повтори** для `shadow-backup.timer` и `shadow-monitor.service`

---

#### **Часть 2: Создать вспомогательные скрипты**

SystemD units запускают bash скрипты. Создай их:

**A. `/usr/local/bin/shadow-backup.sh`**

```bash
#!/bin/bash
# Простой backup script

BACKUP_DIR="/var/backups/shadow"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Создать директорию
mkdir -p "$BACKUP_DIR"

# Backup /var/operations
tar -czf "$BACKUP_DIR/backup_$TIMESTAMP.tar.gz" /var/operations 2>/dev/null

echo "Backup completed: backup_$TIMESTAMP.tar.gz"
```

**Установка:**
```bash
sudo nano /usr/local/bin/shadow-backup.sh
# (скопировать код выше)

sudo chmod +x /usr/local/bin/shadow-backup.sh
```

---

**B. `/usr/local/bin/shadow-monitor.sh`**

```bash
#!/bin/bash
# Простой monitoring script

while true; do
    echo "[$(date)] Monitoring active. Checking for suspicious processes..."

    # Проверка backdoor процессов
    if ps aux | grep -E 'sshd_backup|backdoor' | grep -v grep > /dev/null; then
        echo "[ALERT] Suspicious process detected!"
    fi

    sleep 30
done
```

**Установка:**
```bash
sudo nano /usr/local/bin/shadow-monitor.sh
# (скопировать код выше)

sudo chmod +x /usr/local/bin/shadow-monitor.sh
```

---

#### **Часть 3: Создать системного пользователя**

```bash
# Непривилегированный пользователь для monitor
sudo useradd -r -s /bin/false shadow-monitor

# Рабочая директория
sudo mkdir -p /var/operations/shadow-monitor
sudo chown shadow-monitor:shadow-monitor /var/operations/shadow-monitor
```

---

#### **Часть 4: Установить units в систему**

```bash
# Скопировать units из starter/ в /etc/systemd/system/
sudo cp starter/systemd/shadow-backup.service /etc/systemd/system/
sudo cp starter/systemd/shadow-backup.timer /etc/systemd/system/
sudo cp starter/systemd/shadow-monitor.service /etc/systemd/system/

# Permissions
sudo chmod 644 /etc/systemd/system/shadow-*.service
sudo chmod 644 /etc/systemd/system/shadow-*.timer

# Reload systemd (ОБЯЗАТЕЛЬНО!)
sudo systemctl daemon-reload
```

---

#### **Часть 5: Проверить синтаксис**

```bash
# Проверка units на ошибки
sudo systemd-analyze verify shadow-backup.service
sudo systemd-analyze verify shadow-backup.timer
sudo systemd-analyze verify shadow-monitor.service

# Если ошибки — исправь в starter/, скопируй заново, daemon-reload
```

---

#### **Часть 6: Тестирование**

**A. Backup service (oneshot)**

```bash
# Ручной запуск
sudo systemctl start shadow-backup.service

# Статус (должен быть inactive (dead) — это OK для oneshot!)
sudo systemctl status shadow-backup.service

# Логи
sudo journalctl -u shadow-backup.service

# Проверка backup файла
ls -lh /var/backups/shadow/
```

---

**B. Monitor service (simple)**

```bash
# Запуск
sudo systemctl start shadow-monitor.service

# Статус (должен быть active (running))
sudo systemctl status shadow-monitor.service

# Real-time логи
sudo journalctl -u shadow-monitor.service -f

# (Ctrl+C для выхода)
```

---

**C. Backup timer**

```bash
# Enable + Start
sudo systemctl enable shadow-backup.timer
sudo systemctl start shadow-backup.timer

# Статус
sudo systemctl status shadow-backup.timer

# Когда следующий запуск
sudo systemctl list-timers shadow-backup.timer

# Должно показать:
# NEXT: 2025-10-12 02:00:00 UTC
```

---

**D. Тест автоперезапуска monitor**

```bash
# Найти PID
PID=$(systemctl show shadow-monitor.service -p MainPID --value)

# Убить процесс (симуляция краша)
sudo kill -9 "$PID"

# Подождать 10 секунд (RestartSec=10s)
sleep 10

# Проверить что перезапустился
sudo systemctl status shadow-monitor.service
# Должно быть: active (running), Restarts: 1
```

---

**E. Тест resource limits**

```bash
# Проверить текущие лимиты
systemctl show shadow-monitor.service | grep -E 'CPU|Memory|Tasks'

# Вывод должен содержать:
# CPUQuotaPerSecUSec=250000 (25%)
# MemoryMax=134217728 (128MB)
# TasksMax=50
```

---

#### **Часть 7: Enable на boot**

```bash
# Автозапуск monitoring service
sudo systemctl enable shadow-monitor.service

# Проверка
sudo systemctl is-enabled shadow-monitor.service
# Вывод: enabled

# Backup timer уже enabled (сделали в Part 6C)
```

---

### ✅ Итоговый чеклист

- [ ] Заполнил TODO в `shadow-backup.service` (16 TODO)
- [ ] Заполнил TODO в `shadow-backup.timer` (8 TODO)
- [ ] Заполнил TODO в `shadow-monitor.service` (30 TODO)
- [ ] Создал `/usr/local/bin/shadow-backup.sh` и сделал исполняемым
- [ ] Создал `/usr/local/bin/shadow-monitor.sh` и сделал исполняемым
- [ ] Создал пользователя `shadow-monitor`
- [ ] Скопировал units в `/etc/systemd/system/`
- [ ] Выполнил `systemctl daemon-reload`
- [ ] Проверил синтаксис через `systemd-analyze verify`
- [ ] Протестировал backup (ручной запуск, проверка файла)
- [ ] Протестировал monitor (запуск, статус, логи)
- [ ] Протестировал timer (enable, start, list-timers)
- [ ] Протестировал автоперезапуск (kill → restart)
- [ ] Проверил resource limits
- [ ] Enabled services на boot

**LILITH:**
*"Это не просто 'заполнить форму'. Это понимание КАЖДОЙ опции: зачем она, что блокирует, какой риск минимизирует. Production-grade thinking."*

---

## 🔄 ЦИКЛ 8: Финальный мониторинг и отчёт (10-15 минут)

### 🎬 Сюжет: Финальная проверка

**День 20. Вечер.**

Борис проверяет работу Макса.

```bash
$ sudo systemctl list-units --type=service --state=running | grep shadow
shadow-monitor.service     loaded active running   KERNEL SHADOWS System Monitor

$ sudo systemctl list-timers | grep shadow
Sat 2025-10-12 02:00:00 UTC  5h 32min left     n/a      n/a       shadow-backup.timer

$ sudo journalctl -u shadow-monitor.service -n 5
Oct 11 20:28:15 server shadow-monitor[12456]: [2025-10-11 20:28:15] Monitoring active
Oct 11 20:28:45 server shadow-monitor[12456]: [2025-10-11 20:28:45] Monitoring active
...
```

**Борис** (кивает):
*"Хорошая работа. Мониторинг работает 24/7. Backup запланирован на 02:00 каждый день. Resource limits на месте. Security hardening включен. Логи чистые."*

**Виктор** (видеозвонок):
*"Отличная работа, Макс. Санкт-Петербург завершён. Борис, спасибо за обучение. Макс, следующая остановка — Таллин, Эстония. Episode 11: Disk Management & LVM."*

**Анна:**
*"Макс, последнее. Создай финальный отчёт: все running сервисы, все active timers, статус security features. Документируй что ты настроил. Это пригодится для аудита."*

---

### 📋 Финальный отчёт (ONE-LINER COMPREHENSIVE)

```bash
#!/bin/bash

echo "=== KERNEL SHADOWS EPISODE 10: Final Report ==="
echo "Generated: $(date)"
echo

echo "=== Active Services ==="
systemctl list-units --type=service --state=running | grep shadow

echo
echo "=== Active Timers ==="
systemctl list-timers --all | grep shadow

echo
echo "=== Service Status ==="
sudo systemctl status shadow-monitor.service --no-pager
echo
sudo systemctl status shadow-backup.timer --no-pager

echo
echo "=== Resource Limits (shadow-monitor) ==="
systemctl show shadow-monitor.service | grep -E 'CPU|Memory|Tasks'

echo
echo "=== Security Features (shadow-monitor) ==="
systemctl show shadow-monitor.service | grep -E 'NoNewPrivileges|ProtectSystem|ProtectHome|PrivateTmp'

echo
echo "=== Recent Logs (last 24 hours) ==="
echo "--- shadow-monitor ---"
sudo journalctl -u shadow-monitor.service --since "24 hours ago" -p warning --no-pager | tail -20
echo
echo "--- shadow-backup ---"
sudo journalctl -u shadow-backup.service --since "24 hours ago" --no-pager | tail -10

echo
echo "=== Backup Files ==="
ls -lh /var/backups/shadow/ | tail -10

echo
echo "=== Final Check ==="
echo "✓ Monitor service: $(systemctl is-active shadow-monitor.service)"
echo "✓ Monitor enabled: $(systemctl is-enabled shadow-monitor.service)"
echo "✓ Backup timer: $(systemctl is-active shadow-backup.timer)"
echo "✓ Backup timer enabled: $(systemctl is-enabled shadow-backup.timer)"

echo
echo "=== Report Complete ==="
```

**Сохранить как:**
```bash
nano /var/operations/shadow-final-report.sh
chmod +x /var/operations/shadow-final-report.sh
./var/operations/shadow-final-report.sh > episode10-final-report.txt
```

---

### 🤔 Финальная проверка понимания

**Вопрос:** Как убедиться что сервис перезапустится после reboot?

<details>
<summary>💡 Ответ</summary>

**Ответ:**

**1. Проверь что enabled:**
```bash
sudo systemctl is-enabled shadow-monitor.service
# Вывод: enabled
```

**2. Проверь WantedBy в unit файле:**
```ini
[Install]
WantedBy=multi-user.target
```

**3. Проверь symlink:**
```bash
ls -l /etc/systemd/system/multi-user.target.wants/shadow-monitor.service
# Должен быть symlink на /etc/systemd/system/shadow-monitor.service
```

**4. Перезагрузка (тест):**
```bash
# Перезагрузить систему
sudo reboot

# После перезагрузки — проверить
sudo systemctl status shadow-monitor.service
# Должно быть: active (running) since ... (< 5 минут)
```

**Борис:** *"`systemctl enable` создаёт symlink в target.wants/. SystemD видит symlink → запускает сервис при достижении target."*

</details>

---

### ✅ Чеклист Episode 10: Complete!

- [ ] Понял философию процессов (PID, PPID, дерево)
- [ ] Умею управлять процессами (ps, top, kill, signals)
- [ ] Умею создавать systemd service units
- [ ] Умею создавать systemd timers (замена cron)
- [ ] Понимаю resource limits (CPU, Memory, Tasks)
- [ ] Понимаю security hardening (NoNewPrivileges, ProtectSystem, etc.)
- [ ] Умею читать логи через journalctl
- [ ] Создал production-ready мониторинг с auto-restart
- [ ] Создал backup timer с Persistent=true
- [ ] Протестировал все компоненты

---

## 🎓 Ключевые выводы Episode 10

### 💡 Главные концепты:

1. **Процесс = Программа в памяти**
   - PID, PPID, состояние, owner, ресурсы
   - Дерево процессов: systemd (PID 1) = корень

2. **Signals = Сообщения процессам**
   - SIGTERM (15) = вежливо, SIGKILL (9) = принудительно
   - Graceful shutdown: SIGTERM → wait → SIGKILL

3. **SystemD Service = Production-ready сервис**
   - [Unit] = метаданные, [Service] = как запускать, [Install] = когда
   - Type=simple (daemon) vs Type=oneshot (task)

4. **SystemD Timer = Cron на стероидах**
   - .service (ЧТО) + .timer (КОГДА)
   - OnCalendar, Persistent=true, RandomizedDelaySec

5. **Resource Limits = Защита системы**
   - CPUQuota, MemoryMax, TasksMax
   - Один процесс не может убить всю систему

6. **Security Hardening = Defense in Depth**
   - NoNewPrivileges, ProtectSystem, ProtectHome
   - Principle of Least Privilege

7. **Journalctl = Системные логи**
   - Централизованное логирование
   - Фильтрация по unit, time, priority

---

### 🚀 Production Best Practices:

✅ **DO:**
- Используй непривилегированных пользователей (не root)
- Ограничивай ресурсы (CPU, Memory, Tasks)
- Включай security features
- Настраивай автоперезапуск (Restart=on-failure)
- Логируй в journalctl
- Используй timers вместо cron
- Тестируй units через `systemd-analyze verify`
- Всегда делай `systemctl daemon-reload` после изменений

❌ **DON'T:**
- НЕ запускай сервисы от root без необходимости
- НЕ пиши bash wrapper вокруг systemctl
- НЕ забывай daemon-reload
- НЕ игнорируй resource limits
- НЕ используй SIGKILL без SIGTERM сначала

---

### 📚 Команды для запоминания:

```bash
# Process Management
ps aux                           # Все процессы
pgrep -a процесс                 # Найти PID по имени
kill -15 PID                     # SIGTERM (graceful)
kill -9 PID                      # SIGKILL (force)
pstree -p                        # Дерево процессов

# SystemD Service
sudo systemctl start service     # Запустить
sudo systemctl stop service      # Остановить
sudo systemctl restart service   # Перезапустить
sudo systemctl status service    # Статус
sudo systemctl enable service    # Автозапуск
sudo systemctl daemon-reload     # Перечитать units

# SystemD Timer
sudo systemctl list-timers       # Все timers
systemd-analyze calendar "..."   # Проверить расписание

# Journalctl
journalctl -u service.service    # Логи сервиса
journalctl -f                    # Real-time
journalctl -p err                # Только ошибки
journalctl -b                    # С момента загрузки
journalctl --since "1 hour ago"  # За последний час

# Analysis
systemd-analyze verify service   # Проверить синтаксис
systemd-analyze blame            # Время загрузки
systemctl show service           # Все свойства
systemd-cgtop                    # Real-time ресурсы
```

---

### 🎬 Что дальше?

**Episode 11: Disk Management & LVM**
*Локация: Таллин, Эстония*
*Тема: Разделы диска, файловые системы, LVM, RAID*

**Борис** (на прощание):
*"Макс, ты освоил управление процессами. Теперь ты контролируешь ЧТО работает на сервере. Следующий уровень — disk management: контроль ГДЕ хранятся данные."*

---

## 🔗 Дополнительные ресурсы

### Man Pages

```bash
man systemd.service     # Service units
man systemd.timer       # Timer units
man systemd.exec        # Execution options
man systemd.resource-control  # Resource limits
man journalctl          # Логи
man systemctl           # Управление
```

### Online Documentation

- [ArchWiki: systemd](https://wiki.archlinux.org/title/systemd)
- [Red Hat: SystemD Units](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/assembly_working-with-systemd-unit-files_configuring-basic-system-settings)
- [freedesktop.org: SystemD](https://www.freedesktop.org/software/systemd/man/)

---

## 🧪 Автотесты

```bash
cd /home/fazzz/kernel-shadows/season-3-system-administration/episode-10-processes-systemd
./tests/test.sh
```

**Что проверяют:**
- ✅ Units скопированы в `/etc/systemd/system/`
- ✅ Scripts существуют и исполняемы
- ✅ Services запускаются без ошибок
- ✅ Timer активен
- ✅ Логи пишутся в journalctl
- ✅ Resource limits установлены
- ✅ Security features включены

---

**"SystemD — это не просто init system. Это complete service management framework.
Process lifecycle, resource control, security isolation, logging — всё интегрировано."**

— **Борис Кузнецов**, SystemD Architect, ex-Red Hat

**Saint Petersburg, Russia → Tallinn, Estonia** 🇷🇺 ➡️ 🇪🇪

---

*Episode 10: Complete! 🎉*
*Next: Episode 11 - Disk Management & LVM*
