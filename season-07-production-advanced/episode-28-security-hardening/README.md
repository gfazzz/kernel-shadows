# 🔐 EPISODE 28: SECURITY HARDENING

**KERNEL SHADOWS: Season 7 - Production & Advanced Topics**

```
███████╗██████╗ ██╗███████╗ ██████╗ ██████╗ ███████╗    ██████╗  █████╗
██╔════╝██╔══██╗██║██╔════╝██╔═══██╗██╔══██╗██╔════╝    ╚════██╗██╔══██╗
█████╗  ██████╔╝██║███████╗██║   ██║██║  ██║█████╗       █████╔╝╚█████╔╝
██╔══╝  ██╔═══╝ ██║╚════██║██║   ██║██║  ██║██╔══╝      ██╔═══╝ ██╔══██╗
███████╗██║     ██║███████║╚██████╔╝██████╔╝███████╗    ███████╗╚█████╔╝
╚══════╝╚═╝     ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚══════╝    ╚══════╝ ╚════╝
```

> **"Security is not a product. It's a process. Defense in depth — trust nothing."**
> — Sigríður Jónsdóttir, Security Architect

---

## 📋 МЕТАДАННЫЕ ЭПИЗОДА

| Параметр | Значение |
|----------|----------|
| **Тип эпизода** | Type B (Configuration & Tools) |
| **Сложность** | ⭐⭐⭐⭐⭐ (5/5) |
| **Время прохождения** | 6-7 часов |
| **Локация** | Рейкьявик, Исландия 🇮🇸 |
| **День операции** | День 56 из 60 |
| **До финала** | 4 дня |
| **Технологии** | SELinux, auditd, fail2ban, AppArmor, sysctl security |
| **Финальный результат** | Hardened production system (defense in depth) |

---

## 🎬 PROLOGUE: ПОСЛЕДНИЙ РУБЕЖ

**[04:30 UTC]** — Рейкьявик. 4 дня до финала. Макс не спал 18 часов.

**[Viktor — emergency video call, экран красный]**

**Viktor:** "Макс, у нас **проблема**. Серьёзная."

**Viktor:** "Два часа назад — attempted breach. Неизвестный attacker пытался получить доступ к infrastructure."

**Viktor:** "Firewall остановил. Но это **разведка**. Они тестируют защиту перед финальной атакой."

**Max:** "Кто?"

**Viktor:** "Не знаю. Может Крылов. Может 'Новая Эра'. Может кто-то ещё."

**Viktor:** "Через 4 дня — финал. Global operation starts. **60 серверов по всему миру одновременно.**"

**Viktor:** "Если хоть один сервер скомпрометирован — вся операция провалена. **Game over.**"

**Viktor:** "Performance оптимизирована. Kubernetes развёрнут. Monitoring активен. Но **security?**"

**Viktor (пауза):** "Я отправил к тебе лучшего security архитектора из Nordic countries."

---

### 👤 Новый персонаж: Sigríður Jónsdóttir

**[Дверь открывается. Входит женщина в чёрном, 38 лет, шрам на левой щеке, холодный взгляд]**

**Sigríður Jónsdóttir** (исландский акцент, медленная чёткая речь):
- **Роль:** Security Architect, ex-Icelandic Defense Forces, ex-F-Secure
- **Специализация:** Hardening, penetration testing, incident response
- **Background:** 15 лет в cybersecurity, защищала критическую инфраструктуру (banks, government, energy)
- **Философия:** "Trust nothing. Verify everything. Defense in depth."
- **Особенность:** Паранойя — это не болезнь, это профессия

**Репутация:**
- Единственный человек которого боится сам Алекс Соколов (ex-FSB)
- Провела red team атаку на NATO infrastructure — нашла 47 уязвимостей за 3 дня
- Никогда не улыбается. Security — это не игра.

---

**Sigríður (смотрит на Макса, холодно):** "Viktor told me about you. Junior admin → expert in 56 days. Impressive."

**Sigríður:** "But skill means nothing if system compromised. **One backdoor = total failure.**"

**Sigríður:** "I reviewed your infrastructure. Kubernetes? Good. Monitoring? Good. Performance? Excellent."

**Sigríður (пауза):** "**Security?** Amateur. Default settings. No SELinux. No audit logging. Weak SSH config. **Open target.**"

**Max (защищается):** "У нас firewall, VPN, ключи SSH..."

**Sigríður (качает головой):** "**Perimeter security insufficient.** Firewall breached? Game over."

**Sigríður:** "Real security = **defense in depth**. Multiple layers. If attacker breaks one — ten more waiting."

**Sigríður:** "Think Russian matryoshka doll. Break outer shell → inner shell waiting. Break that → another. **Never single point of failure.**"

---

**Sigríður:** "We have 96 hours until finale. I teach you **security hardening**."

**Sigríður:** "Layer 1: **Mandatory Access Control** (SELinux). Process can't escape sandbox even if compromised."

**Sigríður:** "Layer 2: **Audit logging** (auditd). Every action tracked. Intruder leaves traces."

**Sigríður:** "Layer 3: **Intrusion prevention** (fail2ban). Automated response to attacks."

**Sigríður:** "Layer 4: **Kernel hardening** (sysctl security). Close kernel vulnerabilities."

**Sigríður:** "Layer 5: **Application sandboxing** (AppArmor). Restrict what apps can do."

**Sigríður (смотрит в глаза):** "Security — not checklist. It's **mindset**. Assume breach. Plan for worst."

**Sigríður:** "Ready?"

**Max:** "Готов."

---

