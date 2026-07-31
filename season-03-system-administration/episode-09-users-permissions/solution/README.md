# Episode 09: Users & Permissions — Solution
## Type B: Конфигурирование системы (НЕ bash скрипт)

> *"Root access как заряженный пистолет. Не давай его кому попало."*
> — Андрей Волков, ЛЭТИ, Санкт-Петербург

---

## 🎯 Философия решения

**Это Type B episode:**
- ✅ 70% времени: изучение `/etc/sudoers`, ACL, PAM, конфигурирование
- ✅ 20% времени: ручная настройка через `visudo`, `setfacl`
- ✅ 10% времени: bash ТОЛЬКО для создания пользователей (не для конфигурации!)

**Подход:**
```
❌ ПЛОХО: Написать 800-строчный bash скрипт который делает ВСЁ
✅ ХОРОШО: Использовать реальные конфигурационные файлы + минимальный bash
```

**Принцип из Episode 04:**
> "apt exists for a reason — use it, don't rewrite it"

**Применим к Episode 09:**
> "visudo, setfacl, PAM exist for a reason — use them, don't wrap in bash"

---

## 📁 Структура solution

```
solution/
├── sudoers.d/                      ← Конфигурации sudo
│   ├── alex                        ← Сетевые команды для Алекса
│   ├── anna                        ← Read-only логи для Анны
│   ├── dmitry                      ← Управление сервисами для Дмитрия
│   └── README.md                   ← Документация + установка
│
├── security/                       ← Ограничения ресурсов
│   ├── limits.conf                 ← Лимиты процессов/файлов
│   └── README.md                   ← Документация + примеры
│
├── pam.d/                          ← PAM конфигурация (примеры)
│   ├── common-session-example      ← Пример session настроек
│   └── README.md                   ← Объяснение PAM
│
├── setup_users.sh                  ← Минимальный скрипт (114 строк)
│                                   ← ТОЛЬКО useradd/groupadd
│                                   ← НЕ конфигурация sudo/ACL/PAM!
│
└── README.md                       ← Этот файл (workflow)
```

---

## 🚀 Workflow установки (пошагово)

### Шаг 1: Создание пользователей и групп

**Запустить минимальный скрипт:**
```bash
cd solution/
./setup_users.sh
```

**Что делает скрипт:**
- ✅ Создаёт 4 пользователя: viktor, alex, anna, dmitry
- ✅ Создаёт 5 групп: operations, security, forensics, devops, netadmin
- ✅ Добавляет пользователей в группы
- ✅ Устанавливает временные пароли (нужно сменить при первом входе)

**Что НЕ делает скрипт:**
- ❌ НЕ настраивает sudo (это делается в Шаге 2)
- ❌ НЕ настраивает ACL (это делается в Шаге 3)
- ❌ НЕ настраивает limits/PAM (это делается в Шаге 4-5)

---

### Шаг 2: Конфигурация sudo (через файлы, НЕ скрипт!)

**2.1. Копирование sudoers файлов:**
```bash
# Скопировать конфиги sudo в систему
sudo cp sudoers.d/alex /etc/sudoers.d/alex
sudo cp sudoers.d/anna /etc/sudoers.d/anna
sudo cp sudoers.d/dmitry /etc/sudoers.d/dmitry

# Установить правильные права (440 = read-only)
sudo chmod 440 /etc/sudoers.d/alex
sudo chmod 440 /etc/sudoers.d/anna
sudo chmod 440 /etc/sudoers.d/dmitry
```

**2.2. Проверка синтаксиса (КРИТИЧНО!):**
```bash
# Проверить каждый файл
sudo visudo -c -f /etc/sudoers.d/alex
sudo visudo -c -f /etc/sudoers.d/anna
sudo visudo -c -f /etc/sudoers.d/dmitry

# Ожидается: "parsed OK" для каждого
# Если ошибка — НЕ ПРОДОЛЖАЙ! Исправь синтаксис!
```

**2.3. Тестирование:**
```bash
# Тест: Алекс может выполнять сетевые команды
sudo -u alex sudo ip addr show
# Ожидается: успех

# Тест: Алекс НЕ может создать пользователя
sudo -u alex sudo useradd test
# Ожидается: "Sorry, user alex is not allowed to execute..."
```

