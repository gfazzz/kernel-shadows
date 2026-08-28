# KERNEL SHADOWS — учебный план

**101 серия · 8 сезонов · 8 стран · 60 дней операции · 98 ч 25 мин чистого времени на задачи**

Это указатель: что где изучается и в каком порядке. Содержание живёт в самих
сериях, а не здесь, — поэтому таблицы ниже **генерируются из шапок серий**
скриптом, а не поддерживаются руками:

```bash
bash tools/gen_index.sh
```

Рукописный указатель на сотню строк расходится с реальностью за один
рефакторинг; генерируемый — не может.

> **См. также:**
> - [README.md](../README.md) — с чего начать и как устроен курс
> - [THEORY_MAP.md](THEORY_MAP.md) — какая тема где вводится и на что опирается
> - [RESOURCES.md](RESOURCES.md) — библиография, собранная из `theory.md` всех серий
> - [PROJECTS.md](PROJECTS.md) — сквозные артефакты сезонов
> - [SCENARIO.md](SCENARIO.md), [CHARACTERS.md](CHARACTERS.md), [LOCATIONS.md](LOCATIONS.md) — сюжетный канон

---

## Для кого курс

- **системных администраторов** — конфигурация, диагностика, восстановление;
- **инженеров эксплуатации и DevOps** — контейнеры, оркестрация, наблюдаемость, SLO;
- **тех, кто занимается безопасностью** — укрепление, разбор инцидентов, форензика;
- **сетевых инженеров** — TCP/IP, DNS, фильтрация, туннели;
- **тех, кто работает с встраиваемым Linux** — платы, GPIO, MQTT, модули ядра.

Курс не учит писать на C — для этого есть сестринский курс OPERATION MOONLIGHT.
Он учит не бояться исходников и понимать, из чего сделана система.

---

## Маршрут

| Сезон | Локация | Дни операции | Предмет |
|---|---|---|---|
| 1 | 🇷🇺 Новосибирск | 2–8 | оболочка, файлы, текст, пакеты, права |
| 2 | 🇷🇺 Москва → 🇸🇪 Стокгольм | 9–16 | TCP/IP, DNS, фильтрация, SSH, туннели |
| 3 | 🇷🇺 Санкт-Петербург → 🇪🇪 Таллин | 17–24 | учётные записи, systemd, диски, журнал, бэкапы |
| 4 | 🇳🇱 Амстердам → 🇩🇪 Берлин | 25–32 | git, контейнеры, конвейеры, Ansible |
| 5 | 🇨🇭 Цюрих + Женева | 33–40 | аудит, обнаружение, форензика, укрепление |
| 6 | 🇨🇳 Шэньчжэнь | 41–48 | платы, GPIO, дроны, MQTT, модули ядра |
| 7 | 🇮🇸 Рейкьявик | 49–56 | кластер, метрики, оповещения, производительность, SLO |
| 8 | 🌐 глобально | 57–60 | отражение атаки, разбор, контрнаступление, приёмка |

**Всего:** 8 стран, 60 дней, 27 персонажей.

---

## Как устроена серия

Один концепт — одна задача. В каждой серии:

| Файл | Что в нём |
|---|---|
| `README.md` | сцена, теория одного концепта, вопросы, задание, разбор ошибок |
| `mission.md` | брифинг: обстановка, приказ, критерии приёмки, диагностика |
| `theory.md` | углубление: история вопроса, компромиссы, книги, промпты для LILITH |
| `starter/` | каркас артефакта |
| `solution/` | рабочий эталон |
| `tests/test.sh` | воспроизводимый тест: без root, без сети, на фикстурах |
| `artifacts/` | рабочая папка студента |

**Типы серий** (баланс — часть критериев приёмки сезона):

| Метка | Что делает студент | Что проверяет тест |
|---|---|---|
| `Type A — Automation` | пишет `.sh` | поведение скрипта на фикстуре |
| `Type B — Configuration` | правит конфиг | свойства конфига, идемпотентность |
| `Type C — Investigation` | работает в CLI, отвечает на вопросы | воспроизводимость находки |
| `Type D — Code` | пишет `.py` | поведение программы |

