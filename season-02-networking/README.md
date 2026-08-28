# SEASON 2: NETWORKING

```
KERNEL SHADOWS — Season 2
Тема: TCP/IP, DNS, Firewalls, VPN
Локации: 🇷🇺 Москва → 🇸🇪 Стокгольм, Швеция
Дни операции: 9-16 (из 60)
Сложность: ⭐⭐☆☆☆
Время: 10 ч 35 мин (12 серий, 187 проверок)
```

---

## О сезоне

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

## География

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
- Дни 9, 13–14: адресация, диагностика, фаервол (`s02e01`–`s02e03`, `s02e06`–`s02e07`)


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
- Дни 10–12: DNS и защита от подмены (`s02e04`–`s02e05`)
- Дни 15–16: ключи, туннели, WireGuard (`s02e08`–`s02e12`)

**Культурный контраст:**
- **Россия:** Chaos, improvisation, "работает — не трогай", паранойя
- **Швеция:** Порядок, privacy by design, минимализм, спокойствие

Макс впервые за границей. Культурный шок. Но technology speaks a universal language.

---

## 🆕 v2.0: атомарные серии (новый стандарт)

Рефакторинг v2.0 (см. CHANGELOG) дробит эпизоды на
атомарные серии `sNNeNN`: один концепт — одна задача, README ≤ 650 строк, `mission.md`
с блоком «Требования среды», единая `starter/`, `theory.md` и **воспроизводимый тест**.
Сетевые серии тестируются **без живой сети** — `ping`/`ss` подменяются мок-версиями
(mock-first).

**Season 2 пересобран: 4 исходных эпизода → 12 атомарных серий**
(старые `episode-05…08` убраны; данные-пропсы сохранены в [`data/`](data/)):

| Серия | Из ep | Концепт | Задача (артефакт) | Type | Тест |
|-------|-------|---------|-------------------|------|------|
| [s02e01](s02e01-tcpip-addressing/) | 05 | IPv4-адресация + модель TCP/IP | `ipinfo.sh` | A | 16/16 |
| [s02e02](s02e02-ports-sockets/) | 05 | порты/сокеты (`ss`), адрес привязки | `ports_report.txt` | **C** | 13/13 |
| [s02e03](s02e03-net-diagnostics/) | 05 | диагностика `ping`/`traceroute` (капстоун) | `net_diag.sh` | A | 12/12 |
| [s02e04](s02e04-dns-lookup/) | 06 | DNS-резолвинг (`dig`), типы записей | `dns_report.txt` | **C** | 15/15 |
| [s02e05](s02e05-dns-spoofing-guard/) | 06 | детект DNS-спуфинга (капстоун) | `dns_guard.sh` | B | 12/12 |
| [s02e06](s02e06-firewall-ufw/) | 07 | firewall `ufw`, разбор правил | `fw_report.txt` | **C** | 13/13 |
| [s02e07](s02e07-block-botnet/) | 07 | блокировка ботнета (капстоун) | `block_botnet.sh` | B | 15/15 |
| [s02e08](s02e08-ssh-keys/) | 08 | SSH-ключи (ed25519, права) | `ssh_key_check.sh` | A | 13/13 |
| [s02e09](s02e09-ssh-hardening/) | 08 | закалка `sshd_config` | `sshd_config` | **B** | 14/14 |
| [s02e10](s02e10-ssh-tunnels/) | 08 | SSH-туннели: `-L`, `-R`, `-D`, `ProxyJump` | `~/.ssh/config` | **B** | ✅ 23/23 |
| [s02e11](s02e11-wireguard/) | 08 | WireGuard: ключи, `AllowedIPs`, NAT | `wg0.conf` | **B** | ✅ 19/19 |
| [s02e12](s02e12-firewall-log/) | 08 | журнал фаервола и `ufw limit` (финал сезона) | `fwlog_report.txt` | **C** | ✅ 22/22 |

**Итого Season 2: 12 серий, 187 проверок — все зелёные без root/сети** (сетевые команды
`ping`/`ss`/`dig`/`ufw`/`dpkg` мокаются или работают на фикстурах). Реальные данные
для практики — в [`data/`](data/).

