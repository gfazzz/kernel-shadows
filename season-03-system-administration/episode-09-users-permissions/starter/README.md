# Starter Files для Episode 09
## Type B: Конфигурирование системы

> *"Не переписывай системные инструменты. Используй их."*
> — Философия Type B episodes

---

## 📁 Структура starter

```
starter/
├── sudoers.d/              ← Конфиги sudo с TODO
│   ├── alex                ← Network команды
│   ├── anna                ← Read-only логи
│   └── dmitry              ← Service management
│
├── security/               ← Resource limits
│   └── limits.conf         ← С TODO секциями
│
├── setup_users.sh          ← Минимальный bash (только useradd)
└── README.md               ← Этот файл
```

---

## 🎯 Задание

**Цель:** Настроить безопасный доступ для команды операции.

**Что НЕ нужно делать:**
- ❌ Писать большой bash скрипт который делает всё
- ❌ Переписывать sudo/ACL/PAM в bash

**Что НУЖНО делать:**
- ✅ Конфигурировать систему через файлы (`/etc/sudoers.d/`, `/etc/security/limits.conf`)
- ✅ Использовать готовые инструменты (`visudo`, `setfacl`)
- ✅ Bash ТОЛЬКО для автоматизации создания пользователей

---

## 🚀 Workflow

### Шаг 1: Создание пользователей (bash)

```bash
cd starter/
./setup_users.sh
```

Заполни TODO в `setup_users.sh`:
- Создание пользователей (useradd)
- Создание групп (groupadd)
- Добавление в группы (usermod -aG)

**Теория:** README.md Цикл 2

---

### Шаг 2: Конфигурация sudo (конфиги, НЕ bash!)

**Для каждого пользователя (alex, anna, dmitry):**

```bash
# 1. Заполнить TODO в starter/sudoers.d/alex
nano starter/sudoers.d/alex

# 2. Скопировать в систему
sudo cp starter/sudoers.d/alex /etc/sudoers.d/alex

# 3. Права 440 (read-only)
sudo chmod 440 /etc/sudoers.d/alex

# 4. КРИТИЧНО! Проверить синтаксис
sudo visudo -c -f /etc/sudoers.d/alex

# 5. Протестировать
sudo -u alex sudo ip addr show    # Должно работать
sudo -u alex sudo useradd test    # Должна быть ошибка
```

**Повтори для anna и dmitry.**

**Теория:** README.md Цикл 4

---

### Шаг 3: Resource limits (конфиг)

```bash
# 1. Заполнить TODO в starter/security/limits.conf
nano starter/security/limits.conf

# 2. Backup оригинального файла
sudo cp /etc/security/limits.conf /etc/security/limits.conf.backup

# 3. Копировать конфиг
sudo cp starter/security/limits.conf /etc/security/limits.conf

# 4. Проверить PAM интеграцию
grep pam_limits.so /etc/pam.d/common-session

# 5. Если нет — добавить
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session

# 6. Протестировать (нужен logout/login!)
sudo -i -u alex
ulimit -n    # Ожидается: 16384
ulimit -u    # Ожидается: 1500
exit
```

**Теория:** README.md Цикл 6

---

### Шаг 4: ACL для Анны (вручную, НЕ bash!)

```bash
# 1. Проверить что ACL установлен
which setfacl || sudo apt-get install -y acl

# 2. Дать Anna execute на /var/log
sudo setfacl -m u:anna:rx /var/log

# 3. Read-only на конкретные логи
sudo setfacl -m u:anna:r /var/log/auth.log
sudo setfacl -m u:anna:r /var/log/syslog
sudo setfacl -m u:anna:r /var/log/kern.log

# 4. Default ACL для новых файлов
sudo setfacl -d -m u:anna:r /var/log

# 5. Проверка
getfacl /var/log/auth.log | grep "user:anna"

# 6. Тестирование
sudo -u anna cat /var/log/auth.log           # Успех
sudo -u anna bash -c 'echo "fake" >> /var/log/auth.log'  # Ошибка
```

**Теория:** README.md Цикл 5

---

### Шаг 5: Shared Directory (вручную)