**LILITH (активирована):** "Sigríður — легенда. Я слышала о ней даже в тенях. Когда она говорит о security — слушай каждое слово. Она видела вещи которые заставят тебя больше не спать. **Paranoia saves lives.**"

---

## 🎯 ЗАДАЧИ ЭПИЗОДА

К концу эпизода ты сможешь:

✅ **Настроить SELinux** — Mandatory Access Control, policies, troubleshooting
✅ **Включить audit logging** — auditd, правила аудита, анализ логов
✅ **Защитить от brute-force** — fail2ban, custom jails, автоблокировка
✅ **Хардить ядро** — sysctl security параметры, kernel vulnerabilities
✅ **Настроить AppArmor** — профили приложений, sandboxing
✅ **SSH hardening** — ключи, 2FA, whitelist, honeypot
✅ **Security audit script** — автоматизированная проверка безопасности

**Type B Episode:** Финал = настроенная защищённая система, **НЕ bash скрипт** (скрипт только для аудита)!

---

## 🔄 ЦИКЛ 1: SELINUX - MANDATORY ACCESS CONTROL (15 минут)

### 🎬 Сюжет (2-3 мин)

**Sigríður:** "Traditional Linux security — **Discretionary Access Control** (DAC). User owns file → user decides permissions."

**Sigríður:** "Problem: **Process runs as user → inherits user permissions.** If process compromised → attacker has ALL user permissions."

**Sigríður (открывает терминал):** "Example: Web server runs as `www-data` user. Directory `/var/www` owned by `www-data`."

```bash
# Process compromised
# Attacker can:
echo "<?php system($_GET['cmd']); ?>" > /var/www/html/backdoor.php
# Now attacker executes ANY command as www-data!
```

**Sigríður:** "**SELinux** changes game. Not 'who you are' but '**what you can do**'."

**Sigríður:** "Web server? Only read `/var/www`, write logs, bind port 80/443. **Nothing else.** Even if compromised."

**Sigríður:** "Attacker gets shell? Can't read `/etc/shadow`. Can't write `/tmp`. Can't connect to database directly. **Sandbox.**"

---

### 📚 Теория: SELinux Fundamentals (7-10 мин)

#### 🎭 Метафора: Пропускная система в здании

**Представь:**
- **DAC (традиционный Linux)** = badge даёт доступ везде где ты owner
  - Employee badge → доступ во ВСЕ офисы твоего отдела
  - Если badge украден → вор получает ВСЕ твои permissions

- **SELinux (MAC)** = badge + explicit разрешения для каждой двери
  - Badge говорит "ты John, engineer"
  - Каждая дверь проверяет: "engineer может войти? Policy говорит — НЕТ"
  - Даже если badge украден → вор не может войти без explicit permission

**DAC:** "Я владелец → я могу всё"
**MAC:** "Я владелец, но **policy** решает что я могу"

---

#### 🔒 SELinux Modes

```bash
# Проверить режим
getenforce
# Enforcing | Permissive | Disabled

# Изменить временно
sudo setenforce 0  # Permissive (только логи, не блокирует)
sudo setenforce 1  # Enforcing (блокирует нарушения)

# Изменить постоянно
sudo nano /etc/selinux/config
# SELINUX=enforcing
```

**Режимы:**
- **Enforcing:** SELinux активен, блокирует нарушения → **PRODUCTION**
- **Permissive:** SELinux логирует нарушения, НЕ блокирует → **TESTING/DEBUG**
- **Disabled:** SELinux выключен → **НИКОГДА в production!**

---

#### 🏷️ SELinux Context (Labels)

**Каждый файл/процесс имеет SELinux context:**

```bash
# Посмотреть context файла
ls -Z /var/www/html/index.html
# -rw-r--r--. root root unconfined_u:object_r:httpd_sys_content_t:s0 index.html

# Посмотреть context процесса
ps auxZ | grep httpd
# system_u:system_r:httpd_t:s0 root 1234 ... /usr/sbin/httpd
```

**Format:** `user:role:type:level`

**Важный part:** `type` (третье поле)
- **Файл:** `httpd_sys_content_t` = контент для web сервера
- **Процесс:** `httpd_t` = Apache процесс

**Правило:** Процесс `httpd_t` может читать файлы `httpd_sys_content_t` (разрешено policy).

---

#### 🛡️ SELinux Policy

**Policy определяет:** Какой процесс (`type`) может делать что с каким ресурсом (`type`).

**Пример:**
```
# Policy rule (упрощённо):
allow httpd_t httpd_sys_content_t:file { read getattr open };
# Процесс httpd_t может читать файлы типа httpd_sys_content_t

allow httpd_t httpd_log_t:file { write create append };
# Процесс httpd_t может писать в логи httpd_log_t

# Но НЕ может:
allow httpd_t shadow_t:file read;  # ← этого правила НЕТ!
# httpd_t НЕ может читать /etc/shadow (type: shadow_t)
```

**Результат:** Даже если Apache скомпрометирован, attacker **не может** читать `/etc/shadow`!

---

#### 🔧 Управление SELinux Context

**Изменить context файла:**

```bash
# Временно (до relabel)
sudo chcon -t httpd_sys_content_t /var/www/html/newfile.html

# Постоянно (добавить правило)
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/html/newdir(/.*)?"
sudo restorecon -Rv /var/www/html/newdir
```

**Восстановить default context:**

```bash
sudo restorecon -Rv /var/www/html
```

---

#### 🚨 Troubleshooting SELinux Denials

**Когда SELinux блокирует — смотри audit log:**

```bash
# SELinux denials в audit log
sudo ausearch -m avc -ts recent

# Или через journalctl
sudo journalctl -t setroubleshoot --since "10 minutes ago"

# Или audit2why (человеко-читаемый)
sudo grep denied /var/log/audit/audit.log | audit2why
```

