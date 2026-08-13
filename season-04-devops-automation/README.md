# SEASON 4: DEVOPS & AUTOMATION 🚢🇳🇱🇩🇪

> **"50 серверов вручную? Нет. Docker, Ansible, CI/CD. Едем в Европу — Амстердам и Берлин, DevOps столицы."**
> — Dmitry Orlov

---

## 📍 География и контекст

**Локации:** 🇳🇱 Амстердам, Нидерланды → 🇩🇪 Берлин, Германия
**Дни операции:** 25-32 из 60
**Время прохождения:** 18-22 часа
**Сложность:** ⭐⭐⭐⭐☆

### Почему Амстердам и Берлин?

**Амстердам:**
- Docker HQ Europe — контейнеризация родилась здесь
- Pragmatic Dutch approach: "Если это работает, используй. Если нет — автоматизируй."
- Science Park datacenter cluster
- Культура: велосипеды, каналы, толерантность, tech startups

**Берлин:**
- Chaos Computer Club (CCC) — европейская хакерская культура
- Open Source центр Европы
- Hackerspace'ы, maker culture
- Philosophy: "Hacking is not crime, it's art. Automation is not laziness, it's efficiency."
- Tempelhof airport datacenter (бывший аэропорт → ЦОД)

---

## 🎬 Сюжетная линия Season 4

### Завязка

Виктор (видеозвонок в конце Season 3):
> *"Max, ты справился с системным администрированием. Теперь масштаб. У нас 50 серверов. Через месяц будет 100. Управлять вручную невозможно. Нужна автоматизация. DevOps. Летишь в Амстердам. Dmitry встретит."*

Dmitry Orlov (звонок после):
> *"Макс, привет. Я Дмитрий, DevOps-инженер команды Виктора. Я настраивал Ansible, Docker, CI/CD последние 2 недели, но мне нужна помощь. Амстердам и Берлин — DevOps столицы мира. Там есть эксперты. Поехали учиться."*

### Что происходит в Season 4

**Модернизация инфраструктуры:**
- **Episode 13 (Берлин):** Git для infrastructure as code — версионирование конфигов, branching strategy
- **Episode 14 (Амстердам):** Docker — контейнеризация всех инструментов операции
- **Episode 15 (Берлин):** CI/CD pipelines — автоматические тесты и deploy
- **Episode 16 (Амстердам):** Ansible — автоматизация настройки 50+ серверов одной командой

**Кризисы:**
1. **Git incident (Episode 13):** Кто-то закоммитил пароль от production сервера в public repo
2. **Docker leak (Episode 14):** Supply chain attack — подозрение на предателя
3. **CI/CD break (Episode 15):** Broken deployment разрушил production (rollback under pressure)
4. **Ansible failure (Episode 16):** Mass configuration error на всех 50 серверах одновременно

**Twist:** Marcus Weber (финансист операции) под подозрением — утечки информации продолжаются. Или это отвлекающий манёвр?

### Эмоциональная линия

**Max:**
- Впервые в Западной Европе (после Скандинавии и Балтики)
- Cultural shock: европейская DevOps культура vs русский "ручной труд"
- Знакомство с open source философией (CCC)
- Понимает: автоматизация — это не лень, это выживание на масштабе

**Dmitry:**
- Раскрывается как персонаж (до этого был "удалённый голос")
- Backstory: ex-Yandex DevOps, уволился из-за политики, работал на европейские стартапы
- Мотивация: построить идеальную инфраструктуру, proof of concept для будущих проектов

**Paranoia:**
- Marcus Weber — финансист, серые связи, подозрительные встречи
- Утечки информации Krylov продолжаются
- Supply chain attack на Docker images — кто-то внутри?
- Max учится не доверять слепо (даже коду)

---

## 🆕 v2.0: пересборка в атомарные серии (в работе)

Season 4 мигрирует с монолитных `episode-NN` (1929–3620 строк) на атомарные
серии `sNNeNN`: один концепт — одна задача, README 180–280 строк, воспроизводимый
тест без root. План — [`V2.0_UPGRADE_PLAN.md`](../V2.0_UPGRADE_PLAN.md), этап 6.

