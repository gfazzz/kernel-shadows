# Конфигурации sudo для команды операции
## Episode 09: Пользователи и права доступа

> *"Root access как заряженный пистолет. Не давай его кому попало."*
> — Андрей Волков, ЛЭТИ

---

## 📁 Файлы в этой папке

### `alex` — Алекс Соколов (Сетевой администратор)
**Разрешённые команды:**
- Сетевые утилиты: `ip`, `ss`, `netstat`, `tcpdump`
- Фаервол: `iptables`, `ufw`
- Сканирование: `nmap`, `traceroute`, `mtr`

**Запрещено:**
- Управление пользователями (`useradd`, `passwd root`)
- Изменение sudo конфигурации (`visudo`)
- Деструктивные команды (`rm -rf /`)

**Философия:** Принцип минимальных привилегий (Principle of Least Privilege)

---

### `anna` — Анна Ковалёва (Криминалистический эксперт)
**Разрешённые команды:**
- Чтение логов: `less`, `tail`, `cat`, `grep` для `/var/log/*`
- Журнал systemd: `journalctl`
- Архивные логи: `zgrep`, `zcat`

**Запрещено:**
- Изменение логов (любые write операции)
- Удаление логов (`rm`, `truncate`)
- Управление пользователями

**Философия:** Read-only доступ для forensics (целостность доказательств)

---

### `dmitry` — Дмитрий Орлов (DevOps инженер)
**Разрешённые команды:**
- Управление сервисами: `systemctl start/stop/restart/status`
- Просмотр логов: `journalctl`
- Управление процессами: `kill`, `pkill`, `htop`
- Docker: `docker`, `docker-compose`

**Запрещено:**
- Управление пользователями
- Изменение sudo конфигурации
- Деструктивные команды

**Философия:** Separation of duties (разделение обязанностей)

---

## 📦 Установка

### Шаг 1: Копирование конфигов
```bash
# Скопировать все файлы в /etc/sudoers.d/
sudo cp alex /etc/sudoers.d/alex
sudo cp anna /etc/sudoers.d/anna
sudo cp dmitry /etc/sudoers.d/dmitry
```

### Шаг 2: Установка прав доступа
```bash
# Права 440 (read-only для root и группы, ничего для остальных)
sudo chmod 440 /etc/sudoers.d/alex
sudo chmod 440 /etc/sudoers.d/anna
sudo chmod 440 /etc/sudoers.d/dmitry
```

### Шаг 3: Проверка синтаксиса (КРИТИЧНО!)
```bash
# Проверить каждый файл
sudo visudo -c -f /etc/sudoers.d/alex
sudo visudo -c -f /etc/sudoers.d/anna
sudo visudo -c -f /etc/sudoers.d/dmitry

# Если OK — увидишь сообщение "parsed OK"
# Если ERROR — НЕ ПРОДОЛЖАЙ! Исправь синтаксис!
```

**⚠️ ВАЖНО:** Ошибка в sudoers файле может **полностью заблокировать sudo**!
Всегда проверяй синтаксис через `visudo -c` перед активацией!

### Шаг 4: Проверка что файлы загружены
```bash
# Проверить что sudoers.d включён в основном файле
grep "^#includedir /etc/sudoers.d" /etc/sudoers

# Если строки нет — добавь в /etc/sudoers:
# echo "#includedir /etc/sudoers.d" | sudo tee -a /etc/sudoers
```

---

## ✅ Тестирование

### Тест 1: Алекс может выполнять сетевые команды
```bash
# Успех (должно работать)
sudo -u alex sudo ip addr show
sudo -u alex sudo ss -tulpn
sudo -u alex sudo iptables -L

# Ошибка (должно быть запрещено)
sudo -u alex sudo useradd test
# Ожидается: "Sorry, user alex is not allowed to execute..."
```

### Тест 2: Анна может читать логи, но не изменять
```bash
# Успех (должно работать)
sudo -u anna sudo cat /var/log/auth.log
sudo -u anna sudo journalctl -u ssh --since today
sudo -u anna sudo grep "Failed" /var/log/auth.log

# Ошибка (должно быть запрещено)
sudo -u anna sudo rm /var/log/auth.log
sudo -u anna sudo bash -c 'echo "fake" >> /var/log/auth.log'
```

### Тест 3: Дмитрий может управлять сервисами
```bash
# Успех (должно работать)
sudo -u dmitry sudo systemctl status nginx
sudo -u dmitry sudo journalctl -u nginx -n 50
sudo -u dmitry sudo docker ps

# Ошибка (должно быть запрещено)
sudo -u dmitry sudo useradd test
sudo -u dmitry sudo visudo
```

### Тест 4: NOPASSWD работает (не запрашивает пароль)
```bash
# Флаг -n = non-interactive (не запрашивать пароль)
sudo -u alex sudo -n ip addr show
sudo -u anna sudo -n journalctl -n 10
sudo -u dmitry sudo -n systemctl status

# Если работает без ошибки — NOPASSWD настроен правильно
```

---

## 📊 Проверка текущих прав

### Посмотреть что может конкретный пользователь
```bash
# Показать sudo права для Алекса
sudo -u alex sudo -l

# Вывод покажет:
# User alex may run the following commands on hostname:
#     (root) NOPASSWD: /usr/sbin/ip, /usr/bin/ss, ...
```

### Посмотреть все sudo правила
```bash
# Все активные правила из /etc/sudoers и /etc/sudoers.d/*
sudo cat /etc/sudoers
sudo cat /etc/sudoers.d/*
```

### Проверить логи sudo (кто что делал)
```bash
# Последние sudo команды за сегодня
sudo grep "sudo.*COMMAND" /var/log/auth.log | grep "$(date +%b\ %d)"

# Команды конкретного пользователя
sudo grep "alex.*COMMAND" /var/log/auth.log

# Через journalctl
sudo journalctl _COMM=sudo --since today
```

