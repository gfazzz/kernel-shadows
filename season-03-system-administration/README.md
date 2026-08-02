# SEASON 3: SYSTEM ADMINISTRATION
## Санкт-Петербург → Таллин, Эстония

> *"Root access как заряженный пистолет. Не давай его кому попало."* — Андрей Волков

---

## 📍 География и контекст

**Локации:**
- 🇷🇺 **Санкт-Петербург** (Episodes 09-10, дни 17-20)
  - ЛЭТИ (Ленинградский электротехнический институт), Васильевский остров
  - Unix старая школа, академические традиции
  - Белые ночи — не спится, идеальное время для sysadmin работы
- 🇪🇪 **Таллин, Эстония** (Episodes 11-12, дни 21-24)
  - e-Estonia Briefing Centre
  - Средневековый Old Town + самая цифровая нация мира
  - X-Road infrastructure, государственные серверы

**Время:** Дни 17-24 операции (из 60), ~15-18 часов

**Сложность:** ⭐⭐⭐☆☆

---

## 🎭 Сюжетный контекст

### Кризис:
Один из серверов операции **взломан**. Анна Ковалёва обнаруживает backdoor от Крылова. Виктор в панике: *"Как они проникли? Проверь все системы!"*

**Проблема:** Permissions настроены неправильно. Некоторые учётные записи имеют больше прав, чем нужно. Krylov эксплуатировал это.

**Решение:** Макс едет в Санкт-Петербург, чтобы научиться правильному администрированию систем. Затем в Таллин — изучить опыт e-Government (где безопасность критична).

### Персонажи:

**Core Team (постоянные):**
- **Max Sokolov** — главный герой, растёт как sysadmin
- **Viktor Petrov** — координатор, переживает за безопасность
- **Алекс Соколов** — security expert, двоюродный брат Макса, ex-FSB
- **Анна Ковалёва** — forensics expert, blue team lead
- **Дмитрий Орлов** — DevOps engineer
- **LILITH** — AI-помощник (ты!)

**Local Experts (Season 3):**

#### Санкт-Петербург:
- **Андрей Волков** (Episode 09)
  - Ex-профессор Unix, ЛЭТИ
  - Возраст: ~60 лет, седые волосы, очки, твидовый пиджак
  - Стиль: Академический, методичный, "старая школа"
  - Цитата: *"Root access как заряженный пистолет. Не давай его кому попало. Это я студентам 20 лет говорю."*
  - Учит Max правильной настройке permissions, sudo, ACL

- **Борис Кузнецов** (Episode 10)
  - SystemD архитектор, ex-Red Hat contributor
  - Возраст: ~35 лет, бородатый, толстовка "systemd or die"
  - Стиль: Fanatical про systemd, но знает своё дело
  - Цитата: *"Init scripts — это прошлое. SystemD — это будущее. И настоящее."*
  - Учит Max systemd, services, процессам

#### Таллин, Эстония:
- **Kristjan Tamm** (Episode 11)
  - IT-архитектор e-Government Estonia
  - Возраст: ~40 лет, строгий, профессиональный
  - Стиль: Эстонская эффективность, zero tolerance для ошибок
  - Цитата: *"В Эстонии всё цифровое. Вся страна работает на этих серверах. Если они падают — страна останавливается."*
  - Учит Max LVM, disk management, production reliability

- **Liisa Kask** (Episode 12)
  - Backup engineer, ex-Skype Estonia (10 лет опыта)
  - Возраст: ~30 лет, энергичная, параноидальная про бэкапы
  - Стиль: "3-2-1-T backup rule" фанатик, systemd evangelist
  - Цитата: *"Untested backup = no backup. Test restore every month."*
  - Учит Max backup strategies, disaster recovery, systemd timers, logrotate
  - Скайп научил: 300M users не ждут, persistent timers критичны

**Antagonist:**
- **Полковник Крылов** — ФСБ Управление "К", охотится за Алексом, атакует инфраструктуру

---

## 🆕 v2.0: пересборка в атомарные серии (в работе)

Season 3 мигрирует с монолитных `episode-NN` (2667–3440 строк) на атомарные
серии `sNNeNN`: один концепт — одна задача, README 180–280 строк, воспроизводимый
тест без root. План — [`V2.0_UPGRADE_PLAN.md`](../V2.0_UPGRADE_PLAN.md), этап 5.

**Плановое дробление 4 эпизодов → 13 серий:**

