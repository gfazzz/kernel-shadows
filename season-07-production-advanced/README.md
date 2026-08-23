# SEASON 7: PRODUCTION & ADVANCED TOPICS
**Kernel Shadows** | 🇮🇸 Рейкьявик, Исландия | Дни 49-56 (8 дней)

> *"Production is not staging with more servers. It's different mindset. Monitoring, performance, security — everything matters. One mistake — everything fails. But also: properly configured — everything works. This is final test."* — Björn Sigurdsson

---

## 📋 ОБЗОР СЕЗОНА

**Локация:** Рейкьявик, Исландия 🇮🇸
**Датацентр:** Verne Global (бывшая военная база НАТО)
**Дни операции:** 49-56 из 60 (8 дней до финала)
**Технологии:** Kubernetes, Prometheus, Grafana, Performance Tuning, Security Hardening
**Тип:** Production-ready infrastructure для Season 8 finale

---

## 🎯 ЦЕЛЬ СЕЗОНА

Построить production-ready infrastructure:
- ✅ Kubernetes orchestration (50+ серверов → distributed pods)
- ✅ Real-time monitoring (Prometheus + Grafana)
- ✅ Performance optimization (tuning, profiling, caching)
- ✅ Security hardening (SELinux, auditd, fail2ban)

**Результат:** Полностью готовая infrastructure для Season 8 finale (глобальная битва).

---

## 🌍 ГЕОГРАФИЯ И КОНТЕКСТ

### Исландия — Последний рубеж перед финалом

**Verne Global Datacenter:**
- **История:** Бывшая военная база НАТО времён холодной войны
- **Особенности:**
  - Geothermal энергия (100% возобновляемая)
  - Free cooling (арктический климат)
  - Физическая изоляция (удалённость от мировых конфликтов)
  - Самый защищённый ЦОД мира
- **Почему здесь:** Идеальное место для финальной подготовки перед Season 8

**Макс до Исландии:**
- Новосибирск → Москва → Стокгольм → Санкт-Петербург → Таллин → Амстердам → Берлин → Цюрих → Женева → Шэньчжэнь → **Рейкьявик**
- 47 дней операции, 10 стран, от junior sysadmin до production architect

---

## 👥 ПЕРСОНАЖИ СЕЗОНА

### Core Team (постоянные):
- **Макс Соколов** — главный герой, ты (48 дней experience)
- **Виктор Петров** — координатор операции
- **Алекс Соколов** — security lead (брат Макса)
- **Дмитрий Орлов** — DevOps engineer
- **Анна Ковалёва** — forensics expert
- **LILITH v7.0** — AI-помощник (Production Mode)

### Исландские эксперты (новые):
- **Björn Sigurdsson** — Kubernetes SRE, ex-CCP Games (EVE Online)
  - Episode 25 mentor
  - 15 лет experience managing MMO infrastructure
  - "Kubernetes is not tool. It's operating system for distributed apps."

- **Guðrún Ásta** — Monitoring engineer, ex-DataDog
  - Episode 26 mentor
  - Специализация: observability, metrics, alerting
  - "Without monitoring — you are blind. With bad monitoring — you are blind with false confidence."

- **Ólafur Þórsson** — Performance engineer, HPC background
  - Episode 27 mentor
  - Специализация: performance profiling, kernel tuning
  - "Every millisecond matters. Not because users notice — because it compounds."

- **Sigríður Einarsdóttir** — Security engineer, CERT Iceland
  - Episode 28 mentor
  - Специализация: security hardening, incident response
  - "Security is not feature you add. It's foundation you build on."

### Antagonists (присутствие):
- **Полковник Крылов** — ФСБ, охотится за командой
- **"Новая Эра"** — теневая организация, финальный boss Season 8
- **Surveillance:** Исландия — neutral territory, но атаки продолжаются

---

## 🆕 v2.0: пересборка в атомарные серии (в работе)

Season 7 мигрирует с монолитных `episode-NN` (1345–2104 строк) на атомарные серии
`sNNeNN`: один концепт — одна задача, README 180–280 строк, воспроизводимый тест
без root, без сети и **без кластера**.
План — [`V2.0_UPGRADE_PLAN.md`](../V2.0_UPGRADE_PLAN.md), этап 6.

**Дробление 4 эпизодов → 12 серий:**

