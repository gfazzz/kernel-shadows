# EPISODE 09: ПОЛЬЗОВАТЕЛИ И ПРАВА ДОСТУПА
## Season 3: Системное администрирование | Санкт-Петербург, Россия

> *"Root access как заряженный пистолет. Не давай его кому попало."*
> — Андрей Волков, профессор ЛЭТИ

---

## 📍 Контекст миссии

**Локация:** 🇷🇺 Санкт-Петербург, Россия
**Место:** ЛЭТИ (Ленинградский электротехнический институт), Васильевский остров
**День операции:** 17-18 из 60
**Время прохождения:** 4-5 часов
**Сложность:** ⭐⭐⭐☆☆
**Тип:** **Type B — Конфигурирование** (90% конфиги, 10% bash для автоматизации)

**Персонажи:**
- **Макс Соколов** — вы, растёте как sysadmin
- **Андрей Волков** — ex-профессор Unix (ЛЭТИ), ментор
- **Виктор Петров** — координатор операции
- **Алекс Соколов** — ваш двоюродный брат, ex-FSB, security expert
- **Анна Ковалёва** — forensics expert, blue team lead
- **Дмитрий Орлов** — DevOps engineer
- **LILITH** — AI-помощник (я!)

---

## 🎬 Пролог: Белые ночи

### День 17. Санкт-Петербург. 03:27 Moscow time.

**Виктор** (видеозвонок, тревога в голосе):
*"Макс, у нас проблема. Серьёзная. Один из серверов скомпрометирован."*

**Анна** (screen share — forensics report):
*"Backdoor. `/usr/sbin/sshd_backup` — фейковый sshd процесс. Крылов проник через учётную запись с sudo правами. Проверь `/etc/passwd` — там учётка `devops` с UID 0. ROOT ACCESS."*

**Макс:** *"Как это возможно?!"*

**Алекс:** *"Permissions. Кто-то дал sudo кому не следует. Классическая ошибка. Едь в СПб — там есть человек, который научит тебя правильному администрированию."*

---

### 02:00. Васильевский остров. ЛЭТИ.

Белые ночи. На улице светло, хотя 2 часа ночи. Макс идёт по набережной Невы, мимо Ростральных колонн, к старому зданию ЛЭТИ. Встреча с **Андреем Волковым** в лаборатории Unix.

**Андрей** (седые волосы, очки, твидовый пиджак, чай в стеклянном стакане):
*"Максим. Виктор рассказал о проблеме. Permissions — это не просто команды. Это философия. Principle of least privilege — слышал?"*

**Макс:** *"Нет..."*

**Андрей:**
*"Давай по порядку. Root access как заряженный пистолет. Не давай его кому попало. Это я студентам 20 лет говорю. Но каждый год кто-то всё равно даёт. И каждый год взламывают."*

**Виктор** (звонок):
*"Макс, на сервере будут работать 5 человек: я, ты, Алекс, Анна, Дмитрий. Каждому нужен свой уровень доступа. Алекс — только network команды. Анна — только чтение логов. Дмитрий — управление сервисами. Настрой это правильно."*

**Андрей:**
*"Хорошее упражнение. Начнём с основ. Потом sudo. Потом ACL. К утру справишься. Благо утро наступит не скоро."* (улыбается — белые ночи)

---

## 🎯 Твоя миссия

Настроить **безопасный доступ** для команды операции на сервер.

**Цель:**
Создать пользователей, группы, настроить permissions, sudo и ACL так, чтобы:
- ✅ Каждый имеет **только те права, которые нужны для работы**
- ✅ Алекс может выполнять network команды через sudo (но НЕ всё)
- ✅ Анна может читать логи, но НЕ изменять
- ✅ Shared папка доступна всей команде
- ✅ Крылов больше не сможет эксплуатировать misconfigured permissions

**Итог:** Security audit report для Виктора.

---

## 📚 Структура episode (micro-cycles)

```
Цикл 1: Философия прав доступа           (10 мин)  🎓
Цикл 2: Пользователи и группы            (15 мин)  👥
Цикл 3: Permissions и special bits       (20 мин)  🔒
Цикл 4: Sudo конфигурация                (20 мин)  🛡️
Цикл 5: ACL (Access Control Lists)       (15 мин)  📋
Цикл 6: Resource limits + PAM            (20 мин)  ⚙️
Цикл 7: Security audit (SUID/SGID)       (20 мин)  🔍
Цикл 8: Финальный отчёт                  (10 мин)  📊
──────────────────────────────────────────────────────
Итого: ~130 минут (2 часа теории + 2 часа практики)
```

---

## 🔄 ЦИКЛ 1: Философия прав доступа (10 минут)

### 🎬 Сюжет

**Андрей** (показывает на доску с диаграммой Unix permissions):
*"Перед тем как начать, ответь: зачем вообще нужны права доступа?"*

**Макс:** *"Чтобы... защитить файлы?"*

**Андрей:**
*"Ближе. Чтобы **контролировать, кто что может делать**. Это фундамент безопасности Unix. Посмотри на проблему Крылова глазами администратора."*

*(Андрей открывает forensics report от Анны)*

```
FORENSICS REPORT:
─────────────────
Backdoor user: devops
UID: 0 (root!)
Created: 2025-10-09 14:23:17
Sudo access: ALL=(ALL:ALL) ALL (полный!)
Last login: 2025-10-10 03:15:42 from 185.192.45.118 (Крылов)
```

**Андрей:**
*"Видишь проблему? Кто-то создал пользователя с UID 0 — это как дать Крылову master key от здания. Плюс полный sudo — он мог делать ВСЁ. Вопрос: как это предотвратить?"*

**Макс:** *"Не давать UID 0?"*

**Андрей:**
*"Правильно. Но этого мало. Нужна система. Три принципа безопасного администрирования."*

---

### 📚 Теория: Три принципа безопасности

#### 💡 Метафора: Linux Permissions = Ночной клуб

Представь что Linux — это **ночной клуб** с несколькими зонами.

```
🏢 НОЧНОЙ КЛУБ "LINUX"
│
├─ 🚪 Вход (root зона)
│  Владелец клуба (root) — может ВСЁ
│
├─ 🎵 VIP зона (sudo группа)
│  VIP браслет (sudo) — доступ к спецзонам
│
├─ 🍻 Общий зал (обычные пользователи)
│  Базовый пропуск — ограниченный доступ
│
└─ 🚫 Служебные помещения (system files)
   Только персонал (root, service accounts)
```

**Роли:**
- **root** = владелец клуба (может всё: открыть любую дверь, выключить музыку, выгнать гостей)
- **alex** = охранник на входе (может проверять пропуска, но не управлять клубом)
- **anna** = детектив (может заходить и наблюдать, но не трогать)
- **обычный юзер** = гость (может танцевать в общем зале, но не лезть в VIP)

**Права доступа:**
- `rwx` = пропуск с разными уровнями (read, write, execute)
- `sudo` = temporary VIP браслет на одну ночь
- `SUID` = permanent VIP браслет (всегда VIP, даже если гость)

**Проблема Крылова:**
```
Крылов получил PERMANENT VIP браслет (UID 0)
+ Master key от всех дверей (sudo ALL)
= Полный контроль над клубом
```

---

#### 🛡️ Принцип 1: Principle of Least Privilege

**Определение:**
*Каждый пользователь должен иметь **минимальные** права, необходимые для работы. Не больше.*

**Пример из клуба:**
```
❌ ПЛОХО:
Охранник (alex) получает master key от всех дверей
→ Может зайти в VIP, в служебные помещения, в офис владельца
→ Если Крылов подкупит охранника — всё скомпрометировано

✅ ХОРОШО:
Охранник получает ключ ТОЛЬКО от входной двери + рация
→ Может проверять пропуска и вызвать подкрепление
→ Если Крылов подкупит — доступ только к входу, не к VIP зонам
```

**Применение к Алексу:**
```bash
# ❌ ПЛОХО (полный sudo):
alex ALL=(ALL:ALL) ALL

# ✅ ХОРОШО (только network команды):
alex ALL=(root) NOPASSWD: /usr/sbin/ip, /usr/bin/ss, /usr/sbin/tcpdump
```

---

#### 🎯 Принцип 2: Defense in Depth

**Определение:**
*Многослойная защита. Если один слой пробит — есть второй, третий, четвёртый.*

**Метафора: Замок с несколькими стенами**
```
🏰 СРЕДНЕВЕКОВЫЙ ЗАМОК

1-я стена: ров с водой (password)
2-я стена: высокая стена (permissions)
3-я стена: внутренние ворота (sudo rules)
4-я стена: башня (ACL)
5-я стена: сейф (encryption)

Атакующий должен пробить ВСЕ слои!
```

**Применение к Episode 09:**
```
Слой 1: Permissions (chmod, chown)
         └─ Алекс не владелец /etc/passwd → не может изменить

Слой 2: Sudo configuration
         └─ Алекс может ТОЛЬКО network команды

Слой 3: ACL (Access Control Lists)
         └─ Анна может ТОЛЬКО читать логи, не писать

Слой 4: Resource limits (limits.conf)
         └─ Защита от fork bomb (DoS изнутри)

Слой 5: Audit logs (/var/log/auth.log)
         └─ Все sudo команды логируются
```

