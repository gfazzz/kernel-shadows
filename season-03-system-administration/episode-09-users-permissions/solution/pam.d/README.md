# PAM (Pluggable Authentication Modules)
## Episode 09: Пользователи и права доступа

> *"PAM — это модульная система аутентификации. Один раз настроил — работает для всех сервисов."*
> — Андрей Волков, ЛЭТИ

---

## ⚠️ ВНИМАНИЕ!

Файлы в этой папке — **ПРИМЕРЫ для обучения**, НЕ production конфигурация!

**КРИТИЧНО:** Ошибка в PAM может **полностью заблокировать** вход в систему!

**НИКОГДА:**
- ❌ НЕ копируй файлы напрямую в `/etc/pam.d/` без понимания
- ❌ НЕ редактируй PAM через SSH без local access
- ❌ НЕ экспериментируй с PAM на production сервере

**ВСЕГДА:**
- ✅ Делай backup перед изменением
- ✅ Держи открытой root сессию для отката
- ✅ Тестируй в отдельной сессии
- ✅ Используй recovery mode если что-то сломалось

---

## 💡 Что такое PAM?

### Проблема БЕЗ PAM

Каждый сервис реализует аутентификацию сам:
- SSH → своя проверка пароля
- sudo → своя проверка пароля
- login → своя проверка пароля

Хочешь добавить 2FA?
- Нужно патчить SSH
- Нужно патчить sudo
- Нужно патчить login
- **Кошмар!**

### Решение: PAM

**Модульная система аутентификации:**
```
┌─────────┐
│   SSH   │ ───┐
└─────────┘    │
               │    ┌──────────────┐
┌─────────┐    ├────│     PAM      │
│  sudo   │ ───┤    │ (один раз    │
└─────────┘    │    │  настроил)   │
               │    └──────────────┘
┌─────────┐    │
│  login  │ ───┘
└─────────┘
```

**Преимущества:**
- ✅ Один раз настроил — работает везде
- ✅ Модульность: добавил модуль → все сервисы получили функцию
- ✅ Гибкость: разные политики для разных сервисов

### Метафора: PAM = Охрана в здании

Раньше (без PAM):
```
🏢 Здание
├─ 🚪 Вход 1 → Охранник Вася
├─ 🚪 Вход 2 → Охранник Петя
└─ 🚪 Вход 3 → Охранник Коля

Каждый охранник работает по-своему!
```

С PAM:
```
🏢 Здание
├─ 🚪 Вход 1 ───┐
├─ 🚪 Вход 2 ───┼───► 📋 Единая инструкция
└─ 🚪 Вход 3 ───┘     (PAM модули)

Все охранники работают одинаково!
```

---

## 📁 Типы PAM модулей

PAM работает в **4 этапа:**

### 1. **auth** — Аутентификация
**"Ты кто?"**

```
┌──────────────────┐
│  Вход пользователя│
└────────┬──────────┘
         │
    ┌────▼────┐
    │ auth    │  ← Проверка пароля
    │ modules │  ← 2FA (Google Authenticator)
    └────┬────┘  ← Биометрия
         │
     ✅ или ❌
```

**Модули:**
- `pam_unix.so` — проверка пароля из `/etc/shadow`
- `pam_google_authenticator.so` — 2FA
- `pam_fingerprint.so` — биометрия

### 2. **account** — Проверка аккаунта
**"Тебе разрешено войти?"**

```
    ┌──────────┐
    │ account  │  ← Аккаунт не заблокирован?
    │ modules  │  ← Пароль не истёк?
    └────┬─────┘  ← Время входа разрешено?
         │
     ✅ или ❌
```

**Модули:**
- `pam_unix.so` — проверка что аккаунт не locked
- `pam_time.so` — проверка времени доступа
- `pam_access.so` — проверка access.conf

### 3. **session** — Настройка сессии
**"Настроить окружение для работы"**

```
    ┌──────────┐
    │ session  │  ← Применить limits.conf
    │ modules  │  ← Создать /run/user/<UID>
    └────┬─────┘  ← Показать lastlog
         │
    ✅ Сессия готова
```

