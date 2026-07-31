# Starter Files — Episode 10: Processes & SystemD

> **"Конфигурируй systemd напрямую, не оборачивай его в bash."**  
> — Философия Type B episodes

---

## 📁 Что здесь?

Эта директория содержит **шаблоны systemd units с TODO комментариями**.

Твоя задача — заполнить TODO, установить units в систему, протестировать.

```
starter/
├── systemd/                          # SystemD units с TODO
│   ├── shadow-backup.service         # Backup task (Type=oneshot)
│   ├── shadow-backup.timer           # Scheduler для backup
│   ├── shadow-monitor.service        # Monitoring daemon (Type=simple)
│   └── README.md (этот файл)         # Workflow и инструкции
```

---

## 🎯 Цель задания

**Научиться писать production-ready systemd units:**
- ✅ Service units (`.service`) — что делать
- ✅ Timer units (`.timer`) — когда делать
- ✅ Resource limits — предотвращение перегрузки
- ✅ Security hardening — минимизация рисков
- ✅ Logging — интеграция с journalctl

**НЕ писать bash wrapper вокруг systemctl!**

---

## 🔄 Workflow студента

### Шаг 1: Изучи теорию в Episode README

```bash
# Открой основной README episode
cat ../README.md | less

# Прочитай Cycles 3-6:
# - Cycle 3: SystemD Service Units
# - Cycle 4: SystemD Timers
# - Cycle 5: Resource Limits & Security
# - Cycle 6: Journalctl
```

**LILITH:** *"Сначала теория. Потом практика. Без понимания — будешь копировать не понимая."*

---

### Шаг 2: Заполни TODO в systemd units

#### A. Начни с `shadow-backup.service`

```bash
# Открой файл в редакторе
nano starter/systemd/shadow-backup.service
# или
vim starter/systemd/shadow-backup.service
```

**Заполни TODO 1-16:**
- Description, Documentation
- Type, User, WorkingDirectory
- ExecStart, ExecStartPre, ExecStartPost
- Timeouts, Resource Limits
- Security, Logging

**Подсказки:**
- Каждый TODO содержит комментарий с подсказкой
- Смотри примеры в `solution/systemd/` (но не копируй слепо!)
- Читай комментарии — они объясняют ЗАЧЕМ каждая опция

#### B. Заполни `shadow-backup.timer`

```bash
nano starter/systemd/shadow-backup.timer
```

**Заполни TODO 1-8:**
- OnCalendar (расписание)
- RandomizedDelaySec (рандомизация)
- Persistent (catch missed runs)
- Unit (какой сервис запускать)

**Шпаргалка OnCalendar:**
```
OnCalendar=daily                # 00:00 каждый день
OnCalendar=*-*-* 02:00:00       # 02:00 каждый день
OnCalendar=Mon *-*-* 09:00      # Понедельник 09:00
OnCalendar=*-*-01 03:00         # 1-е число месяца 03:00
```

Проверить синтаксис:
```bash
systemd-analyze calendar "Mon *-*-* 02:00"
```

#### C. Заполни `shadow-monitor.service`

```bash
nano starter/systemd/shadow-monitor.service
```

**Заполни TODO 1-30:**
- Больше опций чем в backup (это сложный сервис!)
- User/Group (непривилегированный пользователь!)
- Restart policy
- Resource limits
- **Security hardening** (NoNewPrivileges, ProtectHome, и т.д.)

**ВАЖНО:**
- `User=shadow-monitor` — НЕ root!
- Security features — изучи каждую опцию (комментарии объясняют)

---

### Шаг 3: Создай вспомогательные скрипты

SystemD units запускают скрипты. Создай их:

#### A. `/usr/local/bin/shadow-backup.sh`

```bash
#!/bin/bash
# Простой backup script

BACKUP_DIR="/var/backups/shadow"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Создать директорию если нет
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

#### B. `/usr/local/bin/shadow-monitor.sh`

```bash
#!/bin/bash
# Простой monitoring script

while true; do
    # Log система
    echo "[$(date)] Monitoring active. CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
    
    # Проверка подозрительных процессов
    if ps aux | grep -E 'sshd_backup|backdoor' | grep -v grep > /dev/null; then
        echo "[ALERT] Suspicious process detected!"
    fi
    
    # Пауза 30 секунд
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

### Шаг 4: Создай системного пользователя для monitor

```bash
# Создать непривилегированного пользователя
sudo useradd -r -s /bin/false shadow-monitor

# Создать рабочую директорию
sudo mkdir -p /var/operations/shadow-monitor
sudo chown shadow-monitor:shadow-monitor /var/operations/shadow-monitor
```