**Прогрессивная автономия.** S1–S3 — полный каркас и эталон; S4–S5 — каркас,
эталон после попытки; S6–S7 — интерфейсы; S8 — только договор. Убывание
подсказок совмещено с сюжетом, а не введено молча.

---

## Указатель серий

## Season 1: Shell & Foundations

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s01e01`](../season-01-shell-foundations/s01e01-terminal-awakening) | pwd — ориентация в дереве файловой системы | Type A — Automation | ~45 мин | ⭐ |
| [`s01e02`](../season-01-shell-foundations/s01e02-ls-look-around) | ls — увидеть содержимое каталога, включая скрытое | Type C — Investigation | ~50 мин | ⭐ |
| [`s01e03`](../season-01-shell-foundations/s01e03-cd-cat-navigate) | cd — перемещение по дереву; cat/less — чтение файлов | Type C — Investigation | ~50 мин | ⭐ |
| [`s01e04`](../season-01-shell-foundations/s01e04-file-operations) | файловые операции — mkdir, cp, mv, touch, rm; и man как источник правды | Type B — Configuration | ~50 мин | ⭐ |
| [`s01e05`](../season-01-shell-foundations/s01e05-editing-files) | правка файлов в терминале — nano, vim, выживание в vi | Type B — Configuration | ~55 мин | ⭐⭐ |
| [`s01e06`](../season-01-shell-foundations/s01e06-find-automation) | find — рекурсивный обход дерева с условиями | Type A — Automation | ~55 мин | ⭐⭐ |
| [`s01e07`](../season-01-shell-foundations/s01e07-variables-ping) | переменные bash + код возврата ($?) | Type A — Automation | ~55 мин | ⭐⭐ |
| [`s01e08`](../season-01-shell-foundations/s01e08-conditions-loops) | условия (if) + цикл по файлу (while read) | Type A — Automation | ~55 мин | ⭐⭐ |
| [`s01e09`](../season-01-shell-foundations/s01e09-logging-monitor) | перенаправление вывода и метки времени — журнал работы | Type A — Automation | ~60 мин | ⭐⭐⭐ |
| [`s01e10`](../season-01-shell-foundations/s01e10-grep-pipes) | grep (фильтр строк) + конвейер (\|) | Type C — Investigation | ~50 мин | ⭐⭐ |
| [`s01e11`](../season-01-shell-foundations/s01e11-awk-stats) | awk (поля строки) + sort \| uniq -c \| sort -rn (рейтинг) | Type C — Investigation | ~55 мин | ⭐⭐ |
| [`s01e12`](../season-01-shell-foundations/s01e12-sed-log-analyzer) | sed (потоковая правка) + сборка отчёта из готовых инструментов | Type B — Configuration/Tools | ~60 мин | ⭐⭐⭐ |
| [`s01e13`](../season-01-shell-foundations/s01e13-apt-dpkg) | apt (пакеты и репозитории) + dpkg (статус установленного) | Type B — Configuration/Tools | ~50 мин | ⭐⭐ |
| [`s01e14`](../season-01-shell-foundations/s01e14-batch-report) | пакетная установка (xargs) + отчёт о состоянии системы | Type B — Configuration/Tools | ~55 мин | ⭐⭐⭐ |
| [`s01e15`](../season-01-shell-foundations/s01e15-permissions-basics) | владелец, группа, rwx, chmod, восьмеричная запись | Type A — Automation | ~50 мин | ⭐⭐ |
| [`s01e16`](../season-01-shell-foundations/s01e16-sudo-basics) | пользователи и группы, sudo как механизм, чтение чужого ls -l | Type C — Investigation | ~50 мин | ⭐⭐ |

**Итого по сезону:** 16 серий, 14 ч 05 мин чистого времени.

## Season 2: Networking

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s02e01`](../season-02-networking/s02e01-tcpip-addressing) | IPv4-адресация (private/public, класс) и модель TCP/IP | Type A — Automation | ~50 мин | ⭐⭐ |
| [`s02e02`](../season-02-networking/s02e02-ports-sockets) | порты и сокеты — ss, состояние LISTEN, адрес привязки | Type C — Investigation | ~50 мин | ⭐⭐ |
| [`s02e03`](../season-02-networking/s02e03-net-diagnostics) | диагностика доступности — ping/ICMP, RTT, traceroute | Type A — Automation | ~55 мин | ⭐⭐ |
| [`s02e04`](../season-02-networking/s02e04-dns-lookup) | разрешение имён — dig, типы записей, порядок резолва | Type C — Investigation | ~50 мин | ⭐⭐ |
| [`s02e05`](../season-02-networking/s02e05-dns-spoofing-guard) | обнаружение подмены DNS сверкой с эталоном | Type B — Configuration/Tools | ~55 мин | ⭐⭐⭐ |
| [`s02e06`](../season-02-networking/s02e06-firewall-ufw) | правила фаервола — default-deny, чтение ufw status, опасные ALLOW | Type C — Investigation | ~50 мин | ⭐⭐⭐ |
| [`s02e07`](../season-02-networking/s02e07-block-botnet) | генерация правил блокировки из списка адресов | Type B — Configuration/Tools | ~55 мин | ⭐⭐⭐ |
| [`s02e08`](../season-02-networking/s02e08-ssh-keys) | SSH-ключи — права приватного ключа, типы, авторизация без пароля | Type A — Automation | ~50 мин | ⭐⭐ |
| [`s02e09`](../season-02-networking/s02e09-ssh-hardening) | закалка sshd_config — директивы, порядок применения, откат | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s02e10`](../season-02-networking/s02e10-ssh-tunnels) | SSH-туннели — ProxyJump, -L, -R, -D, ~/.ssh/config | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s02e11`](../season-02-networking/s02e11-wireguard) | WireGuard — ключи, AllowedIPs, cryptokey routing, NAT | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s02e12`](../season-02-networking/s02e12-firewall-log) | журнал фаервола, ufw limit, что видно и чего не видно | Type C — Investigation | ~55 мин | ⭐⭐⭐ |

**Итого по сезону:** 12 серий, 10 ч 35 мин чистого времени.

## Season 3: System Administration

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s03e01`](../season-03-system-administration/s03e01-users-groups) | учётные записи, группы и UID — /etc/passwd, /etc/group, /etc/shadow | Type C — Investigation | ~50 мин | ⭐⭐ |
| [`s03e02`](../season-03-system-administration/s03e02-permissions) | права на файлы — rwx, восьмеричная запись, SUID/SGID/sticky | Type C — Investigation | ~55 мин | ⭐⭐⭐ |
| [`s03e03`](../season-03-system-administration/s03e03-sudo) | sudo, /etc/sudoers.d, принцип наименьших привилегий | Type B — Configuration | ~60 мин | ⭐⭐⭐ |
| [`s03e04`](../season-03-system-administration/s03e04-processes) | процессы, PID/PPID, состояния, сигналы, /proc | Type C — Investigation | ~55 мин | ⭐⭐⭐ |
| [`s03e05`](../season-03-system-administration/s03e05-systemd-service) | systemd, unit-файлы, зависимости, hardening служб | Type B — Configuration | ~60 мин | ⭐⭐⭐ |
| [`s03e06`](../season-03-system-administration/s03e06-systemd-timers) | systemd.timer, OnCalendar, Persistent, Type=oneshot | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s03e07`](../season-03-system-administration/s03e07-journalctl) | journald, journalctl, приоритеты, восстановление хронологии | Type C — Investigation | ~55 мин | ⭐⭐⭐ |
| [`s03e08`](../season-03-system-administration/s03e08-disks-fs) | устройства, файловые системы, df/du, inode, удалённые файлы | Type C — Investigation | ~55 мин | ⭐⭐⭐ |
| [`s03e09`](../season-03-system-administration/s03e09-lvm) | LVM — физические тома, группы, логические тома, расширение | Type A — Automation | ~55 мин | ⭐⭐⭐ |
| [`s03e10`](../season-03-system-administration/s03e10-fstab) | /etc/fstab, UUID, опции монтирования, порядок fsck | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s03e11`](../season-03-system-administration/s03e11-backup-rsync) | стратегии бэкапа, rsync, инкремент через жёсткие ссылки | Type A — Automation | ~60 мин | ⭐⭐⭐ |
| [`s03e12`](../season-03-system-administration/s03e12-logrotate) | logrotate, postrotate, delaycompress, глубина хранения | Type B — Configuration | ~50 мин | ⭐⭐ |
| [`s03e13`](../season-03-system-administration/s03e13-restore-check) | восстановление, проверка целостности, RTO/RPO | Type A — Automation | ~60 мин | ⭐⭐⭐ |

