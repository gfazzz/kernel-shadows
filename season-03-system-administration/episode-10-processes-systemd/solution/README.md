# Solution Workflow — Episode 10: Processes & SystemD

> **"SystemD unit = production-ready service. Resource limits, security hardening, auto-restart. Enterprise-grade."**  
> — Борис Кузнецов, SystemD Architect

---

## 📁 Что здесь?

Эта директория содержит **референсное решение** Episode 10.

```
solution/
├── systemd/                      # Готовые systemd units
│   ├── shadow-backup.service      # Backup task (Type=oneshot)
│   ├── shadow-backup.timer        # Scheduler для backup
│   ├── shadow-monitor.service     # Monitoring daemon (Type=simple)
│   └── README.md                  # Документация units
│
├── process_manager.sh             # Вспомогательный скрипт (опционально)
└── README.md                      # Этот файл — полный workflow решения
```

---

## ⚠️ ВАЖНО: Не копируй слепо!

**Философия Type B:**
- ❌ НЕ копируй solution files без понимания
- ✅ Используй solution как референс ПОСЛЕ попытки
- ✅ Понимай КАЖДУЮ строку в unit файле

**LILITH:**  
*"Solution — это ответы в конце учебника. Подглядывай только если ЗАСТРЯЛ на 30+ минут. Иначе не научишься."*

---

## 🎯 Полный workflow решения

### Шаг 1: Создать системного пользователя

```bash
# Непривилегированный пользователь для monitor
sudo useradd -r -s /bin/false shadow-monitor

# Рабочая директория
sudo mkdir -p /var/operations/shadow-monitor
sudo chown shadow-monitor:shadow-monitor /var/operations/shadow-monitor
```

**Зачем:**
- Principle of Least Privilege
- Если сервис скомпрометирован → атакующий застрянет с правами `shadow-monitor`
- НЕ root!

---

### Шаг 2: Создать вспомогательные скрипты

#### A. Backup script (`/usr/local/bin/shadow-backup.sh`)

```bash
#!/bin/bash
# Shadow Backup - Episode 10

BACKUP_DIR="/var/backups/shadow"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_TAG="shadow-backup"

# Create backup directory
mkdir -p "$BACKUP_DIR"

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

**Установка:**
```bash
sudo nano /usr/local/bin/shadow-backup.sh
# (скопировать код выше)

sudo chmod +x /usr/local/bin/shadow-backup.sh

# Тест
/usr/local/bin/shadow-backup.sh
ls -lh /var/backups/shadow/
```

---

#### B. Monitor script (`/usr/local/bin/shadow-monitor.sh`)

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
    suspicious=$(ps aux | grep -E 'sshd_backup|backdoor|suspicious' | grep -v grep)
    
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

**Установка:**
```bash
sudo nano /usr/local/bin/shadow-monitor.sh
# (скопировать код выше)

sudo chmod +x /usr/local/bin/shadow-monitor.sh

# Тест (Ctrl+C для остановки)
/usr/local/bin/shadow-monitor.sh
```

---

### Шаг 3: Установить systemd units

```bash
# Скопировать готовые units из solution/
sudo cp solution/systemd/shadow-backup.service /etc/systemd/system/
sudo cp solution/systemd/shadow-backup.timer /etc/systemd/system/
sudo cp solution/systemd/shadow-monitor.service /etc/systemd/system/

# Permissions
sudo chmod 644 /etc/systemd/system/shadow-*.service
sudo chmod 644 /etc/systemd/system/shadow-*.timer

# Reload systemd (КРИТИЧНО!)
sudo systemctl daemon-reload
```

---

### Шаг 4: Проверить синтаксис

```bash
# Проверка units на ошибки
sudo systemd-analyze verify shadow-backup.service
sudo systemd-analyze verify shadow-backup.timer
sudo systemd-analyze verify shadow-monitor.service

# Если ошибок нет — всё OK
```

---

### Шаг 5: Тестирование services

#### A. Backup service (oneshot)

```bash
# Ручной запуск
sudo systemctl start shadow-backup.service

# Статус
sudo systemctl status shadow-backup.service

# Ожидаемый результат:
# ● shadow-backup.service - KERNEL SHADOWS Automated Backup
#      Loaded: loaded (/etc/systemd/system/shadow-backup.service)
#      Active: inactive (dead) since ...
#        Docs: https://github.com/kernel-shadows/episode-10
#     Process: 12345 ExecStart=/usr/local/bin/shadow-backup.sh (code=exited, status=0/SUCCESS)
#    Main PID: 12345 (code=exited, status=0/SUCCESS)