**LILITH:** *"Никогда не запускай сервисы от root если не нужно. Security 101."*

---

### Шаг 5: Установи units в систему

```bash
# Скопировать в /etc/systemd/system/
sudo cp starter/systemd/shadow-backup.service /etc/systemd/system/
sudo cp starter/systemd/shadow-backup.timer /etc/systemd/system/
sudo cp starter/systemd/shadow-monitor.service /etc/systemd/system/

# Установить правильные permissions
sudo chmod 644 /etc/systemd/system/shadow-*.service
sudo chmod 644 /etc/systemd/system/shadow-*.timer

# Reload systemd (обязательно после изменений!)
sudo systemctl daemon-reload
```

**LILITH:** *"Забыл daemon-reload? SystemD не увидит изменения. Запомни."*

---

### Шаг 6: Тестируй units

#### A. Проверь синтаксис

```bash
# Проверить на ошибки ДО запуска
sudo systemd-analyze verify shadow-backup.service
sudo systemd-analyze verify shadow-backup.timer
sudo systemd-analyze verify shadow-monitor.service

# Если ошибки — исправь в starter/, скопируй заново, daemon-reload
```

#### B. Ручной запуск backup (тест)

```bash
# Запустить backup вручную
sudo systemctl start shadow-backup.service

# Проверить статус
sudo systemctl status shadow-backup.service

# Должно быть:
# Active: inactive (dead) — это НОРМАЛЬНО для oneshot!
# Status: "Backup completed successfully"

# Просмотр логов
sudo journalctl -u shadow-backup.service
```

**LILITH:** *"oneshot сервис завершается после выполнения. inactive (dead) — это ОК."*

#### C. Запустить monitoring service

```bash
# Start monitoring
sudo systemctl start shadow-monitor.service

# Проверить статус
sudo systemctl status shadow-monitor.service

# Должно быть:
# Active: active (running) since ...
# Main PID: [число]

# Просмотр логов (real-time)
sudo journalctl -u shadow-monitor.service -f

# Остановить (Ctrl+C для выхода из journalctl)
```

#### D. Включить timer

```bash
# Enable timer (запуск при загрузке)
sudo systemctl enable shadow-backup.timer

# Start timer сейчас
sudo systemctl start shadow-backup.timer

# Проверить когда следующий запуск
sudo systemctl list-timers shadow-backup.timer

# Должно показать:
# NEXT                         LEFT          LAST  PASSED  UNIT
# 2025-10-12 02:00:00 UTC  5h 23min left  n/a   n/a     shadow-backup.timer
```

---

### Шаг 7: Проверь автоперезапуск monitor

```bash
# Убить процесс мониторинга (симуляция краша)
sudo pkill -f shadow-monitor.sh

# Подождать 10 секунд (RestartSec=10s)
sleep 10

# Проверить статус
sudo systemctl status shadow-monitor.service

# Должно быть:
# Active: active (running) — автоматически перезапустился!
# Restarts: 1 (показывает количество перезапусков)
```

**LILITH:** *"Restart=on-failure работает. Сервис упал — systemd поднял его обратно. Production-ready."*

---

### Шаг 8: Проверь resource limits

```bash
# Посмотреть текущее использование ресурсов
systemctl show shadow-monitor.service | grep -E 'CPU|Memory|Tasks'

# Должно быть в пределах лимитов:
# CPUQuota=25% → макс 25% одного ядра
# MemoryLimit=128M → макс 128MB RAM

# Real-time мониторинг всех сервисов
systemd-cgtop
```

---

### Шаг 9: Enable monitoring на boot

```bash
# Enable (автозапуск при загрузке системы)
sudo systemctl enable shadow-monitor.service

# Проверить что enabled
sudo systemctl is-enabled shadow-monitor.service
# Должно вывести: enabled
```

---

## ✅ Чеклист выполнения

Отметь когда выполнил:

- [ ] Прочитал теорию в Episode README (Cycles 3-6)
- [ ] Заполнил TODO в `shadow-backup.service`
- [ ] Заполнил TODO в `shadow-backup.timer`
- [ ] Заполнил TODO в `shadow-monitor.service`
- [ ] Создал `/usr/local/bin/shadow-backup.sh` (chmod +x)
- [ ] Создал `/usr/local/bin/shadow-monitor.sh` (chmod +x)
- [ ] Создал пользователя `shadow-monitor`
- [ ] Скопировал units в `/etc/systemd/system/`
- [ ] Выполнил `systemctl daemon-reload`
- [ ] Проверил синтаксис через `systemd-analyze verify`
- [ ] Протестировал backup вручную (`systemctl start`)
- [ ] Запустил monitoring service
- [ ] Включил и протестировал timer
- [ ] Проверил автоперезапуск (pkill → restart)
- [ ] Проверил resource limits (`systemctl show`)
- [ ] Включил services на boot (`systemctl enable`)
- [ ] Запустил автотесты (`tests/test.sh`)

---

## 🧪 Запуск автотестов

```bash
cd /home/fazzz/kernel-shadows/season-03-system-administration/episode-10-processes-systemd
./tests/test.sh
```

**Что проверяют тесты:**
- ✅ Units скопированы в `/etc/systemd/system/`
- ✅ Scripts существуют и исполняемы
- ✅ Services запускаются без ошибок
- ✅ Timer активен и показывает next run
- ✅ Логи пишутся в journalctl
- ✅ Resource limits установлены
- ✅ Security features включены

---

## 🚨 Troubleshooting

### Проблема: Service не запускается

```bash
# Проверь детальный статус
sudo systemctl status shadow-monitor.service -l

# Проверь логи (последние 50 строк)
sudo journalctl -u shadow-monitor.service -n 50

# Проверь синтаксис unit файла
sudo systemd-analyze verify shadow-monitor.service
```

**Частые ошибки:**
- ❌ Забыл `systemctl daemon-reload` после изменений
- ❌ Скрипт не существует или не исполняем (chmod +x)
- ❌ Пользователь `shadow-monitor` не создан
- ❌ Рабочая директория не существует
- ❌ Опечатка в пути (ExecStart)

---

### Проблема: Timer не запускает backup

```bash
# Проверь статус timer
sudo systemctl status shadow-backup.timer

# Должно быть: Active: active (waiting)

# Посмотри когда следующий запуск
sudo systemctl list-timers shadow-backup.timer

# Ручной запуск backup для теста
sudo systemctl start shadow-backup.service

# Проверь логи backup
sudo journalctl -u shadow-backup.service
```

**Частые ошибки:**
- ❌ Timer не enabled (`systemctl enable shadow-backup.timer`)
- ❌ Timer не started (`systemctl start shadow-backup.timer`)
- ❌ Неправильный синтаксис OnCalendar
- ❌ Неправильное имя Unit= (должно совпадать с .service)

---

### Проблема: Service падает и не перезапускается

```bash
# Проверь restart policy
systemctl show shadow-monitor.service | grep Restart

# Должно быть: Restart=on-failure

# Проверь лимиты перезапусков
systemctl show shadow-monitor.service | grep StartLimit

# StartLimitBurst=5 → макс 5 рестартов
# StartLimitIntervalSec=60s → за 60 секунд

# Если превышен лимит — сбрось счётчик
sudo systemctl reset-failed shadow-monitor.service
```

---

### Проблема: Permission denied

```bash
# Проверь permissions на unit файл
ls -la /etc/systemd/system/shadow-monitor.service

# Должно быть: -rw-r--r-- 1 root root

# Исправь permissions
sudo chown root:root /etc/systemd/system/shadow-monitor.service
sudo chmod 644 /etc/systemd/system/shadow-monitor.service

# Reload
sudo systemctl daemon-reload
```

---

## 📚 Полезные команды

### Service Management

```bash
# Запуск
sudo systemctl start shadow-monitor.service

# Остановка
sudo systemctl stop shadow-monitor.service

# Перезапуск
sudo systemctl restart shadow-monitor.service

# Reload конфигурации (без перезапуска)
sudo systemctl reload shadow-monitor.service

# Статус
sudo systemctl status shadow-monitor.service

# Включить автозапуск
sudo systemctl enable shadow-monitor.service

# Отключить автозапуск
sudo systemctl disable shadow-monitor.service

# Проверить enabled или нет
sudo systemctl is-enabled shadow-monitor.service

# Проверить active или нет
sudo systemctl is-active shadow-monitor.service
```

### Logs

```bash
# Все логи сервиса
sudo journalctl -u shadow-monitor.service

# Последние 50 строк
sudo journalctl -u shadow-monitor.service -n 50

# Real-time (follow)
sudo journalctl -u shadow-monitor.service -f

# С момента загрузки
sudo journalctl -u shadow-monitor.service -b

# За последний час
sudo journalctl -u shadow-monitor.service --since "1 hour ago"

# Только ошибки
sudo journalctl -u shadow-monitor.service -p err

# Только сегодня
sudo journalctl -u shadow-monitor.service --since today
```