**Итого по сезону:** 13 серий, 12 ч 05 мин чистого времени.

## Season 4: DevOps & Automation

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s04e01`](../season-04-devops-automation/s04e01-git-history) | три зоны git, коммиты, ветки, чтение истории | Type C — Investigation | ~55 мин | ⭐⭐⭐ |
| [`s04e02`](../season-04-devops-automation/s04e02-branches-prepush) | ветки, слияние, диапазон коммитов, проверка до отправки | Type A — Automation | ~55 мин | ⭐⭐⭐ |
| [`s04e03`](../season-04-devops-automation/s04e03-gitignore-secrets) | .gitignore, порядок правил, отмена через «!», .env.example | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s04e04`](../season-04-devops-automation/s04e04-images-layers) | образы, слои, `docker history`, `inspect`, базовый образ | Type C — Investigation | ~55 мин | ⭐⭐⭐ |
| [`s04e05`](../season-04-devops-automation/s04e05-dockerfile) | Dockerfile — база, порядок слоёв, USER, exec-форма, .dockerignore | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s04e06`](../season-04-devops-automation/s04e06-compose) | compose.yaml — службы, сети, тома, секреты, порядок запуска | Type B — Configuration | ~55 мин | ⭐⭐⭐ |
| [`s04e07`](../season-04-devops-automation/s04e07-ci-pipeline) | конвейер CI — триггеры, граф job, закреплённые версии, секреты | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s04e08`](../season-04-devops-automation/s04e08-deploy-rollback) | откат релиза — журнал выкатов, выбор цели, граница отката | Type A — Automation | ~60 мин | ⭐⭐⭐⭐ |
| [`s04e09`](../season-04-devops-automation/s04e09-ansible-inventory) | инвентарь Ansible — группы, оси, переменные и приоритет | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s04e10`](../season-04-devops-automation/s04e10-ansible-check) | режим проверки — что ansible собирается сделать и о чём молчит | Type C — Investigation | ~55 мин | ⭐⭐⭐⭐ |
| [`s04e11`](../season-04-devops-automation/s04e11-iac-audit) | аудит репозитория инфраструктуры — восемь разделов, две цифры | Type A — Automation | ~65 мин | ⭐⭐⭐⭐⭐ |
| [`s04e12`](../season-04-devops-automation/s04e12-ansible-playbook) | playbook — модули, идемпотентность, handlers, области видимости | Type B — Configuration | ~60 мин | ⭐⭐⭐⭐⭐ |

**Итого по сезону:** 12 серий, 11 ч 20 мин чистого времени.

## Season 5: Security & Pentesting

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s05e01`](../season-05-security-pentesting/s05e01-attack-surface) | поверхность атаки — какие порты открыты и кто их открыл | Type A — Automation | ~55 мин | ⭐⭐⭐⭐ |
| [`s05e02`](../season-05-security-pentesting/s05e02-audit-report) | отчёт аудита и приоритизация уязвимостей | Type C — Investigation | ~55 мин | ⭐⭐⭐⭐ |
| [`s05e03`](../season-05-security-pentesting/s05e03-file-integrity) | контроль целостности файлов (AIDE) — что под наблюдением, что нет | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s05e04`](../season-05-security-pentesting/s05e04-fail2ban) | автоматическая блокировка перебора (fail2ban) | Type B — Configuration | ~50 мин | ⭐⭐⭐ |
| [`s05e05`](../season-05-security-pentesting/s05e05-access-log-trace) | реконструкция атаки по журналу веб-сервера | Type C — Investigation | ~55 мин | ⭐⭐⭐⭐ |
| [`s05e06`](../season-05-security-pentesting/s05e06-pam-passwords) | политика паролей и блокировка учётной записи (PAM/pwquality) | Type B — Configuration | ~50 мин | ⭐⭐⭐ |
| [`s05e07`](../season-05-security-pentesting/s05e07-pentest-triage) | триаж отчёта пентеста — что настоящее, что шум, что первым | Type C — Investigation | ~50 мин | ⭐⭐⭐⭐ |
| [`s05e08`](../season-05-security-pentesting/s05e08-auditd) | аудит действий ядра (auditd) — что писать и как защитить | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s05e09`](../season-05-security-pentesting/s05e09-forensics-snapshot) | криминалистический снимок — сверять виды, которым нельзя верить | Type C — Investigation | ~55 мин | ⭐⭐⭐⭐⭐ |
| [`s05e10`](../season-05-security-pentesting/s05e10-timeline) | хронология инцидента — свести журналы в одну линию времени | Type A — Automation | ~60 мин | ⭐⭐⭐⭐⭐ |
| [`s05e11`](../season-05-security-pentesting/s05e11-hardening) | укрепление — параметры ядра (sysctl) и AppArmor | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s05e12`](../season-05-security-pentesting/s05e12-cis-check) | проверка машины по CIS-бенчмарку — проверяемый ответ с числом | Type A — Automation | ~60 мин | ⭐⭐⭐⭐⭐ |

**Итого по сезону:** 12 серий, 10 ч 55 мин чистого времени.

## Season 6: Embedded Linux & IoT Security

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s06e01`](../season-06-embedded-iot/s06e01-board-recon) | опознание платы — /proc/cpuinfo, дерево устройств, архитектура | Type C — Investigation | ~50 мин | ⭐⭐⭐ |
| [`s06e02`](../season-06-embedded-iot/s06e02-gpio-sysfs) | GPIO через sysfs — управление железом обычными файлами | Type A — Automation | ~55 мин | ⭐⭐⭐ |
| [`s06e03`](../season-06-embedded-iot/s06e03-boot-config) | загрузка платы — config.txt, cmdline.txt, overlay дерева | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s06e04`](../season-06-embedded-iot/s06e04-readonly-root) | корень только для чтения, tmpfs и overlayfs, износ SD-карты | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s06e05`](../season-06-embedded-iot/s06e05-mavlink-telemetry) | телеметрия MAVLink — разбор кадра и разбор потока | Type C — Investigation | ~55 мин | ⭐⭐⭐⭐ |
| [`s06e06`](../season-06-embedded-iot/s06e06-mission-check) | валидатор плана полёта — проверка маршрута на земле | Type A — Automation | ~60 мин | ⭐⭐⭐⭐ |
| [`s06e07`](../season-06-embedded-iot/s06e07-failsafe) | отказоустойчивость — failsafe, RTL, геозона как параметры | Type B — Configuration | ~55 мин | ⭐⭐⭐⭐ |
| [`s06e08`](../season-06-embedded-iot/s06e08-mqtt-dump) | MQTT — темы, уровни доставки, retained и кто это слышит | Type C — Investigation | ~50 мин | ⭐⭐⭐⭐ |
| [`s06e09`](../season-06-embedded-iot/s06e09-mqtt-broker) | брокер MQTT — TLS, аутентификация, права по темам | Type B — Configuration | ~60 мин | ⭐⭐⭐⭐ |
| [`s06e10`](../season-06-embedded-iot/s06e10-sensor-client) | клиент-датчик — разбор показаний, очередь, переподключение | Type D — Code | ~70 мин | ⭐⭐⭐⭐⭐ |
| [`s06e11`](../season-06-embedded-iot/s06e11-kernel-module) | модуль ядра — сборка, загрузка, параметры, ресурсы | Type D — Code | ~70 мин | ⭐⭐⭐⭐⭐ |
| [`s06e12`](../season-06-embedded-iot/s06e12-char-device) | символьное устройство — file_operations, read, copy_to_user | Type D — Code | ~75 мин | ⭐⭐⭐⭐⭐ |

