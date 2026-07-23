# KERNEL SHADOWS: Учебный план

## 📚 Структура: 8 Сезонов • 32 Эпизода • ~120-160 часов

**KERNEL SHADOWS** — исчерпывающий курс по Linux для:
- 🔧 **Системных администраторов** — конфигурация, управление, troubleshooting
- 🚀 **DevOps инженеров** — Docker, Kubernetes, CI/CD, IaC
- 🔐 **Пентестеров и белых хакеров** — Kali tools, OWASP, forensics
- 🌐 **Сетевых инженеров** — TCP/IP, DNS, VPN, firewall
- 🤖 **Embedded разработчиков** — Raspberry Pi, IoT, UART/I2C/SPI
- 💾 **Database администраторов** — SQL, performance tuning, backup

> **См. также:**
> - [SCENARIO.md](SCENARIO.md) — полный сценарий операции
> - [CHARACTERS.md](CHARACTERS.md) — детальные биографии всех персонажей
> - [LOCATIONS.md](LOCATIONS.md) — описания всех локаций

---

## 🌍 География курса

**Принцип:** Каждый сезон = новая локация с уникальной атмосферой и tech культурой.

**Маршрут Max Sokolov:**
1. **Season 1:** Новосибирск, Россия 🇷🇺 — домашний comfort zone
2. **Season 2:** Москва 🇷🇺 → Стокгольм, Швеция 🇸🇪 — первый международный опыт
3. **Season 3:** Санкт-Петербург 🇷🇺 → Таллин, Эстония 🇪🇪 — Unix традиции + e-Government
4. **Season 4:** Амстердам 🇳🇱 → Берлин, Германия 🇩🇪 — DevOps + hacker culture
5. **Season 5:** Цюрих + Женева, Швейцария 🇨🇭 — banking security + CERN
6. **Season 6:** Шэньчжэнь, Китай 🇨🇳 — hardware Silicon Valley, embedded Linux
7. **Season 7:** Рейкьявик, Исландия 🇮🇸 — production infrastructure, последний рубеж
8. **Season 8:** Глобальная 🌐 — финальная битва во всех локациях

**Всего:** 8+ стран, 35,000+ км, 60 дней, 27 персонажей

---

## SEASON 1: SHELL & FOUNDATIONS
**Тема:** Основы Ubuntu Linux и работа с терминалом
**Локация:** 🇷🇺 Новосибирск, Россия (Академгородок)
**Время:** 12-15 часов (дни 2-8 операции)
**Сложность:** ⭐☆☆☆☆

**Технологии:**
- 📝 Bash scripting (automation)
- 📄 Text files (.txt, .log)
- ⚙️ Basic configs (/etc/hosts, bashrc)
- 🔍 Regex (grep, awk, sed)

**Контекст:**
Max работает удалённо из дома в Академгородке. Сибирская зима, -20°C, тишина снежного леса за окном. Домашний home lab (Dell PowerEdge server, Raspberry Pi). Встречи с локальными сисадминами в кафе "Под Интегралом".

### Episode 01: Terminal Awakening
**Тема:** Первые шаги в терминале
**Время:** 3-4ч
**Миссия:** Viktor активирует вас. Первое задание — освоить терминал.

**Теория:**
- Что такое терминал, shell, bash
- Структура файловой системы Linux (/, /home, /etc, /var)
- Основные команды: `ls`, `cd`, `pwd`, `mkdir`, `rm`, `cp`, `mv`
- Навигация: абсолютные и относительные пути
- Man pages: `man`, `--help`

**Практика:**
- Найти скрытый файл Viktor в `/home/student/.secrets/`
- Создать структуру папок для операции
- Расшифровать сообщение через навигацию по директориям

**Артефакты:**
- `briefing.txt` от Viktor
- Скрытые файлы `.secret_message`
- Структура папок как "карта" операции

**Сюжет:**
- **Локация:** Квартира Max в Академгородке (home lab)
- Viktor (видеозвонок): "Добро пожаловать в операцию. Начнём с основ. Работай удалённо."
- LILITH активируется: "Я LILITH. Твой проводник в тенях. Покажи, на что ты способен."
- Первое задание: найти координаты сервера Viktor в скрытых файлах
- **Атмосфера:** Тишина сибирской зимы, гудение домашнего сервера, кофе и терминал

---

### Episode 02: Shell Scripting Basics
**Тема:** Bash скрипты и автоматизация
**Время:** 3-4ч
**Миссия:** Автоматизировать рутинные задачи через скрипты.
**Персонаж:** Sergey Ivanov (локальный ментор по скриптингу)

**Теория:**
- Что такое shell script
- Shebang `#!/bin/bash`
- Переменные: `VAR="value"`, `$VAR`, `${VAR}`
- Условия: `if`, `[[ ]]`, `test`
- Циклы: `for`, `while`
- Функции
- Exit codes: `$?`, `exit 0`

**Практика:**
- Написать скрипт для проверки статуса серверов
- Автоматизировать backup файлов
- Создать `monitor.sh` для логирования событий

**Артефакты:**
- `servers.txt` — список серверов для проверки
- `backup_template.sh` — шаблон скрипта
- Логи событий

**Сюжет:**
- **Локация:** Кафе "Под Интегралом" (встреча с Sergey)
- Sergey Ivanov: "Знал твоего отца. Он тоже любил автоматизацию. Покажу тебе старую школу скриптинга."
- Dmitry Orlov (видеозвонок): "Мы не можем проверять 50 серверов вручную. Скрипты."
- Задача: скрипт, который проверяет доступность серверов каждые 5 минут
- Sergey: "В мои времена не было StackOverflow. Был man и мозг. Читай man, Макс."
- LILITH: "Автоматизация — это не лень. Это эффективность. Learn the difference."
- **Атмосфера:** Студенческое кафе, плакаты с формулами, Wi-Fi, снег за окном

---

### Episode 03: Text Processing Masters
**Тема:** Обработка текста (grep, awk, sed, pipes)
**Время:** 3-4ч
**Миссия:** Анализировать огромные логи для поиска следов Krylov.
**Персонаж:** Olga Petrova (data scientist, эксперт по логам)

**Теория:**
- Pipes и redirects: `|`, `>`, `>>`, `<`, `2>`
- `grep`: поиск паттернов, regex basics
- `awk`: обработка колонок, filtering
- `sed`: замена текста, stream editing
- `cut`, `sort`, `uniq`, `wc`
- `find` и `xargs`

**Практика:**
- Найти в логах (10K+ строк) IP адреса атак
- Извлечь TOP-10 атакующих IP
- Отфильтровать ложные срабатывания
- Создать отчёт для Anna Kovaleva

**Артефакты:**
- `access.log` (100MB+) — логи сервера
- `suspicious_ips.txt` — база известных угроз
- `report_template.txt`

**Сюжет:**
- **Локация:** Квартира Max + встреча с Olga (НГУ campus)
- Anna Kovaleva (видеозвонок): "Нас атаковали вчера в 03:47. Найди IP атакующих в логах."
- Лог огромный (100MB+) — Max в растерянности
- Olga Petrova: "10 миллионов строк? Это не много. awk справится за секунду. Смотри."
- Найдено: 185.220.101.47 (Tor exit node) + 10 других IP
- LILITH: "Логи не врут. Люди — врут."
- **Атмосфера:** НГУ, лаборатория с Linux серверами, научная традиция Unix

---

### Episode 04: Package Management
**Тема:** Управление пакетами (apt, dpkg, snap)
**Время:** 2-3ч
**Миссия:** Установить необходимые инструменты для операции.

**Теория:**
- APT: `apt update`, `apt upgrade`, `apt install`
- DPKG: `dpkg -i`, `dpkg -l`, `dpkg -r`
- Snap packages: `snap install`, `snap list`
- Репозитории: `/etc/apt/sources.list`
- PPAs (Personal Package Archives)
- Dependencies hell и как его решить

**Практика:**
- Установить набор инструментов: `nmap`, `tcpdump`, `wireshark`, `docker`
- Создать скрипт `install_toolkit.sh`
- Решить конфликт зависимостей

