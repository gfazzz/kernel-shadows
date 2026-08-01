# SEASON 2: NETWORKING

```
KERNEL SHADOWS — Season 2
Тема: TCP/IP, DNS, Firewalls, VPN
Локации: 🇷🇺 Москва → 🇸🇪 Стокгольм, Швеция
Дни операции: 9-16 (из 60)
Сложность: ⭐⭐☆☆☆
Время: 15-18 часов
```

---

## 📖 О сезоне

### Переход на следующий уровень

**Day 8 (21:37) — Звонок от Алекса:**

> *"Макс. У нас проблема. Крылов знает о нас. Нужен ты. Лично. Завтра. Москва."*

**Season 1** был разминкой — работа из дома в Новосибирске, базовые навыки shell.

**Season 2** — настоящая операция:
- Первый раз в Москве для работы
- Встреча с командой лично (Алекс, Анна, Дмитрий, Виктор)
- DDoS атаки от Крылова (50,000 пакетов/сек)
- DNS spoofing
- Первый раз за границей (Стокгольм, Швеция)

### Кто такой Krylov?

**Полковник Кирилл Крылов** — бывший начальник Алекса в ФСБ (Управление "К" — киберпреступность).

Когда Алекс ушёл из ФСБ и отказался фабриковать дела, Крылов не простил. Теперь охотится на Алекса, Виктора, и всю операцию.

**Методы атак:**
- DDoS (Distributed Denial of Service)
- DNS spoofing (подмена DNS ответов)
- Network surveillance (прослушивание трафика)
- Social engineering

**IP адрес Крылова (предположительно):** 185.220.101.47 (Tor exit node)

---

## 🌍 География

### Локация 1: Москва, Россия 🇷🇺

**ЦОД "Москва-1"** (Северо-Восточный АО)

**Атмосфера:**
- Промышленная зона, здание без вывесок, бетонные стены
- Серверная комната A-12: гудение серверов, холодный воздух кондиционеров
- Напряжение — Крылов где-то рядом, паранойя
- Grafana мониторы показывают атаки в реальном времени

**Персонажи в Москве:**
- **Viktor Petrov** — координатор операции, седые волосы, чёрный костюм
- **Алекс Соколов** — твой двоюродный брат, ex-FSB, security expert
- **Анна Ковалёва** — ex-FSB, forensics expert, blue team lead
- **Дмитрий Орлов** — DevOps engineer, embedded specialist

**Эпизоды:**
- Episode 05: TCP/IP Fundamentals (Москва)
- Episode 07: Firewalls (Москва — возврат)

### Локация 2: Стокгольм, Швеция 🇸🇪

**Bahnhof Pionen Datacenter** — бывший ядерный бункер времён холодной войны, 30 метров под землёй

**Атмосфера:**
- Футуристичный дизайн внутри скалы
- Искусственный водопад, неоновое освещение, холод
- Privacy культура (после WikiLeaks, Bahnhof refused government pressure)
- Северная эстетика — холодный минимализм, всё работает идеально

**Персонажи в Стокгольме:**
- **Erik Johansson** — шведский network engineer, BGP/DNS expert, Bahnhof employee
- **Katarina Lindström** — криптография, Stockholm University, DNS over TLS expert

**Эпизоды:**
- Episode 06: DNS & Name Resolution (Стокгольм)
- Episode 08: VPN & SSH Tunneling (Стокгольм + Москва)

**Культурный контраст:**
- **Россия:** Chaos, improvisation, "работает — не трогай", паранойя
- **Швеция:** Порядок, privacy by design, минимализм, спокойствие

Макс впервые за границей. Культурный шок. Но technology speaks a universal language.

---

## 🆕 v2.0: атомарные серии (новый стандарт)

Рефакторинг v2.0 (см. [`V2.0_UPGRADE_PLAN.md`](../V2.0_UPGRADE_PLAN.md)) дробит эпизоды на
атомарные серии `sNNeNN`: один концепт — одна задача, README ≤ 650 строк, `mission.md`
с блоком «Требования среды», единая `starter/`, `theory.md` и **воспроизводимый тест**.
Сетевые серии тестируются **без живой сети** — `ping`/`ss` подменяются мок-версиями
(mock-first, §5.3).