---

### Шаг 3: Настройка ACL для Анны (вручную, НЕ скрипт!)

**3.1. Проверка поддержки ACL:**
```bash
# Проверить что ACL поддерживается
which setfacl
# Если не найдено — установить:
sudo apt-get install -y acl
```

**3.2. Установка ACL для чтения логов:**
```bash
# Анне нужен execute на /var/log (чтобы войти в директорию)
sudo setfacl -m u:anna:rx /var/log

# Read-only на конкретные логи
sudo setfacl -m u:anna:r /var/log/auth.log
sudo setfacl -m u:anna:r /var/log/syslog
sudo setfacl -m u:anna:r /var/log/kern.log

# Опционально: ACL по умолчанию для новых файлов
sudo setfacl -d -m u:anna:r /var/log
```

**3.3. Тестирование:**
```bash
# Тест: Анна может читать логи
sudo -u anna cat /var/log/auth.log
# Ожидается: успех

# Тест: Анна НЕ может изменять логи
sudo -u anna bash -c 'echo "fake" >> /var/log/auth.log'
# Ожидается: ошибка "Permission denied"
```

**3.4. Проверка ACL:**
```bash
# Посмотреть ACL на файле
getfacl /var/log/auth.log

# Ожидается вывод:
# user::rw-
# user:anna:r--    ← ACL для Анны
# group::r--
# ...
```

---

### Шаг 4: Создание shared directory с special bits

**4.1. Создание директории:**
```bash
# Создать shared директорию
sudo mkdir -p /var/operations/shared
```

**4.2. Установка владельца и группы:**
```bash
# Владелец: viktor, группа: operations
sudo chown viktor:operations /var/operations/shared
```

**4.3. Установка permissions с special bits:**
```bash
# Permissions: 3770
# 1 = Sticky bit (только владелец может удалить свой файл)
# 2 = SGID (новые файлы наследуют группу директории)
# 770 = rwx для user и group, ничего для others

sudo chmod 3770 /var/operations/shared
```

**4.4. Проверка permissions:**
```bash
ls -ld /var/operations/shared

# Ожидается:
# drwxrws--T ... viktor operations ... /var/operations/shared
#     ^  ^
#     |  Sticky bit (T)
#     SGID (s)
```

**4.5. Тестирование:**
```bash
# Тест: Viktor может создать файл
sudo -u viktor touch /var/operations/shared/viktor_file.txt
ls -l /var/operations/shared/viktor_file.txt
# Ожидается: -rw-r--r-- viktor operations ...
#            (group наследуется от директории!)

# Тест: Dmitry может создать файл (member of operations)
sudo -u dmitry touch /var/operations/shared/dmitry_file.txt

# Тест: Dmitry НЕ может удалить файл Viktor (sticky bit!)
sudo -u dmitry rm /var/operations/shared/viktor_file.txt
# Ожидается: ошибка "Operation not permitted"

# Тест: Viktor может удалить свой файл
sudo -u viktor rm /var/operations/shared/viktor_file.txt
# Ожидается: успех
```

---

### Шаг 5: Установка limits.conf (ограничения ресурсов)

**5.1. Backup оригинального файла:**
```bash
sudo cp /etc/security/limits.conf /etc/security/limits.conf.backup
```

**5.2. Копирование нового конфига:**
```bash
sudo cp security/limits.conf /etc/security/limits.conf

# Права 644 (read-only для пользователей)
sudo chmod 644 /etc/security/limits.conf
```

**5.3. Проверка PAM конфигурации:**
```bash
# Проверить что PAM использует pam_limits.so
grep pam_limits.so /etc/pam.d/common-session

# Ожидается:
# session required pam_limits.so

# Если строки нет — добавить:
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
```

**5.4. Применение лимитов (нужен logout/login!):**
```bash
# Лимиты применяются при НОВОМ входе пользователя
# Существующие сессии НЕ затронуты!

# Тест: Войти как alex и проверить лимиты
sudo -i -u alex
ulimit -n    # Ожидается: 16384 (из limits.conf)
ulimit -u    # Ожидается: 1500 (из limits.conf)
exit
```