**Дробление 4 эпизодов → 12 серий:**

| Серия | Из ep | Концепт | Артефакт | Type | Статус |
|-------|-------|---------|----------|------|--------|
| [s04e01](s04e01-git-history/) | 13 | Git: три зоны, чтение истории | `history_report.txt` | **C** | ✅ 24/24 |
| [s04e02](s04e02-branches-prepush/) | 13 | ветки, слияние, проверка перед push | `prepush_check.sh` | **A** | ✅ 20/20 |
| [s04e03](s04e03-gitignore-secrets/) | 13 | утёкший секрет: `.gitignore`, `.env.example` (капстоун) | `gitignore` + `env.example` | **B** | ✅ 21/21 |
| [s04e04](s04e04-images-layers/) | 14 | образы и слои: чтение `docker history` | `image_report.txt` | **C** | ✅ 21/21 |
| [s04e05](s04e05-dockerfile/) | 14 | свой `Dockerfile` | `Dockerfile` + `dockerignore` | **B** | ✅ 20/20 |
| [s04e06](s04e06-compose/) | 14 | несколько служб: `compose.yaml` (капстоун) | `compose.yaml` | **B** | ✅ 22/22 |
| [s04e07](s04e07-ci-pipeline/) | 15 | конвейер CI | `.github/workflows/ci.yml` | **B** | ✅ 24/24 |
| [s04e08](s04e08-deploy-rollback/) | 15 | выкат и откат (капстоун) | `rollback.sh` | **A** | ✅ 31/31 |
| [s04e09](s04e09-ansible-inventory/) | 16 | Ansible: inventory и группы | `inventory.yml` | **B** | ✅ 21/21 |
| [s04e10](s04e10-ansible-check/) | 16 | что изменится на 50 серверах: `--check --diff` | `plan_report.txt` | **C** | ✅ 22/22 |
| [s04e11](s04e11-iac-audit/) | 16 | аудит всего репозитория | `iac_audit.sh` | **A** | ✅ 24/24 |
| [s04e12](s04e12-ansible-playbook/) | 16 | playbook: пятьдесят машин одной командой (финал сезона) | `harden.yml` | **B** | ✅ 28/28 |

Баланс по §2A: 3 × Type A, 6 × Type B, 3 × Type C. Конфигураций больше
половины — для сезона про DevOps это и есть предмет.

**Отклонение от плана (11 → 12 серий), 2026-08-08.** Аудит потерь перед
удалением монолитов показал, что при разбиении «ep16 → инвентарь + режим
проверки + аудит» сезон учит Ansible **только на чтение**: playbook,
модули, идемпотентность, handlers, шаблоны и vault не появляются нигде, хотя
в учебных целях сезона записано «писать playbooks и roles». Заодно терялся
и финал исходного эпизода — «пятьдесят серверов одной командой». Обе дыры
закрывает `s04e12`; она же переняла завершение сезона и переход к Season 5,
а `s04e11` теперь передаёт эстафету ей.

**Сквозной артефакт сезона — `shadow_iac`** (§10.2): репозиторий инфраструктуры,
который собирается по сериям. `s04e03` кладёт в него `.gitignore`, `s04e05` —
`Dockerfile`, `s04e06` — `compose.yaml`, `s04e07` — конвейер, `s04e09` и `s04e12` —
Ansible. Предпоследняя `s04e11` проверяет весь репозиторий целиком: нет ли
секретов, не работает ли контейнер от root, закреплены ли версии действий CI,
не лежит ли пароль Ansible открытым текстом. Финал `s04e12` приводит к этому
описанию пятьдесят машин — и требует, чтобы второй прогон не менял ничего.

**Чем проверяется без сети и без root.** `git` есть почти везде, поэтому тесты
Git-серий создают настоящий репозиторий во временном каталоге с фиксированными
датами и автором. `docker` и `ansible` **не требуются**: их конфигурации
проверяются как текст, а вывод команд разбирается по снимкам в `data/`.