**Модули (КРИТИЧНО для Episode 09):**
- `pam_limits.so` — применить `/etc/security/limits.conf` ⭐
- `pam_systemd.so` — интеграция с systemd
- `pam_lastlog.so` — показать "Last login: ..."
- `pam_motd.so` — показать Message of the Day

### 4. **password** — Смена пароля
**"Изменить пароль"**

```
    ┌──────────┐
    │ password │  ← Проверка сложности пароля
    │ modules  │  ← История паролей
    └────┬─────┘  ← Запись нового пароля
         │
    ✅ Пароль изменён
```

**Модули:**
- `pam_unix.so` — изменение пароля в `/etc/shadow`
- `pam_pwquality.so` — проверка сложности пароля
- `pam_pwhistory.so` — запрет повторного использования

---

## 🔧 Связь с limits.conf (Episode 09)

### Проблема

Мы создали `/etc/security/limits.conf` с лимитами для пользователей.

**Но кто применяет limits.conf?**

**Ответ: PAM модуль `pam_limits.so`!**

### Без pam_limits.so:

```
User logs in
     │
     ├─ auth OK ✅
     ├─ account OK ✅
     ├─ session started
     │  └─ ❌ limits.conf ИГНОРИРУЕТСЯ!
     │
     └─ ulimit -a
        Output: default limits (1024 files, etc.)
```

### С pam_limits.so:

```
User logs in
     │
     ├─ auth OK ✅
     ├─ account OK ✅
     ├─ session started
     │  └─ pam_limits.so читает limits.conf
     │  └─ ✅ Применяет лимиты для пользователя
     │
     └─ ulimit -a
        Output: custom limits (16384 files для alex, etc.)
```

### Проверка

**Проверить что pam_limits.so включён:**
```bash
grep pam_limits.so /etc/pam.d/common-session

# Должна быть строка:
# session required pam_limits.so
```

**Если строки нет — добавить:**
```bash
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
```

**Проверка работает:**
```bash
# Войти заново (logout/login)
sudo -i -u alex

# Проверить лимиты
ulimit -a

# Должны быть кастомные лимиты из limits.conf
```

---

## 📂 Структура PAM

### Основные файлы PAM в Ubuntu

```
/etc/pam.d/
├── common-auth              ← auth модули (общие)
├── common-account           ← account модули (общие)
├── common-session           ← session модули (общие) ⭐
├── common-session-noninteractive
├── common-password          ← password модули (общие)
├── sshd                     ← PAM конфигурация для SSH
├── sudo                     ← PAM конфигурация для sudo
├── login                    ← PAM конфигурация для login
└── ...

/etc/security/
├── limits.conf              ← Лимиты ресурсов ⭐
├── time.conf                ← Время доступа
├── access.conf              ← Правила доступа
└── group.conf               ← Членство в группах по времени
```

### Как сервисы используют PAM

**SSH (/etc/pam.d/sshd):**
```
@include common-auth          ← Проверка пароля
@include common-account       ← Проверка аккаунта
@include common-session       ← Настройка сессии (limits!)
```

**sudo (/etc/pam.d/sudo):**
```
@include common-auth          ← Проверка пароля
@include common-account       ← Проверка аккаунта
session required pam_limits.so  ← Применить limits
```

---

## ✅ Проверка PAM конфигурации

### Проверить что pam_limits.so включён

```bash
# Для SSH
grep pam_limits.so /etc/pam.d/sshd

# Для common-session (используется многими сервисами)
grep pam_limits.so /etc/pam.d/common-session

# Для sudo
grep pam_limits.so /etc/pam.d/sudo
```

**Ожидается:**
```
session required pam_limits.so
```

или

```
session optional pam_limits.so
```

### Посмотреть полную PAM конфигурацию

```bash
# SSH
cat /etc/pam.d/sshd

# sudo
cat /etc/pam.d/sudo

# Общие session настройки
cat /etc/pam.d/common-session
```