**Aha! момент:**
```
Крылов пробил Слой 1 (получил backdoor аккаунт)
НО: если бы были Слои 2-5 → он бы застрял!
```

---

#### 🔀 Принцип 3: Separation of Duties

**Определение:**
*Критические операции требуют нескольких человек. Один человек не должен иметь полный контроль.*

**Метафора: Ядерная кнопка**
```
🚀 ЗАПУСК ЯДЕРНОЙ РАКЕТЫ

❌ ПЛОХО:
Президент нажимает кнопку → ракета летит
(Один человек может уничтожить мир)

✅ ХОРОШО:
1. Президент даёт команду
2. Министр обороны подтверждает
3. Генерал вводит код 1
4. Полковник вводит код 2
5. ДВА ключа поворачиваются ОДНОВРЕМЕННО
→ Только тогда ракета летит
```

**Применение к команде:**
```
Алекс (network админ):
  ✅ Может: настроить сеть, firewall
  ❌ Не может: создавать пользователей, менять sudo

Анна (forensics):
  ✅ Может: читать все логи
  ❌ Не может: удалять логи, изменять файлы

Дмитрий (DevOps):
  ✅ Может: управлять сервисами (restart nginx)
  ❌ Не может: менять network настройки

Виктор (координатор):
  ✅ Может: создавать пользователей, назначать роли
  ❌ Не может: прямой доступ к production серверам (только через sudo)
```

**Зачем:**
- Если Крылов скомпрометирует Алекса → доступ только к network
- Если Крылов скомпрометирует Анну → может только читать, не писать
- Если Крылов скомпрометирует Дмитрия → может restart сервисы, но не менять конфиги

**Aha! момент:**
```
Одна скомпрометированная учётка ≠ полный контроль над системой
```

---

### 💻 Практика: Анализ backdoor

**Задание:**
Проверь существующих пользователей на сервере. Найди подозрительные учётки.

```bash
# Все пользователи с shell доступом
grep -E '/bin/(bash|sh)$' /etc/passwd

# Пользователи с UID 0 (кроме root)
awk -F: '$3 == 0 && $1 != "root" {print $1}' /etc/passwd

# Проверка sudo прав
sudo cat /etc/sudoers
sudo ls -la /etc/sudoers.d/
```

**Что ты должен найти:**
- ❌ Пользователь с UID 0 (кроме root) — **BACKDOOR!**
- ❌ Пользователь с `ALL=(ALL:ALL) ALL` в sudoers — **ПОЛНЫЙ ДОСТУП!**
- ❌ Пустой пароль или weak password — **УЯЗВИМОСТЬ!**

---

### 🤔 Проверка понимания

**LILITH:** *"Объясни своими словами: почему нельзя давать всем sudo?"*

<details>
<summary>💭 Подумай перед проверкой (30 секунд)</summary>

**Ответ:**

sudo = temporary root access. Если все имеют sudo → все могут:
- Создавать backdoor пользователей
- Удалять critical файлы
- Изменять system конфигурации
- Читать чужие файлы
- Устанавливать rootkits

**Principle of Least Privilege:** давай только то, что нужно для работы.

**Пример:**
Алексу нужно настроить network → дай sudo ТОЛЬКО для network команд (ip, iptables)
НЕ давай sudo для ALL → он может создать backdoor или украсть sensitive data

**Метафора:**
Не давай мастер-ключ от здания всем сотрудникам. Дай каждому ключ от его кабинета.

</details>

---

**Андрей:**
*"Хорошо. Теперь ты понимаешь ЗАЧЕМ нужны правильные permissions. Давай разберём КАК это настроить."*

---

## 🔄 ЦИКЛ 2: Пользователи и группы (15 минут)

### 🎬 Сюжет

**Андрей** (открывает терминал):
*"Первый шаг — создать пользователей для команды. Виктор сказал 5 человек: Viktor, Alex, Anna, Dmitry и ты."*

**Макс:** *"useradd?"*

**Андрей:**
*"Правильно. Но не просто useradd. Нужна организация. Группы."*

*(Рисует на доске)*

```
         🏢 KERNEL SHADOWS OPERATION
                     │
        ┌────────────┼────────────┐
        │            │            │
   🔷 operations  🔷 security  🔷 devops
    (общая)     (защита)    (автоматизация)
        │            │            │
   ┌────┴───┐   ┌────┴───┐       │
Viktor  Dmitry Alex  Anna     Dmitry
```

**Андрей:**
*"Группы — это организация. Не давай permissions отдельным пользователям. Используй группы. Проще управлять, проще аудитировать."*

---

### 📚 Теория: Пользователи в Linux

#### Файлы хранения

Linux хранит информацию о пользователях в текстовых файлах:

**1. `/etc/passwd` — database пользователей**
```
username:x:UID:GID:comment:home:shell
```

Пример:
```
max:x:1000:1000:Max Sokolov:/home/max:/bin/bash
│   │  │    │    │            │          └─ Shell
│   │  │    │    │            └─ Home directory
│   │  │    │    └─ Comment (GECOS)
│   │  │    └─ Primary GID
│   │  └─ UID (User ID)
│   └─ Password (x = в /etc/shadow)
└─ Username
```

**Важные UID:**
- `0` = root (superuser)
- `1-999` = system users (daemon, www-data, etc.)
- `1000+` = regular users

**2. `/etc/shadow` — зашифрованные пароли**
```
username:encrypted_password:last_change:min:max:warn:inactive:expire
```

Права доступа: `600` (только root может читать!)

**Почему отдельный файл?**
```
/etc/passwd → readable by ALL (нужно для ls -l, ps, etc.)
/etc/shadow → readable ONLY by root (пароли защищены)
```

**3. `/etc/group` — группы**
```
groupname:x:GID:members
```

Пример:
```
operations:x:1001:viktor,dmitry
```

---

### 💡 Метафора: Группы = Отделы компании

```
🏢 КОМПАНИЯ "KERNEL SHADOWS"

┌─ 📋 Отдел "operations" (общие операции)
│   ├─ Viktor (координатор)
│   └─ Dmitry (DevOps)
│
├─ 🛡️ Отдел "security" (безопасность)
│   ├─ Alex (network админ)
│   └─ Anna (forensics)
│
├─ 🔍 Отдел "forensics" (расследования)
│   └─ Anna (только она)
│
├─ ⚙️ Отдел "devops" (автоматизация)
│   └─ Dmitry (только он)
│
└─ 🌐 Отдел "netadmin" (сеть)
    └─ Alex (только он)
```

**Зачем нужны группы?**

**❌ БЕЗ групп:**
```bash
# Дать Viktor доступ к shared directory
chmod 770 /var/operations/shared
chown viktor /var/operations/shared

# Дать Dmitry доступ к shared directory
??? (Viktor уже владелец, как добавить Dmitry?)

# Дать Max доступ
??? (нельзя иметь 3 владельцев!)
```

**✅ С ГРУППАМИ:**
```bash
# Создать группу
groupadd operations

# Добавить Viktor и Dmitry
usermod -aG operations viktor
usermod -aG operations dmitry

# Дать доступ ГРУППЕ
chown viktor:operations /var/operations/shared
chmod 770 /var/operations/shared

# Теперь Viktor и Dmitry оба имеют доступ!
# Добавить Max? usermod -aG operations max — готово!
```

---

### Команды управления пользователями

#### Создание пользователя

```bash
# Минимальный (БЕЗ home, БЕЗ shell)
sudo useradd username

# Полный (С home directory и bash shell)
sudo useradd -m -s /bin/bash username

# С комментарием
sudo useradd -m -s /bin/bash -c "Max Sokolov" max
```

**Флаги:**
- `-m` — создать home directory (`/home/username`)
- `-s /bin/bash` — установить shell (по умолчанию `/bin/sh`)
- `-c "comment"` — комментарий (полное имя)
- `-G group1,group2` — добавить в группы сразу

#### Установка пароля

```bash
# Интерактивно (запросит пароль)
sudo passwd username

# Принудительная смена при первом входе
sudo chage -d 0 username

# Установить срок действия пароля (90 дней)
sudo chage -M 90 username
```

#### Модификация пользователя

```bash
# Добавить в группу (-a = append, НЕ затирает существующие!)
sudo usermod -aG groupname username

# Изменить shell
sudo usermod -s /bin/bash username

# Заблокировать аккаунт
sudo usermod -L username

# Разблокировать
sudo usermod -U username
```

**⚠️ КРИТИЧНО: Всегда используй -a (append) с -G!**
```bash
# ❌ ПЛОХО (затрёт все существующие группы!)
sudo usermod -G newgroup username

# ✅ ХОРОШО (добавит к существующим группам)
sudo usermod -aG newgroup username
```

#### Удаление пользователя

```bash
# Удалить пользователя (оставить home)
sudo userdel username

# Удалить с home directory
sudo userdel -r username
```

#### Информация о пользователе

```bash
# UID, GID, группы
id username

# Только группы
groups username

# Детальная информация
finger username

# Кто онлайн
who

# Кто что делает
w

# История входов
last username
```

---

### Команды управления группами

```bash
# Создать группу
sudo groupadd groupname

# Удалить группу
sudo groupdel groupname

# Добавить пользователя в группу
sudo usermod -aG groupname username

# Удалить из группы
sudo gpasswd -d username groupname

# Информация о группе
getent group groupname

# Все группы пользователя
groups username
```