**Артефакты:**
- `required_tools.txt` — список необходимого ПО
- `install_toolkit.sh` — автоматизация установки
- `sources.list.backup` — бэкап репозиториев

**Сюжет:**
- **Локация:** Квартира Max (home lab)
- Viktor (видеозвонок): "Тебе нужны инструменты. Вот список."
- Конфликт: `docker` требует `containerd`, но он конфликтует с установленным
- LILITH: "Dependencies как семья. Не выбираешь их, но приходится с ними жить."
- **Результат:** Viktor доволен. Приглашает Max в Москву для основной операции.
- Max: *"Я справился. Может быть, я готов к чему-то большему..."*

**Итог Season 1:** Max доказал компетентность. Все навыки будут интегрированы в следующих сезонах. Операция переходит на следующий уровень.

---

## SEASON 2: NETWORKING
**Тема:** Сети TCP/IP, DNS, VPN, SSH
**Локации:** 🇷🇺 Москва → 🇸🇪 Стокгольм, Швеция
**Время:** 15-18 часов (дни 9-16 операции)
**Сложность:** ⭐⭐☆☆☆

**Технологии:**
- 🌐 Network configs (/etc/network/interfaces, /etc/hosts, resolv.conf)
- 🔐 SSH configs (sshd_config, authorized_keys)
- 🔥 Firewall rules (ufw, iptables)
- 📦 Network packets (tcpdump, Wireshark .pcap)
- 🔑 SSL certificates (openssl)
- 🐍 Python (network automation, API)

**Контекст:**
Алекс: *"Макс, у нас проблема. Крылов знает о нас. Приезжай в Москву."* Макс впервые выезжает из Новосибирска. Москва — штаб-квартира Виктора, ЦОД "Москва-1", напряжение. Затем — первый раз за границей: Стокгольм. Холодная скандинавская эстетика, Bahnhof nuclear bunker datacenter. Культурный шок × 2.

### Episode 05: TCP/IP Fundamentals
**Тема:** Основы сетей, модель TCP/IP
**Время:** 4-5ч
**Миссия:** Понять, как работают сети, чтобы защитить их.

**Теория:**
- Модель OSI vs TCP/IP
- IP адреса: IPv4, IPv6, subnetting
- MAC адреса, ARP
- TCP vs UDP
- Порты и сокеты
- `ip`, `ifconfig`, `netstat`, `ss`

**Практика:**
- Определить IP адрес сервера Viktor
- Проверить открытые порты: `netstat -tuln`
- Настроить статический IP
- Ping и traceroute для диагностики

**Артефакты:**
- `network_map.txt` — карта сети операции
- Список серверов с IP
- Результаты traceroute к серверу Viktor

**Сюжет:**
- **Локация:** Москва, ЦОД "Москва-1"
- Max прилетает в Москву. Первая встреча с командой (Alex, Anna, Dmitry).
- Алекс Соколов: "Krylov прослушивает трафик. Нужно понять сеть. Начнём с основ."
- Задача: определить маршрут до сервера Viktor (traceroute)
- Обнаружено: 3 промежуточных узла, последний в Москве
- LILITH: "Каждый packet рассказывает историю. Научись слушать."
- **Атмосфера:** Гудение серверов, холодный воздух кондиционеров, напряжение (Krylov где-то рядом)
- **Личное:** Max впервые видит профессиональный ЦОД. Впечатлён и напуган.

---

### Episode 06: DNS & Name Resolution
**Тема:** DNS, dig, nslookup, /etc/hosts
**Время:** 3-4ч
**Миссия:** Настроить DNS для скрытия инфраструктуры.
**Персонаж:** Erik Johansson (шведский network engineer)
**Локация:** 🇸🇪 Стокгольм, Швеция (Bahnhof Pionen Datacenter)

**Теория:**
- Как работает DNS
- A, AAAA, CNAME, MX, TXT записи
- `dig`, `nslookup`, `host`
- `/etc/hosts` и `/etc/resolv.conf`
- DNS spoofing и защита

**Практика:**
- Настроить локальный DNS через `/etc/hosts`
- Проверить DNS записи сервера Viktor
- Обнаружить DNS spoofing атаку от Krylov

**Артефакты:**
- `dns_records.txt` — записи серверов операции
- `hosts.backup` — бэкап перед изменениями
- `spoofed_dns.log` — лог атаки

**Сюжет:**
- Viktor: *"DNS атаки усиливаются. Летишь в Стокгольм. Erik Johansson встретит."*
- Max прилетает в Швецию. Первый раз за границей. Культурный шок.
- **Erik** (встреча в Arlanda airport): "Welcome to Sweden. Viktor says you're good. We'll see."
- **Локация:** Bahnhof Pionen — бывшее ядерное бомбоубежище 30 метров под землёй
- **Атмосфера:** Футуристичный дизайн внутри скалы, искусственный водопад, неоновое освещение, холод
- Anna (видеозвонок): "DNS запросы идут не туда. Кто-то подменяет ответы."
- Erik: *"In Sweden we take privacy seriously. After WikiLeaks, Bahnhof refused government pressure. DNS over TLS — mandatory."*
- Анализ: DNS cache poisoning от 185.220.101.47
- Решение: DoT (DNS over TLS) + DNSSEC
- **Личное:** Max впечатлён: *"Серверы в ядерном бункере. Это другой уровень."*

---

### Episode 07: Firewalls (iptables/ufw)
**Тема:** Файрволы для защиты периметра
**Время:** 4-5ч
**Миссия:** Защитить серверы от DDoS атаки Krylov.
**Локация:** Москва (возврат из Стокгольма)

**Теория:**
- Netfilter и iptables
- Chains: INPUT, OUTPUT, FORWARD
- Правила: ACCEPT, DROP, REJECT
- UFW (Uncomplicated Firewall) — wrapper
- `nftables` — новое поколение

**Практика:**
- Настроить UFW: закрыть все порты кроме SSH (22)
- Создать правила iptables для защиты от DDoS
- Rate limiting: `iptables -m limit`
- Логирование попыток атак

**Артефакты:**
- `firewall_rules.sh` — скрипт настройки
- `attack.log` — лог DDoS атаки (100K+ пакетов)
- `blocked_ips.txt` — автоматически забаненные IP

**Сюжет:**
- Max возвращается в Москву из Стокгольма
- **INCIDENT:** DDoS атака на ЦОД "Москва-1" — 50K пакетов/сек
- Алекс: "Файрвол. Сейчас. У нас 5 минут до падения сервера."
- Паника. Max применяет знания. UFW + iptables rate limiting.
- Решение: rate limiting спасает сервер
- LILITH: "Firewalls как вышибалы. Хорошие знают, кого впускать."
- **Twist:** Krylov оставляет сообщение в логах: *"Соколов, передай брату — я найду вас. Обоих."*
- **Атмосфера:** Напряжение. Krylov близко. Паранойя нарастает.

---

### Episode 08: VPN & SSH Tunneling
**Тема:** VPN, SSH туннели, безопасные соединения
**Время:** 4-5ч
**Миссия:** Настроить VPN для безопасной коммуникации команды.
**Персонаж:** Katarina Lindström (криптография, Stockholm University)
**Локация:** Москва → Стокгольм → Цюрих (VPN сервер)

**Теория:**
- Что такое VPN, зачем нужен
- OpenVPN vs WireGuard
- SSH tunneling: local, remote, dynamic
- SSH config: `~/.ssh/config`
- SSH keys: `ssh-keygen`, `ssh-copy-id`

**Практика:**
- Настроить OpenVPN сервер
- Создать конфиги для команды (Viktor, Alex, Anna, Dmitry)
- SSH tunnel для доступа к закрытому серверу
- Автоматизировать подключение через скрипт

**Артефакты:**
- `vpn_server.conf` — конфиг OpenVPN
- `client_*.ovpn` — конфиги для клиентов
- `ssh_tunnel.sh` — автоматизация SSH туннеля