| Серия | Из ep | Концепт | Артефакт | Type | Статус |
|-------|-------|---------|----------|------|--------|
| [s03e01](s03e01-users-groups/) | 09 | учётные записи, группы, UID | `users_report.txt` | **C** | ✅ 17/17 |
| [s03e02](s03e02-permissions/) | 09 | права, SUID/SGID/sticky | `perms_report.txt` | **C** | ✅ 17/17 |
| [s03e03](s03e03-sudo/) | 09 | `sudo`, наименьшие привилегии (капстоун) | `sudoers.d/ops-team` | **B** | ✅ 22/22 |
| [s03e04](s03e04-processes/) | 10 | процессы и сигналы; системные вызовы | `proc_report.txt` | **C** | ✅ 22/22 |
| s03e05 | 10 | свой сервис systemd | `.service` | B | план |
| s03e06 | 10 | таймеры вместо cron | `.timer` | B | план |
| s03e07 | 10 | `journalctl` (капстоун) | `journal_report.txt` | C | план |
| s03e08 | 11 | диски и файловые системы | `disk_report.txt` | C | план |
| s03e09 | 11 | LVM: PV, VG, LV | `lvm_plan.sh` | A | план |
| s03e10 | 11 | `fstab` и монтирование (капстоун) | `fstab` | B | план |
| s03e11 | 12 | стратегии бэкапа, `rsync` | `backup.sh` | A | план |
| s03e12 | 12 | расписание бэкапа таймером | `.timer` | B | план |
| s03e13 | 12 | восстановление и проверка (финал сезона) | `restore_check.sh` | A | план |

Целевой баланс по §2A: 3 × Type A, 5 × Type B, 5 × Type C — сезон не состоит
из одних скриптов, как того требует «курс про Linux, а не про bash».

**Линия C** (§2A): в `s03e04` появляется первое знакомство с системными вызовами —
`strace` на простой программе и объяснение, почему `ls` — это `getdents64`.

Учебные данные сезона лежат в [`data/`](data/): снимки `/etc/passwd`,
`/etc/group`, `/etc/shadow`, прав и SUID-файлов со скомпрометированного
`shadow-server-01`. Разбираются копии, поэтому ни root, ни живая система не нужны.

Прогнать тесты сезона: `make test SEASON=season-03-system-administration`.

---

## 📚 Содержание Season 3

### Episode 09: Users & Permissions
**Локация:** 🇷🇺 Санкт-Петербург, ЛЭТИ
**Дни:** 17-18
**Время:** 4-5 часов
**Персонаж:** Андрей Волков

**Тема:** Пользователи, группы, права доступа
- Users: `useradd`, `usermod`, `userdel`, `/etc/passwd`, `/etc/shadow`
- Groups: `groupadd`, `usermod -aG`, `/etc/group`
- Permissions: `chmod`, `chown`, `umask`, rwx notation
- Special bits: SUID, SGID, Sticky bit
- `sudo` и `/etc/sudoers`
- ACL (Access Control Lists): `setfacl`, `getfacl`

**Практика:**
- Создать учётные записи для команды операции (Виктор, Алекс, Анна, Дмитрий)
- Настроить sudo через `/etc/sudoers.d/` для каждого пользователя
- Настроить resource limits через `/etc/security/limits.conf`
- Настроить PAM для session logging
- Конфигурирование системы (Type B), минимум bash scripting

**Сюжет:**
Макс встречается с Андреем Волковым в старом университете. Белые ночи, канал за окном, чай. Андрей рассказывает о Unix permissions philosophy: principle of least privilege. Виктор требует настроить доступы правильно после взлома.

---

### Episode 10: Processes & Systemd
**Локация:** 🇷🇺 Санкт-Петербург
**Дни:** 19-20
**Время:** 4-5 часов
**Персонаж:** Борис Кузнецов

**Тема:** Процессы, сервисы, systemd, cron
- Процессы: `ps`, `top`, `htop`, `pgrep`, `pkill`
- Signals: `kill -SIGTERM`, `kill -9`, `killall`
- Systemd: `systemctl`, unit files, dependencies
- Services: `start`, `stop`, `restart`, `enable`, `disable`
- Timers: systemd.timer (замена cron)
- Journalctl: `journalctl -u service`, logging

**Практика:**
- Создать systemd service для мониторинга (`monitor.service`)
- Настроить systemd timer для автоматического запуска
- Настроить resource limits (CPUQuota, MemoryLimit)
- Security hardening services (NoNewPrivileges, ProtectSystem)
- Анализ логов через journalctl
- Конфигурирование systemd units (Type B), минимум bash

**Сюжет:**
Анна: *"На сервере запущен подозрительный процесс. PID 6623."* Макс с помощью Бориса находит backdoor процесс `sshd_backdoor` (маскировка под sshd). Удаляют через systemd.

---

### Episode 11: Disk Management & LVM
**Локация:** 🇪🇪 Таллин, Эстония (e-Estonia Briefing Centre)
**Дни:** 21-22
**Время:** 4-5 часов
**Персонаж:** Kristjan Tamm