---

### 💻 Практика: Создание пользователей и групп

**Задание 1: Создай пользователей**

```bash
# Создать 4 пользователя для команды
sudo useradd -m -s /bin/bash -c "Viktor Petrov" viktor
sudo useradd -m -s /bin/bash -c "Alex Sokolov" alex
sudo useradd -m -s /bin/bash -c "Anna Kovaleva" anna
sudo useradd -m -s /bin/bash -c "Dmitry Orlov" dmitry

# Установить временные пароли
for user in viktor alex anna dmitry; do
    echo "$user:TempPass123!" | sudo chpasswd
    sudo chage -d 0 "$user"  # Принудительная смена при первом входе
done
```

**Задание 2: Создай группы**

```bash
# Создать 5 групп
sudo groupadd operations
sudo groupadd security
sudo groupadd forensics
sudo groupadd devops
sudo groupadd netadmin
```

**Задание 3: Добавь пользователей в группы**

```bash
# operations (общие операции)
sudo usermod -aG operations viktor
sudo usermod -aG operations dmitry

# security (безопасность)
sudo usermod -aG security alex
sudo usermod -aG security anna

# forensics (только Anna)
sudo usermod -aG forensics anna

# devops (только Dmitry)
sudo usermod -aG devops dmitry

# netadmin (только Alex)
sudo usermod -aG netadmin alex
```

**Задание 4: Проверь членство**

```bash
# Проверка для каждого пользователя
for user in viktor alex anna dmitry; do
    echo "$user: $(groups $user)"
done
```

**Ожидаемый вывод:**
```
viktor: viktor operations
alex: alex security netadmin
anna: anna security forensics
dmitry: dmitry operations devops
```

---

**Совет от LILITH:**
*"Можно автоматизировать через bash. Но помни: bash для АВТОМАТИЗАЦИИ, не для ЗАМЕНЫ useradd. Используй готовые инструменты!"*

**Минимальный скрипт** (смотри `solution/setup_users.sh`):
```bash
#!/bin/bash
users=("viktor" "alex" "anna" "dmitry")
for user in "${users[@]}"; do
    sudo useradd -m -s /bin/bash "$user"
    echo "$user:TempPass123!" | sudo chpasswd
    sudo chage -d 0 "$user"
done
```

---

### 🤔 Проверка понимания

**Андрей:** *"Почему нужен флаг -a в usermod -aG?"*

<details>
<summary>💭 Подумай перед проверкой</summary>

**Ответ:**

`-a` = append (добавить к существующим группам)

**БЕЗ -a:**
```bash
# У alex сейчас: alex security netadmin
sudo usermod -G operations alex
# Теперь у alex: alex operations
# security и netadmin УДАЛЕНЫ!
```

**С -a:**
```bash
# У alex сейчас: alex security netadmin
sudo usermod -aG operations alex
# Теперь у alex: alex security netadmin operations
# Добавилась operations, остальные сохранились
```

**Aha! момент:**
usermod -G затирает все группы и устанавливает только указанные.
usermod -aG добавляет к существующим.

**ВСЕГДА используй -a!**

</details>

---

**Андрей:**
*"Отлично. Пользователи созданы, группы организованы. Теперь самое важное — permissions."*

---

## 🔄 ЦИКЛ 3: Permissions и special bits (20 минут)

### 🎬 Сюжет

**Андрей** (создаёт тестовый файл):
```bash
touch test.txt
ls -l test.txt
```

```
-rw-r--r-- 1 andrei andrei 0 Oct 11 02:30 test.txt
```

**Андрей:**
*"Что ты видишь?"*

**Макс:** *"Буквы... rw-r--r--?"*

**Андрей:**
*"Это permissions. Права доступа. Кто может читать, писать, выполнять файл. Это язык Unix. Научись читать его."*

---

### 📚 Теория: Permissions (права доступа)

#### Структура permissions

```
-rwxr-xr-x
│││││││││└─ Others: execute
││││││││└── Others: write
│││││││└─── Others: read
││││││└──── Group: execute
│││││└───── Group: write
││││└────── Group: read
│││└─────── User (owner): execute
││└──────── User: write
│└───────── User: read
└────────── File type (- = file, d = directory, l = link)
```

#### Три группы доступа (UGO)

```
┌─ User (владелец файла)
│  ┌─ Group (группа файла)
│  │  ┌─ Others (все остальные)
│  │  │
rwxr-xr-x
```

**Метафора: Пропуск в ночной клуб**

```
User (владелец):   VIP пропуск — может всё (rwx)
Group (группа):    Групповой билет — ограниченный доступ (r-x)
Others (остальные): Обычный билет — базовый доступ (r--)
```

#### Типы прав

| Право | Символ | Значение для файла | Значение для директории |
|-------|--------|-------------------|------------------------|
| **read** | `r` (4) | Читать содержимое | Листать содержимое (`ls`) |
| **write** | `w` (2) | Изменять файл | Создавать/удалять файлы внутри |
| **execute** | `x` (1) | Выполнять как программу | Входить в директорию (`cd`) |

**Aha! момент: execute для директорий**
```bash
# Директория БЕЗ execute
mkdir test
chmod 644 test    # rw-r--r-- (нет x)
cd test           # ❌ Ошибка: Permission denied

# Директория С execute
chmod 755 test    # rwxr-xr-x (есть x)
cd test           # ✅ Работает
```

**Зачем нужен execute на директориях?**
Чтобы "войти" в директорию и работать с файлами внутри.

---

#### Восьмеричная запись

Permissions можно записать числами:
- `r` = 4
- `w` = 2
- `x` = 1

Сумма = права:

| Восьмеричное | Символьное | Описание |
|--------------|------------|----------|
| `0` | `---` | Нет прав |
| `1` | `--x` | Только execute |
| `2` | `-w-` | Только write (бесполезно без read) |
| `3` | `-wx` | write + execute |
| `4` | `r--` | Только read |
| `5` | `r-x` | read + execute (чаще всего для directories) |
| `6` | `rw-` | read + write (чаще всего для files) |
| `7` | `rwx` | Все права |

**Примеры:**

```bash
chmod 755 file
# 7 = rwx (user)
# 5 = r-x (group)
# 5 = r-x (others)
# Итого: rwxr-xr-x

chmod 644 file
# 6 = rw- (user)
# 4 = r-- (group)
# 4 = r-- (others)
# Итого: rw-r--r--

chmod 600 file
# 6 = rw- (user)
# 0 = --- (group)
# 0 = --- (others)
# Итого: rw------- (только владелец)
```

**Типичные permissions:**

| Тип файла | Permissions | Восьмеричное | Описание |
|-----------|-------------|--------------|----------|
| **Исполняемый скрипт** | `rwxr-xr-x` | `755` | Все могут выполнять |
| **Конфигурационный файл** | `rw-r--r--` | `644` | Владелец изменяет, остальные читают |
| **Секретный файл** | `rw-------` | `600` | Только владелец |
| **Shared directory** | `rwxrwxr-x` | `775` | Group может писать |
| **Системный конфиг** | `rw-r-----` | `640` | Group может читать |

---

### Команды изменения permissions

#### chmod — изменить права

**Числовой формат:**
```bash
chmod 755 file          # rwxr-xr-x
chmod 644 file          # rw-r--r--
chmod 600 file          # rw-------
```

**Символьный формат:**
```bash
# Добавить execute для владельца
chmod u+x file

# Убрать write для группы
chmod g-w file

# Установить read для всех
chmod a+r file
# (a = all = user + group + others)

# Убрать все права для others
chmod o= file
```

**Рекурсивно для директории:**
```bash
chmod -R 755 directory
```

#### chown — изменить владельца

```bash
# Изменить только владельца
sudo chown user file

# Изменить владельца и группу
sudo chown user:group file

# Рекурсивно
sudo chown -R user:group directory
```

#### chgrp — изменить группу

```bash
sudo chgrp group file
sudo chgrp -R group directory
```

---

### 💡 Special Bits (специальные биты)

Помимо rwx, есть 3 специальных бита:
- SUID (Set User ID) — bit 4000
- SGID (Set Group ID) — bit 2000
- Sticky Bit — bit 1000

#### SUID (Set User ID) — bit 4000

**Что делает:**
Файл выполняется с правами **владельца файла**, а не того кто запустил.

**Пример:**
```bash
ls -l /usr/bin/passwd
# -rwsr-xr-x root root ... /usr/bin/passwd
#    ^
#    s = SUID (вместо x)
```

**Зачем:**
`passwd` должен изменять `/etc/shadow` (owner = root, права 600).
Обычный пользователь не может писать в `/etc/shadow`.
НО: если `passwd` имеет SUID → выполняется от имени root → может изменить `/etc/shadow`.

```
User запускает:  passwd
Процесс работает как:  root (из-за SUID)
Может изменить:  /etc/shadow ✅
```

**⚠️ ОПАСНОСТЬ:**
Если SUID файл имеет уязвимость → privilege escalation к root!

**Установка SUID:**
```bash
chmod 4755 file     # или chmod u+s file
```

---

#### SGID (Set Group ID) — bit 2000

**Для файлов:**
Файл выполняется с правами **группы** владельца.