Прогнать тесты сезона: `make test SEASON=season-04-devops-automation`.

---

## 👥 Персонажи Season 4

### Core Team (постоянные)

**Max Sokolov** — главный герой
- Роль в S4: Infrastructure lead, координация с Dmitry
- Развитие: переход от "ручного" админа к DevOps engineer

**Dmitry Orlov** — DevOps-инженер
- Роль в S4: Ментор по DevOps, со-лид этого сезона
- Первая личная встреча с Max (Амстердам)
- Backstory раскрывается: ex-Yandex, политический беженец

**Виктор Петров** — заказчик операции
- Роль в S4: Coordination, финансирование поездок, давление на results

**Alex Sokolov** — security expert
- Роль в S4: Консультант по security в CI/CD, code review
- Удалённая поддержка из Москвы

**Anna Kovaleva** — forensics expert
- Роль в S4: Расследование supply chain attack (Episode 14)
- Удалённая поддержка

**LILITH** — AI помощник
- Роль в S4: DevOps mode — автоматизация, best practices, troubleshooting

### Local Experts (эпизодические)

**Hans Müller** (Episodes 13, 15) 🇩🇪
- **Специализация:** Git, CI/CD, infrastructure as code
- **Биография:**
  - 35 лет, немецкий DevOps-инженер
  - Chaos Computer Club (CCC) member с 2010
  - Работал на GitLab, потом freelance
  - Open source contributor (Ansible, GitLab CI)
  - Философия: "Code is law. Version control is constitution."
- **Личность:** Педантичный, любит порядок, но с хакерским mindset
- **Цитата:** "In CCC we say: Hacking is art. Infrastructure as Code is poetry."
- **Встречи:** Chaos Computer Club (Берлин), hackerspace'ы

**Sophie van Dijk** (Episode 14) 🇳🇱
- **Специализация:** Docker, containerization, microservices
- **Биография:**
  - 32 года, голландский Docker architect
  - Работала в Docker Inc. (2015-2020), потом Kubernetes consultant
  - Pragmatic approach: "If it doesn't work, rebuild. If it works, don't touch."
  - Cyclist (как все голландцы), любит минимализм
- **Личность:** Прямая, деловитая, no-nonsense
- **Цитата:** "Containers zijn als LEGO. Simple blocks, complex systems."
- **Встречи:** Amsterdam Science Park datacenter, canal-side coffee meetings

**Klaus Schmidt** (Episode 16) 🇩🇪
- **Специализация:** Ansible, Terraform, infrastructure automation
- **Биография:**
  - 45 лет, ex-Siemens infrastructure lead (20 лет опыта)
  - Старая школа: начинал с Puppet, перешёл на Ansible
  - "Measure twice, automate once."
  - Консервативен, но эффективен
- **Личность:** Серьёзный, методичный, German precision
- **Цитата:** "Ansible is idempotent. Like German engineering — predictable perfection."
- **Встречи:** Ex-Tempelhof airport datacenter (Берлин)

### Antagonist subplot

**Marcus Weber** — финансист операции Виктора
- Роль в S4: Под подозрением
- Странные встречи в Цюрихе (по видеозвонку)
- Утечки информации — совпадение или предательство?
- Red herring или реальная угроза? (раскрывается в Season 5)

**Krylov** — полковник ФСБ
- Роль в S4: Background threat
- Атаки на CI/CD pipeline (Episode 15)
- Попытки взлома Docker registry (Episode 14)
- Supply chain attack через compromised packages

---

## 📚 Технологии Season 4

**Git и версионирование** (`s04e01`–`s04e03`): три зоны и чтение истории, ветки и
проверка перед `push`, утёкший секрет и `.gitignore`. Инцидент: пароль от боевого
сервера в общем репозитории.

**Docker** (`s04e04`–`s04e06`): образы и слои, свой `Dockerfile`, `compose.yaml`.
Инцидент: цепочка поставок — шесть образов с ключом внутри.