**Тема:** Управление дисками, LVM, RAID, fstab
- Диски: `df -h`, `du -sh`, `lsblk`, `fdisk`, `parted`
- Partitions: создание, форматирование (ext4, xfs)
- LVM: Physical Volume → Volume Group → Logical Volume
- `pvcreate`, `vgcreate`, `lvcreate`, `lvextend`, `resize2fs`
- `/etc/fstab`: автомонтирование
- (Bonus) RAID: типы (0, 1, 5, 10), `mdadm`

**Практика:**
- Добавить новый диск к серверу (GPT partitioning)
- Создать LVM: расширяемый том для `/var/log` и других директорий
- Настроить автомонтирование через `/etc/fstab`
- Настроить systemd disk monitoring (service + timer)
- Расширить LVM без downtime (production-ready)
- Конфигурирование системы (Type B), disk management + fstab + systemd

**Сюжет:**
Макс в Таллине. Средневековые башни + fiber optic. Kristjan показывает X-Road infrastructure. Анна: *"Логи заполнили диск. `/var/log` 95%. СРОЧНО."* Виктор добавляет 500GB диск. LVM решение без downtime.

---

### Episode 12: Backup & Recovery
**Локация:** 🇪🇪 Таллин
**Дни:** 23-24
**Время:** 3-4 часа
**Персонаж:** Liisa Kask

**Тема:** Резервное копирование и восстановление
- Стратегии backup: full, incremental, differential
- 3-2-1-T rule: 3 copies, 2 media types, 1 offsite, TESTED
- Инструменты: `rsync`, `tar`, `dd`
- Remote backup: `rsync` через SSH + ключи
- Автоматизация: **systemd timers** (modern Linux, не cron)
- Logrotate: ротация backup логов
- Восстановление: testing, disaster recovery, RTO/RPO

**Практика:**
- Написать bash скрипт для backup (8 функций: full, incremental, offsite, restore, health check, cleanup, DR test, report)
- Настроить **systemd timers** для автоматизации (4 timers: full, incremental, offsite, health-check)
- Настроить **logrotate** для backup логов (daily, rotate 30)
- Настроить SSH ключи для offsite backup
- Симуляция: emergency restore (Krylov attack, база удалена)
- Type B подход: 40% bash script + 60% systemd/logrotate configs

**Сюжет:**
**КАТАСТРОФА (3:47 AM):** Звонок Анны: *"Атака Крылова! База удалена! 4.3 GB данных!"* Макс в панике звонит Liisa. Она спокойна: *"Дыши. Три вопроса: когда последний backup? где хранится? ты проверял целостность?"* Макс не знает ни одного ответа. Liisa: *"Классика. Untested backup = no backup."* Встреча в e-Residency office, 04:10. Командный центр. Krylov был внутри 72 часа — incremental backups скомпрометированы. Нужен full backup недельной давности. Restore 4.2 GB, checksums совпадают. 06:30: *"УСПЕХ. Данные восстановлены."* Liisa учит Макса: 3-2-1-T rule, systemd timers, persistent scheduling, disaster recovery testing. **Урок:** "Untested backup = no backup. Test restore every month."

---

## 🎯 Навыки Season 3

После Season 3 вы сможете:

✅ **Управлять пользователями и группами**
✅ **Настраивать permissions (chmod/chown), ACL, PAM**
✅ **Конфигурировать sudo безопасно через `/etc/sudoers.d/`**
✅ **Управлять процессами и signals**
✅ **Создавать systemd services с security hardening**
✅ **Настраивать systemd timers (persistent scheduling)**
✅ **Работать с дисками, LVM, fstab, disk monitoring**
✅ **Настраивать backup стратегии (3-2-1-T rule)**
✅ **Автоматизировать через systemd + logrotate**
✅ **Восстанавливать данные после инцидента (disaster recovery)**
✅ **Думать как sysadmin: least privilege, defense in depth**

---

## 🔗 Связь с другими сезонами

**From Season 1-2:**
- Bash scripting → automation для user management
- Text processing → анализ логов systemd
- Networking → rsync backup через SSH

**To Season 4-8:**
- Users/permissions → Docker containers, Kubernetes RBAC
- Systemd services → microservices orchestration
- LVM → cloud storage, Kubernetes persistent volumes
- Backup → CI/CD, disaster recovery в production

**Философия:** System Administration — это фундамент. Без понимания users, processes, disks невозможно администрировать cloud/containers/Kubernetes.