**Пример denial:**

```
type=AVC msg=audit(1634567890.123:456): avc:  denied  { read } for  pid=1234 comm="httpd" name="secret.txt" dev="sda1" ino=123456 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:user_home_t:s0 tclass=file permissive=0
```

**Расшифровка:**
- **denied { read }:** Запрещено чтение
- **comm="httpd":** Процесс Apache
- **scontext=...httpd_t:** Процесс имеет тип `httpd_t`
- **tcontext=...user_home_t:** Файл имеет тип `user_home_t` (домашняя директория пользователя)
- **Причина:** Policy НЕ разрешает `httpd_t` читать `user_home_t` (правильно!)

---

#### 🔓 Создание Custom Policy (если denial легитимный)

```bash
# 1. Собрать denials в модуль policy
sudo grep denied /var/log/audit/audit.log | audit2allow -M mypolicy

# 2. Просмотреть что будет разрешено
cat mypolicy.te

# 3. Установить модуль
sudo semodule -i mypolicy.pp

# Альтернатива: audit2allow генерирует и устанавливает автоматически
sudo grep denied /var/log/audit/audit.log | audit2allow -M mypolicy
sudo semodule -i mypolicy.pp
```

**⚠️ ОСТОРОЖНО:** Не создавай custom policies вслепую! Сначала пойми **ПОЧЕМУ** denial происходит. Возможно это legitimate block!

---

#### 📋 SELinux Booleans

**Booleans = переключатели для частых сценариев.**

```bash
# Список всех booleans
getsebool -a

# Конкретный boolean
getsebool httpd_can_network_connect
# httpd_can_network_connect --> off

# Включить (временно)
sudo setsebool httpd_can_network_connect on

# Включить (постоянно)
sudo setsebool -P httpd_can_network_connect on
```

**Частые booleans для web серверов:**
- `httpd_can_network_connect` — Apache может делать outbound connections (для API calls)
- `httpd_can_sendmail` — Apache может отправлять email
- `httpd_enable_cgi` — Apache может запускать CGI скрипты
- `httpd_read_user_content` — Apache может читать user home directories

---

**Sigríður:** "SELinux — steep learning curve. But **most powerful security** in Linux. Compromised process? Still trapped in sandbox. **Worth every minute of learning.**"

**LILITH:** "Я видела production без SELinux. Attacker получил web shell, за 5 минут — root access, за 10 — весь кластер. С SELinux? Web shell не смог даже прочитать `/etc/passwd`. **SELinux = последний рубеж.**"

---

### 💻 Практика: Настройка SELinux для Web Server (3-5 мин)

**Задание:** Включить SELinux в enforcing mode, настроить для Apache.

```bash
# 1. Проверить текущий режим
getenforce

# 2. Если Disabled — включить
# Редактировать /etc/selinux/config
sudo sed -i 's/SELINUX=disabled/SELINUX=enforcing/' /etc/selinux/config
# Требуется reboot для переключения из disabled!

# 3. Если Permissive — переключить в Enforcing
sudo setenforce 1

# 4. Проверить context web директории
ls -Z /var/www/html/

# 5. Если неправильный context — восстановить
sudo restorecon -Rv /var/www/html/

# 6. Создать тестовый файл
echo "Test" | sudo tee /var/www/html/test.html

# 7. Проверить context нового файла
ls -Z /var/www/html/test.html
# Должен быть: httpd_sys_content_t

# 8. Если нет — установить
sudo chcon -t httpd_sys_content_t /var/www/html/test.html

# 9. Проверить Apache boolean (если нужно делать API calls)
getsebool httpd_can_network_connect
# Если off и нужно — включить:
# sudo setsebool -P httpd_can_network_connect on

# 10. Проверить denials
sudo ausearch -m avc -ts recent
```

**Подсказка:** Если Apache не запускается после включения SELinux — смотри audit log!

---

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Apache скомпрометирован через уязвимость. Attacker имеет shell как `www-data` user. SELinux в режиме Enforcing. Что attacker **НЕ МОЖЕТ** сделать?

a) Читать файлы в `/var/www/html`
b) Писать в `/var/log/apache2/`
c) Читать `/etc/shadow`
d) Подключаться к порту 80"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **c) Читать `/etc/shadow`**

**Почему:**

**Может (разрешено SELinux policy для httpd_t):**
- ✅ **a) Читать `/var/www/html`** — это job Apache (контент), разрешено
- ✅ **b) Писать в `/var/log/apache2/`** — Apache пишет логи, разрешено
- ✅ **d) Подключаться к порту 80** — Apache слушает на 80, разрешено

**НЕ может (запрещено policy):**
- ❌ **c) Читать `/etc/shadow`** — файл имеет type `shadow_t`, policy НЕ разрешает `httpd_t` читать `shadow_t`!

**Пример denial в audit log:**
```
avc: denied { read } for comm="httpd" name="shadow"
scontext=system_u:system_r:httpd_t:s0
tcontext=system_u:object_r:shadow_t:s0
```

**Результат:** Даже с shell, attacker **НЕ может** эскалировать до root через `/etc/shadow`. SELinux блокирует.

**Вывод:** SELinux = containment даже после compromise. **Это критично.**

</details>

---

## 🔄 ЦИКЛ 2: AUDITD - КАЖДЫЙ ШАГ ЗАПИСАН (12 минут)

### 🎬 Сюжет (2-3 мин)

**Sigríður:** "Imagine: Attacker bypassed firewall, gained access, extracted data, left. **No traces.**"

**Sigríður:** "You don't know **when** breach happened. **What** was stolen. **How** they entered. **Impossible to fix.**"