**Сюжет:**
- Алекс: "Krylov перехватывает трафик. Все коммуникации через VPN. Сейчас."
- Viktor: "У меня есть сервер в Цюрихе. Настрой его как VPN шлюз."
- Max возвращается в Стокгольм, консультация с **Katarina Lindström** (Stockholm University)
- Katarina: "Encryption is mathematics. Mathematics doesn't lie. Unlike people. SSL/TLS для VPN — обязательно."
- Настройка: OpenVPN сервер в Цюрихе, клиенты для команды
- Результат: Безопасная коммуникация через швейцарский сервер
- LILITH: "Шифрование — это не паранойя. Это здравый смысл."
- **Личное:** Alex открывается Max о прошлом: *"Я покинул ФСБ из-за Krylov. Он фабриковал дела. Я отказался. Теперь он охотится."*

**Итог Season 2:** Сетевая инфраструктура защищена. Max побывал в 2 странах. Понимает масштаб операции. Навыки networking будут применяться во всех следующих сезонах.

---

## SEASON 3: SYSTEM ADMINISTRATION
**Тема:** Администрирование систем, процессы, логи
**Локации:** 🇷🇺 Санкт-Петербург → 🇪🇪 Таллин, Эстония
**Время:** 15-18 часов (дни 17-24 операции)
**Сложность:** ⭐⭐⭐☆☆

**Технологии:**
- ⚙️ systemd units (.service files)
- ⏰ Crontab (cron.d/, crontab -e)
- 📁 System configs (fstab, sudoers, sysctl.conf)
- 📊 journald logs (journalctl)
- 💾 Backup formats (tar, rsync, dd)
- 🗄️ SQL (MySQL/PostgreSQL admin)
- 🐍 Python (advanced automation)

**Контекст:**
Кризис: один из серверов взломан (backdoor от Krylov). Anna: *"Нужен полный контроль над системами."* Max едет в СПб (Unix старая школа), затем в Таллин (e-Government expertise). Белые ночи СПб, средневековый Таллин, контраст истории и технологий.

### Episode 09: Users & Permissions
**Тема:** Пользователи, группы, права доступа
**Время:** 4-5ч
**Миссия:** Настроить безопасный доступ для команды операции.
**Персонаж:** Andrei Volkov (ex-university professor, СПб)
**Локация:** 🇷🇺 Санкт-Петербург (ЛЭТИ, Васильевский остров)

**Теория:**
- Users: `useradd`, `usermod`, `userdel`
- Groups: `groupadd`, `usermod -aG`
- Permissions: `chmod`, `chown`, `umask`
- SUID, SGID, Sticky bit
- `sudo` и `/etc/sudoers`
- ACL (Access Control Lists): `setfacl`, `getfacl`

**Практика:**
- Создать учётные записи для команды
- Настроить sudo для Alex (только network команды)
- Ограничить доступ Anna к логам (read-only)
- Настроить ACL для shared папки

**Артефакты:**
- `team_users.sh` — скрипт создания пользователей
- `sudoers.d/alex` — ограниченный sudo
- `permissions_audit.txt` — проверка доступов

**Сюжет:**
- **Локация:** СПб, ЛЭТИ (университет), белые ночи
- Max встречается с **Andrei Volkov** (бывший преподаватель Unix)
- Andrei: "Root access как заряженный пистолет. Не давай его кому попало. Это я студентам 20 лет говорю."
- Viktor: "На сервере будут работать 5 человек. Каждому свой уровень доступа."
- Проблема: Alex нужен sudo для networking, но НЕ для всего
- Andrei обучает правильной настройке permissions, sudo, ACL
- LILITH: "Root access как заряженный пистолет. Не давай его кому попало."
- **Атмосфера:** Белые ночи (не спится), каналы СПб, университетские традиции Unix

---

### Episode 10: Processes & Systemd
**Тема:** Процессы, сервисы, systemd, cron
**Время:** 4-5ч
**Миссия:** Настроить мониторинг процессов и автоматизацию.

**Теория:**
- Процессы: `ps`, `top`, `htop`, `pgrep`, `pkill`
- Signals: `kill -SIGTERM`, `kill -9`, `killall`
- Systemd: `systemctl`, unit files
- Services: `start`, `stop`, `restart`, `enable`, `disable`
- Cron: `crontab -e`, syntax
- Journalctl: `journalctl -u service`

**Практика:**
- Создать systemd service для мониторинга (`monitor.service`)
- Настроить cron для backup каждый час
- Убить зависший процесс (симуляция атаки)
- Анализировать логи через journalctl

**Артефакты:**
- `monitor.service` — systemd unit
- `backup_cron.sh` — скрипт для cron
- `process_attack.log` — лог подозрительного процесса

**Сюжет:**
- Anna: "На сервере запущен подозрительный процесс. PID 6623. Разберись."
- Анализ: процесс `sshd_backdoor` (маскировка под sshd)
- Решение: `kill -9`, проверка systemd services
- LILITH: "Процессы не врут про свой PID. Но врут про имя."

---

### Episode 11: Disk Management & LVM
**Тема:** Управление дисками, LVM, RAID, fstab
**Время:** 4-5ч
**Миссия:** Расширить дисковое пространство для логов.
**Персонаж:** Kristjan Tamm (IT-архитектор e-Government, Эстония)
**Локация:** 🇪🇪 Таллин, Эстония (e-Estonia Briefing Centre)

**Теория:**
- Диски: `df -h`, `du -sh`, `lsblk`, `fdisk`
- Partitions: создание, удаление, форматирование
- LVM: Physical Volume, Volume Group, Logical Volume
- `pvcreate`, `vgcreate`, `lvcreate`, `lvextend`
- RAID: типы (0, 1, 5, 10), `mdadm`
- `/etc/fstab`: монтирование при загрузке

**Практика:**
- Добавить новый диск к серверу
- Создать LVM: расширяемый том для `/var/log`
- Настроить автоматическое монтирование в fstab
- (Опционально) Настроить RAID1 для резервирования

**Артефакты:**
- `lvm_setup.sh` — автоматизация LVM
- `fstab.backup` — бэкап перед изменениями
- `disk_usage_report.txt`

**Сюжет:**
- **Локация:** Таллин (Old Town + e-Estonia Briefing Centre)
- Max в Таллине. Средневековый город, но самая цифровая нация мира.
- **Kristjan Tamm:** "В Эстонии всё цифровое. Вся страна работает на этих серверах. Если они падают — страна останавливается. LVM и резервирование обязательны."
- Anna: "Логи заполнили диск. `/var/log` 95%. Нужно больше места. СРОЧНО."
- Viktor: "У нас есть новый диск 500GB. Добавь его через LVM."
- Kristjan показывает X-Road infrastructure (государственная data exchange layer)
- Решение: LVM extend без downtime (как в e-Government)
- LILITH: "Диски как жизнь. Места всегда мало."
- **Атмосфера:** Средневековые башни + fiber optic. История + будущее.

---

### Episode 12: Backup & Recovery
**Тема:** Резервное копирование и восстановление
**Время:** 3-4ч
**Миссия:** Спасти данные после атаки Krylov.
**Персонаж:** Liisa Kask (backup engineer, ex-Skype, Таллин)
**Локация:** 🇪🇪 Таллин

**Теория:**
- Стратегии backup: full, incremental, differential
- Инструменты: `rsync`, `tar`, `dd`
- Remote backup: `rsync` через SSH
- Автоматизация: cron + rsync
- Восстановление: как не потерять данные

**Практика:**
- Настроить rsync backup на удалённый сервер
- Создать incremental backup скрипт
- Симуляция: "случайно удалили базу данных" — восстановление
- Тестирование восстановления (disaster recovery)

**Артефакты:**
- `backup.sh` — скрипт резервного копирования
- `restore.sh` — скрипт восстановления
- `backup_log.txt` — история бэкапов