**Type B Approach (после рефакторинга v0.4.5.9-12):**
Season 3 использует **Type B** подход — акцент на **конфигурирование системы**, а не bash scripting:
- Episode 09: Конфигурирование через `/etc/sudoers.d/`, `/etc/security/limits.conf`, PAM
- Episode 10: Настройка systemd units с security hardening
- Episode 11: Конфигурирование `/etc/fstab` + systemd disk monitoring
- Episode 12: Systemd timers + logrotate (40% bash, 60% configs)

**Правило:** Используй готовые инструменты (systemd, PAM, logrotate), не переписывай их bash скриптами.

---

## 🌍 Атмосфера Season 3

### Санкт-Петербург:
- **Визуально:** Белые ночи (2:00 AM — светло), каналы, старые здания ЛЭТИ
- **Звуково:** Тишина ночи, редкие машины, гудение серверов в лаборатории
- **Эмоционально:** Академическая традиция, Unix wisdom, спокойная методичность
- **Цитата:** Андрей: *"В мои времена не было Google. Был man и мозг. Читай man pages."*

### Таллин:
- **Визуально:** Средневековый Old Town + современный tech hub, контраст
- **Звуково:** Туристы в Old Town днём, тишина в tech centre ночью
- **Эмоционально:** Эффективность, zero bullshit, работа state-level infrastructure
- **Цитата:** Kristjan: *"Эстония — beta test для цифрового государства. Ошибки недопустимы."*

---

## 🚀 Мотивация

**Почему Season 3 важен?**

System Administration — это **контроль над системой**. После взлома сервера Виктор понял: безопасность начинается с правильного администрирования.

**Андрей Волков:** *"Можно знать все инструменты, но если не понимаешь принципы — ты просто нажимаешь кнопки. Sysadmin — это философия."*

Season 3 учит не просто командам, а **системному мышлению**:
- Принцип наименьших привилегий (least privilege)
- Глубокая защита (defense in depth)
- Надёжность через резервирование
- Автоматизация рутины
- Тестирование восстановления

**Макс после Season 3:** *"Теперь я понимаю, почему Крылов смог проникнуть. И знаю, как это предотвратить."*

---

## 📖 Рекомендации по прохождению

### Для новичков:
1. **Читайте man pages:** `man useradd`, `man chmod`, `man systemctl`
2. **Тестируйте на VM/контейнере:** не на production!
3. **Делайте backup перед изменениями**
4. **Используйте LILITH для вопросов**

### Для опытных:
1. **Практикуйте production scenarios:** что если disk переполнен? что если база удалена?
2. **Изучайте security implications:** SUID exploits, sudo misconfigurations
3. **Автоматизируйте:** создайте Ansible playbooks для user management
4. **Читайте deeper:** systemd architecture, LVM internals

---

## ⚠️ Важные напоминания

### Security:
- ⚠️ **НИКОГДА не давайте полный sudo всем**
- ⚠️ **Проверяйте /etc/sudoers через visudo** (защита от syntax errors)
- ⚠️ **Используйте `/etc/sudoers.d/` для модульности**
- ⚠️ **Permissions на /etc/shadow должны быть 640 или 600**
- ⚠️ **Systemd services: включайте security hardening** (NoNewPrivileges, ProtectSystem)
- ⚠️ **Systemd timers: используйте Persistent=true** (не пропустите запуски)
- ⚠️ **Тестируйте backup recovery, а не только backup creation**
- ⚠️ **"Untested backup = no backup"** — тестируйте restore каждый месяц

### LILITH подход:
- "Root — это оружие. Используй мудро."
- "Процессы не врут про PID. Но врут про имя."
- "Диски как жизнь. Места всегда мало."
- "Untested backup = no backup. Test restore every month."
- "Systemd timers > cron. Persistent = надёжность."
- "Используй готовые инструменты. Не переписывай systemd bash скриптом."

---

## 🎓 Итог Season 3

После прохождения Season 3 Макс:
- ✅ Понимает users/groups/permissions на глубоком уровне
- ✅ Может настроить systemd services для production (hardening, resource limits)
- ✅ Управляет дисками через LVM без downtime
- ✅ Настроил backup систему с systemd timers + logrotate
- ✅ Протестировал disaster recovery (emergency restore в 3:47 AM!)
- ✅ Готов к DevOps (Season 4) и Security (Season 5)

Виктор: *"Хорошая работа. Теперь наши системы защищены. Едем в Амстердам — DevOps следующий шаг."*

**LILITH:** *"Ты научился контролировать систему. Но система — это лишь инструмент. Следующий шаг — автоматизация."*

---

<div align="center">

**Next:** [Season 4: DevOps & Automation](../season-04-devops-automation/) → Amsterdam 🇳🇱 + Berlin 🇩🇪

**"Root — это не привилегия. Это ответственность."** — Андрей Волков

</div>