**Sigríður (смотрит прямо):** "**auditd** changes that. Every syscall, every file access, every command — **logged.**"

**Sigríður:** "Attacker deletes files? Logged. Changes passwords? Logged. Installs backdoor? **Logged.**"

**Sigríður:** "Even if they wipe `/var/log` — audit log protected. **Immutable.** Can't delete even as root."

---

### 📚 Теория: Linux Audit System (5-7 мин)

#### 🎭 Метафора: Камеры видеонаблюдения

**Представь:**
- **Без auditd** = магазин без камер. Кража произошла? Не знаешь кто, когда, что украл.
- **С auditd** = камеры везде. Каждое действие записано. Кража? Rewind tape, find culprit.

**auditd** = чёрный ящик самолёта для Linux. Crash? Audit log расскажет что произошло.

---

#### 🔧 Установка и настройка

```bash
# Установка (Ubuntu/Debian)
sudo apt install auditd audispd-plugins -y

# Установка (RHEL/CentOS)
sudo yum install audit audit-libs -y

# Запуск
sudo systemctl enable auditd
sudo systemctl start auditd

# Проверка
sudo systemctl status auditd
```

---

#### 📋 Audit Rules

**Правила аудита определяют ЧТО логировать.**

**Конфигурация:**
- **Временные rules:** `auditctl -w ...` (до reboot)
- **Постоянные rules:** `/etc/audit/rules.d/*.rules` (переживают reboot)

**Syntax:**

```bash
# Мониторить файл/директорию
auditctl -w /path/to/file -p rwxa -k key_name
# -w = watch path
# -p = permissions (r=read, w=write, x=execute, a=attribute change)
# -k = key (tag для поиска в логах)

# Мониторить syscall
auditctl -a always,exit -F arch=b64 -S syscall_name -k key_name
# -a = add rule
# -F = filter
# -S = syscall
```

---

#### 🎯 Критичные файлы для мониторинга

```bash
# /etc/audit/rules.d/hardening.rules

# Мониторить изменения /etc/passwd и /etc/shadow
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes
-w /etc/group -p wa -k group_changes
-w /etc/gshadow -p wa -k gshadow_changes

# Мониторить sudo usage
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes

# Мониторить SSH config
-w /etc/ssh/sshd_config -p wa -k sshd_config_changes

# Мониторить kernel modules (rootkit detection)
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules

# Мониторить file deletion (unlink syscall)
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k delete

# Мониторить privilege escalation (setuid)
-a always,exit -F arch=b64 -S setuid -S setgid -S setreuid -S setregid -k priv_esc

# Мониторить network connections (для обнаружения backdoors)
-a always,exit -F arch=b64 -S socket -S connect -k network_connections

# Мониторить code injection (ptrace - используется debuggers/injectors)
-a always,exit -F arch=b64 -S ptrace -k code_injection

# Мониторить изменения времени (attacker может изменить timestamps для сокрытия)
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time_changes
```

**Загрузить rules:**

```bash
# Применить rules
sudo augenrules --load

# Или (если не используешь rules.d/)
sudo auditctl -R /etc/audit/audit.rules

# Проверить активные rules
sudo auditctl -l
```

---

#### 🔍 Поиск в Audit Logs

```bash
# Все записи за последние 10 минут
sudo ausearch -ts recent

# Поиск по key
sudo ausearch -k passwd_changes

# Поиск по syscall
sudo ausearch -sc unlink

# Поиск по пользователю
sudo ausearch -ua www-data

# Поиск по файлу
sudo ausearch -f /etc/shadow

# Поиск неудачных попыток доступа
sudo ausearch -m avc -ts today

# Комбо: passwd changes за последние 24 часа
sudo ausearch -k passwd_changes -ts yesterday -te now

# Отчёт в человеко-читаемом формате
sudo aureport

# Отчёт по неудачным логинам
sudo aureport -au --failed

# Отчёт по file modifications
sudo aureport -f
```

---

#### 🔒 Immutable Audit Log (защита от deletion)

**Problem:** Root может удалить audit log, скрыв следы.

**Solution:** Immutable flag + remote logging.

```bash
# 1. Сделать audit log immutable
sudo chattr +i /var/log/audit/audit.log

# Теперь даже root НЕ может удалить!
# sudo rm /var/log/audit/audit.log
# rm: cannot remove '/var/log/audit/audit.log': Operation not permitted

# 2. Снять immutable (только для rotation)
sudo chattr -i /var/log/audit/audit.log

# 3. Автоматический immutable после rotation (в /etc/audit/auditd.conf)
# max_log_file_action = rotate
# space_left_action = email
```

**Best practice:** Отправляй audit logs на remote syslog server (attacker не сможет удалить).

---

**Sigríður:** "Audit log — **forensic evidence**. Breach investigation? Start here. Know every action. **Reconstruct timeline.**"

**LILITH:** "Я помню incident. Attacker был внутри 3 недели. Без audit log — мы бы НЕ узнали что он делал. С audit log — мы нашли backdoor, закрыли уязвимость, восстановили данные. **Audit saved the company.**"

---

### 💻 Практика: Настройка Audit Rules (3-5 мин)

**Задание:** Настроить auditd для мониторинга критичных файлов.