# Логи
sudo journalctl -u shadow-backup.service -n 20

# Проверка backup файла
ls -lh /var/backups/shadow/
# Должен быть файл config_YYYYMMDD_HHMMSS.tar.gz
```

**Борис:**  
*"oneshot service завершается после выполнения. inactive (dead) — это НОРМАЛЬНО. Смотри на status=0/SUCCESS."*

---

#### B. Monitor service (simple)

```bash
# Запуск
sudo systemctl start shadow-monitor.service

# Статус
sudo systemctl status shadow-monitor.service

# Ожидаемый результат:
# ● shadow-monitor.service - KERNEL SHADOWS System Monitor
#      Loaded: loaded (/etc/systemd/system/shadow-monitor.service)
#      Active: active (running) since Sat 2025-10-11 15:00:00 UTC; 5s ago
#        Docs: https://github.com/kernel-shadows/episode-10
#    Main PID: 12456 (shadow-monitor.s)
#       Tasks: 2 (limit: 50)
#      Memory: 2.5M (max: 128.0M)
#         CPU: 100ms (max: 25%)
#      CGroup: /system.slice/shadow-monitor.service
#              └─12456 /bin/bash /usr/local/bin/shadow-monitor.sh

# Real-time логи
sudo journalctl -u shadow-monitor.service -f

# Вывод:
# Oct 11 15:00:00 server shadow-monitor[12456]: [2025-10-11 15:00:00] Shadow Monitor started
# Oct 11 15:00:30 server shadow-monitor[12456]: [2025-10-11 15:00:30] Monitoring active
# Oct 11 15:01:00 server shadow-monitor[12456]: [2025-10-11 15:01:00] Monitoring active
# ...

# (Ctrl+C для выхода)
```

---

#### C. Backup timer

```bash
# Enable (автозапуск при загрузке)
sudo systemctl enable shadow-backup.timer

# Start
sudo systemctl start shadow-backup.timer

# Статус
sudo systemctl status shadow-backup.timer

# Ожидаемый результат:
# ● shadow-backup.timer - KERNEL SHADOWS Backup Timer (Daily at 2 AM)
#      Loaded: loaded (/etc/systemd/system/shadow-backup.timer; enabled)
#      Active: active (waiting) since Sat 2025-10-11 15:00:00 UTC; 10s ago
#        Docs: https://github.com/kernel-shadows/episode-10
#     Trigger: Sun 2025-10-12 02:00:00 UTC; 10h 59min left
#    Triggers: ● shadow-backup.service

# Когда следующий запуск
sudo systemctl list-timers shadow-backup.timer

# Вывод:
# NEXT                         LEFT          LAST  PASSED  UNIT                    ACTIVATES
# Sun 2025-10-12 02:00:00 UTC  10h 59min left  n/a   n/a     shadow-backup.timer     shadow-backup.service
```

**Борис:**  
*"Видишь 'NEXT'? Timer запустит backup в 02:00 завтра. Persistent=true — если сервер был выключен, запустит при включении."*

---

### Шаг 6: Тестирование автоперезапуска

```bash
# Найти PID monitoring сервиса
PID=$(systemctl show shadow-monitor.service -p MainPID --value)
echo "Monitor PID: $PID"

# Убить процесс (симуляция краша)
sudo kill -9 "$PID"

# Подождать 10 секунд (RestartSec=10s)
sleep 10

# Проверить статус
sudo systemctl status shadow-monitor.service

# Ожидаемый результат:
# ● shadow-monitor.service - KERNEL SHADOWS System Monitor
#      Active: active (running) since Sat 2025-10-11 15:05:10 UTC; 5s ago
#    Main PID: 12789 (новый PID!)
#   Restarts: 1

# Логи
sudo journalctl -u shadow-monitor.service -n 20

# Должно быть:
# Oct 11 15:05:00 server systemd[1]: shadow-monitor.service: Main process exited, code=killed, status=9/KILL
# Oct 11 15:05:10 server systemd[1]: shadow-monitor.service: Scheduled restart job, restart counter is at 1.
# Oct 11 15:05:10 server systemd[1]: Started KERNEL SHADOWS System Monitor.
# Oct 11 15:05:10 server shadow-monitor[12789]: [2025-10-11 15:05:10] Shadow Monitor started
```

**Анна:**  
*"Видишь? Сервис упал → systemd подождал 10 секунд → перезапустил автоматически. Restart=on-failure работает. Production-ready."*

---

### Шаг 7: Проверить resource limits

```bash
# Показать все свойства сервиса
systemctl show shadow-monitor.service | grep -E 'CPU|Memory|Tasks'