**Сюжет:**
- **КАТАСТРОФА:** Атака Krylov — сервер скомпрометирован, база данных удалена
- Паника. Max в отчаянии.
- **Liisa Kask:** "Backup'ы как страховка. У меня 3 копии всего. Скайп научил параноидности. У нас есть backup?"
- Viktor: "У нас есть backup с вчерашнего дня. Восстанавливай."
- Liisa обучает rsync, disaster recovery testing
- Процесс восстановления — успешно
- LILITH: "Backup'ы как страховка. Надеешься, что не понадобятся, но рад, что есть."
- **Атмосфера:** Напряжение, но облегчение. Backup спас операцию.

**Итог Season 3:** Max понимает важность систем администрирования. СПб и Таллин показали разные подходы — оба ценны. Навыки sysadmin будут применяться во всех последующих сезонах.

---

## SEASON 4: DEVOPS & AUTOMATION
**Тема:** Docker, Kubernetes, CI/CD, Infrastructure as Code
**Локации:** 🇳🇱 Амстердам → 🇩🇪 Берлин, Германия
**Персонажи:** Hans Müller (CCC), Sophie van Dijk (Docker), Klaus Schmidt (Ansible)
**Время:** 18-22 часа (дни 25-32 операции)
**Сложность:** ⭐⭐⭐⭐☆

**Технологии:**
- 🐳 YAML (Docker Compose, Kubernetes, Ansible, CI/CD)
- 📦 Dockerfile & docker-compose.yml
- 🔧 Makefile (build automation)
- 🔑 Environment files (.env, EnvironmentFile)
- 📝 Templates (Jinja2 для Ansible)
- 🌳 Git (.gitignore, hooks, workflows)
- 🚀 CI/CD configs (.gitlab-ci.yml, GitHub Actions)
- 📊 JSON (API, configs)

**Контекст:**
Dmitry: *"50 серверов вручную? Нет. Docker, Ansible, CI/CD. Едем в Европу — Амстердам и Берлин, DevOps столицы."* Max знакомится с европейской DevOps культурой: pragmatic Dutch approach (Amsterdam) + hacker culture (Berlin CCC). Контейнеризация, автоматизация, CI/CD pipeline. Supply chain attack twist — кто-то предатель?

### Episode 13: Git & Version Control
**Тема:** Git для инфраструктуры как кода
**Время:** 4-5ч
**Миссия:** Организовать репозиторий для конфигов операции.

**Теория:**
- Git basics: `init`, `add`, `commit`, `push`, `pull`
- Branches: `branch`, `checkout`, `merge`
- Workflows: feature branch, GitFlow
- `.gitignore` — что НЕ коммитить (пароли!)
- Git для infrastructure: конфиги, скрипты

**Практика:**
- Создать Git репозиторий для конфигов
- Branching strategy для команды
- Симуляция: конфликт merge и разрешение
- Secrets management: НЕ коммитить пароли

**Артефакты:**
- `configs/` — репозиторий конфигов
- `.gitignore` — правила игнорирования
- `workflow.md` — процесс для команды

**Сюжет:**
- Dmitry Orlov: "Мы не можем управлять конфигами через копирование файлов. Git."
- Проблема: кто-то закоммитил пароль от сервера Viktor в репозиторий
- Решение: `git filter-branch`, secrets в отдельном хранилище
- LILITH: "Version control — это не опция. Это выживание."

---

### Episode 14: Docker Basics
**Тема:** Контейнеризация с Docker
**Время:** 5-6ч
**Миссия:** Упаковать инструменты MOONLIGHT в Docker контейнеры.

**Теория:**
- Что такое контейнеры vs VM
- Docker: images, containers, Dockerfile
- Команды: `docker run`, `docker build`, `docker ps`
- Docker Hub: `docker pull`, `docker push`
- Volumes и networking
- Docker Compose для multi-container

**Практика:**
- Создать Dockerfile для `moonlight_decoder` (из MOONLIGHT Season 1)
- Запустить контейнер с Ubuntu + необходимые инструменты
- Docker Compose: web + database + monitoring
- Оптимизация размера образа (multi-stage build)

**Артефакты:**
- `Dockerfile` для инструментов
- `docker-compose.yml` для инфраструктуры
- `container_logs/` — логи контейнеров

**Сюжет:**
- Dmitry: "Нам нужно развернуть инструменты на 50 серверах. Docker решит это."
- Viktor: "Упакуй `crypto_toolkit` (MOONLIGHT S4) в контейнер."
- Результат: Контейнер запускается на любом сервере за 10 секунд
- LILITH: "Контейнеры как тетрис. Либо всё идеально складывается, либо ничего не работает."

---

### Episode 15: CI/CD Pipelines
**Тема:** Автоматизация развёртывания
**Время:** 5-6ч
**Миссия:** Настроить CI/CD для автоматических обновлений.

**Теория:**
- Что такое CI/CD
- GitHub Actions / GitLab CI
- Pipeline stages: build, test, deploy
- Автоматизация тестов
- Blue-Green deployment, Canary releases

**Практика:**
- Создать GitHub Actions workflow
- Автоматическое тестирование при commit
- Автодеплой на staging сервер
- Rollback при ошибках

**Артефакты:**
- `.github/workflows/ci.yml` — pipeline
- `deploy.sh` — скрипт развёртывания
- `test_results.xml` — результаты автотестов

**Сюжет:**
- Dmitry: "Мы обновляем код 5 раз в день. Это нужно автоматизировать."
- Проблема: кто-то задеплоил broken code на production
- Решение: CI/CD с тестами — broken code не проходит
- LILITH: "Автоматизация — не про замену людей. Это про освобождение от скучных задач."

---

### Episode 16: Ansible & IaC
**Тема:** Infrastructure as Code с Ansible
**Время:** 5-6ч
**Миссия:** Автоматизировать настройку 50 серверов одной командой.

**Теория:**
- Infrastructure as Code концепция
- Ansible: playbooks, roles, inventory
- YAML syntax
- Идемпотентность операций
- Ansible для конфигурации vs Terraform для provisioning

**Практика:**
- Создать Ansible playbook для настройки серверов
- Inventory: список всех серверов операции
- Роли: webserver, database, monitoring
- Запуск playbook на 50 серверах одновременно

**Артефакты:**
- `playbooks/setup_servers.yml` — главный playbook
- `inventory/hosts.ini` — список серверов
- `roles/` — переиспользуемые роли

**Сюжет:**
- Viktor: "Нам нужны ещё 50 серверов. Настроены одинаково. Завтра."
- Dmitry: "Ansible справится за 10 минут."
- Результат: 50 серверов настроены, протестированы, готовы
- LILITH: "Infrastructure as Code — это не магия. Это просто очень хорошая автоматизация."

**Итог Season 4:** DevOps практики освоены. Автоматизация развёртывания работает. Навыки Git, Docker, CI/CD, Ansible будут применяться в production (Season 7-8).

---

## SEASON 5: SECURITY & PENTESTING
**Тема:** Offensive & Defensive Security
**Локации:** 🇨🇭 Цюрих + Женева, Швейцария
**Персонажи:** Eva Zimmerman (UBS security), Marcus Weber (финансист), Jean-Pierre Dubois, Dr. Heinrich Bauer (CERN), Isabella Rossi (Interpol)
**Время:** 18-22 часа (дни 33-40 операции)
**Сложность:** ⭐⭐⭐⭐⭐

**Технологии:**
- 🔐 Kali tools (nmap, metasploit, burp suite)
- 🔑 Certificates & Keys (SSL/TLS, SSH, GPG)
- 📦 Network packets (tcpdump, Wireshark analysis)
- 🔍 Regex (log analysis, pattern matching)
- 📊 JSON (API security testing)
- 🐍 Python (exploit scripts, automation)
- 🛡️ WAF configs (ModSecurity)
- 🔒 Hardening configs (SELinux, AppArmor, fail2ban)

**Контекст:**
Алекс: *"Krylov использует zero-day. Едем в Швейцарию — лучшие security эксперты."* Цюрих — banking security (UBS underground datacenter), Женева — CERN + Interpol. Banking paranoia, максимальный уровень security. **КРИЗИС:** APT атака на Viktor сервер (backdoor, rootkit). Isabella Rossi помогает с forensics. Marcus Weber подозревается в предательстве (red herring). Напряжение maximum.