**Season 2 полностью пересобран: Episodes 05–08 → 9 атомарных серий ✅**
(старые `episode-05…08` убраны; данные-пропсы сохранены в [`data/`](data/)):

| Серия | Из ep | Концепт | Задача (артефакт) | Type | Тест |
|-------|-------|---------|-------------------|------|------|
| [s02e01](s02e01-tcpip-addressing/) | 05 | IPv4-адресация + модель TCP/IP | `ipinfo.sh` | A | 16/16 |
| [s02e02](s02e02-ports-sockets/) | 05 | порты/сокеты (`ss`) | `check_ports.sh` | A | 12/12 |
| [s02e03](s02e03-net-diagnostics/) | 05 | диагностика `ping`/`traceroute` (капстоун) | `net_diag.sh` | A | 12/12 |
| [s02e04](s02e04-dns-lookup/) | 06 | DNS-резолвинг (`dig`), типы записей | `dns_lookup.sh` | B | 11/11 |
| [s02e05](s02e05-dns-spoofing-guard/) | 06 | детект DNS-спуфинга (капстоун) | `dns_guard.sh` | B | 12/12 |
| [s02e06](s02e06-firewall-ufw/) | 07 | firewall `ufw`, аудит правил | `fw_audit.sh` | B | 12/12 |
| [s02e07](s02e07-block-botnet/) | 07 | блокировка ботнета (капстоун) | `block_botnet.sh` | B | 15/15 |
| [s02e08](s02e08-ssh-keys/) | 08 | SSH-ключи (ed25519, права) | `ssh_key_check.sh` | A | 13/13 |
| [s02e09](s02e09-ssh-hardening/) | 08 | hardening sshd + туннели (финал) | `sshd_harden_check.sh` | B | 14/14 |

**Итого Season 2: 9 серий, 117 проверок — все зелёные без root/сети** (сетевые команды
`ping`/`ss`/`dig`/`ufw`/`dpkg` мокаются или работают на фикстурах; §5.3). Реальные данные
для практики — в [`data/`](data/).

Сезонный проект — **`netshield`** (адресация → защита DNS → firewall → шифрованный доступ;
см. [`PROJECTS.md`](../PROJECTS.md)). Закрытые forward-deps: **T2** (`systemd-resolved` —
только read-only `resolvectl`, `systemctl` → Season 3) и **T4** (`fail2ban` — превью, полноценно
Season 5).

**Литературизация по DoD §15 завершена для всего Season 2** (README 180–280 строк прозой,
`theory.md` — воспоминание от первого лица, `mission.md` — брифинг с диагностикой).
Все тесты усилены дискриминаторами: ожидания вычисляются по фикстурам, а не хранятся
константами, и каждый ловит конкретную реальную ошибку.

**В очереди:** Season 3 «System Administration» (Episodes 09–12) → серии `s03e01+`.

---

## 📚 Эпизоды

### Episode 05: TCP/IP Fundamentals ✅
**Локация:** 🇷🇺 Москва (ЦОД "Москва-1")
**День:** 9 из 60
**Время:** 4-5ч
**Сложность:** ⭐⭐☆☆☆

**Миссия:** Понять основы сетей, чтобы защитить инфраструктуру от атак Крылова.

**Теория:**
- TCP/IP модель (4 слоя)
- IP адреса (IPv4, IPv6, private vs public, loopback)
- TCP vs UDP
- Порты и сокеты
- ICMP (ping, traceroute)
- Routing (default gateway, routing table)

**Практика:**
- Определить IP адрес рабочей станции Max
- Определить IP сервера Viktor по hostname
- Проверить доступность (ping)
- Traceroute — маршрут до сервера
- Проверить открытые порты (netstat, ss)
- Сканировать порты сервера Viktor (nmap)
- Routing table
- Создать network audit отчёт

**Команды:**
- `ip a` — IP адрес
- `ping` — проверка доступности
- `traceroute` / `tracepath` — маршрут
- `netstat` / `ss` — открытые порты
- `nmap` — сканирование портов
- `ip route` — таблица маршрутизации