**CI/CD** (`s04e07`–`s04e08`): конвейер, который может сказать «нет», и откат
релиза. Инцидент: сломанный выкат кладёт пятьдесят серверов, пять минут простоя.

**Ansible и IaC** (`s04e09`–`s04e12`): инвентарь по двум осям, режим проверки,
аудит описания и playbook, приводящий пятьдесят машин к описанию одной командой.
Поворот: на одной машине находят ручное вмешательство.

---

## 🎯 Учебные цели Season 4

После прохождения Season 4 вы сможете:

✅ **Git & Version Control:**
- Версионировать infrastructure код
- Работать с branches и merge conflicts
- Защищать secrets от утечки в Git
- Код ревью и collaboration workflows

✅ **Docker:**
- Контейнеризировать приложения
- Писать эффективные Dockerfiles
- Использовать Docker Compose для multi-container setups
- Понимать Docker networking и volumes
- Security best practices для контейнеров

✅ **CI/CD:**
- Настраивать автоматические pipelines
- Automated testing и deployment
- Blue-green deployments, canary releases
- Rollback strategies
- Secrets management в CI/CD

✅ **Ansible:**
- Автоматизировать настройку десятков серверов
- Писать playbooks и roles
- Idempotent operations
- Error handling и testing
- Infrastructure as Code best practices

✅ **DevOps Mindset:**
- Автоматизация вместо ручного труда
- Code review culture
- Version everything
- Test everything
- "If it hurts, do it more often" (automation)

---

## 🗺️ Маршрут Season 4

```
День 25-26 (Episode 13):  Берлин 🇩🇪 → Git & Version Control
    ↓                      Chaos Computer Club, hackerspace
    ↓                      Hans Müller: "Code is law. Git is constitution."

День 27-28 (Episode 14):  Амстердам 🇳🇱 → Docker Basics
    ↓                      Science Park datacenter
    ↓                      Sophie van Dijk: "Containers zijn als LEGO."

День 29-30 (Episode 15):  Берлин 🇩🇪 → CI/CD Pipelines
    ↓                      Hans Müller returns
    ↓                      CRISIS: Broken deployment in production

День 31-32 (Episode 16):  Амстердам 🇳🇱 → Ansible & IaC
                           Klaus Schmidt (via video from Tempelhof datacenter)
                           FINALE: 50 серверов настроены одной командой
```

---

## 🎬 Narrative Arc Season 4

### Act 1: Introduction to DevOps (Episodes 13-14)

**Themes:**
- Переход от ручного управления к автоматизации
- European DevOps culture vs Russian "hands-on" approach
- Git как foundation для всего остального

**Conflict:**
- Max сопротивляется: "Я привык делать руками, так быстрее"
- Dmitry: "Руками быстрее для 5 серверов. Для 50 — невозможно."
- Git incident: leaked password учит важности secrets management

**Development:**
- Max понимает философию DevOps
- Знакомство с CCC culture (Берлин)
- Docker как первый шаг к современной инфраструктуре

### Act 2: Automation Under Fire (Episode 15)

**Climax:**
- CI/CD pipeline deployed
- Виктор: "Теперь обновления автоматические. Что может пойти не так?"
- Broken deployment в production (03:47, как всегда)
- Hans + Max + Dmitry: rollback под давлением (30 минут до total failure)

**Stakes:**
- 50 серверов offline
- Клиенты Виктора теряют деньги
- Reputation на кону

**Resolution:**
- Rollback успешен
- Lesson learned: Автоматизация без тестов = оружие массового поражения
- Automated tests added, staging environment setup

**Paranoia escalates:**
- Anna: "Это не случайность. Кто-то внес malicious code в CI/CD."
- Supply chain attack investigation
- Marcus Weber under suspicion

### Act 3: Infrastructure as Code Victory (Episode 16)

**Challenge:**
- 50 серверов нужно настроить заново (после Episode 15 rollback)
- Виктор: "У нас 24 часа до deadline клиента."
- Max + Dmitry + Klaus: Ansible playbook