### Episode 17: Security Auditing & Vulnerability Assessment
**Тема:** Аудит безопасности и поиск уязвимостей
**Время:** 12-15ч
**Миссия:** Провести полный security audit 50+ серверов за 48 часов.
**Персонаж:** Eva Zimmerman (Swiss security researcher, ex-CERN)
**Локация:** Цюрих (UBS underground datacenter)

**Теория (8 микро-циклов):**
- Основы безопасности Linux (CIA Triad, threat modeling)
- Системный аудит — lynis
- Сканирование сети — nmap
- Контроль целостности файлов — AIDE
- Сканирование веб-уязвимостей — nikto
- Защита от вторжений — fail2ban
- База данных уязвимостей — CVE Search
- Составление отчёта об аудите

**Практика:**
- Установить все инструменты (lynis, nmap, aide, fail2ban, nikto)
- Настроить конфигурационные файлы вручную
- Запустить аудиты и сохранить результаты
- Настроить systemd timer для AIDE (НЕ bash скрипт!)
- Активировать fail2ban для SSH защиты
- Проанализировать результаты и написать отчёт

**Артефакты:**
- `configs/` — конфигурации всех инструментов
- `systemd/` — units и timers для автоматизации
- `reports/` — результаты аудитов
- `audit-report.md` — финальный отчёт

**Тип:** Configuration (Type B) — 95% Linux tools, 5% bash
**Bash:** Только простые one-liners, НЕТ сложного скрипта

**Сюжет:**
- Виктор напряжён: Алекс обнаружил подозрительную активность (SSH login attempt из Москвы)
- Анна нашла странные процессы на сервере
- Задача: полный security audit 50+ серверов за 48 часов
- Eva Zimmerman: "Banking security — это паранойя как профессия. Покажу как работают лучшие."
- Макс находит backdoor на сервере в Стокгольме — это "Новая Эра", они внутри уже 2 недели
- Backdoor закрыт, все серверы пропатчены, continuous monitoring активирован
- LILITH: "Security audit — не чеклист. Это образ мышления. Думай как атакующий."

---

### Episode 18: Penetration Testing Basics
**Тема:** Основы пентестинга и ethical hacking
**Время:** 12-15ч
**Миссия:** Провести pentest собственной инфраструктуры (ethical hacking).
**Персонаж:** Алекс Соколов (offensive security expert, ex-FSB)
**Локация:** Цюрих

**Теория:**
- Методология пентеста (reconnaissance, scanning, exploitation, post-exploitation)
- Web application security testing (burp suite, OWASP Top 10)
- SQL injection manual exploitation
- Password security testing (hydra, john the ripper)
- Metasploit Framework basics
- Vulnerability verification и exploitation
- Ethical hacking principles

**Практика:**
- Установить pentest инструменты в Ubuntu (НЕ Kali!)
- Провести web app pentest на тестовом приложении
- SQL injection manual exploitation
- Password cracking практика
- Использовать metasploit для проверки уязвимостей
- Написать детальный pentest отчёт

**Артефакты:**
- `vulnerable_app/` — тестовое веб-приложение для практики
- `scan_results/` — результаты сканирований (вручную сохранённые)
- `exploits/` — примеры найденных эксплойтов
- `pentest_report.md` — детальный отчёт о найденных уязвимостях

**Тип:** Manual Pentesting (Type B) — ручная работа с pentest tools, НЕ bash scripting

**Сюжет:**
- Алекс: "Audit показал проблемы. Теперь тестируем как атакующий. Я покажу как работал в ФСБ."
- Ethical hacking — команда тестирует свои же серверы
- Ручной pentest, каждый шаг осознанно
- Найдено: SQL injection в админке, слабые пароли, RCE через file upload
- Виктор: "Лучше мы найдём дыры, чем Крылов."
- LILITH: "Pentest — это искусство, не автоматизация. Каждая уязвимость уникальна."

---

### Episode 19: Incident Response & Forensics
**Тема:** Реагирование на инциденты, форензика
**Время:** 12-15ч
**Миссия:** Расследовать APT атаку "Новой Эры" в реальном времени.
**Персонаж:** Isabella Rossi (Interpol cybercrime unit)
**Локация:** Женева (Interpol + CERN)

**Теория:**
- Incident response процесс: Preparation, Detection, Containment, Eradication, Recovery
- Digital forensics: сбор доказательств, chain of custody
- Log analysis: auditd, journald, ELK stack (Elasticsearch/Logstash/Kibana)
- Memory forensics: Volatility framework
- Timeline reconstruction
- SIEM (Security Information and Event Management)

**Практика:**
- Настроить auditd для системного аудита
- Установить и настроить ELK stack для centralized logging
- Настроить osquery для endpoint monitoring
- Анализ скомпрометированного сервера
- Поиск backdoors и rootkits
- Составление timeline атаки

**Артефакты:**
- `/etc/audit/audit.rules` — правила auditd
- `elk/` — конфигурация ELK stack
- `osquery/` — конфигурация osquery
- `forensic_report.md` — детальный отчёт расследования
- `timeline.csv` — timeline атаки

**Тип:** Configuration (Type B) — настройка SIEM и forensics tools

**Сюжет:**
- КРИТИЧЕСКИЙ ИНЦИДЕНТ: Реальная атака "Новой Эры" происходит прямо сейчас
- Анна: "APT атака. Они внутри. Forensics. СЕЙЧАС."
- Isabella Rossi (Interpol): "Я видела их почерк. Это профессионалы. Действуем быстро."
- Расследование в реальном времени: backdoor, keylogger, data exfiltration
- Макс работает 16 часов подряд, находит все следы
- LILITH: "Forensics как работа детектива. Каждый файл — улика. Каждый timestamp — доказательство."

---

### Episode 20: Security Hardening & Best Practices
**Тема:** Системное укрепление безопасности
**Время:** 12-15ч
**Миссия:** Подготовить инфраструктуру к финальной битве (Season 8).
**Персонаж:** Dr. Heinrich Bauer (CERN security architect)
**Локация:** Женева (CERN)

**Теория:**
- Security hardening методология
- SELinux и AppArmor: mandatory access control (MAC)
- CIS Benchmarks для Ubuntu
- Kernel hardening: sysctl security parameters
- Application sandboxing
- Secure boot и TPM
- Zero Trust architecture

**Практика:**
- Baseline audit через Lynis (68/100 → 92/100)
- Создать AppArmor profiles для Apache, MySQL
- Kernel hardening через sysctl (38+ параметров)
- Применить CIS Benchmarks Level 2 (92% compliance)
- Service hardening (SSH, Apache, MySQL)
- Firewall configuration (UFW default deny)
- Автоматизация через Ansible (50 серверов за 6 часов)
- Red team validation testing (Alex)

**Артефакты:**
- `artifacts/baseline_audit/lynis_baseline.txt` — pre-hardening audit
- `artifacts/cis_benchmarks/` — CIS checklist и highlights
- `apparmor/profiles/` — production AppArmor profiles (Apache, MySQL)
- `sysctl.d/99-hardening.conf` — kernel security (ASLR, SYN cookies, etc)
- `service-configs/` — hardened configs (SSH, Apache)
- `ansible/hardening-playbook.yml` — полная автоматизация
- `hardening_report.md` — comprehensive security report

**Тип:** Configuration (Type B) — системное конфигурирование

**Сюжет:**
- Виктор: "Финальная атака близко. Нужен максимальный уровень защиты. Все 50 серверов."
- Dr. Bauer (CERN): "Мы храним данные Large Hadron Collider. Наша безопасность — paranoia level 100. Покажу как."
- Процесс: hardening всех 50 серверов через Ansible за 6 часов
- Алекс (red team): пытается взломать после hardening — защита держится
- Результат: Production-ready secure infrastructure
- LILITH: "Hardening — это не паранойя. Это подготовка к войне."
- Макс: "Я готов. Мы все готовы. Пусть приходят."