**Для директорий (чаще используется):**
Новые файлы в директории наследуют **группу директории**, а не primary group создателя.

**Пример:**
```bash
mkdir shared
chmod 2775 shared      # или chmod g+s shared
ls -ld shared
# drwxrwsr-x ... shared
#       ^
#       s = SGID

# Viktor создаёт файл
sudo -u viktor touch shared/viktor_file.txt
ls -l shared/viktor_file.txt
# -rw-r--r-- viktor SHARED_GROUP viktor_file.txt
#                   ^^^^^^^^^^^^
#                   Группа от директории, не от viktor!
```

**Зачем:**
Для shared directories. Все файлы автоматически получают правильную группу.

**БЕЗ SGID:**
```bash
# Viktor primary group = viktor
touch file.txt
ls -l file.txt
# -rw-r--r-- viktor viktor file.txt
#                   ^^^^^^
# Dmitry не может изменить (не в группе viktor)
```

**С SGID:**
```bash
# Directory group = operations
# Viktor primary group = viktor
# НО directory имеет SGID
touch file.txt
ls -l file.txt
# -rw-r--r-- viktor operations file.txt
#                   ^^^^^^^^^^
# Dmitry может изменить (он в группе operations)
```

---

#### Sticky Bit — bit 1000

**Для директорий:**
Файлы может удалить только:
- Владелец файла
- Владелец директории
- root

**Пример:**
```bash
ls -ld /tmp
# drwxrwxrwt ... /tmp
#         ^
#         t = sticky bit

# Viktor создаёт файл
sudo -u viktor touch /tmp/viktor_file.txt

# Dmitry пытается удалить
sudo -u dmitry rm /tmp/viktor_file.txt
# ❌ Ошибка: Operation not permitted

# Viktor может удалить
sudo -u viktor rm /tmp/viktor_file.txt
# ✅ Работает
```

**Зачем:**
Для shared directories типа `/tmp`. Все могут создавать файлы, но удалять только свои.

**БЕЗ Sticky Bit:**
```bash
# Directory: rwxrwxrwx (все могут писать)
# Dmitry может удалить файл Viktor → хаос!
```

**С Sticky Bit:**
```bash
# Directory: rwxrwxrwt (sticky bit включён)
# Dmitry НЕ может удалить файл Viktor → порядок!
```

**Установка Sticky Bit:**
```bash
chmod 1777 directory    # или chmod +t directory
```

---

### Комбинированные special bits

Можно комбинировать все 3:

```bash
chmod 3770 directory
# 3 = 1 (sticky) + 2 (SGID)
# 770 = rwxrwx---

ls -ld directory
# drwxrws--T ... directory
#       ^ ^
#       │ Sticky bit (T вместо t, потому что нет x для others)
#       SGID (s)
```

**Применение для shared directory операции:**
```bash
mkdir /var/operations/shared
chown viktor:operations /var/operations/shared
chmod 3770 /var/operations/shared

# Теперь:
# - Viktor и Dmitry (operations group) могут создавать файлы
# - Новые файлы наследуют группу operations (SGID)
# - Каждый может удалять только свои файлы (sticky bit)
```

---

### 💻 Практика: Создание shared directory

**Задание: Создай shared directory с правильными permissions**

```bash
# Шаг 1: Создать директорию
sudo mkdir -p /var/operations/shared

# Шаг 2: Установить владельца и группу
sudo chown viktor:operations /var/operations/shared

# Шаг 3: Установить permissions
# 3770 = Sticky bit (1) + SGID (2) + rwxrwx--- (770)
sudo chmod 3770 /var/operations/shared

# Шаг 4: Проверить
ls -ld /var/operations/shared
# Ожидается: drwxrws--T viktor operations
```

**Тестирование:**
```bash
# Тест 1: Viktor создаёт файл
sudo -u viktor touch /var/operations/shared/viktor_file.txt
ls -l /var/operations/shared/viktor_file.txt
# Ожидается: -rw-r--r-- viktor operations viktor_file.txt
#            (группа наследуется от директории благодаря SGID!)

# Тест 2: Dmitry создаёт файл
sudo -u dmitry touch /var/operations/shared/dmitry_file.txt
ls -l /var/operations/shared/dmitry_file.txt
# Ожидается: -rw-r--r-- dmitry operations dmitry_file.txt

# Тест 3: Dmitry пытается удалить файл Viktor
sudo -u dmitry rm /var/operations/shared/viktor_file.txt
# Ожидается: rm: cannot remove 'viktor_file.txt': Operation not permitted
#            (sticky bit защищает!)

# Тест 4: Viktor может удалить свой файл
sudo -u viktor rm /var/operations/shared/viktor_file.txt
# Ожидается: успех
```

---

### 🤔 Проверка понимания

**LILITH:** *"Объясни: зачем нужен Sticky bit на shared directory?"*

<details>
<summary>💭 Подумай перед проверкой</summary>

**Ответ:**

**Проблема БЕЗ Sticky bit:**
```bash
# Directory: drwxrwx--- (viktor:operations)
# Viktor создаёт файл
sudo -u viktor touch file.txt

# Dmitry (member of operations) может:
sudo -u dmitry rm file.txt    # ✅ Удаляет файл Viktor!

# Почему? Dmitry имеет write на directory → может удалять файлы в ней
```

**Решение: Sticky bit**
```bash
# Directory: drwxrws--T (viktor:operations, sticky bit)
# Viktor создаёт файл
sudo -u viktor touch file.txt

# Dmitry (member of operations) пытается:
sudo -u dmitry rm file.txt    # ❌ Operation not permitted

# Sticky bit: можно удалить только:
# - Свой файл
# - Если ты владелец directory
# - Если ты root
```

**Метафора:**
Sticky bit = "каждый может приклеить свой стикер на доску, но снять может только тот, кто приклеил"

**Без sticky bit:**
"Любой может снять любой стикер" → хаос!

</details>

---

**Андрей:**
*"Хорошо! Теперь самое важное — sudo configuration. Это то, где Крылов пробрался."*

---

## 🔄 ЦИКЛ 4: Sudo конфигурация (20 минут)

### 🎬 Сюжет

**Андрей** (открывает `/etc/sudoers`):
```bash
sudo cat /etc/sudoers
```

**Андрей:**
*"Это `/etc/sudoers` — один из самых важных файлов в Linux. Он определяет кто может делать что через sudo. Ошибка здесь = root access для атакующего."*

*(Показывает backdoor Крылова)*

```bash
# В /etc/sudoers.d/backdoor:
devops ALL=(ALL:ALL) ALL
```

**Андрей:**
*"Видишь? ALL=(ALL:ALL) ALL. Это полный root access. Любую команду. От любого пользователя. Без ограничений. Крылов получил master key."*

**Макс:** *"Как правильно?"*

**Андрей:**
*"Principle of Least Privilege. Для Алекса — ТОЛЬКО network команды. Для Анны — ТОЛЬКО чтение логов. Для Дмитрия — ТОЛЬКО управление сервисами. Покажу."*

---

### 📚 Теория: Sudo (Superuser Do)

#### Что такое sudo?

**sudo** = temporary root access.

**Метафора: VIP браслет на одну ночь**
```
🎪 НОЧНОЙ КЛУБ

Обычный вход: проверка пароля → вход в общий зал
Sudo вход: проверка пароля → ВРЕМЕННЫЙ VIP браслет → доступ к VIP зонам

После команды: VIP браслет снят → обратно в общий зал
```

**Зачем нужен sudo?**
```
❌ БЕЗ SUDO:
1. Войти как root: su -
2. Выполнить команду
3. Забыть выйти из root
4. Случайно удалить что-то критичное: rm -rf /

✅ С SUDO:
1. sudo command
2. Команда выполнена от root
3. Автоматически возврат к обычному пользователю
4. Меньше риск случайного удаления
```

**Преимущества:**
- ✅ Audit trail (логирование: кто что выполнил)
- ✅ Гранулярный контроль (кто какие команды может)
- ✅ Безопаснее чем постоянный root
- ✅ Password = ваш пароль (не root пароль)

---

### Файл /etc/sudoers

**⚠️ КРИТИЧНО: НЕ редактируй напрямую!**

```bash
# ❌ ПЛОХО:
sudo nano /etc/sudoers

# ✅ ХОРОШО:
sudo visudo
```

**Почему visudo?**
- Проверяет синтаксис перед сохранением
- Если ошибка → откатывает изменения
- БЕЗ visudo → ошибка = sudo сломан = потеря доступа!

---

### Формат sudoers

```
username HOST=(RUNAS) COMMANDS
│        │    │       └─ Какие команды можно выполнять
│        │    └─ От имени кого выполнять (обычно root)
│        └─ На каких хостах (обычно ALL)
└─ Кто может выполнять
```

**Примеры:**

```bash
# Полный sudo (опасно!)
alex ALL=(ALL:ALL) ALL

# Расшифровка:
# alex — пользователь alex
# ALL — на любом хосте
# (ALL:ALL) — может выполнять от имени любого пользователя:группы
# ALL — любые команды
```

```bash
# Ограниченный sudo (безопасно!)
alex ALL=(root) /usr/sbin/ip, /usr/bin/ss

# Расшифровка:
# alex — пользователь alex
# ALL — на любом хосте
# (root) — может выполнять от имени root
# /usr/sbin/ip, /usr/bin/ss — только эти две команды
```