**Сюжет:**
- Max прилетает в Москву
- Первая встреча с командой (Алекс, Анна, Дмитрий, Виктор)
- DDoS атака от Крылова (50,000 пакетов/сек)
- LILITH v2.0 — Networking Module

---

### Episode 06: DNS & Name Resolution 🚧
**Локация:** 🇸🇪 Стокгольм (Bahnhof Pionen Datacenter)
**День:** 10-12 из 60
**Время:** 3-4ч
**Сложность:** ⭐⭐☆☆☆

**Миссия:** Настроить DNS для скрытия инфраструктуры. Обнаружить DNS spoofing атаку от Крылова.

**Теория:**
- Как работает DNS
- A, AAAA, CNAME, MX, TXT записи
- `dig`, `nslookup`, `host`
- `/etc/hosts` и `/etc/resolv.conf`
- DNS spoofing и защита (DNSSEC, DNS over TLS)

**Практика:**
- Настроить локальный DNS через `/etc/hosts`
- Проверить DNS записи сервера Viktor
- Обнаружить DNS spoofing атаку (cache poisoning)
- Настроить DoT (DNS over TLS)

**Персонажи:**
- **Erik Johansson** — network engineer, BGP/DNS expert
- **Katarina Lindström** — криптография, Stockholm University

**Сюжет:**
- Max первый раз за границей (культурный шок)
- Bahnhof Pionen — ядерный бункер 30м под землёй
- DNS атаки усиливаются
- Erik: "In Sweden we take privacy seriously"

---

### Episode 07: Firewalls (iptables/ufw) 🚧
**Локация:** 🇷🇺 Москва (возврат из Стокгольма)
**День:** 13-14 из 60
**Время:** 4-5ч
**Сложность:** ⭐⭐⭐☆☆

**Миссия:** Защитить серверы от DDoS атаки Крылова.

**Теория:**
- Netfilter и iptables
- Chains: INPUT, OUTPUT, FORWARD
- Правила: ACCEPT, DROP, REJECT
- UFW (Uncomplicated Firewall)
- nftables
- Rate limiting

**Практика:**
- Настроить UFW: закрыть все порты кроме SSH (22)
- Создать правила iptables для защиты от DDoS
- Rate limiting: `iptables -m limit`
- Логирование попыток атак
- Автоматическая блокировка атакующих IP

**Сюжет:**
- **INCIDENT:** DDoS атака на ЦОД "Москва-1" — 50K пакетов/сек
- Алекс: "Файрвол. Сейчас. У нас 5 минут до падения сервера."
- Паника. Макс применяет знания. UFW + iptables rate limiting.
- **Twist:** Крылов оставляет сообщение в логах: *"Соколов, передай брату — я найду вас. Обоих."*

---

### Episode 08: VPN & SSH Tunneling ✅
**Локация:** 🇨🇭 Цюрих (Switzerland) — Season 2 Finale
**День:** 15-16 из 60
**Время:** 6-7ч (8 micro-cycles)
**Сложность:** ⭐⭐⭐⭐☆
**Статус:** ✅ COMPLETE + REFACTORED (v0.4.5.8)
**Тип:** Type A (Workflow Automation)

**Миссия:** Настроить VPN для безопасной коммуникации команды после угрозы DPI от Крылова.

**🎯 Type A Episode:**
- Workflow automation для VPN setup (5 членов команды)
- Multi-step process: SSH keys × 5 → configs → WireGuard × 6 → coordination
- Bash автоматизирует, НЕ заменяет инструменты (ssh-keygen, wg, wg-quick)
- 60-70% времени: изучение SSH/VPN концептов
- 30-40% времени: bash для автоматизации workflow

**Что изучим (8 micro-cycles):**
- **Цикл 1:** SSH Keys Basics (ed25519 > RSA, public/private, security)
- **Цикл 2:** SSH Config Advanced (~/.ssh/config, ProxyJump, multiplexing)
- **Цикл 3:** SSH Local Forward (remote → local, database access)
- **Цикл 4:** SSH Remote Forward (local → remote, webhook exposure)
- **Цикл 5:** Dynamic Forward (SOCKS proxy, all traffic tunneling)
- **Цикл 6:** VPN Concepts (OpenVPN vs WireGuard, kernel vs userspace)
- **Цикл 7:** WireGuard Setup (automated workflow, server + 5 clients)
- **Цикл 8:** Final Audit (Season 2 Summary, security posture)