# Ожидаемый вывод:
# CPUQuotaPerSecUSec=250000           # 25% (250ms из 1000ms)
# MemoryMax=134217728                 # 128MB (в байтах)
# TasksMax=50
# LimitNOFILE=1024
```

**Проверка в реальном времени:**
```bash
# Real-time мониторинг ресурсов
systemd-cgtop

# Вывод (пример):
# Control Group                                Tasks   %CPU   Memory  Input/s Output/s
# /system.slice/shadow-monitor.service             2    0.2     2.5M        -        -
```

**Борис:**  
*"Resource limits работают. Если сервис попытается съесть 129MB → systemd убьёт его. Защита системы."*

---

### Шаг 8: Проверить security features

```bash
# Security features
systemctl show shadow-monitor.service | grep -E 'NoNewPrivileges|ProtectSystem|ProtectHome|PrivateTmp'

# Ожидаемый вывод:
# NoNewPrivileges=yes
# ProtectSystem=strict
# ProtectHome=yes
# PrivateTmp=yes
# ProtectKernelModules=yes
# ProtectKernelTunables=yes
# ProtectKernelLogs=yes
# ProtectControlGroups=yes
```

**Что это значит:**
- **NoNewPrivileges=yes:** Процесс не может повысить привилегии (suid/sudo блокированы)
- **ProtectSystem=strict:** `/` и `/usr` read-only (сервис не может изменять систему)
- **ProtectHome=yes:** `/home`, `/root` недоступны
- **PrivateTmp=yes:** Изолированный `/tmp` (не видит чужие temp файлы)
- **ProtectKernel*:** Kernel защищён от изменений

**Анна:**  
*"Это Defense in Depth. Если атакующий скомпрометирует сервис — он в sandbox. Нет доступа к системе, нет повышения привилегий."*

---

### Шаг 9: Enable на boot

```bash
# Enable monitoring service
sudo systemctl enable shadow-monitor.service

# Проверка
sudo systemctl is-enabled shadow-monitor.service
# Вывод: enabled

sudo systemctl is-enabled shadow-backup.timer
# Вывод: enabled

# Проверить symlinks
ls -l /etc/systemd/system/multi-user.target.wants/shadow-monitor.service
ls -l /etc/systemd/system/timers.target.wants/shadow-backup.timer
```

**Борис:**  
*"`systemctl enable` создаёт symlinks. SystemD видит их при загрузке → запускает сервисы автоматически."*

---

## 🧪 Финальная проверка

```bash
#!/bin/bash

echo "=== EPISODE 10: Final Check ==="

echo "=== Services Status ==="
sudo systemctl status shadow-monitor.service --no-pager
echo
sudo systemctl status shadow-backup.timer --no-pager

echo
echo "=== Next backup ==="
sudo systemctl list-timers shadow-backup.timer

echo
echo "=== Resource Limits ==="
systemctl show shadow-monitor.service | grep -E 'CPU|Memory|Tasks'

echo
echo "=== Security Features ==="
systemctl show shadow-monitor.service | grep -E 'NoNewPrivileges|ProtectSystem|ProtectHome|PrivateTmp'

echo
echo "=== Recent Logs ==="
sudo journalctl -u shadow-monitor.service -n 10 --no-pager

echo
echo "=== Backup Files ==="
ls -lh /var/backups/shadow/ | tail -5

echo
echo "=== Final Results ==="
echo "Monitor active:     $(systemctl is-active shadow-monitor.service)"
echo "Monitor enabled:    $(systemctl is-enabled shadow-monitor.service)"
echo "Timer active:       $(systemctl is-active shadow-backup.timer)"
echo "Timer enabled:      $(systemctl is-enabled shadow-backup.timer)"
echo
echo "✓ Episode 10 Complete!"
```

**Сохранить как:**
```bash
chmod +x solution/final_check.sh
./solution/final_check.sh
```

---

## 📊 Сравнение: До и После

### ❌ ДО (bash-centric approach):

```bash
#!/bin/bash
# Запускать через cron:
# 0 2 * * * /usr/local/bin/backup.sh

BACKUP_DIR="/var/backups"
tar czf "$BACKUP_DIR/backup_$(date +%Y%m%d).tar.gz" /var/operations

# Мониторинг через screen или nohup:
# nohup /usr/local/bin/monitor.sh &

while true; do
    ps aux | grep suspicious
    sleep 60