```bash
# Sudo без пароля
alex ALL=(root) NOPASSWD: /usr/sbin/ip

# NOPASSWD — не запрашивать пароль
```

**Метафора: Доверенность у нотариуса**
```
📋 ДОВЕРЕННОСТЬ

Кто: Alex Sokolov
Может делать что: Настраивать сеть (ip, ss, iptables)
От имени кого: Root (системный администратор)
На какой срок: Всегда (пока файл существует)
Спрашивать паспорт: Да / Нет (NOPASSWD)

Подпись: ____________
         (visudo)
```

---

### Command aliases (алиасы команд)

Для удобства можно создавать алиасы:

```bash
# Определить алиас
Cmnd_Alias NETCMDS = /usr/sbin/ip, /usr/bin/ss, /usr/sbin/tcpdump

# Использовать алиас
alex ALL=(root) NOPASSWD: NETCMDS
```

**Преимущества:**
- ✅ Легко читать (NETCMDS vs длинный список)
- ✅ Легко изменять (добавить команду в одном месте)
- ✅ Переиспользовать (несколько пользователей = один алиас)

---

### Лучшие практики sudo

**1. Используй /etc/sudoers.d/ для отдельных пользователей**

```bash
# Вместо редактирования /etc/sudoers:
sudo visudo

# Создавай отдельные файлы:
sudo visudo -f /etc/sudoers.d/alex
sudo visudo -f /etc/sudoers.d/anna
```

**Преимущества:**
- ✅ Модульность (каждый пользователь = отдельный файл)
- ✅ Легко удалить (rm файл vs поиск в /etc/sudoers)
- ✅ Легко аудитировать (ls /etc/sudoers.d/)

**2. Указывай полные пути команд**

```bash
# ❌ ПЛОХО (небезопасно):
alex ALL=(root) ip

# Атакующий может создать:
# /tmp/ip (фейковая команда)
# export PATH=/tmp:$PATH
# sudo ip → выполнится /tmp/ip от root!

# ✅ ХОРОШО:
alex ALL=(root) /usr/sbin/ip

# Только настоящий /usr/sbin/ip может быть выполнен
```

**3. Используй NOPASSWD с осторожностью**

```bash
# NOPASSWD удобно для автоматизации
# НО: если аккаунт скомпрометирован → атакующий получает те же права БЕЗ пароля

# Используй NOPASSWD только для:
# - Ограниченного набора команд
# - Неопасных команд (например, просмотр статуса)

# Не используй для:
# - Полного sudo (ALL)
# - Деструктивных команд (rm, dd)
```

**4. Явно запрещай опасные команды**

```bash
# Defense in depth: явный запрет
alex ALL=(root) !/usr/sbin/visudo, \
                !/usr/bin/passwd root, \
                !/bin/rm -rf /
```

**5. Логируй sudo действия**

```bash
# Логи sudo в /var/log/auth.log (по умолчанию)
# Проверка:
sudo grep "sudo.*COMMAND" /var/log/auth.log

# Или через journalctl:
sudo journalctl _COMM=sudo --since today
```

---

### 💻 Практика: Конфигурация sudo для команды

**Задание: Настрой sudo для Алекса, Анны, Дмитрия**

**Шаг 1: Создать sudoers файл для Алекса**

```bash
sudo visudo -f /etc/sudoers.d/alex
```

Добавить:
```
# Alex Sokolov — Network Administration
# Principle of Least Privilege: ONLY network commands

Cmnd_Alias NETCMDS = /usr/sbin/ip, \
                      /usr/bin/ss, \
                      /usr/bin/netstat, \
                      /usr/sbin/tcpdump, \
                      /usr/sbin/iptables, \
                      /usr/sbin/ufw, \
                      /usr/bin/nmap

alex ALL=(root) NOPASSWD: NETCMDS

# Explicitly deny dangerous commands
alex ALL=(root) !/usr/sbin/visudo, \
                !/usr/bin/passwd root
```

Сохранить (Ctrl+O, Enter, Ctrl+X).

**Шаг 2: Установить правильные права**

```bash
sudo chmod 440 /etc/sudoers.d/alex
```

**Шаг 3: Проверить синтаксис**

```bash
sudo visudo -c -f /etc/sudoers.d/alex
```

Ожидается: `parsed OK`

**Шаг 4: Протестировать**

```bash
# Тест 1: Alex может выполнять network команды
sudo -u alex sudo ip addr show
# Ожидается: успех (показывает IP адреса)

# Тест 2: Alex НЕ может создать пользователя
sudo -u alex sudo useradd test
# Ожидается: "Sorry, user alex is not allowed to execute..."

# Тест 3: NOPASSWD работает
sudo -u alex sudo -n ss -tulpn
# Флаг -n = non-interactive (не запрашивать пароль)
# Ожидается: успех (показывает открытые порты)
```

---

**Задание: Повтори для Анны и Дмитрия**

**Для Анны (read-only логи):**

```bash
sudo visudo -f /etc/sudoers.d/anna
```

```
# Anna Kovaleva — Forensics Expert
# Read-only log access

Cmnd_Alias LOGCMDS = /usr/bin/less /var/log/*, \
                      /usr/bin/tail /var/log/*, \
                      /usr/bin/cat /var/log/*, \
                      /usr/bin/grep * /var/log/*

Cmnd_Alias JOURNALCMDS = /usr/bin/journalctl

anna ALL=(root) NOPASSWD: LOGCMDS, JOURNALCMDS

# Deny log modification
anna ALL=(root) !/bin/rm /var/log/*, \
                !/usr/bin/tee /var/log/*
```

**Для Дмитрия (service management):**

```bash
sudo visudo -f /etc/sudoers.d/dmitry
```

```
# Dmitry Orlov — DevOps Engineer
# Service management

Cmnd_Alias SERVICECMDS = /usr/bin/systemctl start *, \
                          /usr/bin/systemctl stop *, \
                          /usr/bin/systemctl restart *, \
                          /usr/bin/systemctl status *

Cmnd_Alias DOCKERCMDS = /usr/bin/docker, \
                         /usr/bin/docker-compose

dmitry ALL=(root) NOPASSWD: SERVICECMDS, JOURNALCMDS, DOCKERCMDS
```

---

**Совет от LILITH:**
*"Готовые конфиги в `solution/sudoers.d/`. Не переписывай руками — копируй и адаптируй."*

---

### 🤔 Проверка понимания

**Андрей:** *"Почему NOPASSWD опасно для полного sudo, но OK для ограниченных команд?"*

<details>
<summary>💭 Подумай перед проверкой</summary>

**Ответ:**

**С NOPASSWD + полный sudo:**
```bash
user ALL=(ALL) NOPASSWD: ALL

# Если аккаунт скомпрометирован (например, украден SSH ключ):
$ sudo rm -rf /    # Атакующий может ЭТО БЕЗ пароля!
$ sudo useradd backdoor
$ sudo passwd backdoor
# Полный контроль БЕЗ знания пароля
```

**С NOPASSWD + ограниченные команды:**
```bash
alex ALL=(root) NOPASSWD: /usr/sbin/ip

# Если аккаунт скомпрометирован:
$ sudo ip addr show   # Атакующий может ТОЛЬКО это
$ sudo useradd test   # ❌ Не разрешено
$ sudo rm -rf /       # ❌ Не разрешено

# Ущерб ограничен network командами
```

**Метафора:**
- NOPASSWD + полный sudo = дать мастер-ключ от здания **без охраны**
- NOPASSWD + ограниченные команды = дать ключ от одной комнаты **без охраны**

**Вывод:**
NOPASSWD удобно для автоматизации, но используй ТОЛЬКО с ограниченными командами!

</details>

---

**Андрей:**
*"Отлично. Sudo настроен правильно. Теперь более продвинутая тема — ACL."*

---

## 🔄 ЦИКЛ 5: ACL (Access Control Lists) — 15 минут

### 🎬 Сюжет

**Андрей:**
*"Permissions (rwx) хороши, но ограничены. Один владелец, одна группа, все остальные. Что если Анне нужен доступ к логам, но она не в группе adm?"*

**Макс:** *"Добавить в группу adm?"*

**Андрей:**
*"Можно. Но тогда она получит доступ ко ВСЕМ файлам группы adm. А нам нужно ТОЛЬКО `/var/log/auth.log`. Для этого есть ACL."*

---

### 📚 Теория: ACL (Access Control Lists)

#### Что такое ACL?

**ACL** = более гибкие права доступа, чем стандартные UGO (User, Group, Others).

**Проблема с UGO:**
```
File: /var/log/auth.log
Owner: root
Group: adm
Permissions: rw-r-----

Могут читать:
- root (owner)
- Все в группе adm

Анна НЕ в группе adm → не может читать
```

**Решение: ACL**
```bash
sudo setfacl -m u:anna:r /var/log/auth.log

# Теперь могут читать:
# - root (owner)
# - Все в группе adm
# - anna (через ACL) ← Добавилась!
```