| Серия | Из ep | Концепт | Артефакт | Type | Статус |
|-------|-------|---------|----------|------|--------|
| s07e01 | 25 | что происходит в кластере: снимки `kubectl`, события, почему под не поднялся | `cluster_report.txt` | **C** | ✅ 26 |
| s07e02 | 25 | манифест Deployment: образ, ресурсы, проверки готовности и живости | `deployment.yaml` | **B** | ✅ 31 |
| s07e03 | 25 | как под находит других и откуда берёт настройки | `service.yaml` + `config.yaml` | **B** | ✅ 26 |
| s07e04 | 25 | застрявший выкат: почему обновление не едет | `rollout_check.sh` | **A** | ✅ 48 |
| s07e05 | 26 | экспортёр метрик: имена, типы, единицы, кардинальность | `check_metrics.sh` | **A** | ✅ 28 |
| s07e06 | 26 | правила Prometheus: `rate`, `for`, пороги | `rules.yml` | **B** | ✅ 49 |
| s07e07 | 26 | оповещения, которые будят: маршрутизация и группировка | `alertmanager.yml` | **B** | план |
| s07e08 | 27 | где узкое место: разбор снимков по методу USE | `bottleneck_report.txt` | **C** | план |
| s07e09 | 27 | перцентили и регрессия задержки | `latency.py` | **D** | план |
| s07e10 | 27 | тюнинг, обоснованный замером: sysctl, limits, лимиты подов | `tuning.conf` | **B** | план |
| s07e11 | 28 | SELinux: контексты, режимы, разбор отказов | `selinux_report.txt` | **C** | план |
| s07e12 | 28 | SLO и бюджет ошибок (финал сезона) | `slo.py` | **D** | план |

Баланс по §2A: 2 × Type A, 5 × Type B, 3 × Type C, 2 × Type D.

**Сквозной артефакт сезона — `aurora`:** производственный контур, в который
заворачивается всё построенное раньше. Приложение живёт в кластере
(`s07e01`–`s07e04`), отдаёт метрики и поднимает оповещения (`s07e05`–`s07e07`),
держит заданную задержку под нагрузкой (`s07e08`–`s07e10`), ограничено в правах
(`s07e11`) и наконец описано числом, на которое можно ссылаться в разговоре с
заказчиком (`s07e12`). Узлы `shadow_mesh` из Season 6 сдают в него телеметрию —
и заодно решают проблему, оставленную там открытой: журналы на узлах живут в
памяти и исчезают при перезагрузке.

**Чем проверяется без кластера.** Kubernetes у студента нет, и ставить его ради
курса — неправильная цена. Предмет проверки — то, с чем на самом деле работает
инженер: **манифесты как текст** (`kubectl apply` принимает именно их) и
**снимки состояния** (`kubectl get -o yaml`, `describe`, события, `/metrics`,
`top`, `iostat`). Оба вида артефактов снимаются один раз и разбираются
инструментами, которые уже есть: `awk`, `grep`, Python. Ошибки, которые ловит
сезон, живут именно там — в тексте манифеста и в расхождении между тем, что
описано, и тем, что происходит.

**Что осознанно не переносится из `episode-28`.** Эпизод «Security Hardening»
на 85% дублирует уже пересобранное: `auditd` — [`s05e08`](../season-05-security-pentesting/s05e08-auditd/),
`fail2ban` — [`s05e04`](../season-05-security-pentesting/s05e04-fail2ban/),
`sysctl` и AppArmor — [`s05e11`](../season-05-security-pentesting/s05e11-hardening/),
укрепление SSH — [`s02e09`](../season-02-networking/s02e09-ssh-hardening/),
аудит-скрипт — [`s05e02`](../season-05-security-pentesting/s05e02-audit-report/)
и [`s05e12`](../season-05-security-pentesting/s05e12-cis-check/).
Единственное новое — **SELinux**, и он занимает одну серию (`s07e11`).
Освободившееся место отдано темам, которых в курсе нет и без которых
эксплуатация не бывает: **SLO и бюджет ошибок** (`s07e12`). Повторять то, что
студент уже сдал, — не «закрепление», а трата его времени.

Прогнать тесты сезона: `make test SEASON=season-07-production-advanced`.

---

## 📚 ЭПИЗОДЫ (4 эпизода, ~20-24 часа)

### 🎬 Episode 25: Kubernetes Basics
**Технологии:** Kubernetes, k3s, kubectl, YAML manifests
**Длительность:** 5-6 часов
**Сложность:** ⭐⭐⭐⭐⭐
**Тип:** Type B (Configuration)

**Что изучим:**
- Kubernetes architecture (Control Plane, Worker Nodes)
- k3s installation и setup
- Pods, Deployments, ReplicaSets
- Services & Networking (ClusterIP, DNS)
- ConfigMaps & Secrets
- Scaling (manual + HPA)
- Rolling Updates & Rollback
- Troubleshooting (logs, describe, debugging)