done
```

**Проблемы:**
- ❌ Нет автоперезапуска при крашах
- ❌ Нет resource limits (fork bomb уничтожит систему)
- ❌ Нет security isolation
- ❌ Логи в разных файлах (не централизованы)
- ❌ Cron пропускает задачи если сервер был выключен
- ❌ Запуск от root (всё или ничего)

---

### ✅ ПОСЛЕ (SystemD approach):

```ini
[Unit]
Description=KERNEL SHADOWS System Monitor
After=network-online.target

[Service]
Type=simple
User=shadow-monitor               # НЕ root!
ExecStart=/usr/local/bin/shadow-monitor.sh

Restart=on-failure                # Автоперезапуск
RestartSec=10s

CPUQuota=25%                      # Resource limits
MemoryMax=128M
TasksMax=50

NoNewPrivileges=true              # Security hardening
ProtectSystem=strict
ProtectHome=true

StandardOutput=journal            # Логи в journalctl

[Install]
WantedBy=multi-user.target
```

**Преимущества:**
- ✅ Автоперезапуск при крашах (Restart=on-failure)
- ✅ Resource limits (fork bomb не пройдёт)
- ✅ Security isolation (sandbox)
- ✅ Централизованные логи (journalctl)
- ✅ Timer с Persistent=true (catch missed runs)
- ✅ Непривилегированный пользователь (Principle of Least Privilege)

---

## 🎓 Ключевые отличия solution/ от starter/

| starter/ | solution/ |
|----------|-----------|
| TODO комментарии (заполнить) | Готовые конфиги (референс) |
| Минимальные подсказки | Полные комментарии с объяснениями |
| Для обучения | Для проверки/reference |

**LILITH:**  
*"Starter — это форма для заполнения. Solution — это ответы в конце учебника. Используй solution ТОЛЬКО если застрял надолго."*

---

## 🚨 Troubleshooting

### Проблема: Service не запускается

```bash
# Проверить статус
sudo systemctl status shadow-monitor.service

# Проверить логи
sudo journalctl -u shadow-monitor.service -n 50

# Проверить синтаксис
sudo systemd-analyze verify shadow-monitor.service
```

**Частые ошибки:**
- ❌ Забыл `systemctl daemon-reload`
- ❌ Скрипт не существует или не исполняем
- ❌ Пользователь `shadow-monitor` не создан
- ❌ Рабочая директория не существует

---

### Проблема: Timer не запускает backup

```bash
# Проверить статус timer
sudo systemctl status shadow-backup.timer

# Должно быть: Active: active (waiting)

# Проверить расписание
systemd-analyze calendar "*-*-* 02:00:00"

# Проверить Unit= в timer
grep "Unit=" /etc/systemd/system/shadow-backup.timer
# Должно быть: Unit=shadow-backup.service
```

---

### Проблема: Service падает и не перезапускается

```bash
# Проверить restart policy
systemctl show shadow-monitor.service | grep Restart
# Должно быть: Restart=on-failure

# Проверить лимиты перезапусков
systemctl show shadow-monitor.service | grep StartLimit
# StartLimitBurst=5 (макс 5 рестартов)
# StartLimitIntervalSec=60s (за 60 секунд)

# Если превышен лимит — сбросить
sudo systemctl reset-failed shadow-monitor.service
```

---

## 🔗 Связанные файлы

### Документация units:
- `solution/systemd/README.md` — детальная документация units
- `starter/README.md` — workflow для студентов

### Основной README:
- `../README.md` — полная теория (8 micro-cycles)
- Cycles 3-6 особенно важны для понимания solution

### Тесты:
- `../tests/test.sh` — автотесты (проверяют solution)

---

## ✅ Чеклист использования solution/

- [ ] Прочитал теорию в основном README (Cycles 3-6)
- [ ] Попробовал заполнить starter/ самостоятельно
- [ ] Застрял на 30+ минут → открыл solution
- [ ] Понял КАЖДУЮ строку в solution units (не просто скопировал)
- [ ] Создал пользователя `shadow-monitor`
- [ ] Создал скрипты (`shadow-backup.sh`, `shadow-monitor.sh`)
- [ ] Скопировал units в `/etc/systemd/system/`
- [ ] Выполнил `systemctl daemon-reload`
- [ ] Протестировал все компоненты
- [ ] Проверил resource limits
- [ ] Проверил security features
- [ ] Enabled services на boot

---

**"Solution — это не готовая домашка. Это референс для самопроверки.  
Копировать без понимания = обманывать себя."**

— **Борис Кузнецов**, SystemD Architect

**Saint Petersburg, Russia • SystemD Mastery!** 🇷🇺

---

*Episode 10 Solution • Type B: Configuration over Scripting*