**Метафора: VIP-браслеты на фестивале**
```
🎪 МУЗЫКАЛЬНЫЙ ФЕСТИВАЛЬ

Traditional permissions (UGO):
- 1 владелец (организатор) — может всё
- 1 группа (персонал) — limited access
- Все остальные — только basic

Проблема: Хочу дать Anna VIP доступ, но не делать её персоналом

Решение: ACL = индивидуальный VIP-браслет для Anna
- Организатор (owner) — может всё
- Персонал (group) — limited access
- Anna (ACL) — VIP браслет (custom права)
- Все остальные — только basic
```

---

### Команды ACL

**setfacl — установить ACL**

```bash
# Дать пользователю anna право read
sudo setfacl -m u:anna:r /var/log/auth.log

# Дать группе forensics право read+execute
sudo setfacl -m g:forensics:rx /var/log

# Рекурсивно для директории
sudo setfacl -R -m u:anna:r /var/log

# Default ACL (для новых файлов в директории)
sudo setfacl -d -m u:anna:r /var/log
```

**getfacl — посмотреть ACL**

```bash
getfacl /var/log/auth.log
```

Вывод:
```
# file: /var/log/auth.log
# owner: root
# group: adm
user::rw-               # Owner (root)
user:anna:r--           # ACL для anna ← Новое!
group::r--              # Group (adm)
mask::r--
other::---
```

**Удалить ACL**

```bash
# Удалить ACL для конкретного пользователя
sudo setfacl -x u:anna /var/log/auth.log

# Удалить все ACL
sudo setfacl -b /var/log/auth.log
```

---

### ACL mask

**Mask** = максимальные эффективные права для ACL и group.

```
Effective permissions = Min(ACL rights, mask)
```

Пример:
```bash
# Установить ACL
sudo setfacl -m u:anna:rwx /var/log/auth.log

# Посмотреть
getfacl /var/log/auth.log

# Вывод:
user:anna:rwx           # ACL права
mask::r--               # Mask ограничивает!

# Эффективные права anna = min(rwx, r--) = r--
# anna может ТОЛЬКО читать, несмотря на rwx в ACL!
```

**Изменить mask:**
```bash
sudo setfacl -m m::rw /var/log/auth.log
```

---

### 💻 Практика: ACL для Анны

**Задание: Дать Анне read-only доступ к логам**

**Шаг 1: Проверить что ACL установлен**

```bash
# Проверить наличие setfacl
which setfacl

# Если нет — установить
sudo apt-get install -y acl
```

**Шаг 2: Дать Anna доступ к /var/log**

```bash
# Анне нужен execute на /var/log чтобы войти в директорию
sudo setfacl -m u:anna:rx /var/log
```

**Шаг 3: Дать read-only на конкретные логи**

```bash
sudo setfacl -m u:anna:r /var/log/auth.log
sudo setfacl -m u:anna:r /var/log/syslog
sudo setfacl -m u:anna:r /var/log/kern.log
```

**Шаг 4: Default ACL для новых файлов**

```bash
# Новые логи автоматически получат ACL для anna
sudo setfacl -d -m u:anna:r /var/log
```

**Шаг 5: Проверка**

```bash
# Посмотреть ACL
getfacl /var/log/auth.log

# Ожидается:
# user:anna:r--

# Проверить что в ls -l есть +
ls -l /var/log/auth.log
# -rw-r-----+ ... /var/log/auth.log
#           ^
#           + означает что ACL установлен
```

**Шаг 6: Тестирование**

```bash
# Тест 1: Anna может читать
sudo -u anna cat /var/log/auth.log
# Ожидается: успех (лог выводится)

# Тест 2: Anna НЕ может изменять
sudo -u anna bash -c 'echo "fake" >> /var/log/auth.log'
# Ожидается: "Permission denied"

# Тест 3: Anna НЕ может удалять
sudo -u anna rm /var/log/auth.log
# Ожидается: "Permission denied"
```

---

### 🤔 Проверка понимания

**LILITH:** *"Зачем использовать ACL вместо добавления в группу adm?"*

<details>
<summary>💭 Подумай перед проверкой</summary>

**Ответ:**

**С добавлением в группу adm:**
```bash
sudo usermod -aG adm anna

# Anna получает доступ ко ВСЕМ файлам группы adm:
ls -l /var/log/ | grep "adm"
# -rw-r----- root adm auth.log    ✅ Может читать
# -rw-r----- root adm syslog       ✅ Может читать
# -rw-r----- root adm alternatives.log ✅ Может читать
# ... и ещё 50+ файлов

# Принцип минимальных привилегий нарушен!
```

**С ACL:**
```bash
sudo setfacl -m u:anna:r /var/log/auth.log

# Anna получает доступ ТОЛЬКО к auth.log:
ls -l /var/log/auth.log
# -rw-r-----+ root adm auth.log   ✅ Может читать (через ACL)

ls -l /var/log/syslog
# -rw-r----- root adm syslog       ❌ НЕ может читать

# Principle of Least Privilege соблюдён!
```

**Метафора:**
- Добавление в группу = дать ключи от всех комнат отдела
- ACL = дать ключ от конкретной комнаты

**Вывод:**
Используй ACL для гранулярного контроля доступа!

</details>

---

**Андрей:**
*"Хорошо. Sudo и ACL настроены. Теперь защита от внутренних атак — resource limits."*

---

## 🔄 ЦИКЛ 6: Resource limits + PAM (20 минут)

### 🎬 Сюжет

**Андрей** (запускает странный скрипт):
```bash
:(){ :|:& };:
```

**Макс:** *"Что это?"*

**Андрей:**
*"Fork bomb. Создаёт процессы рекурсивно. Без лимитов — система зависнет за секунды."*

*(Система начинает тормозить... потом восстанавливается)*

**Андрей:**
*"Видишь? Система ещё работает. Потому что у меня настроен nproc limit — максимум 1000 процессов на пользователя. Fork bomb остановилась."*

**Макс:** *"Как это настраивается?"*

**Андрей:**
*"`/etc/security/limits.conf` + PAM. Покажу."*

---

### 📚 Теория: Resource limits

#### Зачем нужны limits?

**Проблема:** Один пользователь может "съесть" все ресурсы системы:
- Fork bomb → миллионы процессов → система зависла
- Открыть все file descriptors → другие процессы не могут работать
- Заполнить диск огромным файлом

**Решение:** Limits — ограничения на ресурсы для каждого пользователя.

**Метафора: Билеты на концерт**
```
🎵 КОНЦЕРТ В КЛУБЕ

Без limits:
- Каждый может привести сколько угодно друзей
- Первый гость приводит 1000 человек
- Клуб переполнен, никто не может войти
- Хаос!

С limits:
- Каждый может привести максимум 10 друзей (nproc limit)
- Первый гость приводит 10
- Остальные тоже могут войти
- Порядок!
```

---

### Файл /etc/security/limits.conf

**Формат:**
```
<domain> <type> <item> <value>
```

**domain:**
- `username` — конкретный пользователь
- `@groupname` — группа (символ @ обязателен!)
- `*` — все пользователи

**type:**
- `soft` — мягкий лимит (пользователь может увеличить до hard)
- `hard` — жёсткий лимит (нельзя превысить)
- `-` — установить оба (soft и hard)

**item:**
- `nproc` — максимум процессов
- `nofile` — максимум открытых файлов (file descriptors)
- `core` — размер core dump (0 = отключить)
- `fsize` — максимальный размер файла
- `cpu` — максимальное CPU время (минуты)
- `maxlogins` — максимум одновременных входов

**value:**
- число — лимит
- `unlimited` — без ограничений

---

### Примеры limits

```
# Все пользователи: максимум 2048 процессов
*    soft    nproc     2048
*    hard    nproc     4096

# Все пользователи: максимум 4096 открытых файлов
*    soft    nofile    4096
*    hard    nofile    65536

# Отключить core dumps (security!)
*    soft    core      0

# Alex: повышенные лимиты (network админ)
alex soft    nofile    16384
alex hard    nofile    65536
alex soft    nproc     1500

# Anna: пониженные лимиты (forensics не нужно много)
anna soft    nproc     500
anna hard    nproc     1000

# Dmitry: высокие лимиты (Docker нужно много процессов)
dmitry soft  nproc     2000
dmitry hard  nproc     4000
dmitry soft  nofile    16384
```

---

### PAM (Pluggable Authentication Modules)

**Что такое PAM?**
Модульная система аутентификации Linux.

**Проблема без PAM:**
- SSH реализует аутентификацию сам
- sudo реализует аутентификацию сам
- login реализует аутентификацию сам
- Хочешь добавить 2FA? Патчи для КАЖДОГО сервиса!

**С PAM:**
- Один раз настроил PAM → работает для всех сервисов
- Модульность: добавил модуль → все сервисы получили функцию

**Метафора: Охрана в здании**
```
🏢 ЗДАНИЕ С НЕСКОЛЬКИМИ ВХОДАМИ

Без PAM:
├─ Вход 1 → Охранник Вася (свои правила)
├─ Вход 2 → Охранник Петя (свои правила)
└─ Вход 3 → Охранник Коля (свои правила)

С PAM:
├─ Вход 1 ───┐
├─ Вход 2 ───┼───► 📋 Единая инструкция (PAM)
└─ Вход 3 ───┘
```

---

### PAM и limits.conf

**Кто применяет limits.conf?**
PAM модуль `pam_limits.so`!