**Практика:**
- Развернуть k3s cluster
- Create Deployment с 3 replicas
- Expose Service (ClusterIP)
- Configure ConfigMap & Secret
- Manual и auto-scaling
- Rolling update + rollback test
- k8s_audit.sh для health check

**Ключевые команды:**
```bash
kubectl get pods
kubectl describe pod <name>
kubectl logs <name>
kubectl apply -f deployment.yaml
kubectl scale deployment <name> --replicas=5
kubectl rollout undo deployment <name>
```

---

### 🎬 Episode 26: Monitoring & Observability
**Технологии:** Prometheus, Grafana, PromQL, Alertmanager
**Длительность:** 5-6 часов
**Сложность:** ⭐⭐⭐⭐☆
**Тип:** Type B (Configuration)

**Что изучим:**
- Prometheus installation (metrics collection)
- Grafana dashboards (visualization)
- PromQL queries (metric aggregation)
- Alertmanager (alerting rules)
- ServiceMonitor & PodMonitor (Kubernetes integration)
- Exporters (node_exporter, blackbox_exporter)
- Retention policies & storage

**Практика:**
- Deploy Prometheus + Grafana on Kubernetes
- Create custom dashboards (CPU, Memory, Network)
- Write PromQL queries
- Configure alerting rules (CPU > 80%, Memory > 90%)
- Test alert firing & notifications
- monitoring_audit.sh для metrics validation

**Ключевые метрики:**
```promql
rate(http_requests_total[5m])
node_cpu_seconds_total
container_memory_usage_bytes
up{job="kubernetes-nodes"}
```

---

### 🎬 Episode 27: Performance Tuning
**Технологии:** perf, sysctl, SQL optimization, Redis caching
**Длительность:** 5-6 часов
**Сложность:** ⭐⭐⭐⭐⭐
**Тип:** Type A (Bash Automation + Tools)

**Что изучим:**
- Linux performance profiling (perf, top, htop, iostat)
- Kernel tuning (sysctl.conf optimization)
- Database optimization (SQL query profiling, indexes)
- Caching strategies (Redis, Memcached)
- Network tuning (TCP/IP parameters)
- Bottleneck analysis (CPU, Memory, Disk I/O, Network)

**Практика:**
- Profile application performance (perf record/report)
- Tune kernel parameters (sysctl)
- Optimize SQL queries (EXPLAIN, indexes)
- Implement Redis caching
- Bash script для performance benchmarking
- performance_audit.sh для comparison

**Ключевые инструменты:**
```bash
perf top                    # Real-time CPU profiling
perf record -g ./app        # Record call graph
perf report                 # Analyze results
sysctl -w net.ipv4.tcp_congestion_control=bbr
redis-cli INFO stats
```

---

### 🎬 Episode 28: Security Hardening
**Технологии:** SELinux, auditd, fail2ban, firewall hardening
**Длительность:** 5-6 часов
**Сложность:** ⭐⭐⭐⭐⭐
**Тип:** Type B (Configuration)

**Что изучим:**
- SELinux (mandatory access control)
- auditd (system call auditing)
- fail2ban (intrusion prevention)
- Firewall hardening (iptables/nftables advanced)
- SSH hardening (key-only, 2FA, rate limiting)
- File integrity monitoring (AIDE)
- Security policies & compliance

**Практика:**
- Enable & configure SELinux (enforcing mode)
- Setup auditd rules (file access, syscalls)
- Configure fail2ban (SSH, nginx bans)
- Harden firewall rules
- Implement SSH 2FA (Google Authenticator)
- security_audit.sh для vulnerability scanning

**Ключевые команды:**
```bash
setenforce 1                 # Enable SELinux
ausearch -f /etc/shadow      # Audit file access
fail2ban-client status sshd  # Check banned IPs
iptables -L -n -v            # List firewall rules
ssh-keygen -t ed25519        # Generate strong keys
```

---

## 📊 СТРУКТУРА СЕЗОНА

### Type A vs Type B баланс:
- **Type A (Bash Automation):** 1 episode (Episode 27 — 25%)
- **Type B (Configuration):** 3 episodes (Episodes 25, 26, 28 — 75%)

**Почему такой баланс:**
- Production infrastructure = больше configuration, меньше scripting
- Kubernetes, Prometheus, SELinux — используем готовые инструменты
- Bash только для automation workflows (performance benchmarking)

### Общее время: 20-24 часа
- Episode 25: 5-6ч (Kubernetes)
- Episode 26: 5-6ч (Monitoring)
- Episode 27: 5-6ч (Performance)
- Episode 28: 5-6ч (Security)