**Практика:**
- Генерация SSH ключей для команды (ed25519, permissions, fingerprints)
- SSH config automation (aliases, jump hosts, connection reuse)
- SSH tunneling: Local/Remote/Dynamic forward
- SOCKS proxy для браузера (DNS leak prevention)
- WireGuard VPN server в Цюрихе (ChaCha20-Poly1305 encryption)
- Client configs для 5 членов (Viktor, Alex, Anna, Dmitry, Max)
- Security testing (IP leak, DNS leak, WebRTC leak)
- Comprehensive Season 2 Audit Report

**Персонажи:**
- **Виктор Петров** — координатор, решение о VPN в Цюрихе
- **Алекс Соколов** — security expert, эмоциональная предыстория
- **Анна Ковалёва** — forensics, обнаружила DPI угрозу
- **Дмитрий Орлов** — DevOps, VPN infrastructure setup
- **Макс Соколов** — главный герой, junior → competent (16 дней)
- **LILITH v2.5** — Security Mode (синий режим — encryption)

**Сюжет (Season 2 Finale):**
- **День 15, 08:00** — Emergency meeting в Цюрихе
- Анна обнаружила DPI (Deep Packet Inspection) от Крылова
- Алекс: "Firewall блокирует атаки. Но НЕ шифрует трафик."
- Виктор: "VPN сервер в Цюрихе. Швейцария — нейтральная территория."
- Макс настраивает WireGuard для 5 членов команды
- **23:00** — VPN operational, весь трафик зашифрован
- Крылов пытался DPI → увидел только ChaCha20 encrypted data
- **Season 2 Complete:** 4 episodes, Max: junior → competent
- Character development: Confidence 35% → 78%
- Next: Season 3 — System Administration (Санкт-Петербург → Таллин 🇪🇪)

**Педагогика (CS50-style):**
- ✅ 8 micro-cycles (interleaving каждые 12-15 минут)
- ✅ 6 метафор (SSH Keys = Дом+Замок, Config = Телефонная книга, etc.)
- ✅ 5+ ASCII diagrams (key generation flow, tunnel flow, VPN encryption)
- ✅ 15+ LILITH quotes (интегрированы В теорию!)
- ✅ 8 "Think before checking" упражнений
- ✅ Type A philosophy explicit (таблица, сравнение с Episode 07)
- ✅ Русские персонажи говорят на русском ✓

**Файлы (после рефакторинга v0.4.5.8):**
- `README.md` — 1,863 строк (было 3,458, **-46% size!**)
- `solution/vpn_setup.sh` — 695 строк (Type A automation)
- `artifacts/README.md` — 670 строк (было ~100, **+570%!**)
- `starter.sh` — Type A aligned
- `tests/test.sh` — comprehensive validation
- `README.md.backup` — старая версия (reference)

**Season 2 Balance:** 2 Type A (Episodes 05, 08) / 2 Type B (Episodes 06, 07) = 50/50 ✅

---

## 🎯 Цели сезона

### Технические навыки:
- ✅ TCP/IP модель
- ✅ IP адресация и subnetting
- ✅ Диагностика сетей (ping, traceroute)
- ✅ Порты и сервисы (netstat, ss, nmap)
- 🔲 DNS (dig, nslookup, DNSSEC, DoT)
- 🔲 Firewalls (ufw, iptables, rate limiting)
- 🔲 VPN (OpenVPN, WireGuard)
- 🔲 SSH (tunneling, port forwarding, keys)

### Личный рост Max:
- ✅ Первая командная работа (Алекс, Анна, Дмитрий, Виктор)
- ✅ Первая поездка в Москву для работы
- 🔲 Первый раз за границей (Стокгольм)
- 🔲 Адаптация к международной команде
- 🔲 Работа под давлением (DDoS атаки, Крылов)