**Итог Season 5:** Security expertise достигнут. Max думает как атакующий и защищается как профессионал. Навыки pentesting и forensics критичны для финала.

---

## SEASON 6: EMBEDDED LINUX & IOT SECURITY
**Тема:** Embedded системы, IoT, дроны, hardware security
**Локация:** 🇨🇳 Шэньчжэнь, Китай
**Персонажи:** Li Wei (ex-DJI, drone expert), Chen Xiaoming (ArduPilot), Zhang Mei (IoT architect)
**Время:** 18-22 часа (дни 41-48 операции)
**Сложность:** ⭐⭐⭐⭐⭐

**Технологии:**
- 🤖 C/C++ (GPIO control, kernel modules, device drivers)
- 🐍 Python (IoT automation, MQTT security)
- 📊 JSON (MQTT payloads, configs)
- 🔧 Device configs (config.txt, device tree, secure boot)
- 📡 Device drivers и модули ядра (Episode 24; выделенная серия UART/I2C/SPI — descoped, см. §6 плана)
- 🚁 MAVLink протокол + шифрование команд
- 🔐 IoT Security (firmware reverse engineering, MQTT TLS, secure updates)
- 📝 Shell scripts (startup automation)
- ⚙️ Real-time Linux (PREEMPT_RT, low latency tuning)

**Контекст:**
Viktor: *"Нужна разведка. Дроны. Летишь в Шэньчжэнь — hardware Silicon Valley."* Max в Китае. Культурный шок × 100. Huaqiangbei electronics market — можно купить ВСЁ. Li Wei (ex-DJI) обучает embedded Linux + IoT security. Неоновый киберпанк IRL. Сборка дронов, Raspberry Pi, kernel modules, hardware hacking. **ОПАСНОСТЬ:** Krylov пытается перехватить drone во время разведки через UART exploitation — шифрование команд + secure boot спасают. Китайская слежка. Firmware reverse engineering для обнаружения backdoors в китайских чипах. Быстрый выезд после миссии. **СЛОЖНОСТЬ МАКСИМАЛЬНА:** C programming, real-time constraints, hardware protocols, IoT security — всё одновременно.

### Episode 21: Raspberry Pi & GPIO
**Тема:** Основы embedded Linux
**Время:** 4-5ч
**Миссия:** Настроить Raspberry Pi для наблюдения.

**Теория:**
- Что такое embedded Linux
- Raspberry Pi: hardware, GPIO pins
- Cross-compilation
- Device Tree
- Bootloaders: U-Boot

**Практика:**
- Установить Ubuntu на Raspberry Pi
- Подключить камеру и сенсоры через GPIO
- Написать программу на C для чтения GPIO
- Удалённый доступ через SSH

**Артефакты:**
- `gpio_control.c` — программа управления GPIO
- `camera_stream.sh` — стриминг с камеры
- `pi_config.txt` — конфигурация

**Сюжет:**
- Dmitry Orlov: "Нам нужна камера наблюдения. Raspberry Pi + Ubuntu."
- Viktor: "Установи её у здания Krylov. Скрытно."
- Результат: Live stream с камеры, скрытая установка
- LILITH: "Embedded Linux как LEGO для взрослых. Но с проводами."

---

### Episode 22: Drones & UAV Control
**Тема:** Управление беспилотниками
**Время:** 5-6ч
**Миссия:** Настроить разведывательный дрон для миссии.

**Теория:**
- UAV (Unmanned Aerial Vehicle) архитектура
- MAVLink протокол
- Автопилоты: ArduPilot, PX4
- Телеметрия: GPS, IMU, барометр
- Computer vision для навигации

**Практика:**
- Установить ArduPilot на Linux board
- Настроить MAVLink коммуникацию
- Написать скрипт для автономного полёта
- Шифрование команд управления (AES из MOONLIGHT S4)

**Артефакты:**
- `drone_control.py` — скрипт управления
- `mission_waypoints.txt` — точки маршрута
- `telemetry_log.csv` — телеметрия полёта

**Сюжет:**
- Viktor: "Нам нужна разведка базы Krylov. Дрон. Завтра."
- Dmitry: "У меня есть квадрокоптер. ArduPilot + шифрование команд."
- Миссия: автономный полёт, фото базы Krylov, возврат
- ОПАСНОСТЬ: Krylov пытается перехватить управление дроном
- Решение: AES шифрование команд (используя `crypto_toolkit` из MOONLIGHT S4)
- LILITH: "Дроны — это весело. Пока кто-то не попытается их угнать."

---

### Episode 23: IoT Security & MQTT
**Тема:** IoT-экосистема, протокол MQTT, безопасность
**Время:** 4-5ч
**Миссия:** Создать защищённую распределённую сеть датчиков.

**Теория:**
- MQTT: publish/subscribe model
- Brokers: Mosquitto
- Topics и QoS levels
- IoT security: TLS, authentication

**Практика:**
- Установить Mosquitto broker
- Подключить Raspberry Pi и датчики через MQTT
- Мониторинг в реальном времени, алерты при аномалиях

**Артефакты:**
- `mqtt_publisher.py` — публикация данных
- `mqtt_subscriber.py` — подписка и алерты
- `sensor_dashboard/` — веб-интерфейс

**Сюжет:**
- Anna: "Нам нужен мониторинг 20 точек. Реал-тайм. MQTT."
- Результат: распределённая сеть датчиков, алерты на Telegram
- LILITH: "IoT — это не 'Internet of Things'. Это 'Internet of Threats'."

---

### Episode 24: Kernel Modules & Device Drivers (SEASON FINALE)
**Тема:** Программирование в kernel space, загружаемые модули ядра
**Время:** 5-6ч
**Миссия:** Написать и загрузить модуль ядра для кастомного устройства.

**Теория:**
- Kernel space vs user space
- Загружаемые модули (LKM): `insmod`, `rmmod`, `modinfo`
- Взаимодействие с ядром: `dmesg`, `/proc`, `/sys`
- Device drivers (базово)

**Практика:**
- Собрать модуль ядра (`Makefile` + `obj-m`)
- Загрузить/выгрузить `.ko`, читать вывод в `dmesg`
- Написать простой символьный драйвер

**Артефакты:**
- `hello.ko` — учебный модуль ядра
- `scripts/load_module.sh` — загрузчик модуля
- `Makefile` — сборка модуля

> ⚠️ **Долг v2.0 (T5, план §2.4):** solution ep24 — заглушка (16-строчный загрузчик
> на `/path/to/hello_complete.ko`, готового `.ko` нет). Достраивается на Этапе 4.

**Сюжет:**
- Li Wei: "Kernel space — здесь нет прощения. Один segfault — kernel panic."
- Финал сезона: разведка Krylov успешна, Max возвращается из Китая с критическими данными.

> **Descoped:** ранее планировалась отдельная серия **Industrial Protocols (UART/I2C/SPI)**.
> В текущей структуре её нет (Season 6 = RPi/GPIO → дроны → IoT/MQTT → kernel modules).
> Тема — кандидат на возврат отдельной серией в будущих версиях (см. `V2.0_UPGRADE_PLAN.md` §6, T5).

**Итог Season 6:** Embedded Linux освоен — от GPIO и дронов до IoT/MQTT и модулей ядра. Разведка Krylov успешна. Max возвращается из Китая с критическими данными.

---

## SEASON 7: ADVANCED TOPICS
**Тема:** Kubernetes, Monitoring, Performance, Hardening
**Локация:** 🇮🇸 Рейкьявик, Исландия
**Персонажи:** Björn Sigurdsson (Kubernetes SRE, ex-EVE Online), Guðrún Ásta (monitoring), Þorsteinn Jónsson (security hardening)
**Время:** 18-22 часа (дни 49-56 операции)
**Сложность:** ⭐⭐⭐⭐⭐