---

## 🎭 СЮЖЕТ СЕЗОНА

### Завязка (День 49, Episode 25):

Макс прибывает в Рейкьявик. Verne Global — бывшая военная база НАТО, теперь самый защищённый ЦОД мира. Виктор: *"Это последний рубеж перед финалом. Kubernetes для 50 серверов. Production-ready."*

Björn Sigurdsson встречает Макса: *"From Docker containers to Kubernetes orchestration. EVE Online — 500,000 players online simultaneously. Same challenges: scaling, self-healing, zero downtime. I teach you."*

### Развитие (Дни 50-53, Episodes 26-27):

**Episode 26:** Guðrún Ásta: *"Kubernetes works. But how you know? Without monitoring — blind. Prometheus collects. Grafana visualizes. Alertmanager warns. Real-time visibility."*

**Episode 27:** Ólafur Þórsson: *"Infrastructure ready. But fast? Every millisecond matters. Profile. Tune. Optimize. From seconds to milliseconds."*

### Нарастание напряжения (Дни 54-55):

**"Новая Эра" атакует infrastructure.** DDoS, intrusion attempts, zero-day exploits. Мониторинг показывает аномалии. Performance деградирует. Security под угрозой.

**Alex** (экстренный звонок): *"Макс, атака идёт. Крылов и 'Новая Эра' координируют. Episode 28 critical. Harden everything. Финал через 4 дня."*

### Кульминация (День 56, Episode 28):

Sigríður Einarsdóttir: *"Security is war. Attackers never stop. SELinux = mandatory access control. Auditd = every action logged. Fail2ban = auto-ban attackers. Harden or fall."*

Макс проходит **red team test** от Alex (симуляция атаки):
- Alex пытается взломать infrastructure 2 часа
- Все атаки отражены (SELinux блокирует, fail2ban банит, auditd логирует)
- **Alex:** *"9/10 security. Production ready. Ты готов к Season 8."*

### Развязка (День 56, вечер):

**Viktor** (видеозвонок, все локальные эксперты присутствуют):

*"Макс, Season 7 complete. Kubernetes — готов. Monitoring — активен. Performance — оптимизирован. Security — hardened. 50+ серверов по всему миру работают как единая система. От Новосибирска до Исландии. 48 дней. 8 стран. Junior sysadmin → Production Architect."*

**Viktor:** *"Season 8 starts in 4 days. Final operation. 'Новая Эра' готовит глобальную атаку. Крылов координирует из Москвы. 72 часа без сна. Используй всё что выучил. Вся команда будет с тобой."*

**Björn:** *"You ready. Kubernetes scales. Monitoring watches. Performance optimized. Security hardened. Production infrastructure — battle-tested."*

**LILITH v7.0:**
*"Макс. 48 дней назад ты не знал что такое pwd. Сегодня управляешь distributed production systems. Kubernetes, Prometheus, SELinux. От команд к архитектуре. Season 8 — финальная битва. Покажи на что способен."*

**Макс** (смотрит на северное сияние над Исландией):
*"От терминала до production infrastructure. Через 8 стран. 48 дней. Всё что выучил — для этого момента. Season 8... я готов."*

---

## 📈 ПРОГРЕСС МАКСА

### До Season 7 (День 48):
- Shell scripting: Advanced
- Networking: Advanced
- System Administration: Advanced
- DevOps: Intermediate
- Security: Intermediate

### После Season 7 (День 56):
- **Kubernetes:** Production-level (orchestration, scaling, troubleshooting)
- **Monitoring:** Expert (Prometheus, Grafana, PromQL, alerting)
- **Performance:** Advanced (profiling, tuning, optimization)
- **Security:** Expert (SELinux, auditd, hardening, compliance)

**Статус:** **Production Architect** (готов к Season 8 finale)

---

## 🎯 КЛЮЧЕВЫЕ НАВЫКИ СЕЗОНА

### Технические:
1. ✅ **Kubernetes:** От нуля до production deployment
2. ✅ **Observability:** Metrics, logs, traces (Prometheus/Grafana)
3. ✅ **Performance:** Profiling, tuning, bottleneck analysis
4. ✅ **Security:** Mandatory access control, intrusion prevention, hardening

### Методологические:
1. ✅ **Production mindset:** Мониторинг, redundancy, testing
2. ✅ **SRE practices:** SLOs, error budgets, incident response
3. ✅ **Security-first:** Defense in depth, least privilege
4. ✅ **Optimization:** Measure first, then optimize

---

## 🔗 СВЯЗЬ С ДРУГИМИ СЕЗОНАМИ