**Проверка:**
```bash
grep pam_limits.so /etc/pam.d/common-session
```

Должна быть строка:
```
session required pam_limits.so
```

**Если нет:**
```bash
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
```

**⚠️ БЕЗ pam_limits.so:**
- limits.conf ИГНОРИРУЕТСЯ!
- Fork bomb защита НЕ работает!

---

### 💻 Практика: Установка limits

**Шаг 1: Backup оригинального файла**

```bash
sudo cp /etc/security/limits.conf /etc/security/limits.conf.backup
```

**Шаг 2: Копирование конфига**

```bash
# Готовый конфиг в solution/security/limits.conf
sudo cp solution/security/limits.conf /etc/security/limits.conf

# Права 644
sudo chmod 644 /etc/security/limits.conf
```

**Шаг 3: Проверка PAM**

```bash
grep pam_limits.so /etc/pam.d/common-session

# Если нет — добавить:
echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
```

**Шаг 4: Применение (нужен logout/login!)**

Лимиты применяются при НОВОМ входе пользователя!

```bash
# Тест: войти как alex
sudo -i -u alex

# Проверить лимиты
ulimit -n    # nofile: ожидается 16384
ulimit -u    # nproc: ожидается 1500

exit
```

**Шаг 5: Тест защиты от fork bomb**

**⚠️ ТОЛЬКО В ТЕСТОВОЙ СРЕДЕ! НЕ НА PRODUCTION!**

```bash
# Установить низкий лимит для теста
ulimit -u 50

# Запустить fork bomb
:(){ :|:& };:

# Ожидается:
# bash: fork: retry: Resource temporarily unavailable
# Система остаётся работоспособной!

# Без лимита: система зависнет полностью
```

---

### 🤔 Проверка понимания

**LILITH:** *"Объясни: почему core dumps отключены по умолчанию?"*

<details>
<summary>💭 Подумай перед проверкой</summary>

**Ответ:**

**Что такое core dump?**
Файл содержащий память процесса в момент краха.

**Зачем нужен?**
Для отладки (debugging) — можно посмотреть что было в памяти когда программа упала.

**В чём проблема?**
Память может содержать sensitive data:

```c
// Программа с паролем в памяти
char password[] = "SuperSecret123";
// Программа падает → создаётся core dump

// Атакующий может извлечь пароль:
$ strings core | grep -i secret
SuperSecret123    ← Пароль в открытом виде!
```

**Также в core dump может быть:**
- SSH ключи
- Токены доступа
- Database passwords
- Encryption keys
- Personal data (PII)

**Решение:**
Отключить core dumps по умолчанию (`ulimit -c 0`).

Если нужны для debug → включить временно.

**Aha! момент:**
Core dumps полезны для debugging, но опасны для security!

</details>

---

**Андрей:**
*"Отлично. Последний шаг — security audit. Найти потенциальные backdoors."*

---

## 🔄 ЦИКЛ 7: Security Audit — SUID/SGID (20 минут)

### 🎬 Сюжет

**Андрей:**
*"Крылов любит оставлять backdoors. Один из любимых трюков — SUID файл. Покажу."*

*(Создаёт простой скрипт)*

```bash
# /tmp/backdoor.sh
#!/bin/bash
/bin/bash
```

```bash
sudo chown root /tmp/backdoor.sh
sudo chmod 4755 /tmp/backdoor.sh    # SUID bit

# Запуск:
/tmp/backdoor.sh
whoami
# Output: root    ← shell от root!
```

**Макс:** *"Но... я запустил как обычный пользователь!"*

**Андрей:**
*"SUID. Файл выполняется от имени владельца (root). Если Крылов оставил такой файл — backdoor готов. Нужно проверить все SUID файлы в системе."*

---

### 📚 Теория: SUID/SGID Security Risks

#### Напоминание: SUID

**SUID** (Set User ID) — файл выполняется от имени **владельца**, не того кто запустил.

**Легитимное использование:**
```bash
/usr/bin/passwd    # Нужен root для изменения /etc/shadow
/usr/bin/sudo      # Нужен root для выполнения команд от root
/usr/bin/ping      # Нужен root для raw sockets
```

**Опасное использование:**
```bash
/tmp/backdoor.sh   # Владелец = root, SUID → instant root shell
/home/user/shell   # Скомпилированный backdoor
```

---

#### Почему SUID опасен?

**Если SUID файл имеет уязвимость:**
- Buffer overflow → execute arbitrary code as root
- Command injection → execute commands as root
- Race condition → modify file before execution

**Пример:**
```c
// suid_program.c (владелец = root, SUID)
#include <stdlib.h>
int main() {
    system("ls");    // ❌ УЯЗВИМОСТЬ: не полный путь!
}
```

```bash
# Компиляция
gcc suid_program.c -o suid_program
sudo chown root suid_program
sudo chmod 4755 suid_program

# Эксплойт:
cat > /tmp/ls << 'EOF'
#!/bin/bash
/bin/bash    # Backdoor shell
EOF
chmod +x /tmp/ls
export PATH=/tmp:$PATH

# Запуск SUID программы:
./suid_program
# Вызывается /tmp/ls (не /bin/ls) → root shell!
```

---

### Поиск SUID/SGID файлов

**Найти все SUID файлы:**
```bash
find / -perm -4000 -type f 2>/dev/null
```

**Найти все SGID файлы:**
```bash
find / -perm -2000 -type f 2>/dev/null
```

**Найти SUID или SGID:**
```bash
find / \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null
```

---

### Baseline approach

**Идея:** Создать список SUID файлов "как должно быть", потом мониторить изменения.

**Шаг 1: Создать baseline**
```bash
find / -perm -4000 -type f 2>/dev/null | sort > /root/suid_baseline.txt
```

**Шаг 2: Проверять регулярно**
```bash
find / -perm -4000 -type f 2>/dev/null | sort | diff /root/suid_baseline.txt -
```

**Если появились новые SUID файлы:**
```
> /tmp/backdoor.sh    ← Новый SUID файл!
```

**→ РАССЛЕДОВАТЬ!**

---

### Известные безопасные SUID файлы (Ubuntu)

```
/usr/bin/sudo
/usr/bin/passwd
/usr/bin/su
/usr/bin/chsh
/usr/bin/chfn
/usr/bin/gpasswd
/usr/bin/newgrp
/usr/bin/mount
/usr/bin/umount
/usr/bin/ping
/usr/bin/pkexec
```

**Подозрительные места:**
- `/tmp` — временные файлы, НЕ должно быть SUID!
- `/home` — пользовательские файлы, НЕ должно быть SUID!
- Любые скрипты (`.sh`, `.py`) с SUID — ОЧЕНЬ подозрительно!

---

### 💻 Практика: SUID/SGID Audit

**Задание: Найди все SUID файлы и проверь на suspicious**

**Шаг 1: Поиск SUID файлов**

```bash
# Найти все SUID файлы
find / -perm -4000 -type f 2>/dev/null

# Сохранить в файл
find / -perm -4000 -type f 2>/dev/null | sort > /tmp/suid_files.txt
```

**Шаг 2: Проверить известные безопасные**

```bash
# Список известных безопасных SUID файлов
cat > /tmp/safe_suid.txt << 'EOF'
/usr/bin/sudo
/usr/bin/passwd
/usr/bin/su
/usr/bin/mount
/usr/bin/umount
/usr/bin/ping
EOF

# Найти файлы которых НЕТ в safe list
comm -23 /tmp/suid_files.txt /tmp/safe_suid.txt
```

**Шаг 3: Проверить подозрительные места**

```bash
# SUID файлы в /tmp
find /tmp -perm -4000 -type f 2>/dev/null

# SUID файлы в /home
find /home -perm -4000 -type f 2>/dev/null

# Если нашёл — ALERT!
```

**Шаг 4: Создать baseline**

```bash
# Сохранить текущий список для будущих проверок
sudo find / -perm -4000 -type f 2>/dev/null | sort > /root/suid_baseline.txt
```

**Шаг 5: Мониторинг (добавить в cron)**

```bash
# Создать скрипт проверки
cat > /usr/local/bin/check_suid.sh << 'EOF'
#!/bin/bash
NEW=$(find / -perm -4000 -type f 2>/dev/null | sort)
DIFF=$(diff /root/suid_baseline.txt <(echo "$NEW"))

if [ -n "$DIFF" ]; then
    echo "⚠️ ALERT: SUID files changed!"
    echo "$DIFF"
    # Отправить alert (email, Slack, etc.)
fi
EOF

chmod +x /usr/local/bin/check_suid.sh

# Добавить в cron (запуск каждый день)
echo "0 2 * * * /usr/local/bin/check_suid.sh" | sudo crontab -
```

---

### 🤔 Проверка понимания

**Андрей:** *"Почему shell scripts с SUID не работают в Linux?"*

<details>
<summary>💭 Подумай перед проверкой</summary>

**Ответ:**

**Linux игнорирует SUID на shell scripts!**

**Почему?**
Security feature. Shell scripts легко эксплойтить:

```bash
# suid_script.sh (владелец = root, SUID)
#!/bin/bash
echo "Hello"
```