**Технологии:**
- 📦 Kubernetes YAML (deployments, services, ingress)
- 📊 Monitoring configs (prometheus.yml, grafana dashboards)
- 🔍 PromQL (Prometheus queries)
- 🗄️ SQL (database performance tuning)
- ⚙️ sysctl configs (kernel tuning)
- 🔒 Hardening configs (SELinux, AppArmor, auditd)
- 🏗️ Terraform (IaC) — Infrastructure as Code
- 🔧 Makefile (automation)
- 🐍 Python (performance profiling scripts)
- 💡 C (system calls понимание) — опционально
- 🧩 eBPF (kernel tracing) — упоминание

**Контекст:**
Anna: *"Финальная атака близко. Едем в Исландию — наши production серверы. Последний рубеж."* Вerne Global datacenter (бывшая военная база НАТО), ЦОД в лавовых пещерах, geothermal energy, free cooling. Изоляция — край света. Kubernetes production кластер, Prometheus + Grafana, максимальный hardening. **НАПРЯЖЕНИЕ:** Viktor: *"'Новая Эра' готовит что-то большое. Неделя. Может меньше."* Северное сияние над datacenter. Подготовка к финалу. Max размышляет: *"Как я здесь оказался?"*

### Episode 25: Kubernetes Basics
**Тема:** Оркестрация контейнеров
**Время:** 5-6ч
**Миссия:** Развернуть микросервисную архитектуру для операции.

**Теория:**
- Kubernetes архитектура: master, nodes, pods
- `kubectl` команды
- Deployments, Services, ConfigMaps
- Namespaces и RBAC

**Практика:**
- Установить Kubernetes (minikube или k3s)
- Развернуть приложение в pods
- Настроить LoadBalancer
- Scaling и rolling updates

**Артефакты:**
- `deployment.yaml` — deployment манифест
- `service.yaml` — service конфиг
- `k8s_dashboard/` — мониторинг кластера

**Сюжет:**
- Dmitry: "Нам нужна масштабируемость. 1000 запросов/сек. Kubernetes."
- Viktor: "Развёрнуть инфраструктуру на Kubernetes. У нас 24 часа."
- Результат: Кластер выдерживает нагрузку, auto-scaling работает
- LILITH: "Kubernetes как дирижирование оркестром. Только каждый музыкант — контейнер."

---

### Episode 26: Monitoring (Prometheus/Grafana)
**Тема:** Мониторинг production систем
**Время:** 5-6ч
**Миссия:** Настроить мониторинг для раннего обнаружения атак.

**Теория:**
- Prometheus: metrics collection
- Grafana: визуализация
- Exporters: node_exporter, blackbox_exporter
- Alerting: Alertmanager
- SLO, SLI, SLA

**Практика:**
- Установить Prometheus + Grafana
- Настроить мониторинг всех серверов
- Создать dashboard для операции
- Alerts на Telegram при аномалиях

**Артефакты:**
- `prometheus.yml` — конфиг Prometheus
- `grafana_dashboard.json` — дашборд
- `alertmanager.yml` — правила алертов

**Сюжет:**
- Anna: "Krylov атакует ночью. Нам нужны алерты 24/7."
- Результат: Grafana dashboard показывает все системы, алерты в Telegram
- ИНЦИДЕНТ: Alert "CPU spike 90%" — обнаружена атака за 30 секунд
- LILITH: "Не можешь измерить — не можешь управлять. Мониторинг обязателен."

---

### Episode 27: Performance Tuning
**Тема:** Оптимизация производительности
**Время:** 5-6ч
**Миссия:** Оптимизировать инфраструктуру под высокую нагрузку.

**Теория:**
- Performance profiling: `perf`, `strace`, `ltrace`
- Bottlenecks: CPU, Memory, Disk I/O, Network
- Kernel tuning: sysctl параметры
- Database optimization: indexes, query plans
- Caching: Redis, Memcached

**Практика:**
- Профилирование приложения с `perf`
- Оптимизация kernel parameters
- Настройка Redis кеша
- Load testing: Apache Bench, wrk

**Артефакты:**
- `perf_report.txt` — отчёт профилирования
- `sysctl_tuning.conf` — оптимизированные параметры
- `load_test_results.csv` — результаты нагрузочного теста

**Сюжет:**
- Viktor: "Нам нужна скорость. 10K requests/sec. Оптимизируй."
- Находки: bottleneck в database queries, медленный DNS
- Решение: Redis кеш + оптимизация запросов → 15K req/sec
- LILITH: "Performance — это не делать больше. Это делать меньше, но быстрее."

---

### Episode 28: Security Hardening
**Тема:** Укрепление безопасности систем
**Время:** 5-6ч
**Миссия:** Подготовить инфраструктуру к финальной атаке (Season 8).

**Теория:**
- Security hardening checklist
- SELinux и AppArmor: mandatory access control
- Fail2ban: автоматическая блокировка атак
- Auditd: аудит действий в системе
- CIS Benchmarks

**Практика:**
- Настроить SELinux (enforcing mode)
- Fail2ban для SSH brute-force защиты
- Auditd для логирования всех действий
- Сканирование: Lynis, OpenSCAP

**Артефакты:**
- `selinux_policy/` — кастомные политики SELinux
- `fail2ban_jail.conf` — правила блокировки
- `audit_rules.conf` — правила аудита
- `hardening_report.pdf` — отчёт сканирования

**Сюжет:**
- Anna: "Финальная атака близко. Нужен максимальный уровень защиты."
- Процесс: hardening всех 50 серверов через Ansible
- Тестирование: Alex пытается взломать (red team) — защита держится
- LILITH: "Hardening — это не паранойя. Это подготовка."

**Итог Season 7:** Инфраструктура в production. Kubernetes, мониторинг, hardening — всё настроено. Исландия — последний рубеж. Всё готово к финальной битве.

---

## SEASON 8: FINAL OPERATION
**Тема:** Финальная операция — защита под атакой
**Локации:** 🌐 ВСЕ предыдущие локации одновременно (глобальная координация)
**Персонажи:** Вся команда + все local experts помогают
**Время:** 15-20 часов (дни 57-60 операции)
**Сложность:** ⭐⭐⭐⭐⭐

**Технологии:**
- 🌟 ВСЕ технологии из Seasons 1-7 одновременно!
- 🔧 Bash, Python, YAML, SQL, Regex, JSON
- 🐳 Docker, Kubernetes, Terraform
- 🔐 Pentesting tools, hardening configs
- 📊 Monitoring, alerting, incident response
- 🌐 Network configs, firewall rules, VPN
- ⚙️ systemd, cron, all Linux configs
- 📝 Real-time coordination scripts
- 🚀 Emergency automation

**Контекст:**
Viktor: *"Они идут. Krylov + 'Новая Эра'. Одновременно. Всё или ничего."* **ФИНАЛЬНАЯ БИТВА:** DDoS 100+ Gbps на все локации, zero-day exploits, APT backdoors, physical threat (Krylov в Москве). Команда распределена по часовым поясам: Max (Исландия — command center), Alex (Москва — offensive), Anna (Цюрих — defense), Dmitry (Берлин — automation). Local experts помогают (Erik, Björn, Li Wei). 72 часа без сна. **TWIST:** Marcus НЕ предатель. The Architect раскрывается. Все атаки отражены. 50 серверов целы. Sunrise over Iceland. Операция завершена. Max возвращается в Новосибирск. Но Viktor: *"Есть ещё одна операция..."*

### Episode 29: Начало бури ✅ (COMPLETE!)
**Тема:** Противодействие атакам отказа в обслуживании
**Время:** 60-90 минут (7 частей)
**Миссия:** Выстоять первый день финальной атаки (День 57).
**Локация:** 🇮🇸 Рейкьявик, Исландия (координация) + 🌐 Все локации

**Теория (интегрирована в сюжет):**
- **DDoS mitigation:** SYN cookies (sysctl), iptables rate limiting, Kubernetes HPA
- **Zero-day response:** ModSecurity WAF, container isolation, traffic rerouting
- **APT detection:** AIDE integrity checking, auditd system auditing, forensics
- **Kubernetes scaling:** HorizontalPodAutoscaler под нагрузкой
- **Stress coordination:** Decision fatigue, false positives, reversible actions