### Builds on:
- **Season 1:** Shell foundations (bash для automation)
- **Season 2:** Networking (Kubernetes networking, Prometheus scraping)
- **Season 3:** System admin (systemd для services, disk для persistent volumes)
- **Season 4:** DevOps (Docker → Kubernetes, CI/CD integration)
- **Season 5:** Security (hardening extends pentesting knowledge)
- **Season 6:** Embedded/IoT (monitoring IoT devices, edge Kubernetes)

### Prepares for:
- **Season 8:** Final operation (production infrastructure готова)
  - Kubernetes handles scale
  - Monitoring detects attacks
  - Performance maintains responsiveness
  - Security defends против "Новая Эра"

---

## 📝 ЗАМЕТКИ ДЛЯ СТУДЕНТОВ

### Сложность:
Season 7 — **самый технически сложный сезон**:
- Kubernetes имеет steep learning curve
- Prometheus/PromQL требует понимания метрик
- Performance tuning требует системного мышления
- Security hardening критичен (одна ошибка = vulnerability)

**Не спешите.** Каждый episode = 5-6 часов. Прочитайте теорию, попробуйте практику, отладьте ошибки.

### Prerequisites:
- Seasons 1-4 обязательны (foundation)
- Season 5 рекомендуется (security context)
- Season 6 опционален (но полезен для понимания edge cases)

### Real-world relevance:
**Всё из Season 7 используется в production:**
- Kubernetes = standard для containerized applications
- Prometheus/Grafana = industry standard для monitoring
- Performance tuning = необходимость для scale
- Security hardening = обязательное требование compliance (SOC2, ISO27001)

**Этот сезон = ваше резюме.** "Production Kubernetes deployment with monitoring and security hardening" — фраза которую ищут работодатели.

---

## 🛠️ ИНСТРУМЕНТЫ СЕЗОНА

### Обязательные:
- `kubectl` (Kubernetes CLI)
- `k3s` (lightweight Kubernetes)
- `prometheus` (metrics collection)
- `grafana` (visualization)
- `perf` (performance profiling)
- `sysctl` (kernel tuning)
- `selinux-utils` (security)
- `auditd` (auditing)
- `fail2ban` (intrusion prevention)

### Опциональные (но полезные):
- `helm` (Kubernetes package manager)
- `k9s` (Kubernetes TUI)
- `dive` (image analysis)
- `trivy` (vulnerability scanning)
- `iftop` (network monitoring)
- `redis-cli` (caching)

---

## 🎓 ПОСЛЕ ПРОХОЖДЕНИЯ SEASON 7

### Вы сможете:
1. ✅ Развернуть production Kubernetes cluster с нуля
2. ✅ Настроить comprehensive monitoring (Prometheus + Grafana)
3. ✅ Профилировать и оптимизировать performance
4. ✅ Hardened Linux system против real-world threats
5. ✅ Troubleshoot сложные production issues
6. ✅ Работать как Production Engineer / SRE

### Следующие шаги:
- **Season 8:** Final operation (применить всё изученное)
- **CKA certification:** Certified Kubernetes Administrator
- **Real projects:** Deploy свой Kubernetes cluster
- **Job search:** Production Engineer, SRE, DevOps

---

## 📚 ДОПОЛНИТЕЛЬНЫЕ РЕСУРСЫ

### Kubernetes:
- Official docs: https://kubernetes.io/docs/
- k3s docs: https://docs.k3s.io/
- CKA prep: https://killer.sh/

### Monitoring:
- Prometheus docs: https://prometheus.io/docs/
- Grafana dashboards: https://grafana.com/grafana/dashboards/
- PromQL tutorial: https://prometheus.io/docs/prometheus/latest/querying/basics/

### Performance:
- Linux Performance: http://www.brendangregg.com/linuxperf.html
- perf wiki: https://perf.wiki.kernel.org/
- Systems Performance book (Brendan Gregg)

### Security:
- SELinux Project: https://github.com/SELinuxProject
- CIS Benchmarks: https://www.cisecurity.org/cis-benchmarks/
- OWASP: https://owasp.org/

---

<div align="center">

**"Production is where theory meets reality. Everything you learned — for this moment."** — Viktor Petrov

**SEASON 7: PRODUCTION & ADVANCED TOPICS**

*Рейкьявик, Исландия 🇮🇸 | Дни 49-56 | 4 episodes | 20-24 hours*

**Status:** ✅ Episode 25 Complete | ⏳ Episodes 26-28 In Progress

**Next:** Episode 26 — Monitoring & Observability (Prometheus/Grafana) 📊

</div>