Сезонный проект — **`netshield`** (адресация → защита DNS → firewall → шифрованный доступ;
см. [`PROJECTS.md`](../docs/PROJECTS.md)). Закрытые forward-deps: **T2** (`systemd-resolved` —
только read-only `resolvectl`, `systemctl` → Season 3) и **T4** (`fail2ban` — превью, полноценно
Season 5).

Тесты построены на дискриминаторах: ожидания вычисляются по фикстурам, а не хранятся
константами, и каждый ловит конкретную реальную ошибку.

---

## Сюжетная линия

### День 9, Москва: первая атака (s02e01–s02e03)

Макс прилетает в Москву и впервые видит команду вживую — Алекс, Анна, Дмитрий,
Виктор. В тот же день ЦОД «Москва-1» получает DDoS: пятьдесят тысяч пакетов в
секунду. Разбираться приходится с нуля: где машина в сети, что она слушает, где
рвётся путь до сервера.

**LILITH v2.0 — Networking Module.**

### Дни 10–12, Стокгольм: DNS (s02e04–s02e05)

Первая заграница и культурный шок: Bahnhof Pionen — ЦОД в ядерном бункере
тридцатью метрами под гранитом. **Erik Johansson** (сетевой инженер, BGP и DNS)
и **Katarina Lindström** (криптография, Stockholm University) учат читать
резолвинг. Крылов отвечает подменой DNS-ответов.

> Erik: *«In Sweden we take privacy seriously.»*

### Дни 13–14, Москва: фаервол (s02e06–s02e07)

Возврат в Москву — и настоящий инцидент. Алекс: *«Фаервол. Сейчас. У нас пять
минут до падения сервера.»* Макс закрывает периметр `ufw`, разбирает правила и
блокирует ботнет по журналу.

**Поворот:** Крылов оставляет запись в логах — *«Соколов, передай брату: я найду
вас. Обоих.»*

### Дни 15–16, Цюрих: шифрование (s02e08–s02e12)

Анна обнаруживает DPI — глубокую инспекцию трафика. Фаервол блокирует атаки, но
не прячет содержимое. Виктор: *«VPN в Цюрихе. Швейцария — нейтральная
территория.»* Ключи SSH, закалка `sshd_config`, туннели, WireGuard для пятерых —
и разбор журнала фаервола, где видно, что перебор прекратился ровно в ту минуту,
когда атакующий вошёл легально.

Крылов пробует DPI и видит только шифрованный поток.

**Дальше → Season 3: System Administration (Санкт-Петербург → Таллин 🇪🇪).**

---

## Цели сезона

**Технические навыки:** модель TCP/IP и адресация; порты и сокеты — что слушает
машина и на каком адресе; диагностика снизу вверх (`ping`, `traceroute`, `ss`,
`curl`); DNS-резолвинг и распознавание подмены; фаервол `ufw` с ограничением
частоты; ключи SSH и закалка `sshd_config`; туннели `-L`/`-R`/`-D`; WireGuard;
чтение журнала фаервола.

**Личный рост Макса:** первая работа в команде, первая поездка за границу,
работа под давлением настоящего инцидента — и переход от «сделаю руками» к
«настрою так, чтобы держалось само».

**Сюжет:** знакомство с командой лично, осознание масштаба угрозы Крылова,
первые серьёзные атаки, международное сотрудничество и сближение с Алексом.

---

## Прогресс

Прогнать сезон: `make test SEASON=season-02-networking` (12 серий, 187 проверок).
Посмотреть, что пройдено: `make progress` — засчитывается работа в `artifacts/`
с зелёным тестом.

---

## Основные персонажи

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

#### Erik Johansson (Стокгольм)
- **Роль:** Network engineer, Bahnhof employee
- **Локация:** Стокгольм, Швеция
- **Специализация:** BGP routing, DNS, datacenter infrastructure
- **Характер:** Профессиональный, privacy-focused, Swedish pragmatism
- **Цитата:** *"In Sweden we take privacy seriously. After WikiLeaks, Bahnhof refused government pressure."*

#### Katarina Lindström (Стокгольм)
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

## Философия сезона

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

## Инструменты сезона

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

## Рекомендуемые ресурсы

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