**Итого по сезону:** 12 серий, 11 ч 50 мин чистого времени.

## Season 7: Production & Advanced Topics

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s07e01`](../season-07-production-advanced/s07e01-cluster-recon) | состояние кластера — снимки kubectl, события, причины незапуска | Type C — Investigation | ~55 мин | ⭐⭐⭐⭐ |
| [`s07e02`](../season-07-production-advanced/s07e02-deployment-manifest) | манифест Deployment — образ, ресурсы, пробы | Type B — Configuration | ~65 мин | ⭐⭐⭐⭐ |
| [`s07e03`](../season-07-production-advanced/s07e03-service-config) | Service и ConfigMap — как под находят и откуда он берёт настройки | Type B — Configuration | ~60 мин | ⭐⭐⭐⭐ |
| [`s07e04`](../season-07-production-advanced/s07e04-rollout-stuck) | застрявший выкат — почему обновление не едет и как это увидеть | Type A — Automation | ~70 мин | ⭐⭐⭐⭐ |
| [`s07e05`](../season-07-production-advanced/s07e05-metrics-exporter) | экспозиция метрик — имена, типы, единицы, кардинальность | Type A — Automation | ~70 мин | ⭐⭐⭐⭐ |
| [`s07e06`](../season-07-production-advanced/s07e06-alert-rules) | правила оповещения — rate, окно, выдержка, порог | Type B — Configuration | ~65 мин | ⭐⭐⭐⭐ |
| [`s07e07`](../season-07-production-advanced/s07e07-alert-routing) | маршрутизация, группировка и подавление оповещений | Type B — Configuration | ~60 мин | ⭐⭐⭐⭐ |
| [`s07e08`](../season-07-production-advanced/s07e08-bottleneck) | поиск узкого места по методу USE | Type C — Investigation | ~60 мин | ⭐⭐⭐⭐ |
| [`s07e09`](../season-07-production-advanced/s07e09-latency-percentiles) | перцентиль по гистограмме и разрешение измерения | Type D — Code | ~75 мин | ⭐⭐⭐⭐⭐ |
| [`s07e10`](../season-07-production-advanced/s07e10-tuning) | тюнинг ядра, обоснованный измерением | Type B — Configuration | ~60 мин | ⭐⭐⭐⭐ |
| [`s07e11`](../season-07-production-advanced/s07e11-selinux) | SELinux — контексты, режимы, разбор отказов | Type C — Investigation | ~65 мин | ⭐⭐⭐⭐⭐ |
| [`s07e12`](../season-07-production-advanced/s07e12-slo) | SLO и бюджет ошибок | Type D — Code | ~80 мин | ⭐⭐⭐⭐⭐ |

**Итого по сезону:** 12 серий, 13 ч 05 мин чистого времени.

## Season 8: Final Operation

| Серия | Концепт | Тип | Время | Сложность |
|---|---|---|---|---|
| [`s08e01`](../season-08-final-operation/s08e01-first-wave) | атака против наплыва — что исчерпано на самом деле | Type C — Investigation | ~65 мин | ⭐⭐⭐⭐ |
| [`s08e02`](../season-08-final-operation/s08e02-syn-defense) | защита от SYN-флуда — параметры стека и правила фильтра | Type B — Configuration | ~70 мин | ⭐⭐⭐⭐ |
| [`s08e03`](../season-08-final-operation/s08e03-blackhole) | когда фильтровать поздно — что отдать и по какому правилу | Type D — Code | ~75 мин | ⭐⭐⭐⭐⭐ |
| [`s08e04`](../season-08-final-operation/s08e04-zeroday) | временная мера против уязвимости, для которой нет патча | Type B — Configuration | ~65 мин | ⭐⭐⭐⭐ |
| [`s08e05`](../season-08-final-operation/s08e05-persistence) | где в Linux закрепляются и как это найти | Type A — Automation | ~75 мин | ⭐⭐⭐⭐⭐ |
| [`s08e06`](../season-08-final-operation/s08e06-timeline) | приведение времени к одной оси | Type D — Code | ~80 мин | ⭐⭐⭐⭐⭐ |
| [`s08e07`](../season-08-final-operation/s08e07-supply-chain) | цепочка поставок — что запущено против того, что опубликовано | Type A — Automation | ~70 мин | ⭐⭐⭐⭐ |
| [`s08e08`](../season-08-final-operation/s08e08-cleanup-proof) | очистка как состояние, а не как действие | Type A — Automation | ~70 мин | ⭐⭐⭐⭐ |
| [`s08e09`](../season-08-final-operation/s08e09-weber-case) | что доказывает журнал и чего он не доказывает | Type C — Investigation | ~70 мин | ⭐⭐⭐⭐ |
| [`s08e10`](../season-08-final-operation/s08e10-scope-disclosure) | границы активных действий и раскрытия | Type B — Configuration | ~70 мин | ⭐⭐⭐⭐ |
| [`s08e11`](../season-08-final-operation/s08e11-rootkit) | обнаружение руткита сравнением двух взглядов | Type C — Investigation | ~70 мин | ⭐⭐⭐⭐⭐ |
| [`s08e12`](../season-08-final-operation/s08e12-shadow-core) | приёмка всей инфраструктуры одной проверкой | Type D — Code | ~90 мин | ⭐⭐⭐⭐⭐ |

**Итого по сезону:** 12 серий, 14 ч 30 мин чистого времени.

---

**Всего: 101 серия, 98 ч 25 мин чистого времени на задачи.**

Время получено обходом шапок всех серий, а не назначено на глаз.

---

## Хронометраж по сезонам

Получен обходом шапок серий, а не назначен на глаз. Прежняя
заявка «~120–160 часов» ничем не подтверждалась.

| Сезон | Серий | Время | Заметно, что |
|---|---|---|---|
| S1 Shell | 16 | 14 ч 05 мин | больше всего серий: концепты мелкие, шаг короткий |
| S2 Networking | 12 | 10 ч 35 мин | самый лёгкий по времени |
| S3 SysAdmin | 13 | 12 ч 05 мин | самый плотный по темам |
| S4 DevOps | 12 | 11 ч 20 мин | сквозной `shadow_iac` собирается по сериям |
| S5 Security | 12 | 10 ч 55 мин | разбор снимков, а не настройка |
| S6 Embedded | 12 | 11 ч 50 мин | первый Type D и модуль ядра |
| S7 Production | 12 | 13 ч 05 мин | рост во второй половине курса |
| S8 Final | 12 | 14 ч 30 мин | самый дорогой: каркас содержит только договор |

Рост во второй половине не случаен: с Season 6 появляется Type D, с Season 7
исчезают подсказки, и время уходит на проектирование, а не на набор команд.

---

## Сюжетный канон

Описания эпизодов, биографии и хронология вынесены в отдельные документы,
чтобы не дублироваться с сериями:

- [SCENARIO.md](SCENARIO.md) — сценарий операции по дням, кроссовер с MOONLIGHT
- [CHARACTERS.md](CHARACTERS.md) — 27 персонажей, включая разворот с Вебером и личность Архитектора
- [LOCATIONS.md](LOCATIONS.md) — локации и их атмосфера

**Ключевые узлы сюжета** (спойлеры — в самих документах):

| Где | Что происходит |
|---|---|
| S1–S4 | Макс втягивается в операцию, не зная её цели |
| S5 | первый кризис: APT-атака, форензика вместо настройки |
| S6 | разведка в Шэньчжэне, попытка перехвата дрона |
| S7 | контур `aurora` построен, измерен и описан числом |
| S8 | атака, разбор, контрнаступление по ордеру, приёмка |

---

## Что дальше после курса

Курс заканчивается приёмкой `shadow_core` (`s08e12`), которая возвращает ноль
или не возвращает. Дальше — то, к чему он готовил:

- **работа**: инженер эксплуатации, SRE, администратор, DevOps;
- **сертификации**: LFCS, RHCSA, CKA — большая часть их программы пройдена;
- **сестринский курс OPERATION MOONLIGHT** — C и системное программирование:
  из чего сделано всё, что здесь проверялось;
- **своя инфраструктура**: приёмка из финала — рабочий шаблон для неё.

---

*Указатель серий генерируется: `bash tools/gen_index.sh`. Библиография —
`bash tools/gen_bibliography.sh`. Оба обходят сами серии, поэтому расходиться
с ними не могут.*