```bash
# 1. Создать директорию
sudo mkdir -p /var/operations/shared

# 2. Владелец и группа
sudo chown viktor:operations /var/operations/shared

# 3. Permissions: 3770 (Sticky bit + SGID + rwxrwx---)
sudo chmod 3770 /var/operations/shared

# 4. Проверка
ls -ld /var/operations/shared
# Ожидается: drwxrws--T viktor operations

# 5. Тестирование
sudo -u viktor touch /var/operations/shared/viktor_file.txt
ls -l /var/operations/shared/viktor_file.txt
# Группа должна быть operations (SGID работает!)

sudo -u dmitry rm /var/operations/shared/viktor_file.txt
# Должна быть ошибка (Sticky bit защищает!)
```

**Теория:** README.md Цикл 3

---

### Шаг 6: Security Audit

```bash
# 1. Поиск SUID файлов
find / -perm -4000 -type f 2>/dev/null > /tmp/suid_files.txt

# 2. Поиск SGID файлов
find / -perm -2000 -type f 2>/dev/null > /tmp/sgid_files.txt

# 3. Создать baseline для мониторинга
sudo find / -perm -4000 -type f 2>/dev/null | sort > /root/suid_baseline.txt

# 4. Проверка подозрительных мест
find /tmp /home -perm -4000 -type f 2>/dev/null
# Если что-то нашёл — ALERT!
```

**Теория:** README.md Цикл 7

---

### Шаг 7: Финальный отчёт

```bash
# ONE-LINER comprehensive report
{
  echo "═════════════════════════════════════════"
  echo "    SECURITY AUDIT - EPISODE 09"
  echo "═════════════════════════════════════════"
  echo "Date: $(date)"
  echo
  echo "1. USERS CREATED:"
  for u in viktor alex anna dmitry; do id "$u"; done
  echo
  echo "2. SUDO CONFIGURATION:"
  sudo ls -la /etc/sudoers.d/
  echo
  echo "3. SHARED DIRECTORY:"
  ls -ld /var/operations/shared
  echo
  echo "4. SUID AUDIT:"
  echo "Files: $(find / -perm -4000 -type f 2>/dev/null | wc -l)"
} > security_audit_ep09.txt

cat security_audit_ep09.txt
```

**Теория:** README.md Цикл 8

---

## 📚 Референс и помощь

### Застрял?

1. **Смотри `solution/`** — полные референсные конфиги
2. **Читай `README.md`** — теория с метафорами и примерами
3. **Man pages:** `man sudoers`, `man setfacl`, `man limits.conf`

### Типичные ошибки

**Ошибка 1: "Sorry, user alex is not allowed..."**
- Проверь синтаксис: `sudo visudo -c -f /etc/sudoers.d/alex`
- Проверь права: `ls -l /etc/sudoers.d/alex` (должно быть 440)

**Ошибка 2: limits.conf не применяется**
- Проверь PAM: `grep pam_limits.so /etc/pam.d/common-session`
- Нужен logout/login! Лимиты применяются при новом входе

**Ошибка 3: ACL не работает**
- Проверь что ACL установлен: `which setfacl`
- Проверь ACL: `getfacl /var/log/auth.log`
- Должен быть `+` в `ls -l`: `-rw-r-----+ ... auth.log`

---

## 🎓 Философия Type B

**Что ты учишь:**
- ✅ Конфигурировать систему напрямую (`/etc/sudoers.d/`, `/etc/security/limits.conf`)
- ✅ Использовать готовые инструменты (`visudo`, `setfacl`, PAM)
- ✅ Понимать КАК работает система (не просто писать wrapper)

**Что НЕ учишь:**
- ❌ Писать bash wrapper вокруг sudo/ACL
- ❌ Переписывать системные инструменты

**Принцип:**
> "useradd exists — use it, don't rewrite it"
> "visudo exists — use it, don't wrap it in bash"
> "setfacl exists — use it, don't script around it"

---

## ⏱️ Время прохождения

- **Создание пользователей (bash):** 20-30 мин
- **Конфигурация sudo:** 30-40 мин
- **Resource limits + PAM:** 20-30 мин
- **ACL:** 20-30 мин
- **Shared directory:** 15-20 мин
- **Security audit:** 20-30 мин
- **Финальный отчёт:** 10-15 мин

**Итого:** ~2.5-3.5 часа (из 4-5 часов episode)

Остальное время — изучение теории в README.md!

---

<div align="center">

**"Root — это не привилегия. Это ответственность."**

— Андрей Волков, профессор, ЛЭТИ

**Удачи в конфигурировании! 🚀**

</div>