### Сюжетная линия:
- ✅ Знакомство с командой лично
- ✅ Понимание угрозы Крылова
- 🔲 Первые серьёзные атаки
- 🔲 Международное сотрудничество (Erik, Katarina)
- 🔲 Развитие отношений с Алексом (брат, ментор)

---

## 📊 Прогресс

**Эпизоды:** 4/4 (100%) ✅ **SEASON 2 COMPLETE!**

| Episode | Название | Локация | Прогресс | Статус |
|---------|----------|---------|----------|--------|
| 05 | TCP/IP Fundamentals | Москва 🇷🇺 | 100% | ✅ Complete |
| 06 | DNS & Name Resolution | Стокгольм 🇸🇪 | 100% | ✅ Complete |
| 07 | Firewalls & iptables | Москва 🇷🇺 | 100% | ✅ Complete |
| 08 | VPN & SSH Tunneling | 🇸🇪→🇷🇺→🇨🇭 | 100% | ✅ Complete (Finale!) |

---

## 🎭 Основные персонажи

### Core Team (постоянные):

#### Viktor Petrov
- **Роль:** Координатор операции, заказчик
- **Возраст:** ~45 лет
- **Внешность:** Седые волосы, чёрный костюм, проницательный взгляд
- **Локация:** Москва (штаб-квартира)
- **Характер:** Деловой, немногословный, контролирует всё

#### Alex Sokolov
- **Роль:** Security expert, offensive security, ex-FSB
- **Возраст:** 35 лет
- **Родство:** Двоюродный брат Max
- **Прошлое:** ФСБ Управление "К" (киберпреступность), покинул из-за конфликта с Крыловым
- **Навыки:** Penetration testing, offensive security, тактика атакующих
- **Характер:** Параноидальный, циничный, надёжный

#### Anna Kovaleva
- **Роль:** Forensics expert, blue team lead, ex-FSB
- **Возраст:** 32 года
- **Прошлое:** ФСБ (та же команда что и Алекс), ушла вместе с Алексом
- **Навыки:** Digital forensics, log analysis, incident response
- **Характер:** Спокойная, методичная, профессиональная

#### Dmitry Orlov
- **Роль:** DevOps engineer, embedded specialist
- **Возраст:** 29 лет
- **Внешность:** Hoodie, джинсы, 3 монитора
- **Навыки:** Docker, Kubernetes, Ansible, embedded Linux
- **Характер:** Энтузиаст, friendly, любит автоматизацию

### Local Experts (Season 2):

#### Erik Johansson (Episode 06)
- **Роль:** Network engineer, Bahnhof employee
- **Локация:** Стокгольм, Швеция
- **Специализация:** BGP routing, DNS, datacenter infrastructure
- **Характер:** Профессиональный, privacy-focused, Swedish pragmatism
- **Цитата:** *"In Sweden we take privacy seriously. After WikiLeaks, Bahnhof refused government pressure."*

#### Katarina Lindström (Episode 08)
- **Роль:** Криптография researcher, Stockholm University
- **Локация:** Стокгольм, Швеция
- **Специализация:** SSL/TLS, DNS over TLS, cryptographic protocols
- **Характер:** Академичная, строгая к security, mathematics-driven
- **Цитата:** *"Encryption is mathematics. Mathematics doesn't lie. Unlike people."*

### Antagonist:

#### Полковник Krylov
- **Роль:** Главный антагонист Season 2
- **Организация:** ФСБ Управление "К" (киберпреступность)
- **Прошлое:** Бывший начальник Алекса и Анны
- **Мотивация:** Месть Алексу за "предательство" (отказ фабриковать дела)
- **Методы:** DDoS, DNS spoofing, network surveillance, social engineering
- **IP:** 185.220.101.47 (Tor exit node, предположительно)

---

## 💡 Философия сезона

### "Packets tell stories. Learn to listen."

Каждый сетевой пакет несёт информацию:
- Откуда пришёл (source IP)
- Куда идёт (destination IP)
- Что хочет (порт, протокол)
- Когда (timestamp)

Networking — это не просто технология. Это **коммуникация**.

Понимание сетей = понимание как системы общаются = понимание как защищать или атаковать.

### Security vs Usability

**Season 2 исследует трейдофф:**
- Полная безопасность = неудобство (VPN замедляет, firewall блокирует)
- Полное удобство = уязвимость (открытые порты, незашифрованный трафик)