**Эксплойт (если бы SUID работал):**
```bash
# Атакующий подменяет $PATH
export PATH=/tmp:$PATH

# Создаёт фейковый echo
cat > /tmp/echo << 'EOF'
#!/bin/bash
/bin/bash    # root shell!
EOF
chmod +x /tmp/echo

# Запускает script
./suid_script.sh
# Вызывается /tmp/echo → root shell!
```

**Защита:**
Linux kernel игнорирует SUID на:
- Shell scripts (#!/bin/bash)
- Interpreted languages (#!/usr/bin/python, #!/usr/bin/perl)

**SUID работает только на:**
- Compiled binaries (ELF executables)

**Aha! момент:**
Если находишь shell script с SUID → либо кто-то не знает что это не работает, либо это приманка (honeypot).

</details>

---

**Андрей:**
*"Отлично. Audit завершён. Теперь последний шаг — итоговый отчёт для Виктора."*

---

## 🔄 ЦИКЛ 8: Финальный отчёт (10 минут)

### 🎬 Сюжет

**Виктор** (звонок):
*"Макс, как успехи? Настроил?"*

**Макс:** *"Да. Все пользователи созданы, sudo ограничен, ACL настроен, limits применены."*

**Виктор:**
*"Хорошо. Отправь мне отчёт. Security audit report. Что настроено, какие меры безопасности."*

**Андрей:**
*"Покажу как сделать comprehensive report."*

---

### 💻 Практика: Генерация итогового отчёта

**ONE-LINER отчёт** (как в Episode 04):

```bash
{
  echo "═══════════════════════════════════════════════════════════"
  echo "        SECURITY AUDIT REPORT - EPISODE 09"
  echo "             Users & Permissions"
  echo "═══════════════════════════════════════════════════════════"
  echo
  echo "Operation: KERNEL SHADOWS"
  echo "Location: Saint Petersburg, Russia (LETI)"
  echo "Date: $(date)"
  echo "Auditor: Max Sokolov"
  echo "Mentor: Andrei Volkov"
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "1. USERS CREATED"
  echo "───────────────────────────────────────────────────────────"
  for u in viktor alex anna dmitry; do
    if id "$u" &>/dev/null; then
      echo "✓ $u: $(id $u)"
    fi
  done
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "2. GROUPS & MEMBERSHIP"
  echo "───────────────────────────────────────────────────────────"
  for u in viktor alex anna dmitry; do
    if id "$u" &>/dev/null; then
      echo "$u: $(groups $u | cut -d: -f2)"
    fi
  done
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "3. SUDO CONFIGURATION"
  echo "───────────────────────────────────────────────────────────"
  echo "Alex: Limited to network commands"
  sudo ls -la /etc/sudoers.d/alex 2>/dev/null || echo "Not configured"
  echo "Anna: Limited to log reading"
  sudo ls -la /etc/sudoers.d/anna 2>/dev/null || echo "Not configured"
  echo "Dmitry: Limited to service management"
  sudo ls -la /etc/sudoers.d/dmitry 2>/dev/null || echo "Not configured"
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "4. ACL CONFIGURATION"
  echo "───────────────────────────────────────────────────────────"
  echo "Anna log access:"
  getfacl /var/log/auth.log 2>/dev/null | grep "user:anna" || echo "Not configured"
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "5. SHARED DIRECTORY"
  echo "───────────────────────────────────────────────────────────"
  ls -ld /var/operations/shared 2>/dev/null || echo "Not created"
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "6. RESOURCE LIMITS"
  echo "───────────────────────────────────────────────────────────"
  echo "Alex limits:"
  sudo -i -u alex bash -c 'echo "  nofile: $(ulimit -n), nproc: $(ulimit -u)"'
  echo "Anna limits:"
  sudo -i -u anna bash -c 'echo "  nofile: $(ulimit -n), nproc: $(ulimit -u)"'
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "7. SUID/SGID AUDIT"
  echo "───────────────────────────────────────────────────────────"
  suid_count=$(find / -perm -4000 -type f 2>/dev/null | wc -l)
  sgid_count=$(find / -perm -2000 -type f 2>/dev/null | wc -l)
  echo "SUID files found: $suid_count"
  echo "SGID files found: $sgid_count"
  echo "Baseline saved: /root/suid_baseline.txt"
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "8. SECURITY POSTURE"
  echo "───────────────────────────────────────────────────────────"
  echo "✓ Principle of Least Privilege: Implemented"
  echo "✓ Defense in Depth: Multiple security layers"
  echo "✓ Separation of Duties: Role-based access"
  echo "✓ Audit Trail: All sudo commands logged"
  echo
  echo "───────────────────────────────────────────────────────────"
  echo "RECOMMENDATIONS"
  echo "───────────────────────────────────────────────────────────"
  echo "1. Monitor SUID files weekly (diff baseline)"
  echo "2. Review sudo logs daily (/var/log/auth.log)"
  echo "3. Enforce strong password policy"
  echo "4. Enable auditd for detailed tracking"
  echo "5. Regular security audits (quarterly)"
  echo
  echo "═══════════════════════════════════════════════════════════"
  echo "                    END OF REPORT"
  echo "═══════════════════════════════════════════════════════════"
  echo
  echo "Signed: Max Sokolov, System Administrator"
  echo "        Andrei Volkov, Mentor (LETI)"
  echo
} > security_audit_ep09.txt

# Показать отчёт
cat security_audit_ep09.txt
```

---

### Эпилог: Белое утро

**06:00. Санкт-Петербург. Рассвет над Невой.**

**Андрей** (провожает Макса на вокзал):
*"Хорошая работа, Макс. Permissions настроены правильно. Principle of Least Privilege. Defense in Depth. Separation of Duties. Ты понял основы безопасного администрирования."*

**Макс:** *"Спасибо, Андрей Николаевич. Многое стало понятно. Теперь понимаю как Крылов пробрался — misconfigured permissions."*

**Андрей:**
*"Именно. Root access как заряженный пистолет. Теперь ты знаешь как его правильно выдавать. Но помни: безопасность — это процесс, не продукт. Мониторинг обязателен."*

**Виктор** (звонок):
*"Макс, отчёт получил. Отлично. Теперь я могу спать спокойно. Permissions настроены правильно. Krылов больше не сможет проникнуть через misconfigured accounts."*

**Алекс:**
*"Хорошая работа. Но это только первый слой защиты. Дальше — процессы, systemd, мониторинг. Готовься к Episode 10."*

**LILITH:**
*"Неплохо. Root — это ответственность, не привилегия. Ты начинаешь понимать. Следующий шаг — systemd. Готовься."*

---

## 🎓 Что ты освоил

### Технические навыки:
- ✅ **Пользователи и группы:** useradd, groupadd, usermod, организация по ролям
- ✅ **Permissions:** chmod, chown, восьмеричная запись, special bits (SUID, SGID, Sticky)
- ✅ **Sudo:** конфигурация через /etc/sudoers.d/, Principle of Least Privilege
- ✅ **ACL:** setfacl, getfacl, гранулярный контроль доступа
- ✅ **Resource limits:** /etc/security/limits.conf, защита от fork bomb
- ✅ **PAM:** понимание модульной аутентификации, pam_limits.so
- ✅ **Security audit:** поиск SUID/SGID файлов, baseline monitoring

### Принципы безопасности:
- ✅ **Principle of Least Privilege** — минимальные привилегии для каждого
- ✅ **Defense in Depth** — многослойная защита (permissions + sudo + ACL + limits)
- ✅ **Separation of Duties** — разделение ответственности по ролям
- ✅ **Audit Trail** — логирование всех действий для расследований

### Философия:
- ✅ **Конфигурирование > Программирование** — используй готовые инструменты (visudo, setfacl, PAM)
- ✅ **Bash = автоматизация** — НЕ замена системных инструментов, только для автоматизации рутины
- ✅ **Security by design** — безопасность с самого начала, не afterthought

---

## 📖 Дополнительные ресурсы

### Man pages (обязательно к прочтению!):
```bash
man useradd      # Создание пользователей
man chmod        # Изменение permissions
man sudo         # Superuser do
man sudoers      # Sudo конфигурация
man setfacl      # Set ACL
man getfacl      # Get ACL
man limits.conf  # Resource limits
man pam          # PAM overview
```

### Online ресурсы:
- [Red Hat: User Management](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_basic_system_settings/managing-users-and-groups_configuring-basic-system-settings)
- [Ubuntu Server Guide: Security](https://ubuntu.com/server/docs/security-users)
- [Sudo Manual](https://www.sudo.ws/docs/man/sudoers.man/)
- [Arch Wiki: Access Control Lists](https://wiki.archlinux.org/title/Access_Control_Lists)

### Связанные episodes:
- **Episode 04:** Package Management — философия "используй готовые инструменты"
- **Episode 10:** Processes & Systemd — управление процессами и сервисами
- **Episode 12:** Backup & Recovery — защита данных

---

## 🚀 Следующий шаг

**Episode 10: Processes & Systemd** ждёт тебя!

Темы:
- Управление процессами (ps, top, htop, kill)
- Systemd units (.service, .timer)
- Журналирование (journalctl)
- Мониторинг системы

---

<div align="center">

**"Root — это не привилегия. Это ответственность."**

— Андрей Волков, профессор, ЛЭТИ

**Episode 09: Type B Complete! 🎉**

**День 17-18 / 60 выполнен!**

</div>