**Execution:**
- 1 playbook, 50 серверов, 10 минут
- Виктор impressed: "Это магия?"
- Dmitry: "Нет. Это DevOps."

**Season Finale:**
- Инфраструктура automated
- Git → Docker → CI/CD → Ansible = complete DevOps pipeline
- Виктор: "Теперь мы можем масштабироваться. Хорошая работа."
- **But:** Marcus Weber mystery unresolved
- **Cliffhanger:** Alex звонок: "Max, Krylov использует zero-day exploit. Нам нужно учиться думать как атакующие. Летишь в Швейцарию. Season 5: Security."

---

## 💡 Философия Season 4

### DevOps принципы (LILITH wisdom)

1. **"Automate everything"**
   - Если делаешь больше одного раза — автоматизируй
   - If it hurts, do it more often (until it doesn't hurt)

2. **"Infrastructure as Code"**
   - Серверы — это не pets, это cattle
   - Kill it, recreate it from code
   - Never manual changes in production

3. **"Version control everything"**
   - Code, configs, documentation
   - If it's not in Git, it doesn't exist

4. **"Test everything"**
   - Untested code = broken code waiting to happen
   - Automated tests = sleep at night

5. **"Fail fast, recover faster"**
   - Errors are inevitable
   - Recovery должно быть автоматизировано

6. **"Security from the start"**
   - Don't commit secrets
   - Least privilege access
   - Security scanning в CI/CD

### Cultural differences

**Russian approach (Max background):**
- Ручное управление серверами
- "Я знаю, что делаю, мне не нужна автоматизация"
- SSH в production и править вручную
- Documentation? "Я помню что я настроил"

**European DevOps (Dmitry + locals):**
- Автоматизация everything
- "If it's not in Git, it didn't happen"
- No manual changes in production
- Documentation as code

**Conflict → Resolution:**
- Max learns: На масштабе 50+ серверов ручное управление = suicide
- Europeans learn: Иногда нужна импровизация (Russian flexibility)
- Best of both worlds: Automated infrastructure + human judgment

---

## 🔗 Связь с другими сезонами

### From Season 3:
- **Users & Permissions** → используется в Ansible playbooks
- **Systemd Services** → автоматизируются через Ansible
- **Backup & Recovery** → automated через CI/CD
- **LVM & Disks** → provisioning через Infrastructure as Code

### To Season 5 (Security):
- **Git** → code review для security
- **Docker** → container security, vulnerability scanning
- **CI/CD** → security scanning integration
- **Ansible** → security hardening automation

### To Season 7 (Production):
- **Docker** → Kubernetes (orchestration на следующем уровне)
- **CI/CD** → production deployment strategies
- **Ansible** → массовая настройка production кластеров
- **Monitoring** → интеграция с CI/CD и Ansible

---

## 🎓 Skills Progression

**Начало Season 4:**
- Max: традиционный sysadmin (SSH + ручная настройка)
- Dmitry: DevOps-инженер (автоматизация всего)
- Gap: Max не понимает зачем так сложно

**Середина Season 4:**
- Max: Docker и Git освоены
- Понимает преимущества версионирования
- Все еще skeptical про "over-automation"

**Конец Season 4:**
- Max: конвертирован в DevOps
- "Руками? Никогда больше. Ansible или ничего."
- Написал 5+ playbooks, 10+ Dockerfiles
- Готов для Season 5 (где DevSecOps — security + автоматизация)

---

## 🏆 Итоговый проект Season 4

**Нет отдельного финального проекта.**

Все навыки из Episodes 13-16 естественно интегрируются в Episode 16 (Ansible) и используются в Season 5-8.

**К концу Season 4 у вас будет:**
- ✅ Git repository с всеми конфигами операции
- ✅ Docker images для всех инструментов
- ✅ CI/CD pipeline для automated testing и deployment
- ✅ Ansible playbooks для управления 50+ серверами
- ✅ Infrastructure as Code для всей операции

**Эти артефакты будут использоваться в:**
- Season 5: Security scanning integration
- Season 7: Production deployment с Kubernetes
- Season 8: Финальная битва (scaling под DDoS)

---

## 📝 Цитаты Season 4

**Hans Müller (CCC):**
> "In Chaos Computer Club we have three rules: 1) Hack the planet. 2) Share the knowledge. 3) Version control everything. Git is not optional. Git is life."

**Sophie van Dijk:**
> "Containers zijn als LEGO. You build once, run anywhere. Simple concept, powerful execution. Dutch pragmatism."

**Klaus Schmidt:**
> "Ansible is idempotent. Like German engineering. You run it once, you run it thousand times — same result. Predictable. Reliable. Boring. Perfect."

**Dmitry Orlov:**
> "Макс, в России мы говорим: 'Работает — не трогай.' В DevOps мы говорим: 'Работает — автоматизируй.' Разница."

**LILITH:**
> "Automation is not laziness. It's self-preservation. At scale, manual work kills. Literally. System failures, burnout, 3 AM wake-up calls. Automate or die."

**Max (evolution):**
- Episode 13: "Зачем Git для конфигов? Я и так помню что менял."
- Episode 14: "Docker сложный. Проще установить все в систему."
- Episode 15: "Хорошо, CI/CD полезен. Но где staging?"
- Episode 16: "Ansible — лучшее, что я видел. Настроить 50 серверов за 10 минут? Магия."

---

## 🎬 Начало Season 4

**[KERNEL SHADOWS — SEASON 4: DEVOPS & AUTOMATION]**

```
FADE IN:

EXT. AIRPORT TEGEL (BERLIN) — DAY 25

Max выходит из терминала. Холодный берлинский ветер. Graffiti на стенах.
Industrial aesthetic.

Dmitry Orlov (30s, Russian accent, backpack with laptop stickers: Docker, Kubernetes, Ansible)
стоит у выхода.

DMITRY
Max Sokolov?

MAX
Dmitry?

(рукопожатие)

DMITRY
Добро пожаловать в Берлин. Chaos Computer Club через час.
Hans Müller ждёт. Поехали.

MAX
(оглядывается)
Берлин... Я слышал про CCC. Хакеры, которые изменили Европу.

DMITRY
Не просто хакеры. Философия. Open source, privacy, автоматизация.
Git родился из этой культуры. Infrastructure as Code — тоже.

MAX
Мы собираемся хакать?

DMITRY
(улыбается)
Нет. Мы собираемся автоматизировать. Что почти то же самое.

CUT TO:

INT. CHAOS COMPUTER CLUB — DAY 25

Hans Müller (35, German, CCC hoodie, multiple monitors, mechanical keyboard)
печатает код. Git commit message видно на экране:

"feat: add infrastructure automation for operation shadow"

Dmitry и Max входят.

HANS
(не отрываясь от экрана)
You must be Max. Viktor spoke highly of you.
(оборачивается)
But Viktor also said you don't use version control for configs.
This is... problematic.

MAX
(защищается)
Я знаю что я делаю. Я помню все изменения.

HANS
(серьёзно)
You remember now. But in one month? After 50 servers? After 1000 commits?
Memory is fallible. Git is not.
(поворачивается к доске)
Let me show you why version control is not optional.
It's survival.

(На доске появляется схема: Git → Docker → CI/CD → Ansible)

HANS (CONT'D)
This is the pipeline. Everything starts with Git.
No version control — no automation.
No automation — you die at scale.

Welcome to Season 4. Let's begin.

LILITH (V.O., в наушниках Max)
He's dramatic. But correct.
Master the kernel. Control the shadows.
Starting with version control.

FADE TO:

[EPISODE 13: GIT & VERSION CONTROL]
```

---

---

<div align="center">

**Season 4: DevOps & Automation**

*From manual to automated. From chaos to control. From sysadmin to DevOps engineer.*

🇳🇱 Amsterdam • 🇩🇪 Berlin • Git • Docker • CI/CD • Ansible

**"Automate or die at scale."**

[⬆ Back to Main README](../README.md) | [➡️ s04e01 — Git: три зоны и чтение истории](s04e01-git-history/)

</div>