```bash
# 1. Установить auditd
sudo apt install auditd -y

# 2. Создать custom rules
sudo tee /etc/audit/rules.d/99-security-hardening.rules << 'EOF'
# Password files
-w /etc/passwd -p wa -k passwd_changes
-w /etc/shadow -p wa -k shadow_changes

# Sudo
-w /etc/sudoers -p wa -k sudoers_changes

# SSH
-w /etc/ssh/sshd_config -p wa -k sshd_changes

# Kernel modules
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules

# File deletions
-a always,exit -F arch=b64 -S unlink -S unlinkat -k delete

# Privilege escalation
-a always,exit -F arch=b64 -S setuid -k priv_esc
EOF

# 3. Загрузить rules
sudo augenrules --load

# 4. Проверить загружены ли rules
sudo auditctl -l

# 5. Тест: изменить /etc/passwd
sudo usermod -c "Test change" root

# 6. Проверить audit log
sudo ausearch -k passwd_changes -ts recent

# Должен показать change!
```

**Проверка immutable:**

```bash
# Сделать текущий audit log immutable
sudo chattr +i /var/log/audit/audit.log

# Попробовать удалить (должно fail)
sudo rm /var/log/audit/audit.log
# rm: cannot remove: Operation not permitted

# Снять для rotation
sudo chattr -i /var/log/audit/audit.log
```

---

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "Attacker получил root access, удалил `/var/log/auth.log` и `/var/log/syslog` чтобы скрыть следы. Audit log НЕ immutable. Что произойдёт?

a) Audit log тоже удалится
b) Audit log останется, но deletion НЕ будет залогирован
c) Audit log запишет deletion, потом удалится
d) Audit log запишет deletion и останется (если есть audit rule для unlink)"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **d) Audit log запишет deletion и останется (если есть audit rule для unlink)**

**Почему:**

1. **Audit log пишет ДО выполнения syscall** (или сразу после)
2. Если есть rule `-a always,exit -S unlink -k delete`, deletion `/var/log/auth.log` будет залогирован
3. Attacker может удалить `/var/log/auth.log` и `/var/log/syslog` — это обычные файлы
4. **Audit log (`/var/log/audit/audit.log`) отдельный** — attacker может удалить его тоже (если не immutable)
5. **НО** само удаление audit log ТОЖЕ будет залогировано (в тот же файл перед удалением!)

**Правильная защита:**
```bash
# 1. Immutable flag
sudo chattr +i /var/log/audit/audit.log

# 2. Remote logging (syslog forward)
# В /etc/audit/audisp-remote.conf:
# remote_server = log-server.example.com
# port = 514

# 3. Audit rule для защиты самого себя
-w /var/log/audit/ -k audit_log_changes
```

**Результат:** Даже если attacker root — НЕ может удалить audit log (immutable) + копия на remote server.

**LILITH:** "Defense in depth. Audit log важнее чем system logs. Protect it like nuclear codes."

</details>

---

## 🔄 ЦИКЛ 3: FAIL2BAN - АВТОМАТИЧЕСКАЯ ОБОРОНА (12 минут)

### 🎬 Сюжет (2-3 мин)

**Sigríður (показывает real-time логи SSH):**

```
Failed password for root from 123.45.67.89 port 54321
Failed password for admin from 123.45.67.89 port 54322
Failed password for user from 123.45.67.89 port 54323
Failed password for root from 123.45.67.89 port 54324
...
```

**Sigríður:** "Brute-force attack. **1000 attempts per minute**. Eventually — password cracked."

**Sigríður:** "Manual response too slow. You see this — **already too late**."

**Sigríður:** "**fail2ban** = automated response. 5 failed attempts? IP banned. **Immediately.**"

**Sigríður:** "Attacker tries 5 times → firewall blocks. Game over. **Self-defending system.**"

---

### 📚 Теория: fail2ban Intrusion Prevention (5-7 мин)

#### 🎭 Метафора: Автоматический bouncer в клубе

**Представь:**
- **Без fail2ban** = bouncer вручную проверяет каждого, медленно реагирует на проблемы
- **С fail2ban** = автоматическая система: попытался войти с fake ID 3 раза → **blacklist, навсегда**

**fail2ban** = bouncer который никогда не спит, не устаёт, реагирует мгновенно.

---

#### 🔧 Установка