### Тестирование

```bash
# Создать тестового пользователя
sudo useradd -m -s /bin/bash testuser

# Установить лимит в limits.conf
echo "testuser soft nofile 5000" | sudo tee -a /etc/security/limits.conf

# Войти как testuser
sudo -i -u testuser

# Проверить лимит
ulimit -n

# Ожидается: 5000 (если pam_limits.so работает)
# Если default (1024) — pam_limits.so не включён!
```

---

## 🐛 Troubleshooting

### Проблема: limits.conf не применяется

**Симптомы:**
```bash
sudo -i -u alex
ulimit -a
# Output: default limits (не те что в limits.conf)
```

**Причина 1:** pam_limits.so не включён

**Решение:**
```bash
grep pam_limits.so /etc/pam.d/common-session

# Если нет — добавить:
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
```

**Причина 2:** Не сделан logout/login

Лимиты применяются при **новом входе**, не в существующей сессии!

**Решение:**
```bash
exit
sudo -i -u alex
ulimit -a  # Теперь новые лимиты
```

---

### Проблема: Не могу войти после изменения PAM

**ПАНИКА MODE!** 😱

**Если есть открытая root сессия:**
```bash
# Откатить изменения
sudo cp /etc/pam.d/common-session.backup /etc/pam.d/common-session
```

**Если НЕТ root сессии:**

1. Перезагрузиться в **recovery mode**:
   - При загрузке нажать Shift (GRUB menu)
   - Выбрать "Advanced options"
   - Выбрать "Recovery mode"
   - Выбрать "Drop to root shell"

2. В root shell:
```bash
# Смонтировать / для записи
mount -o remount,rw /

# Откатить backup
cp /etc/pam.d/common-session.backup /etc/pam.d/common-session

# Перезагрузиться
reboot
```

**Поэтому:** ВСЕГДА делай backup и держи root сессию открытой!

---

## 🔒 Безопасность

### Правила безопасного изменения PAM

1. **ВСЕГДА держи открытой root сессию**
   - Terminal 1: root для отката
   - Terminal 2: тестирование

2. **ВСЕГДА делай backup**
   ```bash
   sudo cp /etc/pam.d/common-session /etc/pam.d/common-session.backup
   ```

3. **Тестируй перед применением**
   ```bash
   # После изменения PAM:
   sudo -i -u alex    # Проверить что вход работает
   ```

4. **НЕ редактируй PAM через SSH без local access**
   - Если сломаешь — не сможешь войти
   - Нужен physical access или IPMI/iLO

5. **Используй recovery mode для отката**
   - Если всё сломалось — recovery mode спасёт

---

## 📖 Дополнительные ресурсы

### Man pages
```bash
man pam              # Общая информация о PAM
man pam.conf         # Формат PAM конфигурации
man pam_limits       # pam_limits.so документация
man pam_systemd      # pam_systemd.so документация
man pam_lastlog      # pam_lastlog.so документация
```

### Online
- [Linux PAM Documentation](https://linux.die.net/man/5/pam.conf)
- [pam_limits man page](https://linux.die.net/man/8/pam_limits)
- [Arch Wiki: PAM](https://wiki.archlinux.org/title/PAM)

### Связанные episode
- Episode 09: Users & Permissions (limits.conf + PAM)
- Episode 10: Processes & Systemd (systemd integration)

---

## 📝 История изменений

- **2025-10-11:** Созданы примеры PAM конфигурации для Episode 09
  - Демонстрация работы pam_limits.so
  - Интеграция с limits.conf
  - Примеры для обучения (НЕ production!)
  - Ментор: Андрей Волков, ЛЭТИ
  - Локация: Санкт-Петербург, белые ночи

---

<div align="center">

**"PAM — это как охрана в здании. Один раз обучил — все входы защищены."**

— Андрей Волков, профессор, ЛЭТИ

**⚠️ ОСТОРОЖНО С PAM! Ошибка = потеря доступа к системе!**

</div>