**5.5. Тестирование защиты от fork bomb:**
```bash
# ⚠️ ТОЛЬКО В ТЕСТОВОЙ СРЕДЕ!
# НЕ ЗАПУСКАЙ НА PRODUCTION!

# Установить низкий лимит
ulimit -u 50

# Попытка запустить fork bomb (создаёт процессы рекурсивно)
:(){ :|:& };:

# Ожидается: остановится на ~50 процессах
# bash: fork: retry: Resource temporarily unavailable

# Система остаётся работоспособной (защита работает!)
```

---

### Шаг 6: Security audit — SUID/SGID файлы

**6.1. Поиск SUID файлов:**
```bash
# Найти все файлы с SUID битом (выполняются от имени владельца)
find / -perm -4000 -type f 2>/dev/null

# Пример вывода:
# /usr/bin/sudo
# /usr/bin/passwd
# /usr/bin/su
# ...
```

**6.2. Поиск SGID файлов:**
```bash
# Найти все файлы с SGID битом
find / -perm -2000 -type f 2>/dev/null
```

**6.3. Проверка подозрительных файлов:**
```bash
# Известные безопасные SUID файлы:
# /usr/bin/sudo, /usr/bin/passwd, /usr/bin/su, /usr/bin/mount, /usr/bin/ping

# Подозрительные места:
# - /tmp (временные файлы — не должно быть SUID!)
# - /home (пользовательские файлы — не должно быть SUID!)

# Поиск SUID в /tmp и /home
find /tmp /home -perm -4000 -type f 2>/dev/null

# Если нашёл — ALERT! Возможен backdoor!
```

**6.4. Создание baseline для мониторинга:**
```bash
# Сохранить список SUID файлов
find / -perm -4000 -type f 2>/dev/null | sort > /root/suid_baseline.txt

# Потом (например, через неделю) — проверить изменения:
find / -perm -4000 -type f 2>/dev/null | sort | diff /root/suid_baseline.txt -

# Если появились новые SUID файлы — расследовать!
```

---

## ✅ Финальная проверка

### Чеклист проверки конфигурации

- [ ] **Пользователи созданы:**
  ```bash
  for u in viktor alex anna dmitry; do id "$u"; done
  ```

- [ ] **Группы созданы и заполнены:**
  ```bash
  for u in viktor alex anna dmitry; do groups "$u"; done
  ```

- [ ] **Sudo работает для Алекса (только сетевые команды):**
  ```bash
  sudo -u alex sudo ip addr show    # Успех
  sudo -u alex sudo useradd test    # Ошибка
  ```

- [ ] **Sudo работает для Анны (только чтение логов):**
  ```bash
  sudo -u anna sudo cat /var/log/auth.log    # Успех
  sudo -u anna sudo rm /var/log/auth.log     # Ошибка
  ```

- [ ] **Sudo работает для Дмитрия (управление сервисами):**
  ```bash
  sudo -u dmitry sudo systemctl status ssh   # Успех
  sudo -u dmitry sudo useradd test           # Ошибка
  ```

- [ ] **ACL для Анны работает:**
  ```bash
  getfacl /var/log/auth.log | grep "user:anna"
  ```

- [ ] **Shared directory настроена правильно:**
  ```bash
  ls -ld /var/operations/shared
  # Ожидается: drwxrws--T viktor operations
  ```

- [ ] **Sticky bit работает (нельзя удалить чужие файлы):**
  ```bash
  sudo -u viktor touch /var/operations/shared/test.txt
  sudo -u dmitry rm /var/operations/shared/test.txt  # Должна быть ошибка
  ```

- [ ] **Limits.conf применяется:**
  ```bash
  sudo -i -u alex
  ulimit -n    # Ожидается: 16384
  ulimit -u    # Ожидается: 1500
  ```

- [ ] **SUID/SGID audit выполнен:**
  ```bash
  ls -la /root/suid_baseline.txt
  ```

---

## 📊 Итоговый отчёт

**Создать отчёт одной командой (ONE-LINER как в Episode 04):**