```bash
# Ubuntu/Debian
sudo apt install fail2ban -y

# RHEL/CentOS
sudo yum install epel-release
sudo yum install fail2ban -y

# Запуск
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

---

#### 📋 Конфигурация

**Файлы:**
- `/etc/fail2ban/jail.conf` — default config (НЕ редактируй напрямую!)
- `/etc/fail2ban/jail.local` — local overrides (создай этот файл)
- `/etc/fail2ban/jail.d/*.conf` — дополнительные jails

**Создать custom config:**

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local
```

---

#### 🎯 Основные параметры

```ini
[DEFAULT]
# Ban time (секунды)
bantime = 3600        # 1 час

# Find time (окно наблюдения)
findtime = 600        # 10 минут

# Max retry (попыток до бана)
maxretry = 5          # 5 попыток

# Действие при бане
banaction = iptables-multiport
# или: nftables-multiport, ufw

# Email уведомления
destemail = admin@example.com
sendername = Fail2Ban
action = %(action_mwl)s
# action_mwl = ban + email с логами
```

**Логика:**
- **findtime = 600, maxretry = 5:** Если 5 неудачных попыток за 10 минут → BAN на bantime
- **bantime = 3600:** Бан на 1 час, потом IP разбанивается автоматически
- **bantime = -1:** Permanent ban (навсегда)

---

#### 🛡️ Jails (защита разных сервисов)

**Jail = правило защиты для конкретного сервиса.**

**SSH Protection:**

```ini
[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

**Apache Protection (brute-force на login pages):**

```ini
[apache-auth]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log
maxretry = 5

[apache-noscript]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log
maxretry = 6

[apache-overflows]
enabled = true
port    = http,https
logpath = /var/log/apache2/error.log
maxretry = 2
```

**Nginx Protection:**

```ini
[nginx-http-auth]
enabled = true
port    = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port    = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
```

**MySQL Protection (brute-force на DB):**

```ini
[mysqld-auth]
enabled = true
port    = 3306
logpath = /var/log/mysql/error.log
maxretry = 5
```

---

#### 🔍 Управление

```bash
# Статус всех jails
sudo fail2ban-client status

# Статус конкретного jail
sudo fail2ban-client status sshd

# Забанить IP вручную
sudo fail2ban-client set sshd banip 1.2.3.4

# Разбанить IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# Reload конфигурации
sudo fail2ban-client reload

# Перезапустить jail
sudo fail2ban-client restart sshd
```

---

#### 🎨 Custom Filters

**Создать custom filter для своего приложения:**

```bash
# /etc/fail2ban/filter.d/myapp.conf
[Definition]
failregex = ^<HOST> .* "POST /login .* 401
            ^<HOST> .* "POST /api/auth .* 403
ignoreregex =

# <HOST> = placeholder для IP адреса (fail2ban заменяет автоматически)
```

**Использовать в jail:**

```ini
[myapp]
enabled = true
port    = http,https
logpath = /var/log/myapp/access.log
filter  = myapp
maxretry = 5
bantime = 7200
```

---

#### 📊 Monitoring

```bash
# Banned IPs
sudo iptables -L -n | grep DROP
# или
sudo fail2ban-client banned

# Логи fail2ban
sudo tail -f /var/log/fail2ban.log

# Сколько IP сейчас забанено
sudo fail2ban-client status sshd | grep "Total banned"
```

---

**Sigríður:** "fail2ban — **automated defense**. Attacks happen at 3 AM? fail2ban doesn't sleep. **Always vigilant.**"

**LILITH:** "Production server: 50,000 SSH brute-force attempts per day. Без fail2ban — админ бы сошёл с ума. С fail2ban — 99.9% blocked автоматически. **Set it and forget it.**"

---

### 💻 Практика: Настройка fail2ban для SSH (3-5 мин)

**Задание:** Защитить SSH от brute-force.

```bash
# 1. Установить fail2ban
sudo apt install fail2ban -y

# 2. Создать local config
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
destemail = admin@localhost
sendername = Fail2Ban
action = %(action_mwl)s

[sshd]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[sshd-ddos]
enabled = true
port = ssh
logpath = /var/log/auth.log
maxretry = 10
bantime = 600
EOF

# 3. Запустить fail2ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban

# 4. Проверить статус
sudo fail2ban-client status
sudo fail2ban-client status sshd

# 5. Тест: симулировать неудачные попытки
# (с другой машины или локально)
# ssh wronguser@localhost (3 раза с неправильным паролем)

# 6. Проверить banned IPs
sudo fail2ban-client status sshd

# 7. Проверить iptables rules
sudo iptables -L f2b-sshd -n

# 8. Разбанить себя (если нужно)
sudo fail2ban-client set sshd unbanip YOUR_IP
```

---

### 🤔 Вопрос LILITH (1 мин)

**LILITH:** "fail2ban настроен: `maxretry=5`, `findtime=600`, `bantime=3600`. Attacker делает 4 неудачных SSH попытки, ждёт 15 минут, делает ещё 4 попытки. Забанен?

a) Да, 8 попыток > 5
b) Нет, findtime window истёк
c) Да, IP tracked навсегда
d) Нет, только permanent bans работают"

<details>
<summary>💡 Думай перед проверкой</summary>

**Ответ:** **b) Нет, findtime window истёк**

**Почему:**

**Логика fail2ban:**
1. `findtime = 600` (10 минут) = sliding window
2. `maxretry = 5` = максимум попыток в этом окне

**Timeline:**
```
00:00 - 4 попытки (счётчик = 4)
00:15 (15 минут спустя) - ещё 4 попытки

Проверка:
- Текущее время: 00:15
- Findtime window: 00:15 - 00:05 (последние 10 минут)
- Попытки в window: только последние 4 (первые 4 уже вне window!)
- 4 < 5 (maxretry) → НЕТ БАНА
```

**Если бы было 15:00 + 5 минут:**
```
00:00 - 4 попытки
00:05 (5 минут спустя) - ещё 2 попытки

Window check:
- Текущее время: 00:05
- Window: 00:05 - 00:00 (последние 10 минут включает ОБЕ группы!)
- Попытки в window: 4 + 2 = 6
- 6 > 5 → БАН!
```

**Вывод:** findtime = **sliding window**, не cumulative. После findtime счётчик сбрасывается.

**Если хочешь cumulative ban (постоянное отслеживание):**
```ini
# В jail.local:
bantime = -1          # Permanent ban
maxretry = 10         # Лимит за всё время
# Или используй recidive jail (repeat offenders)
```

</details>

---

## 🔄 ЦИКЛ 4: SYSCTL SECURITY (10 минут)

### 🎬 Сюжет (2-3 мин)

**Sigríður:** "Remember Episode 27? You tuned kernel for **performance**. Now — tune for **security**."

**Sigríður:** "Trade-off: Performance vs Security. Some optimizations **reduce security**. Must balance."

**Sigríður:** "Example: IP forwarding. For routers — needed. For server? **Attack vector**. Disable."

---

### 📚 Теория: Kernel Security Hardening (краткая — см. Episode 27 для sysctl basics)

#### 🔒 Критичные security параметры

```bash
# /etc/sysctl.d/99-security.conf

# === NETWORK SECURITY ===

# Disable IP forwarding (если не router!)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# Disable source routing (защита от IP spoofing)
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Disable ICMP redirects (защита от MitM)
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Disable sending ICMP redirects
net.ipv4.conf.all.send_redirects = 0

# Enable reverse path filtering (защита от IP spoofing)
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# SYN cookies (защита от SYN flood DDoS)
net.ipv4.tcp_syncookies = 1

# Ignore ICMP ping requests (скрыть сервер от ping scans)
net.ipv4.icmp_echo_ignore_all = 1

# Ignore broadcast pings (Smurf attack prevention)
net.ipv4.icmp_echo_ignore_broadcasts = 1

# Log suspicious packets (martians = packets с невозможными src IP)
net.ipv4.conf.all.log_martians = 1

# === KERNEL SECURITY ===

# Address Space Layout Randomization (ASLR)
kernel.randomize_va_space = 2
# 0 = disabled, 1 = partial, 2 = full (рекомендуется)

# Restrict access to kernel logs (dmesg)
kernel.dmesg_restrict = 1

# Restrict kernel pointers в /proc и /sys
kernel.kptr_restrict = 2
# 0 = unrestricted, 1 = restricted to root, 2 = hidden

# Disable kernel module loading после boot (если не нужно)
# kernel.modules_disabled = 1  # ОСТОРОЖНО: необратимо до reboot!

# Restrict ptrace (защита от process injection)
kernel.yama.ptrace_scope = 2
# 0 = classic ptrace, 1 = restricted, 2 = admin-only, 3 = disabled

# Restrict perf events (защита от side-channel attacks)
kernel.perf_event_paranoid = 3
# 3 = максимальная защита

# Enable ExecShield (memory protection)
kernel.exec-shield = 1

# Restrict core dumps (могут содержать passwords в memory)
fs.suid_dumpable = 0

# === FILE SYSTEM ===

# Restrict access to /proc/<pid>/ (защита от information leak)
kernel.pid_max = 65536
```

**Применить:**

```bash
# Создать файл
sudo tee /etc/sysctl.d/99-security.conf << 'EOF'
[вставить параметры выше]
EOF

# Применить
sudo sysctl -p /etc/sysctl.d/99-security.conf
```

---

### 💻 Практика: Security Hardening via sysctl (краткая)

```bash
# Создать security sysctl config
sudo tee /etc/sysctl.d/99-security.conf << 'EOF'
net.ipv4.ip_forward = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
kernel.randomize_va_space = 2
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
fs.suid_dumpable = 0
EOF

sudo sysctl -p /etc/sysctl.d/99-security.conf

# Проверить применились ли
sysctl net.ipv4.ip_forward
sysctl kernel.randomize_va_space
```

---

## 🔄 ЦИКЛ 5: SSH HARDENING (10 минут)

### 📚 Теория: Защита SSH (краткая)

**SSH — главная точка входа. Критично защитить!**

```bash
# /etc/ssh/sshd_config

# === AUTHENTICATION ===

# Отключить password authentication (ТОЛЬКО ключи!)
PasswordAuthentication no
ChallengeResponseAuthentication no

# Отключить root login
PermitRootLogin no

# Whitelist пользователей
AllowUsers deployer admin

# Или whitelist группы
AllowGroups ssh-users

# === NETWORK ===

# Изменить порт (security through obscurity — дополнительная мера)
Port 2222

# Listen только на конкретном IP (если есть private network)
ListenAddress 10.0.0.5

# === PROTOCOL ===

# Использовать только SSH protocol 2
Protocol 2

# Ограничить ciphers (только сильные)
Ciphers aes256-gcm@openssh.com,aes128-gcm@openssh.com

# Ограничить MACs
MACs hmac-sha2-512,hmac-sha2-256

# Ограничить KexAlgorithms
KexAlgorithms curve25519-sha256,diffie-hellman-group-exchange-sha256

# === LIMITS ===

# Max authentication attempts
MaxAuthTries 3

# Login grace time (сколько секунд на ввод пароля)
LoginGraceTime 30

# Max sessions per connection
MaxSessions 2

# Max startups (против DoS)
MaxStartups 10:30:60

# === 2FA (опционально) ===
# ChallengeResponseAuthentication yes
# AuthenticationMethods publickey,keyboard-interactive

# === LOGGING ===
LogLevel VERBOSE
```

**Применить:**

```bash
sudo nano /etc/ssh/sshd_config
# Внести изменения

# Проверить синтаксис
sudo sshd -t

# Применить
sudo systemctl restart sshd
```

---

## 🔄 ЦИКЛ 6: APPARMOR (опционально, 8 минут)

### 📚 Теория: AppArmor (краткая)

**AppArmor = альтернатива SELinux** (проще настроить, менее мощный).

**Ubuntu использует AppArmor по умолчанию** (вместо SELinux).

```bash
# Проверить статус
sudo aa-status

# Режимы профилей:
# - enforce: блокирует нарушения
# - complain: логирует, не блокирует

# Перевести профиль в complain
sudo aa-complain /usr/sbin/nginx

# Перевести в enforce
sudo aa-enforce /usr/sbin/nginx

# Отключить профиль
sudo ln -s /etc/apparmor.d/usr.sbin.nginx /etc/apparmor.d/disable/
sudo apparmor_parser -R /etc/apparmor.d/usr.sbin.nginx

# Включить обратно
sudo rm /etc/apparmor.d/disable/usr.sbin.nginx
sudo apparmor_parser -r /etc/apparmor.d/usr.sbin.nginx
```

---

## 🔄 ЦИКЛ 7: SECURITY AUDIT SCRIPT (12 минут)

### 💻 Практика: Создать `security_audit.sh`

**См. starter/security_audit.sh для шаблона.**

**Скрипт должен проверять:**
1. ✅ SELinux enabled & enforcing
2. ✅ auditd running
3. ✅ fail2ban active
4. ✅ SSH config hardened
5. ✅ sysctl security параметры
6. ✅ Firewall active (ufw/iptables)
7. ✅ Automatic updates enabled
8. ✅ Rootkit check (rkhunter/chkrootkit)
9. ✅ Open ports audit
10. ✅ File permissions (/etc/shadow, sudoers)

**См. solution/security_audit.sh для референса.**

---

## 🔄 ЦИКЛ 8: FINAL SECURITY CHECK (10 минут)

### 🎬 Сюжет: Red Team Test

**[23:45 UTC]** — Финальный тест безопасности.

**Sigríður:** "Configuration done. Now — **test**. Real attack simulation."

**Sigríður:** "I asked Alex (your cousin, ex-FSB) to attack infrastructure. **Full force**. No holds barred."

**Max:** "Алекс?! Он же..."

**Sigríður:** "Best pentester I know. If **he** can't breach — **no one** can."

---

**[Alex Sokolov подключается к видеозвонку]**

**Alex (улыбается):** "Привет, Макс. Готов к атаке?"

**Alex:** "Sigríður дала мне IP адреса. Я буду атаковать 2 часа. **No mercy.**"

**Alex:** "Brute-force, exploit scanning, social engineering (email phishing), DDoS, everything."

**Alex:** "Если найду уязвимость — скажу. Если нет — вы готовы к финалу."

**Max:** "Давай."

---

**[2 HOURS LATER — 01:45 UTC]**

**Alex:** "Finished. Results:"

**Alex:**
- ✅ SSH brute-force → **fail2ban blocked after 3 attempts**
- ✅ Port scan → **only 22, 80, 443 open** (остальные closed)
- ✅ Exploit на web server → **SELinux contained, не смог читать /etc/shadow**
- ✅ Попытка загрузить kernel module → **audit log записал, SELinux blocked**
- ✅ DDoS на SSH → **SYN cookies handled, сервер устоял**
- ✅ Phishing email (fake Viktor) → **Макс не открыл** (good!)

**Alex:** "Я нашёл **одну** minor уязвимость: nginx version disclosure. Fix: `server_tokens off;`"

**Alex:** "Otherwise — **solid defenses**. 9 из 10."

**Alex:** "Вы готовы к финалу."

---

**Sigríður (кивает, редкая улыбка):** "Good work, Max. From amateur to paranoid в 4 дня."

**Sigríður:** "Remember: Security — **never finished**. Always evolving. Attackers evolve → you evolve."

**Sigríður:** "**Defense in depth** — multiple layers. One breaks → others hold."

**Sigríður:** "Season 8 starts in 72 hours. **Global operation.** Everything you learned — you'll need."

---

**[Viktor — final call]**

**Viktor:** "Макс, infrastructure готова."

**Viktor:** "✅ Kubernetes deployed (Episode 25)
✅ Monitoring active (Episode 26)
✅ Performance optimized (Episode 27)
✅ Security hardened (Episode 28)"

**Viktor:** "60 серверов. 8 стран. 72 часа до старта."

**Viktor:** "Season 8 — **finale**. 'Новая Эра' готовит финальную атаку. Крылов мобилизует ресурсы."

**Viktor:** "Ты прошёл путь от junior admin до expert за 56 дней. **Impressive.**"

**Viktor:** "Rest. Through 72 hours — **war begins.**"

---

## ✅ ЧТО ТЫ ИЗУЧИЛ

### Технологии:
- ✅ **SELinux:** Mandatory Access Control, contexts, policies, booleans, troubleshooting
- ✅ **auditd:** Audit rules, log analysis, immutable logs, forensics
- ✅ **fail2ban:** Jails, filters, automated banning, intrusion prevention
- ✅ **sysctl security:** Kernel hardening, network security, ASLR
- ✅ **SSH hardening:** Key-based auth, port changes, whitelist, 2FA
- ✅ **AppArmor:** Profiles, enforce/complain modes, sandboxing
- ✅ **Security audit:** Автоматизированная проверка защиты

### Type B Episode:
- ✅ Конфигурация систем (НЕ bash scripting как финал!)
- ✅ Bash скрипт только для аудита (вспомогательный)
- ✅ Фокус: использовать и настраивать готовые инструменты

**Развёрнуто:**
- Hardened system: SELinux enforcing, auditd logging, fail2ban active
- Red team test: 9/10 security score (Alex Sokolov approval)
- Defense in depth: 5 layers защиты

**Время прохождения:** 6-7 часов
**Сложность:** ⭐⭐⭐⭐⭐
**Production готовность:** 95% (ГОТОВ К ФИНАЛУ!)

---

## 🔗 СЛЕДУЮЩИЙ СЕЗОН

**SEASON 8: FINAL OPERATION** (4 эпизода, 72 часа non-stop)

**Episode 29-32:** Глобальная финальная операция
- 60 серверов, 8 стран, одновременный запуск
- "Новая Эра" — финальная атака
- Крылов (ФСБ) — погоня
- Alex, Anna, Viktor, Dmitry, LILITH — вся команда
- **All skills tested:** Shell, Networking, SysAdmin, DevOps, Security
- **72 часа без сна**
- **Winner takes all**

**День 60 операции** — ФИНАЛ

---

<div align="center">

**🔐 "Trust nothing. Verify everything. Defense in depth." — Sigríður Jónsdóttir**

**[SEASON 7: COMPLETE]**

**[NEXT: SEASON 8 — FINAL OPERATION]**

**[72 HOURS UNTIL WAR]**

</div>