### Timers

```bash
# Список всех timers
sudo systemctl list-timers --all

# Конкретный timer
sudo systemctl list-timers shadow-backup.timer

# Статус timer
sudo systemctl status shadow-backup.timer

# Enable/Start timer
sudo systemctl enable shadow-backup.timer
sudo systemctl start shadow-backup.timer
```

### SystemD Analysis

```bash
# Проверка синтаксиса
sudo systemd-analyze verify shadow-monitor.service

# Проверка расписания timer
systemd-analyze calendar "Mon *-*-* 02:00"

# Показать зависимости
systemctl list-dependencies shadow-monitor.service

# Время загрузки сервисов
systemd-analyze blame
```

### Resource Usage

```bash
# Real-time мониторинг
systemd-cgtop

# Конкретный сервис
systemctl show shadow-monitor.service | grep -E 'CPU|Memory|Tasks'
```

---

## 💡 Best Practices (из Episode README)

### ✅ DO

- ✅ Используй непривилегированных пользователей (не root)
- ✅ Ограничивай ресурсы (CPU, Memory, Tasks)
- ✅ Включай security features (NoNewPrivileges, ProtectHome, ...)
- ✅ Настраивай автоперезапуск (Restart=on-failure)
- ✅ Логируй в journal (StandardOutput=journal)
- ✅ Используй timers вместо cron
- ✅ Всегда делай `systemctl daemon-reload` после изменений
- ✅ Тестируй units через `systemd-analyze verify` перед запуском

### ❌ DON'T

- ❌ НЕ запускай сервисы от root без необходимости
- ❌ НЕ пиши bash wrapper вокруг systemctl
- ❌ НЕ забывай daemon-reload после изменений
- ❌ НЕ hardcode values — используй Environment/EnvironmentFile
- ❌ НЕ игнорируй resource limits — они предотвращают DoS
- ❌ НЕ пропускай pre-checks (ExecStartPre)

---

## 🔗 Дополнительные ресурсы

### Man Pages

```bash
man systemd.service     # Service units
man systemd.timer       # Timer units
man systemd.exec        # Execution options (User, CPUQuota, etc.)
man systemd.resource-control  # Resource limits
man journalctl          # Log viewing
man systemctl           # Service control
```

### Online Documentation

- [systemd.service — Arch Wiki](https://wiki.archlinux.org/title/systemd)
- [SystemD by Example — Red Hat](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/assembly_working-with-systemd-unit-files_configuring-basic-system-settings)
- [Understanding SystemD Units](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)

---

## 🎓 Вопросы для самопроверки

После выполнения задания, ответь на вопросы:

1. **В чём разница между Type=simple и Type=oneshot?**
   <details><summary>Ответ</summary>
   - simple: Долго работающий процесс (monitoring, web server)
   - oneshot: Запускается, выполняется, завершается (backup, setup tasks)
   </details>

2. **Зачем нужен RandomizedDelaySec в timer?**
   <details><summary>Ответ</summary>
   Распределяет запуск задач во времени. Если 100 серверов запустят backup ровно в 02:00, это создаст пиковую нагрузку. RandomizedDelaySec распределяет запуск на ±15 минут.
   </details>

3. **Что делает NoNewPrivileges=true?**
   <details><summary>Ответ</summary>
   Запрещает процессу получать больше привилегий чем у него есть. Предотвращает атаки через suid бинарники.
   </details>

4. **Почему service unit не имеет [Install] секции?**
   <details><summary>Ответ</summary>
   oneshot сервис, который запускается через timer, не нуждается в [Install]. Timer сам активирует сервис по расписанию.
   </details>

5. **Как узнать когда timer запустится в следующий раз?**
   <details><summary>Ответ</summary>
   `sudo systemctl list-timers shadow-backup.timer` — показывает NEXT (следующий запуск) и LEFT (осталось времени).
   </details>

6. **Зачем ограничивать CPUQuota и MemoryLimit?**
   <details><summary>Ответ</summary>
   Предотвращает resource exhaustion. Если сервис уходит в бесконечный цикл или утечка памяти, systemd убьёт процесс до того как он положит весь сервер.
   </details>

---

**"SystemD unit = production-ready service. Resource limits, security hardening, auto-restart. Enterprise-grade."**

— Борис Кузнецов, SystemD Architect

**Saint Petersburg, Russia • SystemD Mastery!** 🇷🇺

---