```bash
{
  echo "=== SECURITY AUDIT REPORT - EPISODE 09 ==="
  echo "Date: $(date)"
  echo "Location: Saint Petersburg, LETI"
  echo "Auditor: Max Sokolov"
  echo "Mentor: Andrei Volkov"
  echo
  echo "1. USERS CREATED:"
  for u in viktor alex anna dmitry; do id "$u"; done
  echo
  echo "2. GROUPS & MEMBERSHIP:"
  for u in viktor alex anna dmitry; do echo "$u: $(groups $u)"; done
  echo
  echo "3. SUDO CONFIGURATION:"
  echo "Alex: sudo limited to network commands"
  sudo ls -la /etc/sudoers.d/alex
  echo "Anna: sudo limited to log reading"
  sudo ls -la /etc/sudoers.d/anna
  echo "Dmitry: sudo limited to service management"
  sudo ls -la /etc/sudoers.d/dmitry
  echo
  echo "4. ACL CONFIGURATION:"
  getfacl /var/log/auth.log 2>/dev/null | grep "user:anna" || echo "ACL not set"
  echo
  echo "5. SHARED DIRECTORY:"
  ls -ld /var/operations/shared 2>/dev/null || echo "Not created"
  echo
  echo "6. RESOURCE LIMITS:"
  echo "Alex nofile limit: $(sudo -i -u alex bash -c 'ulimit -n')"
  echo "Anna nproc limit: $(sudo -i -u anna bash -c 'ulimit -u')"
  echo
  echo "7. SUID/SGID AUDIT:"
  echo "SUID files: $(find / -perm -4000 -type f 2>/dev/null | wc -l)"
  echo "SGID files: $(find / -perm -2000 -type f 2>/dev/null | wc -l)"
  echo
  echo "=== END OF REPORT ==="
} > security_audit_ep09.txt

# Показать отчёт
cat security_audit_ep09.txt
```

---

## 🔧 Откат изменений (если нужно)

### Удаление пользователей
```bash
for u in viktor alex anna dmitry; do
  sudo userdel -r "$u"  # -r = удалить home directory
done
```

### Удаление групп
```bash
for g in operations security forensics devops netadmin; do
  sudo groupdel "$g"
done
```

### Удаление sudo конфигов
```bash
sudo rm /etc/sudoers.d/alex
sudo rm /etc/sudoers.d/anna
sudo rm /etc/sudoers.d/dmitry
```

### Удаление ACL
```bash
sudo setfacl -b /var/log/auth.log  # Удалить все ACL
```

### Удаление shared directory
```bash
sudo rm -rf /var/operations
```

### Откат limits.conf
```bash
sudo cp /etc/security/limits.conf.backup /etc/security/limits.conf
```

---

## 📚 Связь с другими episodes

### Episode 04: Package Management
- Принцип: "apt exists — use it, don't rewrite it"
- Применён к Episode 09: "visudo exists — use it, don't wrap in bash"

### Episode 10: Processes & Systemd
- Limits для systemd сервисов (LimitNOFILE в .service файлах)
- Интеграция pam_systemd.so

### Episode 12: Backup & Recovery
- Backup пользовательских данных
- Защита от заполнения диска через limits

---

## 🎓 Что ты освоил

### Технические навыки:
- ✅ Создание пользователей и групп (`useradd`, `groupadd`, `usermod`)
- ✅ Конфигурация sudo через `/etc/sudoers.d/` (Principle of Least Privilege)
- ✅ ACL для гранулярного контроля доступа (`setfacl`, `getfacl`)
- ✅ Special bits: SUID, SGID, Sticky bit
- ✅ Resource limits через `/etc/security/limits.conf`
- ✅ PAM интеграция (pam_limits.so)
- ✅ Security audit (SUID/SGID файлы)

### Принципы безопасности:
- ✅ Principle of Least Privilege (минимальные привилегии)
- ✅ Defense in Depth (эшелонированная защита)
- ✅ Separation of Duties (разделение обязанностей)
- ✅ Audit Trail (логирование действий)

### Философия:
- ✅ Конфигурирование > Программирование
- ✅ Использовать готовые инструменты, не переписывать их
- ✅ Bash = инструмент автоматизации, НЕ замена системных инструментов

---

<div align="center">

**"Root — это не привилегия. Это ответственность."**

— Андрей Волков, профессор, ЛЭТИ

**Episode 09: Type B Complete! 🎉**

Next: [Episode 10: Processes & Systemd](../../episode-10-processes-systemd/)

</div>