**Сюжет:**
День 57 операции (06:00-18:00 UTC). Атака начинается:
1. **08:47** — DDoS 15 Gbps (SYN flood)
2. **09:30** — Эскалация до 80 Gbps, 47/50 серверов атакованы
3. **10:30** — Zero-day уязвимость в nginx обнаружена
4. **12:00** — APT backdoors активируются (Docker supply chain)
5. **14:00** — 8 часов работы, усталость решений, Marcus подозревается
6. **16:00** — Защита держится, атака ослабевает

**Практика:**
- `solution/night_shift_response.sh` — обнаружение криптомайнинга (финальное задание)
- Применение техник DDoS mitigation в реальном времени
- Kubernetes масштабирование (1 → 5 реплик)
- Forensics analysis (AIDE, auditd)

**Артефакты:**
- `monitoring/lilith_alerts.txt` — оповещения LILITH (День 57)
- `forensics/backdoor_analysis.txt` — отчёт Анны о бэкдорах

**Результат:** 50/50 серверов стабильны. Инфраструктура выстояла.
Макс координировал оборону под стрессом.

**Метафоры:**
- SYN-флуд = Касса в "Чёрную пятницу" (очередь, но никто не платит)
- Kubernetes масштабирование = 1 касса vs 5 касс
- Нулевой день = Замок без ключа (временно заколачиваешь дверь)
- APT бэкдор = Вор скопировал ключ (входит когда хочет)

---

### Episode 30: Око бури ✅ (COMPLETE!)
**Тема:** Security Audit & Emergency Hardening
**Время:** 60-90 минут
**Миссия:** День 58 — Forensics analysis, backdoor cleanup, infrastructure hardening.
**Локация:** 🇮🇸 Рейкьявик + 🌐 Все локации

**Теория:**
- **AIDE (Advanced Intrusion Detection Environment):** File integrity monitoring
- **auditd:** System call auditing, security logging
- **fail2ban:** Automated IP banning based on log patterns
- **SELinux:** Mandatory access control (enforcing mode)
- **Docker supply chain security:** Image integrity, digest verification
- **Ansible automation:** Mass hardening (50 servers)

**Сюжет:**
День 58. После атаки дня 57 — forensics analysis. Найдены:
- 7 контейнеров с backdoors (Docker supply chain compromise)
- Modified binaries в /usr/bin
- Suspicious cron jobs
- Network connections to C&C servers

Marcus Weber подозревается (ложное срабатывание). Emergency hardening через Ansible.

**Результат:** Инфраструктура укреплена, backdoors удалены, системы ready для контратаки.

---

### Episode 31: Контрнаступление ✅ (COMPLETE!)
**Тема:** Offensive Operations & Botnet Cleanup
**Время:** 60-90 минут
**Миссия:** День 59 — Атака на серверы "Новой Эры", responsible disclosure.
**Локация:** 🇮🇸 Рейкьявик (command) + 🌐 Offensive targets

**Теория:**
- **nmap:** Network reconnaissance, service fingerprinting
- **OSINT:** Open source intelligence gathering
- **Hydra:** Password bruteforce attacks
- **PostgreSQL exploitation:** Weak credentials → shell access
- **SQL injection to RCE:** COPY TO PROGRAM technique
- **Ansible mass automation:** Botnet cleanup (5,247 IoT devices)
- **Responsible disclosure:** PII redaction, legal compliance

**Сюжет:**
День 59. Лучшая защита — нападение. Алекс: "Атакуем их инфраструктуру."

Reconnaissance → Exploitation → Database dump (3.3 GB evidence) → The Architect revealed → Botnet cleanup → Interpol coordination → Media leak (2.5M reach)

**Результат:** "Новая Эра" нейтрализована, evidence собраны, responsible disclosure complete.

---

### Episode 32: Финальная защита ✅ (COMPLETE!)
**Тема:** Ultimate Integration & Final Stand
**Время:** 45-60 минут
**Миссия:** День 60 — ФИНАЛ операции, Krylov defeated, victory!

**Локация:** 🇮🇸 Рейкьявик (command) + 🇷🇺 Москва (physical threat) + 🌐 Global

**Теория:**
- **Kernel forensics:** /proc analysis, memory dumps, rootkit detection
- **Ultimate integration:** ВСЕ навыки Seasons 1-8 одновременно
- **Physical security:** Krylov vs Alex confrontation (Moscow datacenter)
- **The Architect final strike:** Last attempt (defeated)
- **Victory conditions:** 50/50 servers safe, operation complete

**Сюжет:**
День 60. ФИНАЛЬНАЯ БИТВА.

**06:00** — Sunrise over Iceland. Макс координирует последний день.
**09:00** — Rootkit detected (kernel level). Memory forensics начинается.
**12:00** — Krylov физически приходит в московский ЦОД. Alex vs Krylov.
**14:00** — The Architect final strike (отражена через координацию команды).
**16:00** — Krylov defeated (арестован или бежал — open ending).
**18:00** — 50/50 servers safe. VICTORY!

**Эпилог:**
- Viktor: "50 серверов. 8 стран. 60 дней. Ты справился."
- Алекс: "Ты стал настоящим сисадмином. И бойцом. Я горжусь, брат."
- Анна: "Крылов отступил, но угрозы остались. Мы будем нужны снова."
- LILITH: "Ты выжил в тенях. Ты заслужил свой root-доступ. Welcome to the shadows."

Макс возвращается в Новосибирск. Снег. Академгородок. Всё как раньше. Но он изменился.

**Финальная сцена:** Новое письмо от Виктора: *"Subject: OPERATION PENUMBRA. Макс, есть ещё одна операция..."*

Макс смотрит на экран. Улыбается. Закрывает laptop. *"Может быть. Может быть."*

**[KERNEL SHADOWS — COMPLETE]** ✅

**Итог Season 8:** Операция KERNEL SHADOWS завершена. Все 8 сезонов, 32 эпизода, 8 стран, 60 дней. Max Sokolov: junior sysadmin → DevSecOps expert. Все навыки интегрированы. Курс 100% готов!

---

## 📊 Общая статистика

- **Сезонов:** 8 (ALL COMPLETE! 100%)
- **Эпизодов:** 32 (ALL COMPLETE! 100%)
- **Время:** 120-160 часов
- **Технологий:** 50+
- **Персонажей:** 27 (Core Team + Local Experts + Antagonists)
- **Локаций:** 8 стран (🇷🇺 🇸🇪 🇪🇪 🇳🇱 🇩🇪 🇨🇭 🇨🇳 🇮🇸)
- **Серверов:** 50+
- **Строк кода:** ~18,000+
- **Строк документации:** ~50,000+

### Статус по сезонам:
- ✅ Season 1: Shell & Foundations (Episodes 01-04) — 100%
- ✅ Season 2: Networking (Episodes 05-08) — 100%
- ✅ Season 3: System Administration (Episodes 09-12) — 100%
- ✅ Season 4: DevOps & Automation (Episodes 13-16) — 100%
- ✅ Season 5: Security & Pentesting (Episodes 17-20) — 100%
- ✅ Season 6: Embedded Linux & IoT (Episodes 21-24) — 100%
- ✅ Season 7: Production & Advanced (Episodes 25-28) — 100%
- ✅ Season 8: Final Operation (Episodes 29-32) — 100%

---

## 🎯 Результаты обучения

После прохождения KERNEL SHADOWS вы сможете:

✅ Администрировать Ubuntu Linux системы
✅ Настраивать сети, VPN, firewalls
✅ Автоматизировать через Bash, Python, Ansible
✅ Работать с Docker, Kubernetes
✅ Проводить пентестинг и hardening
✅ Настраивать мониторинг production систем
✅ Оптимизировать performance
✅ Реагировать на инциденты безопасности
✅ Работать с embedded Linux и IoT
✅ Мыслить как системный администратор И как атакующий

---

<div align="center">

**"Master the kernel. Control the shadows."**

[⬆ Наверх](#kernel-shadows-учебный-план)

</div>