---

## 🔒 Безопасность

### Принципы, реализованные в этих конфигах:

**1. Principle of Least Privilege (Принцип минимальных привилегий)**
- Каждый пользователь имеет **только** те права, которые нужны для работы
- Алекс: ТОЛЬКО сетевые команды
- Анна: ТОЛЬКО чтение логов
- Дмитрий: ТОЛЬКО управление сервисами

**2. Defense in Depth (Эшелонированная защита)**
- Явный запрет опасных команд (`!command`)
- Даже если что-то пропустили — опасные команды заблокированы

**3. Separation of Duties (Разделение обязанностей)**
- Никто не имеет полного sudo
- Алекс не может управлять сервисами
- Дмитрий не может менять сетевые настройки
- Анна не может изменять то, что расследует

**4. Audit Trail (Следы аудита)**
- Все sudo команды логируются в `/var/log/auth.log`
- Можно проверить кто, когда, что выполнил

**5. NOPASSWD с осторожностью**
- NOPASSWD удобно для автоматизации
- НО: если аккаунт скомпрометирован — атакующий получает те же права
- Поэтому: только ограниченный набор команд!

---

## ⚠️ Частые ошибки

### Ошибка 1: Забыл проверить синтаксис
```bash
# ❌ ПЛОХО: скопировал файл и перезагрузился — sudo не работает!
sudo cp alex /etc/sudoers.d/alex

# ✅ ХОРОШО: проверил синтаксис ПЕРЕД перезагрузкой
sudo visudo -c -f /etc/sudoers.d/alex
```

### Ошибка 2: Неправильные права доступа
```bash
# ❌ ПЛОХО: файл доступен для записи обычным пользователям
chmod 644 /etc/sudoers.d/alex
# sudo откажется использовать файл!

# ✅ ХОРОШО: только root может читать и писать
sudo chmod 440 /etc/sudoers.d/alex
```

### Ошибка 3: Забыл про includedir
```bash
# Проверь что в /etc/sudoers есть строка:
grep "^#includedir /etc/sudoers.d" /etc/sudoers

# Если нет — файлы в /etc/sudoers.d/ игнорируются!
```

### Ошибка 4: Слишком широкие маски
```bash
# ❌ ОПАСНО: alex может выполнять ВСЁ в /usr/sbin/
alex ALL=(root) NOPASSWD: /usr/sbin/*

# ✅ БЕЗОПАСНО: только конкретные команды
alex ALL=(root) NOPASSWD: /usr/sbin/ip, /usr/sbin/iptables
```

---

## 🛠️ Отладка проблем

### Проблема: "Sorry, user alex is not allowed..."
**Причины:**
1. Файл не в `/etc/sudoers.d/`
2. Неправильные права (не 440)
3. Синтаксическая ошибка в файле
4. `includedir` не настроен в `/etc/sudoers`

**Решение:**
```bash
# Проверить что файл на месте
ls -la /etc/sudoers.d/alex

# Проверить права
stat /etc/sudoers.d/alex
# Должно быть: Access: (0440/-r--r-----)

# Проверить синтаксис
sudo visudo -c -f /etc/sudoers.d/alex

# Проверить includedir
grep includedir /etc/sudoers
```

### Проблема: sudo запрашивает пароль (игнорирует NOPASSWD)
**Причины:**
1. В `/etc/sudoers` есть конфликтующее правило
2. Порядок правил неправильный (последнее правило выигрывает)

**Решение:**
```bash
# Проверить все правила для пользователя
sudo -u alex sudo -l

# Если видишь "(ALL) NOPASSWD: ALL" и ниже "(root) /usr/sbin/ip"
# Значит первое правило перекрывает второе

# Порядок загрузки:
# 1. /etc/sudoers
# 2. /etc/sudoers.d/* (в алфавитном порядке)
```

### Проблема: После изменения sudoers файла sudo перестал работать
**ПАНИКА MODE!**

Если у тебя есть открытая root сессия:
```bash
# В root сессии — исправь файл
visudo -f /etc/sudoers.d/alex

# Или удали проблемный файл
rm /etc/sudoers.d/alex
```

Если нет root сессии — придётся использовать recovery mode:
1. Перезагрузить в recovery mode (GRUB меню)
2. Выбрать "Drop to root shell"
3. Исправить `/etc/sudoers` или `/etc/sudoers.d/*`

**Поэтому:** ВСЕГДА проверяй синтаксис через `visudo -c` ДО активации!

---

## 📖 Дополнительные ресурсы

### Man pages
```bash
man sudoers       # Полная документация по формату sudoers
man sudo          # Документация по команде sudo
man visudo        # Редактор sudoers с проверкой синтаксиса
```

### Online
- [Sudo Official Documentation](https://www.sudo.ws/docs/man/sudoers.man/)
- [Arch Wiki: sudo](https://wiki.archlinux.org/title/Sudo)
- [Red Hat: Configuring sudo](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/managing-sudo-access_configuring-basic-system-settings)

### Примеры из этого курса
- Episode 04: Package Management (принцип "используй готовые инструменты")
- Episode 10: Processes & Systemd (управление сервисами)

---

## 📝 История изменений

- **2025-10-11:** Созданы конфигурации для операции KERNEL SHADOWS
  - alex: Сетевые команды
  - anna: Read-only логи (forensics)
  - dmitry: Управление сервисами (DevOps)
  - Ментор: Андрей Волков, ЛЭТИ
  - Локация: Санкт-Петербург, белые ночи

---

<div align="center">

**"Root — это не привилегия. Это ответственность."**

— Андрей Волков, профессор, ЛЭТИ

</div>
