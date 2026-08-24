# RESOURCES — библиография курса

**Собрано скриптом `tools/gen_bibliography.sh`** из разделов «Книги и справка»
и «Куда смотреть дальше» всех `theory.md` курса. Это не список «что полезно
почитать по Linux», а реальная опора серий: рядом с каждым источником указано,
где именно он нужен.

**Источников: 358. Серий, из которых собрано: 101.**

Пересобрать: `bash tools/gen_bibliography.sh > RESOURCES.md`

---

| Источник | Где нужен |
|---|---|
| **Advanced Bash-Scripting Guide**, глава про коды возврата — таблица соглашений. | s01e07 |
| **Aho, Kernighan, Weinberger, «The AWK Programming Language»** — книга авторов языка, тонкая и до сих пор лучшая. | s01e11 |
| **BashFAQ 001** — «How can I read a file line by line?»: канонический разбор идиомы `while IFS= read -r`. | s01e08 |
| **BashGuide, раздел Redirection** — разбор `2>&1` и порядка операций. | s01e09 |
| **Chacon & Straub, «Pro Git»** — главы 2, 3, 7; бесплатно на git-scm.com | s04e01, s04e02 |
| **Dougherty, Robbins, «sed & awk»** — классика O'Reilly, если понадобится всерьёз. | s01e12 |
| **FHS (Filesystem Hierarchy Standard)** — почему `/etc`, а не `/config`: стандарт, которому следуют дистрибутивы. | s01e01 |
| **Friedl, «Mastering Regular Expressions»** — если regex понадобятся всерьёз. | s01e10 |
| **Kernighan & Pike, «The UNIX Programming Environment»** — откуда взялась философия «одна программа — одна задача» и почему `cat` умеет склеивать. | s01e03 |
| **Kerrisk, «The Linux Programming Interface», гл. 18** — каталоги, ссылки и CWD глазами ядра: откуда `pwd` берёт ответ. | s01e01, s01e04 |
| **Kurose, Ross, «Computer Networking: A Top-Down Approach»** — если захочется теории всерьёз. | s02e01 |
| **Liu, Albitz, «DNS and BIND»** — классика, если понадобится глубоко. | s02e04 |
| **Love, «Linux System Programming»** — `fork`/`exec`, сигналы, системные вызовы. | s03e04 |
| **Nemeth и др., «UNIX and Linux System Administration Handbook»** — глава о software management, включая сравнение семейств. | s01e13, s01e14, s02e01, s02e02, s02e03, s02e06, s03e01, s03e02, s03e03, s03e04, s03e05, s03e06, s03e07, s03e08, s03e09, s03e10, s03e11, s03e12, s03e13 |
| **Nemeth, «UNIX and Linux System Administration Handbook»** — `find` в задачах аудита. | s01e06 |
| **RFC 1034 / 1035** (основы DNS), **RFC 4033** (DNSSEC), **RFC 7858** (DNS over TLS) | s02e04 |
| **RFC 1918** (приватные диапазоны), **RFC 4632** (CIDR), **RFC 6598** (CGNAT) | s02e01 |
| **RFC 4251–4254** (архитектура SSH), **RFC 8709** (ed25519 в SSH) | s02e08 |
| **RFC 4254** (каналы и проброс портов в SSH) | s02e09 |
| **RFC 4987** — SYN-флуд и меры противодействия. | s02e07 |
| **RFC 5452** (устойчивость DNS к подмене), **RFC 4033–4035** (DNSSEC), **RFC 7858** (DoT), **RFC 8484** (DoH) | s02e05 |
| **RFC 6335** — реестр портов IANA и правила их распределения. | s02e02 |
| **RFC 792** (ICMP), **RFC 1191** (Path MTU Discovery) | s02e03 |
| **Robbins, «Learning the vi and Vim Editors»** — если захочется вглубь. | s01e05 |
| **Shotts, «The Linux Command Line», гл. 12** — мягкое введение в `vi`. | s01e05 |
| **Shotts, «The Linux Command Line», гл. 15 и 20** — пакеты и `xargs` в конвейерах. | s01e14 |
| **Shotts, «The Linux Command Line», гл. 15** — управление пакетами. | s01e13 |
| **Shotts, «The Linux Command Line», гл. 17** — поиск файлов, `find` и `xargs`. | s01e06 |
| **Shotts, «The Linux Command Line», гл. 19–20** — регулярные выражения и обработка текста. | s01e10 |
| **Shotts, «The Linux Command Line», гл. 20** — обработка текста. | s01e11 |
| **Shotts, «The Linux Command Line», гл. 21** — `sed`, потоковое редактирование. | s01e12 |
| **Shotts, «The Linux Command Line», гл. 24–26** — скрипты, переменные, ветвление. | s01e07 |
| **Shotts, «The Linux Command Line», гл. 27–29** — ветвление, циклы, чтение построчно. | s01e08 |
| **Shotts, «The Linux Command Line», гл. 2–3** — навигация, дерево, пути. [Бесплатно](https://linuxcommand.org/tlcl.php). | s01e01 |
| **Shotts, «The Linux Command Line», гл. 3** — обзор файловой системы. | s01e02, s01e03 |
| **Shotts, «The Linux Command Line», гл. 4** — операции с файлами и каталогами. | s01e04 |
| **Shotts, «The Linux Command Line», гл. 6** — перенаправление, `tee`, `/dev/null`. | s01e09 |
| **XDG Base Directory Specification** — куда современные программы кладут конфиги и почему не всё подряд валится в `~`. | s01e02 |
| AIDE и `dm-verity` — контроль целостности после факта и до него | s08e05 |
| Alex Birsan, «Dependency Confusion» — разбор приёма с публичными и внутренними именами | s08e07 |
| Ansible docs: «How to build your inventory», «Variable precedence: where should I put a variable?», «Patterns: targeting hosts and groups» | s04e09 |
| Ansible docs: «Intro to playbooks», «Handlers: running operations on change», «Roles», «Protecting sensitive data with Ansible vault» | s04e12 |
| Ansible docs: «Validating tasks: check mode and diff mode», «Playbook keywords», «Understanding variable precedence» | s04e10 |
| Ansible documentation: Idempotency — то же свойство в развёртывании | s08e08 |
| ArduPilot: Failsafe (Radio/GCS/Battery/EKF), RTL, SmartRTL, Geofencing | s06e07 |
| ArduPilot: Flight Modes, Failsafe, EKF — что означают режимы и почему они переключаются | s06e05 |
| ArduPilot: Mission Command List, Prearm Safety Checks, Geofencing, Terrain Following | s06e06 |
| Argo Rollouts, Flagger — как выглядит канареечный выкат, когда его не делают руками | s07e04 |
| Brendan Gregg, «Systems Performance» — гл. 2, 6, 9; метод USE и утилиты | s07e08 |
| Brendan Gregg, метод USE: <http://www.brendangregg.com/usemethod.html> | s07e05 |
| Buildroot / Yocto: сборка неизменяемого образа целиком | s06e04 |
| Buildroot и Yocto — сборка образа целиком под целевую архитектуру (за рамками курса, но это следующий шаг после ручной кросс-компиляции) | s06e01 |
| CFAA и аналоги в других юрисдикциях — что закон считает несанкционированным доступом | s08e10 |
| CFS bandwidth control: `Documentation/scheduler/sched-bwc.rst` в исходниках ядра — про то, как устроен троттлинг | s07e02 |
| CIS Benchmarks (Kernel, MAC); Kernel Self-Protection Project (KSPP) | s05e11 |
| CIS Benchmarks (раздел auditd), DISA STIG; проект Neo23x0/auditd | s05e08 |
| CIS Benchmarks, раздел «Network» — какие службы отключать по умолчанию | s05e01 |
| CIS Benchmarks: «1.3 Filesystem Integrity Checking» | s05e03 |
| CIS Benchmarks; NIST SP 800-53 / 800-171 (каталоги контролей) | s05e12 |
| CISA: «Known Exploited Vulnerabilities Catalog» | s05e02 |
| Cliff Stoll, «The Cuckoo's Egg» — расследование, где атрибуция заняла год и оказалась верной | s08e09 |
| Cloudflare Blog, разборы SYN-флудов — редкий случай публичных измерений на большом масштабе | s08e02 |
| D. J. Bernstein, «SYN cookies» — исходное описание механизма | s08e01 |
| Datasheet BCM2711, раздел GPIO — предельные токи и напряжения | s06e02 |
| Debian Policy Manual, раздел о состояниях пакетов — если захочется первоисточник. | s01e13 |
| Devicetree Specification — devicetree.org | s06e01 |
| Docker docs: «Compose file reference», «Compose networking», «Secrets in Compose», «Healthcheck» | s04e06 |
| Docker docs: «Dockerfile reference», «Best practices for writing Dockerfiles», «Multi-stage builds», «Build secrets» | s04e05 |
| FIRST, руководства по координированному раскрытию | s08e10 |
| FIRST, спецификация CVSS — что именно оценивает шкала и чего она не оценивает | s08e04 |
| FIRST.org: «CVSS v3.1 Specification Document»; EPSS Model | s05e02 |
| GDPR, статьи 5 и 25 — минимизация данных и защита по умолчанию | s08e10 |
| GTFOBins — каталог «безобидных» команд с выходом в оболочку. | s03e03 |
| Gil Tene, «How NOT to Measure Latency» — доклад, из которого пошло понятие координированного упущения | s07e09 |
| GitHub docs: «Workflow syntax», «Security hardening for GitHub Actions», «Using environments for deployment» | s04e07 |
| Google SRE Book, гл. «Postmortem Culture: Learning from Failure» | s04e08 |
| Google SRE Book, гл. «Postmortem Culture» — как список правил пополняется после инцидентов | s04e11 |
| Google SRE Book, глава «Data Integrity: What You Read Is What You Wrote» | s03e13 |
| Grafana documentation: Provision dashboards, Recording rules — панель как код и предрасчёт | s07e05 |
| HdrHistogram — библиотека, хранящая распределение с заданной относительной погрешностью | s07e09 |
| Heuer, «Psychology of Intelligence Analysis» — разбор конкурирующих гипотез как метод | s08e09 |
| HiveMQ MQTT Essentials — короткие разборы каждой возможности | s06e08 |
| IANA Time Zone Database (`tzdata`) — почему смещение вычисляют, а не хранят | s08e06 |
| ISO/IEC 29147 и 30111 — раскрытие уязвимостей: приём и обработка | s08e10 |
| James Kettle, «HTTP Desync Attacks» — как расхождение разборщиков превращается в атаку | s08e04 |
| Kahneman, «Thinking, Fast and Slow» — подтверждающее искажение | s08e09 |
| Kernel Newbies (kernelnewbies.org) — первые шаги и разбор частых ошибок | s06e11 |
| Kubernetes docs: Deployments (Rolling Update, Progress Deadline, Pausing), ReplicaSet, Disruptions | s07e04 |
| Kubernetes docs: Managing Resources for Containers; Pod Quality of Service Classes; Node-pressure Eviction; Secrets; Server-Side Apply | s07e02 |
| Kubernetes docs: Pod Lifecycle, Configure Liveness/Readiness/Startup Probes, Assign Memory Resources | s07e01 |
| Kubernetes docs: Service, EndpointSlices, DNS for Services and Pods, Virtual IPs and Service Proxies, ConfigMap | s07e03 |
| Kubernetes documentation: Using sysctls in a Cluster — про безопасные и небезопасные параметры | s07e10 |
| Linux Audit documentation (redhat.com/security) | s05e08 |
| MAVProxy: `param` — загрузка, сравнение, выгрузка наборов | s06e07 |
| MITRE ATT&CK, TA0003 Persistence — перечень способов с примерами из практики | s08e05 |
| MQTT Explorer, MQTT.fx — графические клиенты для разбора сети | s06e08 |
| Marek Majkowski (Cloudflare), «SYN packet handling in the wild» — две очереди в подробностях | s07e10 |
| Martin Fowler: «BlueGreenDeployment», «CanaryRelease», «ParallelChange» | s04e08 |
| NIST SP 800-61r2 — обработка инцидентов, разделы Containment, Eradication, Recovery | s08e08 |
| NIST SP 800-63B «Digital Identity Guidelines: Authentication» — длина, отказ от ротации и композиции | s05e06 |
| NIST SP 800-86 — интеграция криминалистических методов, что считается свидетельством | s08e09 |
| NIST SP 800-92 (управление журналами) — почему укорачивание лога есть сигнал | s05e03 |
| NSA/CISA «Kubernetes Hardening», аналогичные руководства по Linux | s05e11 |
| Nemeth и др., «UNIX and Linux System Administration Handbook» — фильтрация трафика. | s02e07 |
| Nicole Forsgren и др., «Accelerate» — время восстановления как метрика, а не частота отказов | s04e08 |
| Nicole Forsgren, Jez Humble, Gene Kim, «Accelerate» — что именно измеряют DORA-метрики | s04e07 |
| OASIS MQTT 3.1.1 и MQTT 5.0 — первоисточники | s06e08 |
| OCI Image Specification и Distribution Specification — манифесты, индексы, отпечатки | s08e07 |
| OWASP IoT Top 10; ETSI EN 303 645 — требования к потребительским IoT-устройствам | s06e09 |
| OWASP, «Virtual Patching Best Practices» — приём целиком, включая порядок снятия | s08e04 |
| OWASP: «Blocking Brute Force Attacks»; NIST SP 800-63B (аутентификация, ограничение попыток) | s05e04 |
| OWASP: «SQL Injection», «Testing for SQL Injection (OTG-INPVAL-005)» | s05e05 |
| OWASP: «Secrets Management Cheat Sheet», «CI/CD Security Cheat Sheet» | s04e11 |
| OWASP: «Web Security Testing Guide», «Risk Rating Methodology» | s05e07 |
| Open Policy Agent, InSpec, `goss` — политики и приёмка как исполняемый код | s08e12 |
| OpenSCAP, `scap-security-guide`, DISA STIG | s05e12 |
| OpenSSF Scorecard — почему закрепление версий действий проверяют автоматически | s04e07 |
| PTES и OSSTMM — методологии пентеста, разделы про область и правила ведения | s08e10 |
| PTES — Penetration Testing Execution Standard (этап Reporting) | s05e07 |
| PX4: Safety Configuration, Return Mode, Geofence | s06e07 |
| Prometheus documentation: Alerting rules, Recording rules, Query functions, Unit testing for rules | s07e06 |
| Prometheus documentation: Alertmanager — Configuration, Notification template examples, High availability | s07e07 |
| Prometheus documentation: Histograms and summaries; Native histograms; `histogram_quantile` | s07e09 |
| Prometheus documentation: Metric and label naming, Instrumentation, Histograms and summaries, Exposition formats, Relabeling | s07e05 |
| Prometheus documentation: Recording rules — SLI считают заранее, а не в момент запроса панели | s07e12 |
| QGroundControl: Plan View, форматы `.waypoints` и `.plan` | s06e06 |
| RFC 2827 / BCP 38 «Network Ingress Filtering» — почему подделка возможна и что с ней делают | s08e01 |
| RFC 2827 / BCP 38 — фильтрация подделки на входе | s08e03 |
| RFC 3339 и RFC 5424 — форматы времени, на которые стоит опираться | s08e06 |
| RFC 3882, RFC 5635 — blackhole и RTBH | s08e03 |
| RFC 4987 «TCP SYN Flooding Attacks and Common Mitigations» — систематический разбор мер и их цены | s08e01 |
| RFC 4987 — меры против SYN-флуда и цена каждой | s08e02 |
| RFC 5575 — Flowspec, правила фильтрации через BGP | s08e01 |
| RFC 5575, RFC 8955 — flowspec | s08e03 |
| RFC 7323 — масштабирование окна и метки времени: что теряется в режиме cookie | s08e02 |
| RFC 9112, §7 «Transfer Codings» — устройство chunked и требования к разбору | s08e04 |
| Raspberry Pi documentation → Computers → Configuration: `config.txt`, `cmdline.txt`, conditional filters | s06e03 |
| Red Hat, «Using SELinux» — практическая часть | s07e11 |
| Reproducible Builds — проект и перечень типовых источников недетерминизма | s08e07 |
| Rob Ewaschuk, «My Philosophy on Alerting» — короткий текст, из которого выросла половина практики | s07e06 |
| SANS FOR508 «Timeline Analysis»; `plaso`/`log2timeline`, Timesketch | s05e10 |
| SD Association: Physical Layer Specification — как устроено выравнивание износа | s06e04 |
| SELinux Notebook (Richard Haines) — свободная и самая полная книга по модели | s07e11 |
| SLSA — уровни зрелости цепочки поставок, от «есть сборка» до воспроизводимости | s08e07 |
| SPDX и CycloneDX — форматы перечня компонентов | s08e07 |
| Sparkplug B — соглашение о схеме тем и полезной нагрузке для промышленных систем | s06e08 |
| Thompson, «Reflections on Trusting Trust» — предел доверия в принципе | s08e11, s08e12 |
| Tom Wilkie, метод RED — доклад «Monitoring Microservices» | s07e05 |
| Troubleshooting: Debug Pods, Debug Running Pods, Determine the Reason for Pod Failure | s07e01 |
| U-Boot documentation (docs.u-boot.org) — если плата не Raspberry Pi | s06e03 |
| UEFI Secure Boot, TPM measured boot, `dm-verity` — цепочка доверенной загрузки | s08e11 |
| US-CERT TA14-017A — коэффициенты усиления по протоколам, единственный публичный свод | s08e03 |
| Volatility Framework (анализ дампов памяти); SANS FOR508 | s05e09 |
| WireGuard whitepaper — протокол и криптография | s02e11 |
| `/boot/overlays/README` на плате — документация всех overlay | s06e03 |
| `Documentation/ABI/` — правила для `sysfs`: почему «одно значение на файл» | s06e12 |
| `Documentation/admin-guide/kernel-parameters.txt` — параметры ядра | s06e03 |
| `Documentation/admin-guide/sysctl/` в исходниках ядра — единственный полный источник | s07e10 |
| `Documentation/dev-tools/kasan.rst`, `kmemleak.rst` | s06e11 |
| `Documentation/devicetree/bindings/` в исходниках ядра: как описывается каждое устройство | s06e01 |
| `Documentation/driver-api/`, `Documentation/filesystems/vfs.rst` | s06e12 |
| `Documentation/filesystems/overlayfs.rst`, `Documentation/admin-guide/blockdev/zram.rst` | s06e04 |
| `Documentation/gpio/sysfs.rst` и `Documentation/ABI/obsolete/sysfs-gpio` — интерфейс и его статус | s06e02 |
| `Documentation/kbuild/modules.rst`, `Documentation/core-api/memory-allocation.rst` | s06e11 |
| `Documentation/networking/ip-sysctl.rst` в дереве ядра — единственный источник, который не устаревает вместе со статьями | s08e02 |
| `Documentation/process/coding-style.rst` — стиль, принятый в ядре | s06e11 |
| `Documentation/timers/timers-howto.rst` в ядре — как там обращаются с кольцевыми счётчиками | s06e05 |
| `Documentation/userspace-api/media/v4l/` — V4L2, если дело дойдёт до камеры | s06e12 |
| `Documentation/w1/slaves/w1_therm.rst`; datasheet DS18B20 | s06e10 |
| `SITL` и параметры `SIM_*` для моделирования отказов | s06e07 |
| `amtool` — `config routes test`, `silence add`, `alert query` | s07e07 |
| `ansible-doc -l`, `ansible-doc file` — какие модули есть и что они умеют | s04e12 |
| `ansible-inventory --graph`, `--host`; `ansible-lint` | s04e09 |
| `ansible-lint` — набор правил, половину которых эта серия проверяет вручную | s04e12 |
| `ansible-playbook --check --diff`, `--limit`, `--tags`, `--list-tasks` | s04e10 |
| `arch/arm64/include/asm/cputype.h` — таблица implementer/part | s06e01 |
| `chkrootkit`, `rkhunter`, Volatility — инструменты перекрёстного и внешнего взгляда | s08e11 |
| `chronyc tracking`, `man 1 timedatectl` — чем измеряют расхождение | s08e06 |
| `common.xml`, `ardupilotmega.xml` — источники истины по номерам и полям | s06e05 |
| `cosign`, `in-toto` — подпись артефактов и подтверждение шагов сборки | s08e07 |
| `dnsutils`-под из документации — стандартный способ отладки разрешения имён изнутри кластера | s07e03 |
| `docker compose config`, `docker compose ps`, `docker scout` — проверка того, что получилось | s04e06 |
| `f2fs-tools`, `mkfs.f2fs` — если узел всё-таки много пишет | s06e04 |
| `git help everyday` — набор команд на каждый день | s04e01 |
| `git help workflows` — обзор схем ветвления | s04e02 |
| `git log -S`, `git log --all --name-only`, `git check-ignore -v`, `git filter-repo` | s04e11 |
| `git-secrets`, `gitleaks`, `trufflehog` — поиск секретов в истории | s04e03 |
| `github.com/github/gitignore` — наборы под язык и инструмент | s04e03 |
| `goaccess` — интерактивный разбор access.log; `urlencode`/`urldecode` | s05e05 |
| `hadolint` — линтер Dockerfile; `dive` — разбор слоёв | s04e05 |
| `help cd`, `man cat`, `man less`, `man head`, `man tail`, `man file` | s01e03 |
| `help if`, `help while`, `help read`, `help test`, `man bash` (Compound Commands, Parameter Expansion) | s01e08 |
| `jq` — если план в формате `.plan` | s06e06 |
| `k9s`, `stern` — удобный просмотр состояния и логов нескольких подов | s07e01 |
| `kubectl explain deployment.spec --recursive` — полная схема прямо из кластера | s07e02 |
| `kubectl explain deployment.status.conditions` | s07e04 |
| `kubectl explain pod.spec.containers.resources` — справка прямо из кластера | s07e01 |
| `kubectl explain service.spec`; `kubectl explain configmap` | s07e03 |
| `libgpiod` (git.kernel.org/pub/scm/libs/libgpiod) — `gpioinfo`, `gpioset`, `gpiomon`, привязки к Python | s06e02 |
| `man 1 git-commit` (`--author`, `-S`), `man 1 git-verify-commit` — почему поле и подпись разное | s08e09 |
| `man 2 rename`, `man 2 fsync` — почему переименование атомарно и когда этого мало | s08e08 |
| `man 2 stat` (поле `st_mode`), `man 7 inode` — как режим устроен внутри | s03e02 |
| `man 5 crontab`, `man anacron` | s03e06 |
| `man 5 fstab`, `man 8 mount`, `man 5 tmpfs`, `man 5 journald.conf` | s06e04 |
| `man 5 fstab`, `man mount`, `man findmnt`, `man blkid`, `man 8 mount.nfs` | s03e10 |
| `man 5 logrotate.conf` — на будущее, перед Season 3. | s01e09 |
| `man 5 passwd`, `man 5 shadow`, `man 5 group`, `man 5 login.defs`, `man 5 nsswitch.conf` | s03e01 |
| `man 5 proc` — откуда `ps`, `ss` и `lsmod` берут данные на самом деле | s08e11 |
| `man 5 proc`, `man 1 file`, `man 1 lscpu` | s06e01 |
| `man 5 resolv.conf`, `man resolvectl` — что делает `DNS =` в конфиге | s02e11 |
| `man 5 sysctl.d`, `man 8 systemd-sysctl`, `man 7 tcp`, `man 5 proc` | s07e10 |
| `man 5 systemd.generator`, `man 8 systemd-run` — места, не вошедшие в восьмёрку | s08e05 |
| `man 5 systemd.service`, `man 5 systemd.exec`, `sd_notify(3)` | s06e10 |
| `man 5 tzfile`, `man 3 tzset` — как это устроено внутри | s08e06 |
| `man 7 hier`, `man du` — устройство дерева и настоящий размер каталогов. | s01e02 |
| `man 7 inode` — как режим устроен внутри (пригодится в Season 3) | s01e15 |
| `man 7 inode`, `man 2 unlink`, `man 5 ext4` | s03e08 |
| `man 7 tcp`, `man 7 socket` — пределы очередей и что на них влияет | s08e01 |
| `man 7 udev`, `man 8 udevadm` — права на устройства и ожидание их появления | s06e02 |
| `man 8 ld.so` — раздел про `LD_PRELOAD` и `/etc/ld.so.preload` | s08e05 |
| `man 8 nft`, `man 5 nftables` | s08e02 |
| `man 8 rpi-eeprom-config`, `vcgencmd` — прошивка и её состояние | s06e03 |
| `man 8 semanage`, `man 5 selinux_config`, `man 8 restorecon`, `man 1 matchpathcon` | s07e11 |
| `man 8 sshd`, раздел AUTHORIZED_KEYS FILE FORMAT — требования к правам | s08e08 |
| `man 9 copy_to_user`, `man 2 read`, `man 7 epoll` | s06e12 |
| `man aide`, `man aide.conf`; документация Tripwire | s05e03 |
| `man apt`, `man apt-get`, `man dpkg`, `man dpkg-query`, `man sources.list` | s01e13 |
| `man auditctl`, `man audit.rules`, `man ausearch`, `man aureport`, `man augenrules` | s05e08 |
| `man awk`, `man gawk`, `man sort`, `man uniq` | s01e11 |
| `man bash` (раздел REDIRECTION), `help exec`, `man date`, `man tee`, `man logger` | s01e09 |
| `man chmod`, `man 1 stat`, `man umask`, `man chown`, `man id` | s01e15 |
| `man chmod`, `man chown`, `man umask`, `man setfacl`, `man getfacl`, `man find`, `man chattr` | s03e02 |
| `man date`, `man 5 tzfile`; RFC 3339, ISO 8601, RFC 5424 (syslog) | s05e10 |
| `man df`, `man du`, `man lsof`, `man lsblk`, `man findmnt`, `man tune2fs`, `man resize2fs`, `man parted`, `man edquota` | s03e08 |
| `man dig`, `man delv`, `man resolvectl` | s02e05 |
| `man dig`, `man host`, `man getent`, `man nsswitch.conf`, `man resolv.conf`, `man resolvectl` | s02e04 |
| `man docker-build`, `man docker-history`, `man docker-inspect`, `man dockerignore` | s04e04 |
| `man dockerignore` | s04e05 |
| `man fail2ban-jail.conf` — когда лимита пакетов мало | s02e12 |
| `man find` (раздел EXAMPLES особенно), `man xargs`, `man du`, `man locate` | s01e06 |
| `man git-log`, `man git-rev-list`, `man git-show`, `man gitrevisions`, `man git-reflog` | s04e01 |
| `man gitignore`, `man git-check-ignore`, `man git-rm`, `man git-status` | s04e03 |
| `man gitrevisions` (диапазоны), `man git-rev-list`, `man githooks`, `man git-rebase` | s04e02 |
| `man grep`, `man 7 regex`, `info grep` (раздел про BRE/ERE) | s01e10 |
| `man id`, `man groups`, `man sudo`, `man sudoers`, `man su`, `man 5 passwd` | s01e16 |
| `man ip`, `man ip-address`, `man ip-route` | s02e01 |
| `man jail.conf`, `man fail2ban-client`, `man fail2ban-regex` | s05e04 |
| `man journalctl` (`-k`), `man dmesg` | s02e12 |
| `man journalctl`, `man journald.conf`, `man systemd.journal-fields`, `man 3 syslog` | s03e07 |
| `man logger`, `man systemd-cat`, `man logrotate` | s03e07 |
| `man logrotate`, `man 5 logrotate.conf`, `man 2 truncate` | s03e12 |
| `man ls`, `info coreutils 'ls invocation'` — все флаги с примерами. | s01e02 |
| `man lvm`, `man pvcreate`, `man vgextend`, `man lvextend`, `man lvreduce`, `man lvmthin`, `man pvmove`, `man mdadm` | s03e09 |
| `man lynis`, `man debsecan`, `man dpkg --compare-versions` | s05e02 |
| `man man` — про сам `man`; `man 7 hier` — карта дерева каталогов. | s01e04 |
| `man mkdir`, `man cp`, `man mv`, `man rm`, `man touch`, `man ln` | s01e04 |
| `man nano`, `man vim`, `:help` внутри vim. | s01e05 |
| `man ping`, `man bash` (Special Parameters, Quoting), `help set`, `help exit` | s01e07 |
| `man ping`, `man traceroute`, `man mtr`, `man tcpdump`, `man ip-route` | s02e03 |
| `man proc` — раздел про `/proc/stat` и `/proc/diskstats`, откуда берут данные все эти утилиты | s07e08 |
| `man proc`, `man comm`; RFC 3227 «Guidelines for Evidence Collection and Archiving» | s05e09 |
| `man ps`, `man 5 proc`, `man 7 signal`, `man 2 fork`, `man 2 execve`, `man strace` | s03e04 |
| `man pwd`, `help pwd` (встроенная версия), `man hier` — карта дерева каталогов. | s01e01 |
| `man pwquality.conf`, `man faillock`, `man pam.d`, `man 5 login.defs` | s05e06 |
| `man resize2fs`, `man xfs_growfs`, `man e2fsck` | s03e09 |
| `man rsync`, `man sha256sum`, `man tar`, `man ssh` (раздел `authorized_keys`) | s03e11 |
| `man rsyslogd`, `man nginx` (раздел «SIGNALS»), `man journald.conf` | s03e12 |
| `man sed`, `info sed` | s01e12 |
| `man sha256sum`, `man comm`, `man tar`, `man pg_restore` | s03e13 |
| `man ss`, `man lsof`, `man nc`, файл `/etc/services` | s02e02 |
| `man ss`, `man ps`, `man proc`, `man lsof`, `man nmap` | s05e01 |
| `man ssh`, `man ssh-keygen`, `man ssh_config`, `man sshd_config`, `man ssh-agent`, `man authorized_keys` | s02e08 |
| `man ssh`, `man ssh_config`, `man sshd_config`, `man ssh-agent` | s02e10 |
| `man sshd_config`, `man sshd` (ключи `-T`, `-t`), `man ssh_config`, `man wg`, `man wg-quick` | s02e09 |
| `man sudoers`, `man sudo`, `man visudo`, `man sudoreplay`, `man pam`, `man 5 limits.conf` | s03e03 |
| `man sysctl.d`, `man apparmor.d`, `man aa-enforce`, `man capabilities`, `man systemd.exec` | s05e11 |
| `man systemctl`, `man systemd-analyze`, `man systemd.directives` (указатель всех директив) | s03e05 |
| `man systemd.mount`, `man systemd-fstab-generator`, `man systemd.automount` | s03e10 |
| `man systemd.timer`, `man systemd.time`, `man systemd.service`, `man systemd-analyze` | s03e06 |
| `man systemd.unit`, `man systemd.service`, `man systemd.exec`, `man systemd.resource-control` | s03e05 |
| `man ufw`, `man iptables`, `man iptables-extensions`, `man ipset`, `man fail2ban-client` | s02e07 |
| `man ufw`, `man ufw-framework`, `man iptables`, `man iptables-extensions` (модуль `recent`) | s02e12 |
| `man ufw`, `man ufw-framework`, `man iptables`, `man iptables-extensions`, `man nft` | s02e06 |
| `man useradd`, `man usermod`, `man chage`, `man getent`, `man id` | s03e01 |
| `man visudo` — почему этот файл правят особой командой | s01e16 |
| `man wg`, `man wg-quick`, `man ip-route` | s02e11 |
| `man xargs`, `man find` (раздел `-exec`), `man apt`, `man dpkg` | s01e14 |
| `mosquitto-go-auth`, `mosquitto_dynamic_security` — внешние источники учётных записей и прав | s06e09 |
| `mosquitto.conf(5)`, `mosquitto-tls(7)`, `mosquitto_passwd(1)`, `mosquitto_ctrl(1)` | s06e09 |
| `mosquitto.conf(5)`, `mosquitto_sub(1)`, `mosquitto_pub(1)` | s06e08 |
| `nikto`, `nmap --script vuln`, `sqlmap` — и почему их вывод требует ручной проверки | s05e07 |
| `openssl` cookbook — выпуск собственного удостоверяющего центра | s06e09 |
| `paho-mqtt` — документация клиента; `mosquitto_sub`/`pub` для ручной проверки | s06e10 |
| `pgbouncer` — что делают с пулом, когда его размер упёрся в базу | s07e08 |
| `pinout.xyz` — соответствие контактов гребёнки и номеров GPIO у Raspberry Pi | s06e02 |
| `promtool check metrics < metrics.txt` — официальная версия того, что писалось в этой серии | s07e05 |
| `promtool test rules` — модульные тесты правил, если Prometheus всё-таки под рукой | s07e06 |
| `pymavlink.mavwp` — разбор и генерация миссий из Python | s06e06 |
| `pymavlink`, MAVProxy, QGroundControl | s06e05 |
| `python3 -m unittest`, `pytest`, `unittest.mock` — инструменты проверки | s06e10 |
| `rt-tests` (`cyclictest`), wiki.linuxfoundation.org/realtime — если нужны гарантии по времени | s06e11 |
| `sealert` и `setroubleshoot` — то же, что делалось руками, с человеческими объяснениями | s07e11 |
| `ssh -G`, `ssh -v` — что понято и что происходит | s02e10 |
| `trivy`, `grype`, `dive` — сканирование и разбор слоёв | s04e04 |
| `vimtutor` — 25 минут интерактивно, лучший старт. | s01e05 |
| ardupilot.org → Complete Parameter List — единицы и диапазоны всех параметров | s06e07 |
| k3s docs: Architecture; `kind` и `minikube` — локальный кластер под манифесты | s07e01 |
| k6 documentation: constant-arrival-rate — нагрузка с постоянным темпом, а не «как ответит» | s07e08 |
| mavlink.io — спецификация, определения сообщений, руководство по подписи | s06e05 |
| mavlink.io → `MAV_CMD`, `MAV_FRAME` — полные списки | s06e06 |
| nftables wiki: Sets, Meters, Rate limiting — динамические множества и ограничители | s08e02 |
| nginx documentation: `ngx_http_core_module`, директивы `location`, `limit_except`, `client_max_body_size` | s08e04 |
| xkcd 936 «Password Strength»; Have I Been Pwned (проверка утечек) | s05e06 |
| «Algorithms» (Dasgupta, Papadimitriou, Vazirani), гл. 5–6 — где жадность оптимальна | s08e03 |
| «Digital Forensics with Open Source Tools» (Altheide, Carvey) — построение хронологии как метод | s08e06 |
| «Exponential Backoff And Jitter», AWS Architecture Blog — про разброс | s06e10 |
| «File System Forensic Analysis» (Carrier) — временные метки и их надёжность | s05e10 |
| «File System Forensic Analysis» (Carrier), гл. 3 — время в расследовании | s08e06 |
| «Implementing Service Level Objectives» (Alex Hidalgo) — про малый трафик, пользовательские сценарии и переговоры о целях | s07e12 |
| «Incident Management for Operations» (Lucas, Schauenberg, Green) — про то, что происходит после звонка | s07e07 |
| «Incident Response & Computer Forensics» (Luttgens, Pepe, Mandia) — что сохраняют и как | s08e08, s08e09 |
| «Infrastructure as Code» (Morris) — контроль дрейфа и сверка с эталоном | s08e12 |
| «Introduction to Algorithms» (Cormen et al.), гл. 16, 35.5 — рюкзак и приближения | s08e03 |
| «Kubernetes Patterns» (Ibryam, Huß) — «Predictable Demands», «Declarative Deployment» | s07e02, s07e03, s07e04 |
| «Kubernetes Up & Running» (Burns, Beda, Hightower) — гл. 10 «Deployments» | s07e02 |
| «Kubernetes Up & Running» (Burns, Beda, Hightower); «Kubernetes Patterns» (Ibryam, Huß) | s07e01 |
| «Linux Device Drivers», 3-е изд. — свободно доступна на lwn.net | s06e11 |
| «Linux Device Drivers», гл. 3 «Char Drivers», гл. 6 «Advanced Char Driver Operations» | s06e12 |
| «Practical Forensic Imaging» (Nikkel) — как снимают то, чему потом верят | s08e05, s08e08 |
| «Prometheus: Up & Running» (Brazil) — гл. 3 и 5; там же про кардинальность подробнее всего | s07e05, s07e06, s07e07 |
| «SELinux System Administration» (Vermeulen) | s07e11 |
| «Securing DevOps», «Practical Linux Hardening» | s05e12 |
| «Seeking SRE» (Blank-Edelman) — как политика бюджета приживается в компаниях, не похожих на Google | s07e12 |
| «Site Reliability Engineering» (Beyer et al.) — гл. 8 «Release Engineering» | s07e04, s07e05, s07e06, s07e07, s07e12, s08e12 |
| «Systems Performance» (Gregg) — гл. 2, методологии и статистика | s07e09, s07e10 |
| «Systems Performance» (Gregg), гл. 10 — сеть: где мерить и чем | s08e01 |
| «The Art of Computer Systems Performance Analysis» (Jain) — очереди без упрощений | s07e08 |
| «The Art of Memory Forensics» (Ligh et al.) — гл. 1–3, чего не видно в файлах вообще | s08e05 |
| «The Art of Memory Forensics» (Ligh и др.) | s05e09 |
| «The Art of Memory Forensics» (Ligh, Case, Levy, Walters) — взгляд через дамп памяти | s08e11 |
| «The Art of Software Security Assessment» (Dowd, McDonald, Schuh) — гл. 6 и 17, разбор длин и границ | s08e04 |
| «The Checklist Manifesto» (Gawande) — почему полнота важнее качества пункта | s08e12 |
| «The Cuckoo's Egg» (Stoll) — образец работы через координатора вместо hack-back | s08e10 |
| «The Rootkit Arsenal» (Blunden) — сокрытие и обнаружение, оба направления | s08e11 |
| «The Site Reliability Workbook» — гл. 2 «Implementing SLOs», гл. 5 «Alerting on SLOs»: там же вывод множителей и пары окон | s07e12 |
| «The Tail at Scale» (Dean, Barroso) — про хвосты в распределённых системах | s07e09 |
| Документация Docker о взаимодействии с `iptables` и цепочке `DOCKER-USER`. | s02e06 |
| Документация Docker: «Best practices for writing Dockerfiles», «Multi-stage builds» | s04e04 |
| Документация mosquitto: Authentication, Access control, Bridges | s06e09 |
| Документация формата логов nginx/apache (combined) | s05e05 |
| Его же «BPF Performance Tools» — если нужен слой глубже, чем `vmstat` | s07e08 |
| И, если захочется дальше, — сестринский курс по C: из чего сделано всё, что здесь проверялось | s08e12 |
| Исходники `kube-proxy` — лучший способ увидеть, что правила в ядре и есть вся служба | s07e03 |
| Исходники простых драйверов в ядре: `drivers/char/misc.c`, `drivers/char/mem.c` | s06e12 |
| Проект Spoofer (CAIDA) — измерения того, откуда подделка ещё возможна | s08e01 |
| Разбор атаки Камински — классический материал по механике отравления кеша. | s02e05 |
| Рекомендации Mozilla по конфигурации OpenSSH — практичный чек-лист директив. | s02e09 |
| документация `restic`, `borg` — если своё писать не хочется | s03e11 |