**Баланс — ключ.**

### Культурные различия в tech подходах

- **Россия:** Chaos, improvisation, "работает — не трогай", срочность
- **Швеция:** Порядок, privacy by design, минимализм, long-term thinking

Макс учится адаптироваться к разным культурам. Technology transcends borders.

---

## 🔧 Инструменты сезона

### Сетевые утилиты:
```bash
ip a              # IP адреса
ping              # Проверка доступности
traceroute        # Маршрут до хоста
netstat / ss      # Открытые порты
nmap              # Сканирование портов
dig / nslookup    # DNS lookup
tcpdump           # Захват пакетов
wireshark         # Анализ трафика (GUI)
```

### Firewall:
```bash
ufw               # Uncomplicated Firewall
iptables          # Firewall правила
nftables          # Новое поколение firewall
```

### VPN & SSH:
```bash
ssh               # Secure Shell
ssh-keygen        # Генерация ключей
openvpn           # OpenVPN клиент/сервер
wireguard         # Современный VPN
```

### Мониторинг:
- Prometheus — сбор метрик
- Grafana — визуализация
- Alertmanager — алерты

---

## 📖 Рекомендуемые ресурсы

### Книги:

**📘 Теория (академические учебники):**
- **Олифер В.Г., Олифер Н.А. — Компьютерные сети** (6-е изд., 2020) 🇷🇺
  - Лучший русскоязычный учебник по сетям
  - Архитектура, маршрутизация, протоколы, безопасность
  - Обязательная литература для Season 2
- **Kurose & Ross — Computer Networking: A Top-Down Approach** (8th ed., 2021)
  - Самый популярный академический учебник в мире
  - Top-Down подход (от приложений к физике)
  - Wireshark labs, современные темы (HTTP/3, QUIC, SDN)
- **W. Richard Stevens — TCP/IP Illustrated, Volume 1** (2nd ed., 2011)
  - Классика, детальный разбор TCP/IP
  - Packet analysis, troubleshooting

**🛠️ Практика (администрирование):**
- **Craig Hunt — TCP/IP Network Administration** (O'Reilly, 3rd ed., 2002)
  - Практический подход: "как настроить"
  - DNS (BIND), DHCP, routing на Linux/Unix
  - Реальные конфигурационные файлы
- **Chris Sanders — Practical Packet Analysis** (Wireshark)
  - Анализ трафика, troubleshooting
- **Richard Bejtlich — The Practice of Network Security Monitoring**
  - Security monitoring, incident response

### Онлайн курсы:
- [Introduction to Networking](https://www.coursera.org/learn/computer-networking) (Coursera)
- [Wireshark Tutorial](https://www.wireshark.org/docs/wsug_html_chunked/) (официальная документация)

### Практика:
- [OverTheWire: Bandit](https://overthewire.org/wargames/bandit/) — SSH практика
- [HackTheBox](https://www.hackthebox.eu/) — networking challenges
- [TryHackMe: Network Fundamentals](https://tryhackme.com/) — интерактивные задания

### Tools:
- [Wireshark](https://www.wireshark.org/) — анализ пакетов (GUI)
- [nmap](https://nmap.org/) — сканирование сетей
- [tcpdump](https://www.tcpdump.org/) — захват пакетов (CLI)

---

## ⏭️ Следующий сезон

**SEASON 3: SYSTEM ADMINISTRATION**

**Локации:** 🇷🇺 Санкт-Петербург → 🇪🇪 Таллин, Эстония
**Дни:** 17-24 из 60
**Тема:** Users & Permissions, Processes, Disk Management, Backup

**Кризис:** Один из серверов взломан (backdoor от Крылова). Анна: *"Нужен полный контроль над системами."*

---

<div align="center">

**KERNEL SHADOWS — Season 2: Networking**

*"Каждый пакет рассказывает историю. Научись слушать."* — LILITH

**[← Season 1](../season-01-shell-foundations/README.md) | [Season 3 →](../season-03-system-administration/README.md)**

**[Первая серия: s02e01 →](s02e01-tcpip-addressing/README.md)**

</div>
