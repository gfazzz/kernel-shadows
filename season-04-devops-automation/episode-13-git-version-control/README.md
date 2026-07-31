# EPISODE 13: GIT & VERSION CONTROL 📦🇩🇪

> **"Code is law. Version control is constitution. Without Git, you have anarchy."**
> — Hans Müller, Chaos Computer Club

---

## 📍 Контекст операции

**День:** 25-26 из 60
**Локация:** 🇩🇪 Берлин, Германия (Chaos Computer Club, hackerspace)
**Время:** 4-5 часов
**Сложность:** ⭐⭐⭐☆☆

**Предыдущий эпизод:** [Episode 12: Backup & Recovery](../../season-03-system-administration/episode-12-backup-recovery/README.md) (Tallinn, Estonia)
**Следующий эпизод:** Episode 14: Docker Basics (Amsterdam, Netherlands)

---

## 🎬 Сюжет

### Переход Season 3 → Season 4

**Виктор (видеозвонок, конец Episode 12):**
> *"Макс, ты справился с системным администрированием. Backup спас операцию. Но теперь — масштаб. У нас 50 серверов. Через месяц будет 100. Управлять конфигами вручную невозможно. Нужна автоматизация. DevOps. Летишь в Берлин. Дмитрий встретит."*

**Дмитрий Орлов (звонок на следующий день):**
> *"Макс, привет. Я Дмитрий, DevOps-инженер команды. Я последние 2 недели настраивал Docker, Ansible, CI/CD, но мне нужна помощь. В Берлине есть Hans Müller — один из лучших DevOps в Европе, участник CCC. Он научит нас infrastructure as code. Начнём с Git."*

### День 25: Прилёт в Берлин

**15:00 — Tegel Airport**

Макс выходит из терминала. Берлин — индустриальный, холодный, graffiti на стенах, но энергичный.

Дмитрий Орлов (30 лет, русский акцент, backpack с наклейками Docker/Kubernetes/Ansible) встречает у выхода.

**Дмитрий:**
> *"Макс? Добро пожаловать в Берлин. Chaos Computer Club через час. Hans ждёт. Поехали. О, и кстати — Hans педантичен. Если увидит что мы не используем Git для конфигов, будет лекция на 2 часа. Предупреждён — значит вооружён."*

**17:00 — Chaos Computer Club (CCC)**

Хакерспейс в индустриальном здании. Серверы, множество мониторов, механические клавиатуры, Open Source постеры, анархистская эстетика встречает немецкую точность.

Hans Müller (35 лет, CCC hoodie, серьёзный) печатает код. На экране — Git commit message:

```
feat: add infrastructure automation for operation shadow

- ansible playbooks for server provisioning
- docker-compose for microservices
- CI/CD pipeline for automated deployment

Signed-off-by: Hans Müller <hans@ccc.de>
```

**Hans (не отрываясь от экрана):**
> *"Ты, должно быть, Макс. Виктор много рассказывал о тебе."*

(оборачивается)

> *"Но Виктор также сказал, что ты управляешь конфигами 50 серверов **без version control**. Это... проблематично. Нет, это преступление."*

**Макс (защищается):**
> *"Я знаю что я делаю. У меня backup'ы. Я помню все изменения."*

**Hans:**
> *"Сейчас помнишь. А через месяц? После 1000 изменений? Память ненадёжна. Люди ненадёжны. **Git надёжен**."*

(поворачивается к доске, рисует схему)

```
Git → Docker → CI/CD → Ansible → Kubernetes
 ↑
 └── Everything starts here
```

> *"Infrastructure as Code. Version control для всего: конфигов, скриптов, документации. If it's not in Git, it doesn't exist. Welcome to DevOps. Let's begin."*

### ИНЦИДЕНТ (происходит в середине Episode)

**21:30 — Emergency звонок от Anna**

**Anna (паника в голосе):**
> *"Max! EMERGENCY! Кто-то из команды закоммитил **пароль от production сервера** в Git repository! Public repository! GitHub! Полчаса назад! Krylov уже знает! У нас 10 минут до атаки!"*

**Hans (мгновенно серьёзный):**
> *"Scheisse. Классическая ошибка. Git никогда не забывает. Даже если удалишь commit, он останется в истории. Нужен git filter-branch. НЕМЕДЛЕННО."*

**Задача:**
- Найти leaked secret в Git history
- Удалить из истории (git filter-branch или BFG Repo-Cleaner)
- Force push (осторожно!)
- Ротация паролей (немедленно!)
- Audit: кто закоммитил? когда? почему не было .gitignore?

**Resolution:**
- 5 минут: Git history cleaned
- 3 минуты: Password rotated
- 2 минуты: Anna блокирует попытку Krylov (IP 185.220.101.52, Tor node)

**Hans (после):**
> *"Вот почему у нас есть `.gitignore`. Вот почему мы НИКОГДА не коммитим secrets. Git мощный. Но сила требует ответственности. Усвоили урок?"*

**Макс:**
> *"Жёсткий урок. Но усвоен."*

**LILITH:**
> *"Secrets в Git — как заряженный пистолет в детской комнате. Не делайте так. Никогда."*

### Финал Episode 13

**23:00 — Debriefing**

**Виктор (видеозвонок):**
> *"Crisis averted. Password rotated. No breach. Good work. Hans, thank you."*

**Hans:**
> *"Не проблема. Но Max, Dmitry — вам нужно изучить **весь pipeline**. Git — это фундамент. Дальше: Docker (Sophie в Амстердаме), потом CI/CD (я помогу удалённо), затем Ansible (Klaus). Четыре эпизода. Две недели. Готовы?"*

**Макс:**
> *"Готовы. Автоматизируем всё."*

**Дмитрий:**
> *"Welcome to DevOps, Max. Automation или смерть на масштабе."*

**Cliffhanger:**

**Alex (текстовое сообщение):**
> *"Макс. Krylov пытался атаковать через leaked password. Но это была **отвлекающая атака**. Что-то большее готовится. Supply chain attack. Будь осторожен в Амстердаме. Docker images — легко компрометировать. — A."*

---

## 🎯 Миссия Episode 13

**Основная задача:** Организовать Git repository для конфигов операции, настроить branching strategy, научиться защищать secrets.

**Конкретные задания:**

1. ✅ **Инициализировать Git репозиторий** для конфигов операции
2. ✅ **Создать структуру папок** (configs/, scripts/, docs/, ansible/, docker/)
3. ✅ **Настроить .gitignore** (secrets, logs, temporary files)
4. ✅ **Branching strategy** (main, development, feature branches)
5. ✅ **Commit с правильными сообщениями** (conventional commits)
6. ✅ **Simulate merge conflict** и разрешение
7. ✅ **Secrets management** (git-crypt, .env.example, HashiCorp Vault integration)
8. ✅ **Audit leaked secret** (найти, удалить из истории, ротировать пароль)
9. ✅ **Generate Git audit report** (commits, branches, security)

**Финальный артефакт:**
- Чистый Git repository
- `.gitignore` со всеми правилами
- Branching strategy документирована
- Secrets защищены
- Audit report сгенерирован

---

---

## 🎓 Учебная программа: 7 циклов

**Продолжительность:** 4-5 часов
**Формат:** Interleaving (Сюжет → Теория → Практика → Проверка)

1. **Цикл 1:** Git Basics — Time Machine для кода (10-15 мин)
2. **Цикл 2:** Branching — Параллельные вселенные (10-15 мин)
3. **Цикл 3:** Secrets Management — Bouncer ночного клуба (10-15 мин)
4. **Цикл 4:** Merge Conflicts — Слияние временных линий (10-15 мин)
5. **Цикл 5:** INCIDENT — Leaked Secret 🔥 (15-20 мин)
6. **Цикл 6:** Infrastructure as Code (10-15 мин)
7. **Цикл 7:** Git Advanced — Команды для профи (10-15 мин)

---

## ЦИКЛ 1: Git Basics — Time Machine для кода ⏰
### (10-15 минут)

### 🎬 Сюжет: Прилёт в Берлин

**17:00 — Chaos Computer Club (CCC)**

Макс и Дмитрий входят в хакерспейс. Серверы гудят, механические клавиатуры щёлкают, на стенах — постеры с Open Source лого.

Hans Müller (35 лет, CCC hoodie, серьёзный) печатает код. На экране — идеальный Git commit:

```
feat: add infrastructure automation for operation shadow

- ansible playbooks for server provisioning
- docker-compose for microservices
- CI/CD pipeline for automated deployment

Signed-off-by: Hans Müller <hans@ccc.de>
```

**Hans (не отрываясь от экрана):**
> *"Ты, должно быть, Макс. Виктор много рассказывал."*

(оборачивается)

> *"Но он также сказал, что ты управляешь конфигами 50 серверов **без version control**. Это не просто проблема. Это преступление."*

**Макс (защищается):**
> *"У меня backup'ы. Я помню все изменения."*

**Hans:**
> *"Сейчас помнишь. А через месяц? После 1000 коммитов? Память ненадёжна. Люди ненадёжны. **Git надёжен**."*

(рисует на доске)

```
Git → Docker → CI/CD → Ansible → Kubernetes
 ↑
 └── Everything starts here
```

> *"Infrastructure as Code начинается с Git. If it's not in Git, it doesn't exist."*

---

### 📚 Теория: Зачем нужен Git?

**Представь:** Ты редактируешь important_config.conf на production сервере.

**Без Git:**
```
important_config.conf        ❌ Какая это версия?
important_config_backup.conf ❌ Когда создан backup?
important_config_OLD.conf    ❌ Кто правил?
important_config_v2.conf     ❌ Что изменилось от v1 к v2?
```

**С Git:**
```bash
git log important_config.conf

commit a1b2c3d Author: Max Sokolov Date: 2025-10-01
feat: add SSL configuration

commit e4f5g6h Author: Dmitry Orlov Date: 2025-09-30
fix: correct port from 8080 to 80

commit i7j8k9l Author: Anna Kovaleva Date: 2025-09-25
chore: initial configuration
```

✅ Полная история: кто, когда, что, зачем
✅ Простой откат: `git revert e4f5g6h`
✅ Audit trail: compliance, security

**LILITH:**
> *"Git — это Time Machine для кода. Можешь вернуться в любой момент прошлого. Но в будущее не прыгнешь — коммить нужно регулярно."*

---

### 💡 Метафора: Git = Time Machine + Фотоаппарат

**Git как Time Machine:**
- **Commit** = Snapshot (фото текущего состояния)
- **Branch** = Параллельная временная линия
- **Merge** = Слияние временных линий
- **Checkout** = Телепортация в прошлое/будущее

**Пример:**
```
2025-10-01 10:00  [Photo] feat: add nginx config  ← Snapshot #3
2025-10-01 09:00  [Photo] fix: correct port       ← Snapshot #2
2025-10-01 08:00  [Photo] initial commit          ← Snapshot #1
```

Можешь вернуться к любому снимку: `git checkout <commit>`

**LILITH:**
> *"Коммит — это не кнопка 'Save'. Это кнопка 'Freeze Time'. После коммита этот момент навсегда останется в истории."*

---

### 📖 Git: Три зоны

Понимание трёх зон — ключ к Git.

```
┌─────────────────────┐
│  Working Directory  │  ← Ты редактируешь файлы здесь
│   (edit files)      │
└──────────┬──────────┘
           │ git add
           ↓
┌─────────────────────┐
│   Staging Area      │  ← Подготовка к commit
│   (готово к commit) │
└──────────┬──────────┘
           │ git commit
           ↓
┌─────────────────────┐
│   Repository        │  ← История (все commits)
│   (.git/)           │
└──────────┬──────────┘
           │ git push
           ↓
        Remote (GitHub/GitLab)
```

**Метафора: Концерт**
- **Working Directory** = Репетиция (пробуешь идеи)
- **Staging Area** = Backstage (выбрал что показать публике)
- **Repository** = Сцена (публичное выступление, записано навсегда)

**LILITH:**
> *"Staging Area — это last chance передумать. Добавил файл в staging? Ещё можешь отменить. Закоммитил? Welcome to history."*

---

### 💻 Практика 1: Initialize Git repository

**Задача:**
```bash
# 1. Создать папку для infrastructure
mkdir -p ~/operation-shadow-infrastructure
cd ~/operation-shadow-infrastructure

# 2. Инициализировать Git
git init

# 3. Configure Git
git config user.name "Max Sokolov"
git config user.email "max@operation-shadow.net"

# 4. Создать первый файл
echo "# Operation Shadow Infrastructure" > README.md

# 5. Проверить статус
git status

# Что видишь?
# On branch main
# Untracked files:
#   README.md
```

**Вопрос:** Почему README.md "untracked"?

<details>
<summary>💡 Ответ (думай 30 секунд)</summary>

**Untracked** = Git видит файл, но ещё не следит за ним.

Файл в **Working Directory**, но не в Staging Area и не в Repository.

Чтобы Git начал следить:
```bash
git add README.md    # Working → Staging
git commit -m "chore: initial commit"  # Staging → Repository
```

Теперь файл **tracked** (Git следит за изменениями).

</details>

**Hans (смотрит на твой экран):**
> *"Untracked files — это как гости без приглашения. Git их видит, но не пускает внутрь. `git add` — это приглашение."*

---

### 💻 Практика 2: First commit

**Задача:**
```bash
# 1. Добавить файл в Staging
git add README.md

# 2. Проверить статус
git status
# Changes to be committed:
#   new file:   README.md

# 3. Commit
git commit -m "chore: initial commit"

# 4. Проверить историю
git log
# commit a1b2c3d (HEAD -> main)
# Author: Max Sokolov <max@operation-shadow.net>
# Date:   Thu Oct 10 18:00:00 2025
#
#     chore: initial commit
```

**Поздравляю!** Ты создал первый snapshot в Time Machine.

**LILITH:**
> *"Первый коммит — как первый прыжок с парашютом. Страшно, но потом привыкаешь. Скоро будешь коммитить не задумываясь."*

---

### 🤔 Проверка понимания: Цикл 1

**LILITH:** *"Проверим, усвоил ли ты основы. Три вопроса."*

**Вопрос 1:** Что делает `git add`?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Перемещает файлы из **Working Directory** в **Staging Area** (подготовка к commit).

**НЕ** сохраняет в repository! Это делает `git commit`.

</details>

**Вопрос 2:** Можно ли вернуться к прошлому коммиту?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Да! `git checkout <commit-hash>` или `git revert <commit>`.

Git — это Time Machine. Каждый commit — точка в прошлом, к которой можно вернуться.

</details>

**Вопрос 3:** Что хранится в папке `.git/`?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Вся история repository (все commits, branches, refs).

Удалишь `.git/` → потеряешь всю историю (останутся только текущие файлы).

**LILITH:** *"`.git/` — это мозг репозитория. Без него Git не помнит прошлого."*

</details>

**Hans:**
> *"Неплохо. Три из трёх — ты готов к branching. Следующая тема сложнее."*

---

## ЦИКЛ 2: Branching — Параллельные вселенные 🌌
### (10-15 минут)

### 🎬 Сюжет: Обсуждение стратегии

**18:00 — CCC, через час после начала**

Hans открывает whiteboard, рисует схему:

```
main (production)
 ├── development (testing)
 │    ├── feature/docker (Max)
 │    ├── feature/ansible (Dmitry)
 │    └── hotfix/urgent-fix
 └── (main защищён от прямых изменений)
```

**Hans:**
> *"В Chaos Computer Club у нас правило: **main всегда стабилен**. Никто не коммитит в main напрямую. Только через branches и code review."*

**Дмитрий:**
> *"А если срочный hotfix? Продакшн горит?"*

**Hans:**
> *"Hotfix branch. Фиксим, тестируем, мержим. Даже при пожаре — процесс есть процесс. Хаос в коде — хуже пожара."*

**Макс:**
> *"Но зачем столько веток? Можно ведь в одной работать?"*

**Hans (улыбается):**
> *"Можно. Также как можно жить в одной комнате с 50 людьми. Теоретически возможно. Практически — ад. Branches — это личное пространство. Экспериментируй сколько хочешь. Сломал? Удали branch. Main остался чист."*

**LILITH:**
> *"Branches — это параллельные вселенные. В одной Max ломает всё. В другой Dmitry создаёт шедевр. Main — это та вселенная, где всё работает. Всегда."*

---

### 📚 Теория: Branches — параллельные временные линии

**Метафора: Мультивселенная**

Представь:
- **main** = Основная вселенная (стабильная, production)
- **feature/docker** = Альтернативная вселенная где Max экспериментирует с Docker
- **feature/ansible** = Другая вселенная где Dmitry пишет Ansible playbooks

Каждая вселенная развивается независимо. Когда feature готов → **merge** (слияние вселенных).

**Визуализация:**

```
Time →

main:       A───B───────E───F      (production)
             \         /
              \       /
feature/docker:  C───D              (Max's experiments)
```

- `A`, `B` = commits в main
- `C`, `D` = commits в feature/docker (Max работает изолированно)
- `E` = merge (слияние feature → main)
- `F` = продолжение main

**Зачем branches?**

✅ **Изоляция:** Эксперименты не ломают production
✅ **Параллельная работа:** Max и Dmitry работают одновременно
✅ **Code review:** Проверка перед merge
✅ **Откат:** Сломал feature? Удали branch, main не пострадал

**LILITH:**
> *"Branch — это sandbox. Можешь ломать что угодно. Main — это production. Ломать нельзя. Никогда."*

---

### 💻 Практика 3: Create and switch branches

**Задача:**
```bash
cd ~/operation-shadow-infrastructure

# 1. Посмотреть текущий branch
git branch
# * main

# 2. Создать development branch
git checkout -b development
# Switched to a new branch 'development'

# 3. Создать feature branch
git checkout -b feature/episode13-git
# Switched to a new branch 'feature/episode13-git'

# 4. Посмотреть все branches
git branch
#   development
# * feature/episode13-git
#   main

# 5. Переключиться обратно на main
git checkout main
```

**Команды:**
- `git branch` — список branches
- `git checkout -b <name>` — создать + переключиться
- `git checkout <name>` — переключиться на существующий

**LILITH:**
> *"Переключение branch — это телепортация между вселенными. Файлы меняются мгновенно. Магия? Нет. Git."*

---

### 💻 Практика 4: Work in branches

**Сценарий:** Max создаёт ansible playbook в feature branch.

```bash
# 1. Переключиться на feature branch
git checkout feature/episode13-git

# 2. Создать структуру
mkdir -p ansible/playbooks
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
EOF

# 3. Commit в feature branch
git add ansible/
git commit -m "feat: add ansible playbook for nginx webservers"

# 4. Проверить что main не изменился
git checkout main
ls ansible/  # Нет такой папки! (ansible только в feature branch)

# 5. Вернуться в feature
git checkout feature/episode13-git
ls ansible/  # Папка есть!
```

**Aha! момент:** Файлы "исчезают" и "появляются" при переключении branches!

**LILITH:**
> *"Вуду? Нет. Git переключает всю файловую систему под твоим носом. Ты работаешь в feature — видишь feature. Переключился в main — видишь main. Каждый branch — своя реальность."*

---

### 💻 Практика 5: Merge branches

**Задача:** Merge feature branch в main.

```bash
# 1. Переключиться на main (куда мержим)
git checkout main

# 2. Merge feature branch
git merge feature/episode13-git

# Output:
# Updating a1b2c3d..e4f5g6h
# Fast-forward
#  ansible/playbooks/webservers.yml | 10 ++++++++++
#  1 file changed, 10 insertions(+)

# 3. Проверить что файлы появились в main
ls ansible/playbooks/
# webservers.yml  ← Теперь в main!

# 4. Удалить feature branch (уже не нужен)
git branch -d feature/episode13-git
# Deleted branch feature/episode13-git (was e4f5g6h)
```

**Fast-forward merge:** Если main не изменился с момента создания branch, Git просто "перематывает" main вперёд.

**Hans:**
> *"Merge — это момент когда эксперимент становится реальностью. Feature проверен, протестирован, готов. Welcome to production."*

---

### 🤔 Проверка понимания: Цикл 2

**LILITH:** *"Branching — сложная тема. Проверим понимание."*

**Вопрос 1:** Что произойдёт если создать файл в feature branch, но не коммитить?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Файл останется в **Working Directory** при переключении branch.

Uncommitted changes "путешествуют" с тобой между branches (пока не создают конфликты).

**Правило:** Коммить или stash перед переключением branch!

```bash
git stash       # Спрятать uncommitted changes
git stash pop   # Вернуть changes
```

</details>

**Вопрос 2:** Можно ли удалить main branch?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Технически да, но **НИКОГДА НЕ ДЕЛАЙ ЭТО**.

main = production. Удалишь main → удалишь production историю.

Git не даст удалить текущий branch: нужно переключиться на другой перед удалением.

**LILITH:** *"Удалить main — как delete production database. Технически возможно. Карьерно — самоубийство."*

</details>

**Вопрос 3:** Почему не коммитить в main напрямую?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Best practice:** main всегда стабилен.

- Feature branch → экспериментируй
- Сломал → откатывай, удаляй branch
- Работает → code review → merge в main

**Прямой commit в main** = риск сломать production без review.

**Hans:** *"В CCC нарушение этого правила = public shaming на конференции. Работает эффективно."*

</details>

**Hans:**
> *"Отлично. Branching усвоен. Теперь самая важная тема: **secrets**. Здесь ошибки стоят дорого."*

---

## ЦИКЛ 3: Secrets Management — Bouncer ночного клуба 🚫
### (10-15 минут)

### 🎬 Сюжет: Предупреждение Hans

**18:30 — CCC, Hans серьёзнеет**

Hans открывает laptop, показывает скриншот:

```
GitHub Public Repository
├── config.yml
├── deploy.sh
└── .env  ← 💀 ПАРОЛИ В PUBLIC REPO!

DB_PASSWORD=SuperSecret123
AWS_KEY=AKIAIOSFODNN7EXAMPLE
```

**Hans:**
> *"Это реальный случай. Startup, Германия, 2023. Закоммитили `.env` в public GitHub. Через 15 минут — злоумышленники в их AWS. $50,000 ущерб за ночь. Компания закрылась через месяц."*

**Макс (бледнеет):**
> *"15 минут? Как они так быстро нашли?"*

**Hans:**
> *"Боты сканируют GitHub 24/7. Ищут паттерны: `password=`, `api_key=`, `SECRET=`. Найдут секрет → автоматическая атака. Не люди. Боты."*

**Дмитрий:**
> *"А если удалить commit?"*

**Hans (качает головой):**
> *"Git НИКОГДА НЕ ЗАБЫВАЕТ. Удалишь файл — он останется в истории. Нужен `git filter-branch`. Сложная операция. Проще — НЕ КОММИТИТЬ СЕКРЕТЫ ВООБЩЕ."*

**LILITH:**
> *"Secrets в Git — как татуировка на лбу. Можешь потом удалить, но все уже увидели. И боты сфотографировали."*

---

### 📚 Теория: .gitignore — Bouncer ночного клуба

**Метафора: Ночной клуб**

`.gitignore` = Bouncer у входа в клуб (Git repository).

- **VIP гости** (код, конфиги) → пропускаются ✅
- **Нежелательные** (secrets, логи, временные файлы) → НЕ пропускаются ❌

**Визуализация:**

```
Files trying to enter Git:
    ↓
┌─────────────────┐
│   .gitignore    │  ← Bouncer проверяет список
│   (rules)       │
└────────┬────────┘
         │
    ✅ main.py        → Allowed (код)
    ✅ config.yml     → Allowed (конфиг)
    ❌ .env           → BLOCKED (секреты!)
    ❌ *.log          → BLOCKED (логи)
    ❌ .DS_Store      → BLOCKED (OS мусор)
         │
         ↓
     Git Repository
```

**Правило:** `.gitignore` создавай **ДО ПЕРВОГО КОММИТА!**

**LILITH:**
> *"`.gitignore` сначала, коммит потом. Не наоборот. НИКОГДА наоборот."*

---

### 💻 Практика 6: Create .gitignore

**Задача:**
```bash
cd ~/operation-shadow-infrastructure

# 1. Создать .gitignore СЕЙЧАС (до коммита секретов!)
cat > .gitignore << 'EOF'
# Secrets (NEVER commit!)
.env
.env.*
*.pem
*.key
*_rsa
*_rsa.pub
passwords.txt
secrets.yml
credentials.json

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db

# Temporary
*.tmp
*.swp
*~
EOF

# 2. Commit .gitignore
git add .gitignore
git commit -m "chore: add .gitignore for secrets protection"

# 3. Test: создать .env файл
echo "DB_PASSWORD=test123" > .env

# 4. Проверить статус
git status
# .env НЕ появляется! (ignored)

# 5. Попробовать добавить
git add .env
# The following paths are ignored by one of your .gitignore files:
# .env
```

✅ `.env` заблокирован! Bouncer работает.

**Hans:**
> *"Теперь даже если случайно сделаешь `git add .`, секреты не попадут в repository. Первая линия защиты работает."*

---

### 💡 "Aha!" момент: git add . без .gitignore

**Сценарий БЕЗ .gitignore:**

```bash
# ❌ ОПАСНО! БЕЗ .gitignore
echo "PASSWORD=secret123" > .env
git add .       # Добавляет ВСЁ, включая .env!
git commit -m "update"   # .env в repository!
git push        # .env на GitHub!
# 💀 Боты нашли пароль через 5 минут
```

**Сценарий С .gitignore:**

```bash
# ✅ БЕЗОПАСНО! С .gitignore
# .gitignore создан ПЕРВЫМ ДЕЛОМ
echo "PASSWORD=secret123" > .env
git add .       # .env игнорируется автоматически
git commit -m "update"   # .env НЕ попал в commit
# ✅ Секреты в безопасности
```

**LILITH:**
> *"git add . — это граната. С .gitignore — граната с предохранителем. Без .gitignore — ты уже мёртв."*

---

### 💻 Практика 7: .env.example pattern

**Best practice:** Commit `.env.example` (template), actual `.env` ignore.

```bash
# 1. Create .env.example (template — safe to commit)
cat > .env.example << 'EOF'
# Database credentials
DB_HOST=localhost
DB_PORT=5432
DB_NAME=operation_shadow
DB_USER=your_username_here
DB_PASSWORD=your_password_here

# API keys
GITHUB_TOKEN=your_token_here
EOF

# 2. Commit template
git add .env.example
git commit -m "chore: add .env.example template"

# 3. Create actual .env (will be ignored)
cp .env.example .env
# Edit .env with REAL secrets (не коммитится!)

# 4. Add documentation
cat > docs/SECRETS_MANAGEMENT.md << 'EOF'
# Secrets Management

## Setup
1. Copy `.env.example` to `.env`
2. Fill in real secrets
3. NEVER commit `.env` to Git!

## If leaked:
1. Rotate secrets IMMEDIATELY!
2. Remove from Git history (see below)

## Remove from history:
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty -- --all
```
EOF

git add docs/SECRETS_MANAGEMENT.md
git commit -m "docs: add secrets management guide"
```

**Hans:**
> *"Новый член команды клонирует repo → видит `.env.example` → копирует в `.env` → заполняет свои секреты → работает. Секреты никогда не в Git."*

---

### 🤔 Проверка понимания: Цикл 3

**LILITH:** *"Secrets — критическая тема. Три вопроса."*

**Вопрос 1:** Можно ли `.gitignore` добавить после того как уже закоммитил секреты?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Можно, но **ПОЗДНО**.

`.gitignore` работает только для **новых** файлов. Уже закоммиченные остаются в истории!

**Нужно:**
1. Добавить `.gitignore`
2. Удалить секреты из истории (`git filter-branch`)
3. Ротировать пароли (старые уже leaked!)

**LILITH:** *".gitignore — это презерватив. Надевать нужно ДО, не после."*

</details>

**Вопрос 2:** Почему `.env.example` можно коммитить, а `.env` нельзя?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:**

- `.env.example` = TEMPLATE (placeholder values)
  ```
  DB_PASSWORD=your_password_here  ← Не настоящий пароль
  ```

- `.env` = REAL SECRETS
  ```
  DB_PASSWORD=SuperSecret123!  ← Настоящий пароль
  ```

`.env.example` показывает структуру, но не содержит реальных секретов.

</details>

**Вопрос 3:** Боты действительно так быстро находят секреты на GitHub?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **ДА. 100% реально.**

Исследования показывают:
- **< 5 минут** — AWS ключи обнаружены и использованы
- **Тысячи ботов** сканируют GitHub 24/7
- **Автоматически** ищут паттерны: `api_key=`, `password=`, `secret=`

**Real world:** GitHub Leaked Secret Detection блокирует ~2 миллиона секретов в год.

**Hans:** *"Это не паранойя. Это реальность. Боты быстрее людей."*

**LILITH:** *"Закоммитил пароль на GitHub? Считай что он публичный. Через 5 минут его знают все. Включая ботнеты."*

</details>

**Hans:**
> *"Отлично. Теперь ты понимаешь почему я так параноидален. Secrets — это не шутки. Одна ошибка — и операция провалена."*

---

## ЦИКЛ 4: Merge Conflicts — Слияние временных линий ⚡
### (10-15 минут)

### 🎬 Сюжет: Max и Dmitry работают параллельно

**19:00 — CCC, Hans ушёл за кофе**

Max и Dmitry работают в разных feature branches.

**Max (в feature/max-nginx):** Правит `ansible/playbooks/webservers.yml`, устанавливает nginx на порт 80.

**Dmitry (в feature/dmitry-nginx):** В том же файле устанавливает nginx на порт 8080.

Оба коммитят. Hans возвращается.

**Hans:**
> *"Хорошо. Merge оба branch в main. Посмотрим что получится."*

**Max:**
```bash
git checkout main
git merge feature/max-nginx
# Merged successfully
```

**Dmitry:**
```bash
git merge feature/dmitry-nginx
# ⚠️ CONFLICT in webservers.yml!
```

**Dmitry (паника):**
> *"Ошибка! Auto-merging webservers.yml CONFLICT!"*

**Hans (спокойно):**
> *"Это не ошибка. Это **merge conflict**. Git не знает чью версию выбрать — твою или Max. Ты должен решить."*

**LILITH:**
> *"Merge conflict — это как два человека одновременно правят Google Doc. Кто-то должен разрулить. В Git этот кто-то — ты."*

---

### 📚 Теория: Merge Conflicts — что это?

**Merge conflict** происходит когда:
- Два branches изменили **одну и ту же строку** файла
- Git не знает какую версию оставить
- Требует **ручного разрешения**

**Метафора: Слияние временных линий**

Представь фильм "Back to the Future":
- **Timeline A:** Marty в 1985 году (Max's changes)
- **Timeline B:** Marty в 1955 году (Dmitry's changes)
- **Merge:** Попытка объединить две timeline → КОНФЛИКТ!

Git не может автоматически решить что правильно. Нужен человек (ты).

**Визуализация конфликта:**

```
main:       A───B───E (trying to merge)
             \     /
              \   /
Max branch:    C (port 80)
Dmitry branch:  D (port 8080)

Конфликт: C и D изменили одну строку!
```

**LILITH:**
> *"Merge conflict — это Git говорит: 'Слушай, умник, я тут два противоречащих изменения нашёл. Разбирайся сам.'"*

---

### 💻 Практика 8: Simulate merge conflict

**Воссоздадим сценарий Max vs Dmitry:**

```bash
cd ~/operation-shadow-infrastructure

# 1. Max создаёт свой branch
git checkout -b max-nginx-fix
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  tasks:
    - name: Configure nginx
      lineinfile:
        path: /etc/nginx/nginx.conf
        line: '    listen 80;'   # Max: port 80
EOF
git add ansible/playbooks/webservers.yml
git commit -m "fix: configure nginx port 80"

# 2. Вернуться в main
git checkout main

# 3. Dmitry создаёт свой branch (from main, before Max's merge!)
git checkout -b dmitry-nginx-fix
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  tasks:
    - name: Configure nginx
      lineinfile:
        path: /etc/nginx/nginx.conf
        line: '    listen 8080;'   # Dmitry: port 8080
EOF
git add ansible/playbooks/webservers.yml
git commit -m "fix: configure nginx port 8080"

# 4. Max мержит первым
git checkout main
git merge max-nginx-fix
# ✅ Merged successfully (fast-forward)

# 5. Dmitry пытается мержить
git merge dmitry-nginx-fix
# ⚠️ CONFLICT!
```

**Output:**
```
Auto-merging ansible/playbooks/webservers.yml
CONFLICT (content): Merge conflict in ansible/playbooks/webservers.yml
Automatic merge failed; fix conflicts and then commit the result.
```

---

### 📖 Разрешение конфликта

**Откроем файл:**

```bash
cat ansible/playbooks/webservers.yml
```

**Git вставил специальные markers:**

```yaml
---
- hosts: webservers
  tasks:
    - name: Configure nginx
      lineinfile:
        path: /etc/nginx/nginx.conf
<<<<<<< HEAD
        line: '    listen 80;'   # Max's version (current branch)
=======
        line: '    listen 8080;'   # Dmitry's version (incoming)
>>>>>>> dmitry-nginx-fix
```

**Markers:**
- `<<<<<<< HEAD` — начало текущей версии (Max)
- `=======` — разделитель
- `>>>>>>> dmitry-nginx-fix` — конец incoming версии (Dmitry)

**Твоя задача:** Выбрать одну версию (или объединить), удалить markers.

**LILITH:**
> *"Видишь эти `<<<<<<<`, `=======`, `>>>>>>>`? Это Git кричит: 'ПОМОГИТЕ! Не знаю что делать!' Удали markers, выбери версию, закоммить — конфликт решён."*

---

### 💻 Практика 9: Resolve conflict

**Решение:** Выбрать port 80 (production standard).

```bash
# 1. Отредактировать файл вручную
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  tasks:
    - name: Configure nginx
      lineinfile:
        path: /etc/nginx/nginx.conf
        line: '    listen 80;'   # Resolved: chose port 80 for production
EOF

# 2. Markers удалены! Добавить в staging
git add ansible/playbooks/webservers.yml

# 3. Проверить статус
git status
# All conflicts fixed. Ready to commit.

# 4. Commit разрешение
git commit -m "fix: resolve merge conflict (chose port 80 for production)"

# 5. Проверить историю
git log --oneline --graph --all
```

**Conflict resolved!** ✅

**Hans:**
> *"Хорошо. Конфликт разрешён правильно. В production выбирай стандартные порты. Port 80 для HTTP — правильный выбор."*

---

### 💡 "Aha!" момент: Что если не удалить markers?

**Сценарий:** Забыл удалить `<<<<<<<`, `=======`, `>>>>>>>`.

```yaml
# ❌ ОШИБКА: Markers остались!
---
- hosts: webservers
  tasks:
<<<<<<< HEAD
    - name: Install nginx
=======
    - name: Setup nginx
>>>>>>> branch
```

**Commit с markers:**
```bash
git add .
git commit -m "fix: resolve conflict"  # НЕ ЗАМЕТИЛ MARKERS!
```

**Результат:**
- ❌ Ansible playbook сломан (синтаксическая ошибка)
- ❌ Deployment fails
- ❌ Hans недоволен

**LILITH:**
> *"Markers в файле — как забыть снять ценник с новой одежды. Технически работает. Выглядит дебильно. Коллеги заметят."*

**How to avoid:**
```bash
# После редактирования, ВСЕГДА проверяй:
grep -r "<<<<<" ansible/
grep -r ">>>>>" ansible/
# Если вывод пустой — markers удалены ✅
```

---

### 🤔 Проверка понимания: Цикл 4

**LILITH:** *"Merge conflicts — частая проблема. Три вопроса."*

**Вопрос 1:** Почему возникают merge conflicts?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Когда два branches изменяют **одну и ту же строку** файла.

Git не знает какую версию выбрать → требует ручного разрешения.

**НЕ конфликт:**
- Max правит `file1.txt`, Dmitry правит `file2.txt` → нет конфликта
- Max правит строку 10, Dmitry правит строку 50 **того же файла** → нет конфликта

**Конфликт:**
- Max правит строку 10, Dmitry **тоже** правит строку 10 → КОНФЛИКТ!

</details>

**Вопрос 2:** Можно ли избежать merge conflicts?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Полностью избежать — **нет**. Минимизировать — **да**.

**Как минимизировать:**
1. **Частые merges:** Не держи feature branch месяцами
2. **Маленькие commits:** Меньше изменений = меньше конфликтов
3. **Коммуникация:** "Я сейчас правлю nginx.conf" → другие не трогают
4. **Модульность:** Разные файлы для разных features

**Hans:** *"В команде 50 человек конфликты неизбежны. Главное — уметь разрешать быстро."*

</details>

**Вопрос 3:** Что делает `git merge --abort`?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **Отменяет merge** и возвращает repository в состояние **до merge**.

```bash
git merge feature-branch
# CONFLICT!
# "Блин, слишком сложно. Потом разберусь."
git merge --abort
# Merge отменён, всё как было
```

Полезно когда конфликтов слишком много и нужно сначала подумать.

**LILITH:** *"`git merge --abort` — это кнопка 'Undo'. Застрял в конфликтах? Откат. Подумай. Попробуй снова."*

</details>

**Hans:**
> *"Merge conflicts — нормальная часть работы. Не паникуй. Открой файл, удали markers, выбери версию, commit. Всё."*

---

## ЦИКЛ 5: INCIDENT — Leaked Secret 🔥🚨
### (15-20 минут)

### 🎬 Сюжет: Emergency звонок от Anna

**21:30 — CCC, Max и Dmitry почти закончили Git setup**

**BZZZZT!** Телефон Max вибрирует. Anna. Video call.

**Anna (на экране, лицо напряжённое, за спиной — мониторы с логами):**
> *"Max! EMERGENCY! Кто-то из команды закоммитил **пароль от production database** в Git repository!"*

**Max:**
> *"Что? Кто?"*

**Anna:**
> *"Не важно кто! Репозиторий public! GitHub! Коммит 30 минут назад! **Krylov уже знает!** У нас 10 минут до атаки!"*

**Hans (мгновенно серьёзный, отодвигает кофе):**
> *"Scheisse. Классическая ошибка. Git никогда не забывает. Даже если удалишь commit, он остаётся в истории."*

(печатает команды)

> *"Нужен `git filter-branch` или BFG Repo-Cleaner. НЕМЕДЛЕННО."*

**Dmitry:**
> *"Сколько времени?"*

**Hans:**
> *"5 минут на cleanup истории. 3 минуты на ротацию пароля. 2 минуты запас. Go! Go! Go!"*

**LILITH:**
> *"Это не учебная тревога. Это real incident. Одна ошибка — Krylov в нашей базе данных. Вся операция под угрозой."*

---

### 📚 Теория: Git History — Immutable Blockchain

**Критическая концепция:** Git history = **blockchain**.

Однажды что-то закоммитив → оно остаётся навсегда. Даже если "удалишь" файл.

**Визуализация:**

```
Commit history (как blockchain):
A → B → C → D → E
        ↑
     Leaked secret here!

"Удаление" commit C:
❌ Не работает: C остаётся в истории
✅ Работает: Rewrite history (опасно!)
```

**Why Git doesn't forget:**

Git хранит **все commits** (даже удалённые) для:
- Возможности отката (`git reflog`)
- Безопасности (нельзя потерять данные случайно)
- Audit trail

**Проблема:** Если закоммитил секрет → он в истории. Навсегда.

**LILITH:**
> *"Git — это слон. Помнит всё. Не забывает никогда. Закоммитил пароль? Git запомнил. GitHub запомнил. Боты запомнили. Ротируй пароль. Сейчас же."*

---

### 💻 Практика 10: INCIDENT — Find leaked secret

**Simulate incident:**

```bash
cd ~/operation-shadow-infrastructure

# ❌ ОШИБКА: кто-то (не ты!) закоммитил secrets.txt
cat > secrets.txt << 'EOF'
# Production Database Password
DB_PASSWORD=ProdSecret2024!
DB_HOST=10.20.30.40

# Viktor SSH key
SSH_KEY=-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
EOF

git add secrets.txt
git commit -m "Add production secrets"  # 💀 FATAL MISTAKE!

# Secret теперь в истории!
git log --oneline
# a1b2c3d Add production secrets  ← 💀 LEAK!
```

**Task 1: Find leaked secret**

```bash
# Search Git history for "password"
git log --all -S "DB_PASSWORD" --oneline

# Output:
# a1b2c3d Add production secrets  ← Found it!

# See full commit
git show a1b2c3d
# Видим весь секрет!
```

**Hans:**
> *"Найден. Commit a1b2c3d. 5 минут прошло. Осталось 5 минут. Remove from history. NOW!"*

---

### 💻 Практика 11: Remove from Git history

**Option 1: git filter-branch** (slow but built-in)

```bash
# Remove secrets.txt from ALL history
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch secrets.txt" \
  --prune-empty --tag-name-filter cat -- --all

# Clean up refs
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Option 2: BFG Repo-Cleaner** (fast, recommended)

```bash
# Install BFG (if not installed)
# sudo apt install bfg

# Remove file from history
bfg --delete-files secrets.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Hans (смотрит на часы):**
> *"2 минуты. History cleaned. Теперь force push."*

---

### 💻 Практика 12: Force push & Password rotation

```bash
# ⚠️ WARNING: Force push rewrites remote history!
# Notify team BEFORE doing this!
git push --force --all

# Output:
# + a1b2c3d...e4f5g6h main -> main (forced update)
```

**Hans:**
> *"Remote history rewritten. Secret удалён. Но!"*

(серьёзно смотрит на Max)

> *"Password уже leaked. Боты могли скопировать. Ротация пароля. IMMEDIATELY."*

**Anna (на видеосвязи):**
> *"Меняю пароль БД прямо сейчас... Готово. Новый пароль установлен. Старый больше не работает."*

**Hans:**
> *"Сколько времени прошло?"*

**Max (смотрит на часы):**
> *"8 минут. Успели."*

**Anna:**
> *"Вижу попытку подключения с Tor node (185.220.101.52). Krylov. Пароль не подошёл. Blocked."*

**LILITH:**
> *"8 минут. Между утечкой и катастрофой. Ротация пароля спасла операцию. В следующий раз можем не успеть."*

---

### 💡 "Aha!" момент: Force push danger

**Force push** = **переписывание истории**.

**Danger:**
- Если кто-то уже pull old history → конфликты у всей команды
- Потеря commits других людей
- Requires coordination

**When to use:**
- ✅ Leaked secret (чрезвычайная ситуация)
- ❌ "Oops, typo in commit message" (не нужен!)

**Rule:** Force push = last resort. Только для критических проблем.

**Hans:**
> *"Force push — это ядерная опция. Решает проблему, но создаёт побочные эффекты. Used only when absolutely necessary."*

---

### 📋 Post-Incident Checklist

**After leaked secret incident:**

```bash
# 1. Add to .gitignore (prevent future)
echo "secrets.txt" >> .gitignore
git add .gitignore
git commit -m "fix: add secrets.txt to .gitignore after leak incident"

# 2. Document incident
cat > docs/INCIDENT_2025_10_10.md << 'EOF'
# Incident: Leaked Production Password

**Date:** 2025-10-10 21:30 UTC
**Severity:** CRITICAL
**Status:** Resolved

## What happened:
- Production database password committed to public GitHub
- Discovered 30 minutes after commit
- Responded in 8 minutes

## Actions taken:
1. Removed secret from Git history (git filter-branch)
2. Force pushed to remote
3. Rotated password immediately
4. Blocked attacker (Krylov, Tor node 185.220.101.52)

## Root cause:
- No .gitignore for secrets.txt
- Team member unfamiliar with Git security

## Prevention:
- Added secrets.txt to .gitignore
- Team training on Git security
- Pre-commit hooks to scan for secrets (planned)

## Lessons learned:
- .gitignore FIRST, commit SECOND
- Password rotation must be automatic
- Incident response time critical (<10 minutes)
EOF

git add docs/INCIDENT_2025_10_10.md
git commit -m "docs: incident report for leaked secret"
```

**Hans:**
> *"Инцидент закрыт. Password ротирован. История очищена. Атака предотвращена. Good work."*

**LILITH:**
> *"Выжили. В этот раз. В следующий раз можем не успеть. `.gitignore` — это не suggestion. Это survival."*

---

### 🤔 Проверка понимания: Цикл 5

**LILITH:** *"Incident разобран. Критические вопросы."*

**Вопрос 1:** Почему нельзя просто удалить файл (`git rm`) после leak?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** `git rm` удаляет файл из **текущего состояния**, но НЕ из **истории**.

```bash
git rm secrets.txt
git commit -m "remove secrets"
# Файла нет в новом commit
# НО! Он остался в предыдущих commits!

git log --all -- secrets.txt
# Видим все commits где файл был
git show <old-commit>:secrets.txt
# Можем прочитать содержимое!
```

Нужен `git filter-branch` для полного удаления из истории.

**LILITH:** *"`git rm` — это прятать труп под ковром. Труп остался. Просто не виден. Git history знает где искать."*

</details>

**Вопрос 2:** Сколько времени есть на реакцию после leak на GitHub?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **< 5-10 минут** для популярных secrets (AWS keys, DB passwords).

Research показывает:
- AWS keys: compromised за < 5 минут
- Database passwords: < 10 минут
- API tokens: < 15 минут

Боты сканируют GitHub commits в real-time.

**Hans:** *"10 минут — это если повезёт. Bots работают 24/7. Реакция должна быть мгновенной."*

</details>

**Вопрос 3:** Что важнее: удалить secret из истории или ротировать пароль?
<details>
<summary>Думай перед проверкой</summary>

**Ответ:** **РОТАЦИЯ ПАРОЛЯ ВАЖНЕЕ!**

**Priority:**
1. **Rotate password** (немедленно) — старый пароль больше не работает
2. Remove from history — очистить следы
3. Add to .gitignore — предотвратить повтор

**Why:** Даже если удалишь из Git, боты могли скопировать. Единственная защита = сделать пароль неактуальным.

**LILITH:** *"Git history можно почистить потом. Пароль ротируй сейчас. Каждая секунда — шанс для атаки."*

</details>

**Hans:**
> *"Критический урок усвоен. Leak — это не конец. Но реакция должна быть быстрой. 8 минут — хорошо. 5 минут — лучше. 2 минуты — идеально."*

**Max:**
> *"Понял. `.gitignore` — это первая линия защиты. Но если проломили — ротация пароля спасает операцию."*

---

## ЦИКЛ 6: Infrastructure as Code — Git для DevOps 🏗️
### (10-15 минут)

### 🎬 Сюжет: После инцидента

**22:30 — CCC, Crisis resolved**

Hans откидывается назад, делает глубокий вдох.

**Hans:**
> *"Хорошо. Инцидент закрыт. Теперь вы понимаете почему Git критичен для infrastructure."*

(открывает свой laptop, показывает repository)

```
operation-shadow-infrastructure/
├── ansible/
│   ├── playbooks/
│   │   ├── webservers.yml
│   │   ├── databases.yml
│   │   └── monitoring.yml
│   ├── roles/
│   └── inventory/
├── docker/
│   ├── web/Dockerfile
│   └── api/Dockerfile
├── terraform/
│   ├── main.tf
│   └── variables.tf
└── .gitlab-ci.yml  ← CI/CD automation
```

**Hans:**
> *"Infrastructure as Code. Всё в Git. Серверы, конфиги, deployment pipelines. Changes через Git workflow: branch → review → merge → automated deployment."*

**Dmitry:**
> *"Всё автоматизировано?"*

**Hans:**
> *"Да. Git commit → CI/CD pipeline запускается → тесты → deployment на production. Без human intervention. Это DevOps."*

**LILITH:**
> *"Infrastructure as Code = серверы описаны кодом. Код в Git. Git — source of truth. Ручной конфиг на сервере? Не существует. Только через Git."*

---

### 📚 Теория: Infrastructure as Code (IaC)

**Традиционный подход (плохо):**
- Конфиги хранятся на серверах
- Changes вручную (SSH → vim → edit → save)
- Нет истории изменений
- Impossible to replicate (как настроен сервер? Никто не помнит)

**Infrastructure as Code (хорошо):**
- Конфиги в Git repository
- Changes через pull requests
- Полная история + code review
- Easy to replicate (git clone → apply configs)

**Метафора: LEGO Instructions**

**Без IaC:** Сервер = готовая LEGO модель. Хочешь изменить? Ломай, собирай заново. Никто не помнит как было.

**С IaC:** Сервер = LEGO инструкция в Git. Хочешь изменить? Редактируй инструкцию → commit → сервер автоматически пересобирается.

**Визуализация workflow:**

```
Developer          Git          CI/CD          Production
    │               │              │                │
    ├─ git commit → │              │                │
    │               ├─ trigger  → │                │
    │               │              ├─ test          │
    │               │              ├─ build         │
    │               │              ├─ deploy    →  │
    │               │              │                ├─ applied!
```

**LILITH:**
> *"IaC — это рецепт для серверов. Рецепт в Git. Хочешь изменить блюдо? Правишь рецепт, не импровизируешь на кухне."*

---

### 💻 Практика 13: Create IaC repository structure

```bash
cd ~/operation-shadow-infrastructure

# Create comprehensive structure
mkdir -p ansible/playbooks ansible/roles ansible/inventory
mkdir -p docker/web docker/api docker/database
mkdir -p terraform scripts docs

# Ansible playbook example
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- name: Configure web servers
  hosts: webservers
  become: yes

  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Deploy website
      copy:
        src: ../files/index.html
        dest: /var/www/html/

    - name: Start nginx
      systemd:
        name: nginx
        state: started
        enabled: yes
EOF

# Dockerfile example
cat > docker/web/Dockerfile << 'EOF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# Document IaC workflow
cat > docs/INFRASTRUCTURE_AS_CODE.md << 'EOF'
# Infrastructure as Code Workflow

## Process
1. Create feature branch: `git checkout -b feature/new-server`
2. Edit configs (Ansible/Docker/Terraform)
3. Test locally
4. Commit: `git commit -m "feat: add monitoring server config"`
5. Push: `git push origin feature/new-server`
6. Create Pull Request
7. Code review by team
8. Merge to main
9. CI/CD deploys automatically

## Benefits
- Version control for infrastructure
- Code review process
- Easy rollback (git revert)
- Reproducible environments
- Audit trail

## Tools
- Ansible: Server configuration
- Docker: Containerization
- Terraform: Infrastructure provisioning
- GitLab CI/CD: Automated deployment
EOF

git add .
git commit -m "feat: add infrastructure as code structure and documentation"
```

**Hans:**
> *"Теперь вся infrastructure versioned. Rollback? `git revert`. Новый сервер? `git clone` → apply. Простои."*

---

### 🤔 Проверка понимания: Цикл 6

**Вопрос:** Почему IaC лучше ручной конфигурации?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:**

✅ **С IaC:**
- История изменений (кто, когда, зачем)
- Code review (ошибки выявляются до production)
- Reproducible (легко создать копию сервера)
- Automated deployment (без human error)
- Rollback одной командой (git revert)

❌ **Ручная конфигурация:**
- Нет истории (кто менял config? когда?)
- Нет review (ошибки попадают в production)
- Impossible to replicate ("Как был настроен старый сервер? Никто не помнит")
- Manual deployment (risk of human error)
- Rollback сложный (помнишь что менял?)

**LILITH:** *"Ручная конфигурация — это freestyle rap. IaC — это написанная песня. Freestyle круто для шоу. Но для production нужна предсказуемость."*

</details>

---

## ЦИКЛ 7: Git Advanced — Команды для профи 🎓
### (10-15 минут)

### 🎬 Сюжет: Final review from Hans

**23:00 — CCC, Финал эпизода**

Hans смотрит на часы.

**Hans:**
> *"6 часов прошло. Вы усвоили Git basics, branching, secrets, conflicts, infrastructure as code. Последняя тема: advanced Git commands."*

(открывает терминал, печатает команды)

**Hans:**
> *"В CCC мы используем Git ежедневно. Не только `add`, `commit`, `push`. Есть мощные команды для debugging, анализа, cleanup. Покажу самые полезные."*

**LILITH:**
> *"Git — это не только version control. Это инструмент расследования. Forensics для кода. Научись копать глубже."*

---

### 📚 Теория: Git Advanced Commands

**Beyond basics:**

Вы знаете: `git add`, `git commit`, `git push`

Теперь изучите: `git log --graph`, `git reflog`, `git bisect`, `git blame`, `git stash`

### 1. `git log --graph` — Визуализация истории

```bash
# Красивый graph с branches
git log --graph --oneline --all --decorate

# Output:
* e4f5g6h (HEAD -> main) Merge branch 'feature'
|\
| * a1b2c3d (feature) Add nginx config
|/
* i7j8k9l Initial commit
```

**Метафора:** Семейное древо. Видишь все branches, merges, relationships.

### 2. `git reflog` — Time Machine для Git

```bash
# Показать ВСЕ действия (даже удалённые commits)
git reflog

# Output:
a1b2c3d HEAD@{0}: commit: Add config
e4f5g6h HEAD@{1}: reset: moving to HEAD~1  ← Deleted commit!
i7j8k9l HEAD@{2}: commit: Deleted by mistake

# Restore deleted commit:
git reset --hard HEAD@{1}
```

**Use case:** Случайно удалил commit? `git reflog` спасёт!

### 3. `git bisect` — Binary search для багов

```bash
# Найти commit где появился баг
git bisect start
git bisect bad                # Current commit (has bug)
git bisect good v1.0          # Old commit (no bug)

# Git автоматически проверяет commits (binary search)
# Тестируешь каждый:
# - git bisect good (bug нет)
# - git bisect bad (bug есть)

# Git найдёт exact commit где появился баг!
git bisect reset  # Exit bisect mode
```

### 4. `git blame` — Кто написал этот код?

```bash
# Кто изменял каждую строку файла?
git blame ansible/playbooks/webservers.yml

# Output:
a1b2c3d (Max   2025-10-10) - name: Install nginx
e4f5g6h (Dmitry 2025-10-11)   apt:
i7j8k9l (Max   2025-10-10)     name: nginx
```

**Use case:** "Кто добавил эту странную строку? Почему?"

### 5. `git stash` — Temporary storage

```bash
# Спрятать uncommitted changes
git stash

# Work on something else...
git checkout main
# ... make changes ...

# Return stashed changes
git stash pop
```

**Метафора:** Drawer для незаконченных работ. Спрячь сейчас, достань потом.

### 6. `git cherry-pick` — Copy commit to другой branch

```bash
# Copy specific commit from feature to main
git checkout main
git cherry-pick a1b2c3d

# Commit a1b2c3d теперь в main (но не весь feature branch)
```

**Use case:** "Нужен только этот один commit, не весь branch."

### 7. `git rebase` — Rewrite history (advanced!)

```bash
# Вместо merge, перебазировать feature на main
git checkout feature
git rebase main

# История становится линейной (no merge commits)
```

**⚠️ WARNING:** Rebase переписывает историю! Только для локальных branches!

---

### 💻 Практика 14: Git Advanced Commands

**Задачи:**

```bash
cd ~/operation-shadow-infrastructure

# 1. Visualize history
git log --graph --oneline --all --decorate

# 2. Find who changed .gitignore
git blame .gitignore

# 3. Search commits containing "password"
git log -S "password" --oneline

# 4. Show commits by Max
git log --author="Max" --oneline

# 5. Commits in last 24 hours
git log --since="1 day ago"

# 6. Show file changes in commit
git show a1b2c3d

# 7. Compare two branches
git diff main..development

# 8. List files changed in commit
git diff-tree --no-commit-id --name-only -r a1b2c3d

# 9. Count commits per author
git shortlog -sn

# 10. Repository statistics
echo "Total commits: $(git rev-list --count HEAD)"
echo "Total branches: $(git branch | wc -l)"
echo "Repository size: $(du -sh .git | cut -f1)"
```

**Hans:**
> *"Эти команды — ваш инструментарий профессионала. Debugging, forensics, analysis. Git — это не только add/commit. Это мощная база данных с полной историей проекта."*

---

### 🤔 Проверка понимания: Цикл 7

**Вопрос:** Когда использовать `git reflog`?

<details>
<summary>Думай перед проверкой</summary>

**Ответ:** Когда случайно удалил commit или branch.

**Scenarios:**
- `git reset --hard` слишком далеко назад → потерял commits
- Удалил branch (`git branch -D`) → но нужен commit оттуда
- Ошибочный merge → хочешь вернуться

`git reflog` показывает ВСЕ действия (даже удалённые commits).

**Recovery:**
```bash
git reflog           # Find deleted commit hash
git reset --hard <hash>  # Restore
```

**LILITH:** *"`git reflog` — это чёрный ящик самолёта. Когда всё рухнуло, он покажет что произошло. И как вернуться."*

</details>

**Hans (финальная речь):**
> *"6 часов. От нуля до Git профессионала. Вы прошли crash course. В CCC обучение занимает недели. Но emergency — лучший учитель."*

**Max:**
> *"Понял почему Git критичен. Это не просто version control. Это фундамент DevOps."*

**Dmitry:**
> *"Спасибо, Hans. Теперь мы готовы к Docker, CI/CD, Ansible."*

**Hans:**
> *"Gut. Завтра летите в Амстердам. Sophie van Dijk научит вас Docker. А я помогу с CI/CD удалённо. До встречи в pipeline."*

**LILITH:**
> *"Episode 13 complete. Git освоен. Secrets защищены. Infrastructure as Code настроен. Welcome to DevOps, Max. Дальше будет сложнее."*

---

## 🏆 Финальная проверка

**После завершения всех 7 циклов у вас должно быть:**

✅ Git repository инициализирован
✅ Структура Infrastructure as Code (ansible/, docker/, terraform/, scripts/, docs/)
✅ `.gitignore` настроен (secrets защищены)
✅ Branching strategy документирована
✅ 15+ коммитов с правильными сообщениями (Conventional Commits)
✅ Merge conflicts понятны и разрешены
✅ Secrets management настроен (.env.example + docs)
✅ INCIDENT resolved (leaked secret cleanup)
✅ Git advanced commands освоены (log, reflog, blame, bisect)

**Запустите тест:**
```bash
cd ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control
./tests/test.sh
```

---

## 📖 Команды Git: Справочник

<details>
<summary><strong>🔹 Основные команды</strong></summary>

**Repository** — это папка + скрытая папка `.git` с историей всех изменений.

```bash
# Инициализировать новый репозиторий
git init

# Или клонировать существующий
git clone https://github.com/user/repo.git

# Проверить статус
git status
```

**Три зоны Git:**
1. **Working Directory** — твои файлы (редактируешь здесь)
2. **Staging Area (Index)** — подготовка к commit (`git add`)
3. **Repository (.git)** — история commits (`git commit`)

```
Working Directory  →  Staging Area  →  Repository
     (edit)         git add             git commit
                                            ↓
                                       git push → Remote
```

</details>

<details>
<summary><strong>📖 2. Basic commands</strong></summary>

```bash
# 1. Добавить файлы в Staging Area
git add file.txt           # Один файл
git add configs/           # Вся папка
git add .                  # Всё (осторожно! используй .gitignore)

# 2. Commit (сохранить snapshot)
git commit -m "Add server configs"

# Лучше: multi-line commit message
git commit
# Откроется редактор:
# Subject line (50 chars max): Add server configs for operation
#
# Body (wrap at 72 chars):
# - Added nginx.conf for web servers
# - Added postgresql.conf for database
# - Configured firewall rules

# 3. Проверить историю
git log                    # Полная история
git log --oneline          # Краткая (1 commit = 1 line)
git log --graph --all      # Визуализация branches

# 4. Проверить изменения
git diff                   # Working Directory vs Staging
git diff --staged          # Staging vs последний commit
git diff HEAD~1            # Текущая vs предыдущая версия

# 5. Отменить изменения
git checkout -- file.txt   # Отменить изменения в файле (Working Dir)
git reset file.txt         # Убрать из Staging (но изменения остаются)
git reset --hard HEAD      # ОПАСНО: отменить все изменения (необратимо)
```

**Best practice: Commit messages**

❌ Плохо:
```
git commit -m "fix"
git commit -m "update config"
git commit -m "stuff"
```

✅ Хорошо (Conventional Commits):
```
git commit -m "feat: add nginx load balancing config"
git commit -m "fix: correct firewall rule for port 8080"
git commit -m "docs: update README with deployment instructions"
git commit -m "refactor: simplify ansible playbook structure"
```

**Format:**
```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

**Types:**
- `feat`: new feature
- `fix`: bug fix
- `docs`: documentation
- `style`: formatting (не меняет код)
- `refactor`: code refactoring
- `test`: adding tests
- `chore`: maintenance

</details>

<details>
<summary><strong>📖 3. Branches</strong></summary>

**Branch** — это независимая линия разработки.

**Зачем branches?**
- Параллельная разработка features
- Изоляция экспериментов
- Code review перед merge в main
- Откат без затрагивания main branch

```bash
# Посмотреть branches
git branch                 # Локальные
git branch -a              # Все (включая remote)

# Создать branch
git branch feature-ansible
git checkout feature-ansible    # Переключиться на branch

# Или короче (create + switch):
git checkout -b feature-ansible

# Работать в branch:
# ... edit files ...
git add .
git commit -m "feat: add ansible playbook"

# Переключиться обратно на main
git checkout main

# Merge branch в main
git merge feature-ansible

# Удалить branch (после merge)
git branch -d feature-ansible
```

**Branching strategies:**

**1. Feature Branch Workflow:**
```
main (production-ready)
 ├── feature-docker (Max работает)
 ├── feature-ansible (Dmitry работает)
 └── hotfix-password-leak (urgent fix)
```

**2. GitFlow:**
```
main (production releases)
 └── develop (integration branch)
      ├── feature/docker
      ├── feature/ansible
      └── release/1.0
```

**3. Trunk-Based Development:**
```
main (single branch, short-lived feature branches)
 ├── feature (< 2 days, quick merge)
 └── feature2 (< 2 days, quick merge)
```

**Для KERNEL SHADOWS операции:**
- `main` — production configs
- `development` — testing configs
- `feature/episodeXX` — новые features
- `hotfix/security` — urgent fixes

</details>

<details>
<summary><strong>📖 4. Merge conflicts</strong></summary>

**Merge conflict** — когда два branches изменили одну и ту же строку файла.

**Пример:**

**Branch A:**
```nginx
server {
    listen 80;           # Changed by Max
}
```

**Branch B:**
```nginx
server {
    listen 8080;         # Changed by Dmitry
}
```

**Git merge result:**
```nginx
server {
<<<<<<< HEAD
    listen 80;           # Your version (Max)
=======
    listen 8080;         # Their version (Dmitry)
>>>>>>> feature-branch
}
```

**Разрешение:**
```bash
# 1. Открыть файл, manually resolve:
server {
    listen 80;           # Выбрали версию Max (или 8080, или обе)
}

# 2. Удалить markers (<<<<<<<, =======, >>>>>>>)

# 3. Commit resolution:
git add file
git commit -m "fix: resolve merge conflict (chose port 80)"
```

**Инструменты для разрешения конфликтов:**
- `git mergetool` — визуальный diff
- VS Code, IntelliJ — встроенные редакторы слияния
- `vimdiff`, `meld` — консольные инструменты

</details>

<details>
<summary><strong>📖 5. .gitignore</strong></summary>

**`.gitignore`** — файл, который говорит Git **игнорировать** определённые файлы.

**Зачем?**
- ❌ Не коммитить secrets (.env, passwords, keys)
- ❌ Не коммитить временные файлы (логи, кеш, артефакты сборки)
- ❌ Не коммитить OS junk (.DS_Store, Thumbs.db)

**Пример `.gitignore` для infrastructure:**

```gitignore
# Secrets (НИКОГДА НЕ КОММИТИТЬ!)
.env
.env.local
.env.production
*.pem
*.key
*_rsa
*_rsa.pub
passwords.txt
secrets.yml
credentials.json

# Ansible
*.retry
.vault_pass
.vault_password

# Terraform
*.tfstate
*.tfstate.backup
.terraform/

# Logs
*.log
logs/
*.log.*

# OS files
.DS_Store
Thumbs.db
desktop.ini

# Temporary files
*.tmp
*.swp
*.swo
*~
.cache/

# Backup files
*.bak
*.backup
*.old

# IDE
.vscode/
.idea/
*.sublime-*
```

**Best practices:**
1. Create `.gitignore` **первым делом** при `git init`
2. Use templates: https://github.com/github/gitignore
3. Never commit secrets (даже на 1 секунду!)
4. If leaked: `git filter-branch` to remove from history

</details>

<details>
<summary><strong>📖 6. Remote repositories</strong></summary>

**Remote** — это Git repository на другом сервере (GitHub, GitLab, Bitbucket, self-hosted).

```bash
# Добавить remote
git remote add origin https://github.com/user/repo.git

# Проверить remotes
git remote -v

# Push (отправить commits на remote)
git push origin main

# Pull (получить commits с remote)
git pull origin main

# Fetch (получить commits, но не merge)
git fetch origin
git merge origin/main
```

**GitHub/GitLab workflow:**
```
Local repo  →  git push  →  GitHub/GitLab  →  git pull  →  Other team members
```

**SSH vs HTTPS:**

**HTTPS:**
```bash
git clone https://github.com/user/repo.git
# Требует username/password (или token)
```

**SSH (recommended):**
```bash
git clone git@github.com:user/repo.git
# Требует SSH key (более безопасно)

# Setup SSH key:
ssh-keygen -t ed25519 -C "max@operation-shadow.net"
cat ~/.ssh/id_ed25519.pub   # Copy to GitHub/GitLab
```

</details>

<details>
<summary><strong>📖 7. Secrets management</strong></summary>

**Проблема:** Как хранить secrets (пароли, API keys) если Git repository public?

**Solutions:**

**1. `.env` files + `.gitignore` (простое):**
```bash
# Commit .env.example (template) — OK
echo "DB_PASSWORD=your_password_here" > .env.example
git add .env.example

# Actual .env — в .gitignore (NOT committed)
echo "DB_PASSWORD=SuperSecret123!" > .env
echo ".env" >> .gitignore
git add .gitignore
```

**2. git-crypt (encryption):**
```bash
# Encrypt files in repo
sudo apt install git-crypt
git-crypt init
git-crypt add-gpg-user max@operation-shadow.net

# .gitattributes:
secrets.yml filter=git-crypt diff=git-crypt
*.key filter=git-crypt diff=git-crypt

git add .gitattributes secrets.yml
git commit -m "Add encrypted secrets"
```

**3. HashiCorp Vault (production):**
```bash
# Store secrets in Vault, reference in code
DB_PASSWORD=$(vault kv get -field=password secret/database)
```

**4. Environment variables (CI/CD):**
```yaml
# GitHub Actions secrets
- name: Deploy
  env:
    DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

**If leaked:**
```bash
# 1. Rotate secret immediately (change password!)
# 2. Remove from Git history:
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch secrets.txt" \
  --prune-empty --tag-name-filter cat -- --all

# Or use BFG Repo-Cleaner (faster):
bfg --delete-files secrets.txt
git push --force --all
```

</details>

<details>
<summary><strong>📖 8. Git for Infrastructure as Code</strong></summary>

**Infrastructure as Code (IaC):**
- Серверы описываются кодом (Ansible, Terraform)
- Конфиги версионируются в Git
- Changes через Git workflow (branch → review → merge)
- Rollback = git revert

**Структура репозитория:**
```
operation-shadow-infrastructure/
├── ansible/
│   ├── playbooks/
│   │   ├── webservers.yml
│   │   ├── databases.yml
│   │   └── monitoring.yml
│   ├── roles/
│   │   ├── nginx/
│   │   ├── postgresql/
│   │   └── prometheus/
│   └── inventory/
│       ├── production
│       ├── staging
│       └── development
├── docker/
│   ├── web/
│   │   ├── Dockerfile
│   │   └── docker-compose.yml
│   └── api/
│       ├── Dockerfile
│       └── docker-compose.yml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── scripts/
│   ├── deploy.sh
│   ├── backup.sh
│   └── monitor.sh
├── docs/
│   ├── README.md
│   ├── DEPLOYMENT.md
│   └── TROUBLESHOOTING.md
├── .gitignore
├── .gitlab-ci.yml        # CI/CD pipeline
└── README.md
```

**Workflow:**
```
1. Developer creates branch: git checkout -b feature-ansible
2. Makes changes: edit ansible/playbooks/webservers.yml
3. Commits: git commit -m "feat: add nginx load balancing"
4. Pushes: git push origin feature-ansible
5. Creates Pull Request/Merge Request
6. Code review by team
7. CI/CD runs tests
8. Merge to main
9. Automated deployment to production
```

**Benefits:**
- ✅ Version control для всей инфраструктуры
- ✅ Процесс code review
- ✅ Audit trail (кто что изменил)
- ✅ Простой откат (git revert)
- ✅ Совместная работа (несколько инженеров)
- ✅ Интеграция с CI/CD

</details>

---

## 💻 Практика: 9 заданий

### Задание 1: Initialize Git repository

**Миссия:** Создать Git repository для конфигов операции.

**Задача:**
```bash
# 1. Создать папку для infrastructure
mkdir -p ~/operation-shadow-infrastructure
cd ~/operation-shadow-infrastructure

# 2. Инициализировать Git
git init

# 3. Configure Git (если еще не настроен)
git config user.name "Max Sokolov"
git config user.email "max@operation-shadow.net"

# 4. Проверить статус
git status
```

**Expected output:**
```
Initialized empty Git repository in .git/
On branch main
No commits yet
```

<details>
<summary>💡 Hint 1: Git configuration (если застряли > 5 минут)</summary>

Git нужно знать кто ты (для информации об авторе коммита).

```bash
# Глобально (для всех репозиториев):
git config --global user.name "Your Name"
git config --global user.email "your@email.com"

# Или только для этого репозитория:
git config user.name "Max Sokolov"
git config user.email "max@operation-shadow.net"
```

Проверить:
```bash
git config user.name
git config user.email
```

</details>

<details>
<summary>💡 Hint 2: Common issues (если застряли > 10 минут)</summary>

**Problem:** "fatal: not a git repository"
**Solution:** Убедись что выполнил `git init` в правильной папке.

**Problem:** "Author identity unknown"
**Solution:** Настрой `git config user.name` и `user.email`.

**Problem:** `.git` папка не видна
**Solution:** Это нормально! `.git` скрытая. Проверить: `ls -la | grep .git`

</details>

<details>
<summary>✅ Solution (если застряли > 15 минут)</summary>

```bash
#!/bin/bash

# Create directory structure
mkdir -p ~/operation-shadow-infrastructure
cd ~/operation-shadow-infrastructure

# Initialize Git repository
git init

# Configure Git (if not configured globally)
git config user.name "Max Sokolov"
git config user.email "max@operation-shadow.net"

# Verify
echo "Git initialized!"
git status
```

**Explanation:**
- `git init` создаёт скрытую папку `.git` с метаданными
- `git config` настраивает информацию об авторе для коммитов
- `git status` показывает текущее состояние репозитория

</details>

---

### Задание 2: Create directory structure

**Миссия:** Создать организованную структуру папок для infrastructure code.

**Задача:**
```bash
# В ~/operation-shadow-infrastructure/ создать:
mkdir -p ansible/{playbooks,roles,inventory}
mkdir -p docker/{web,api,database}
mkdir -p terraform
mkdir -p scripts
mkdir -p docs

# Создать README файлы
echo "# Operation Shadow Infrastructure" > README.md
echo "# Documentation" > docs/README.md
echo "# Ansible Playbooks" > ansible/README.md
echo "# Docker Containers" > docker/README.md

# Проверить структуру
tree -L 2  # или ls -R если tree нет
```

**Expected structure:**
```
operation-shadow-infrastructure/
├── ansible/
│   ├── playbooks/
│   ├── roles/
│   ├── inventory/
│   └── README.md
├── docker/
│   ├── web/
│   ├── api/
│   ├── database/
│   └── README.md
├── terraform/
├── scripts/
├── docs/
│   └── README.md
└── README.md
```

<details>
<summary>💡 Hint: Commit structure</summary>

После создания структуры — commit!

```bash
git add .
git commit -m "chore: initialize infrastructure directory structure"
git log --oneline
```

</details>

---

### Задание 3: Create .gitignore

**Миссия:** Защитить репозиторий от случайного коммита секретов и временных файлов.

**Задача:**
```bash
# Создать .gitignore в корне repo
cat > .gitignore << 'EOF'
# Secrets (NEVER commit!)
.env
.env.local
.env.production
*.pem
*.key
*_rsa
*_rsa.pub
passwords.txt
secrets.yml
credentials.json
vault_password.txt

# Ansible
*.retry
.vault_pass

# Terraform
*.tfstate
*.tfstate.backup
.terraform/
terraform.tfvars

# Logs
*.log
logs/

# OS files
.DS_Store
Thumbs.db

# Temporary
*.tmp
*.swp
*~
.cache/
EOF

# Commit .gitignore
git add .gitignore
git commit -m "chore: add .gitignore for secrets and temp files"
```

**Test:**
```bash
# Try to create a secret file
echo "PASSWORD=SuperSecret123" > .env
git status   # Should show ".env" as untracked BUT ignored

# Verify .env is ignored
git add .env   # Should fail or warn: "The following paths are ignored by one of your .gitignore files"
```

<details>
<summary>💡 Hint: .gitignore patterns</summary>

**Patterns:**
- `*.log` — все файлы, заканчивающиеся на .log
- `logs/` — вся папка logs/
- `!important.log` — exception (do NOT ignore important.log)
- `**/secrets.txt` — secrets.txt в любой папке (recursive)

**Check if file is ignored:**
```bash
git check-ignore -v .env
# Output: .gitignore:2:.env    .env
```

</details>

---

### Задание 4: Branching strategy

**Миссия:** Настроить branching strategy для команды (Max, Dmitry, Alex, Anna).

**Задача:**
```bash
# 1. Create development branch
git checkout -b development

# 2. Create feature branches
git checkout -b feature/episode13-git
git checkout -b feature/episode14-docker
git checkout -b feature/episode15-cicd
git checkout -b feature/episode16-ansible

# 3. Switch back to main
git checkout main

# 4. List all branches
git branch -a

# 5. Create BRANCHING_STRATEGY.md documentation
cat > docs/BRANCHING_STRATEGY.md << 'EOF'
# Branching Strategy for Operation Shadow

## Branches

- **main** — production-ready infrastructure
- **development** — integration branch for testing
- **feature/episodeXX-name** — feature branches (short-lived)
- **hotfix/description** — urgent fixes

## Workflow

1. Create feature branch from `development`:
   ```
   git checkout development
   git checkout -b feature/new-feature
   ```

2. Make changes and commit:
   ```
   git add .
   git commit -m "feat: add new feature"
   ```

3. Merge to development:
   ```
   git checkout development
   git merge feature/new-feature
   ```

4. When ready for production, merge development → main:
   ```
   git checkout main
   git merge development
   ```

## Commit Message Convention

Use **Conventional Commits**:
- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation
- `chore:` — maintenance

Example: `feat: add ansible playbook for nginx`
EOF

# Commit branching docs
git add docs/BRANCHING_STRATEGY.md
git commit -m "docs: add branching strategy documentation"
```

<details>
<summary>💡 Hint: Branch naming</summary>

**Good branch names:**
- `feature/ansible-webservers`
- `fix/nginx-config-typo`
- `hotfix/password-leak`
- `docs/update-readme`

**Bad branch names:**
- `test`
- `my-branch`
- `branch1`
- `asdfgh`

</details>

---

### Задание 5: Commits with proper messages

**Миссия:** Practice proper commit messages (Conventional Commits).

**Задача:**
```bash
# 1. Create sample config files
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
EOF

cat > docker/web/Dockerfile << 'EOF'
FROM nginx:alpine
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOF

# 2. Add and commit with proper message
git add ansible/playbooks/webservers.yml
git commit -m "feat: add ansible playbook for nginx webservers"

git add docker/web/Dockerfile
git commit -m "feat: add nginx Dockerfile for web containers"

# 3. View commit history
git log --oneline
git log --graph --all --oneline
```

**Expected log:**
```
a1b2c3d (HEAD -> main) feat: add nginx Dockerfile for web containers
e4f5g6h feat: add ansible playbook for nginx webservers
i7j8k9l docs: add branching strategy documentation
m0n1o2p chore: add .gitignore for secrets and temp files
q3r4s5t chore: initialize infrastructure directory structure
```

<details>
<summary>💡 Hint: Multi-line commit messages</summary>

Для подробных сообщений коммита (рекомендуется):

```bash
git commit
# Откроется редактор (vim/nano):

feat: add ansible playbook for nginx webservers

- Configured nginx with SSL/TLS
- Added load balancing for 5 backend servers
- Enabled HTTP/2 support
- Configured logging to /var/log/nginx/

Related: Episode 13 (Git basics)
```

**Format:**
- Line 1: Subject (50 chars max)
- Line 2: Blank
- Line 3+: Body (wrap at 72 chars)

</details>

---

### Задание 6: Simulate merge conflict

**Миссия:** Создать merge conflict и научиться его разрешать.

**Scenario:** Max и Dmitry одновременно правят один и тот же файл.

**Задача:**
```bash
# 1. Max creates branch and changes nginx port
git checkout -b max-nginx-fix
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Configure nginx port
      lineinfile:
        path: /etc/nginx/nginx.conf
        regexp: 'listen'
        line: '    listen 80;'   # Max chose port 80
EOF
git add ansible/playbooks/webservers.yml
git commit -m "fix: configure nginx to listen on port 80"

# 2. Switch to main, simulate Dmitry's changes
git checkout main
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Configure nginx port
      lineinfile:
        path: /etc/nginx/nginx.conf
        regexp: 'listen'
        line: '    listen 8080;'   # Dmitry chose port 8080
EOF
git add ansible/playbooks/webservers.yml
git commit -m "fix: configure nginx to listen on port 8080"

# 3. Try to merge Max's branch
git merge max-nginx-fix
# ⚠️ CONFLICT!
```

**Expected output:**
```
Auto-merging ansible/playbooks/webservers.yml
CONFLICT (content): Merge conflict in ansible/playbooks/webservers.yml
Automatic merge failed; fix conflicts and then commit the result.
```

**Resolution:**
```bash
# 1. Open conflicted file
cat ansible/playbooks/webservers.yml
# You'll see:
# <<<<<<< HEAD
#     listen 8080;   # Dmitry's version
# =======
#     listen 80;     # Max's version
# >>>>>>> max-nginx-fix

# 2. Edit file manually, choose one version (or combine)
# Let's say we decide: port 80 for production
cat > ansible/playbooks/webservers.yml << 'EOF'
---
- hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Configure nginx port
      lineinfile:
        path: /etc/nginx/nginx.conf
        regexp: 'listen'
        line: '    listen 80;'   # Resolved: chose port 80
EOF

# 3. Mark as resolved and commit
git add ansible/playbooks/webservers.yml
git commit -m "fix: resolve merge conflict (chose port 80 for production)"

# 4. Verify
git log --oneline --graph --all
```

<details>
<summary>💡 Hint: Merge conflict markers</summary>

```
<<<<<<< HEAD
Your current branch changes
=======
Incoming branch changes
>>>>>>> branch-name
```

**Steps:**
1. Find markers (`<<<<<<<`, `=======`, `>>>>>>>`)
2. Choose version (yours, theirs, or both)
3. Delete markers
4. `git add` resolved file
5. `git commit` to complete merge

</details>

---

### Задание 7: Secrets management

**Миссия:** Настроить безопасное хранение secrets (passwords, API keys).

**Задача:**
```bash
# 1. Create .env.example (template — OK to commit)
cat > .env.example << 'EOF'
# Database credentials
DB_HOST=localhost
DB_PORT=5432
DB_NAME=operation_shadow
DB_USER=your_username_here
DB_PASSWORD=your_password_here

# API keys
GITHUB_TOKEN=your_github_token_here
AWS_ACCESS_KEY=your_aws_key_here
EOF

# 2. Create actual .env with real secrets (NOT committed due to .gitignore)
cat > .env << 'EOF'
DB_HOST=10.20.30.40
DB_PORT=5432
DB_NAME=operation_shadow
DB_USER=max_sokolov
DB_PASSWORD=SuperSecret123!

GITHUB_TOKEN=ghp_abc123def456
AWS_ACCESS_KEY=AKIAIOSFODNN7EXAMPLE
EOF

# 3. Verify .env is ignored
git status   # .env should NOT appear (because of .gitignore)

# 4. Commit .env.example
git add .env.example
git commit -m "chore: add .env.example template for secrets"

# 5. Create docs/SECRETS_MANAGEMENT.md
cat > docs/SECRETS_MANAGEMENT.md << 'EOF'
# Secrets Management

## ⚠️ NEVER commit secrets to Git!

### Files that MUST be in .gitignore:
- `.env`
- `*.pem`, `*.key`
- `passwords.txt`
- `credentials.json`

### Safe practices:

1. **Use .env files:**
   - Commit `.env.example` (template)
   - Actual `.env` in `.gitignore`

2. **For production:**
   - Use HashiCorp Vault
   - Use GitHub Secrets (for CI/CD)
   - Use AWS Secrets Manager

3. **If leaked:**
   - Rotate secret immediately!
   - Remove from Git history:
     ```
     git filter-branch --force --index-filter \
       "git rm --cached --ignore-unmatch .env" \
       --prune-empty -- --all
     ```

## Current secrets locations:
- Database credentials: `.env` (local only)
- SSH keys: `~/.ssh/` (NOT in repo)
- Ansible vault: `ansible/.vault_pass` (in .gitignore)
EOF

git add docs/SECRETS_MANAGEMENT.md
git commit -m "docs: add secrets management guidelines"
```

<details>
<summary>💡 Hint: Ansible Vault (bonus)</summary>

Ansible has built-in encryption:

```bash
# Create encrypted file
ansible-vault create ansible/secrets.yml
# Enter password: ****

# Edit encrypted file
ansible-vault edit ansible/secrets.yml

# Use in playbook:
ansible-playbook playbook.yml --ask-vault-pass
```

</details>

---

### Задание 8: INCIDENT — Find and remove leaked secret

**‼️ EMERGENCY SCENARIO ‼️**

**Anna (звонок, 21:30):**
> *"Max! Кто-то закоммитил пароль в Git! Public repo! Krylov может уже знать! У нас 10 минут!"*

**Leaked file:**
```bash
# Simulate: someone committed secrets.txt
cat > secrets.txt << 'EOF'
# Production Database Password
DB_PASSWORD=ProdSecret2024!
DB_HOST=10.20.30.40

# Viktor SSH key
SSH_KEY=-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...
EOF

git add secrets.txt
git commit -m "Add production secrets" # ❌ MISTAKE!
git log --oneline   # secret is in history!
```

**Tasks:**

1. **Find the leaked secret in Git history:**
```bash
# Search Git history for "password"
git log --all --full-history -- secrets.txt
git log -S "DB_PASSWORD" --all
```

2. **Remove from Git history (⚠️ DANGEROUS operation):**

**Option A: BFG Repo-Cleaner (recommended, faster):**
```bash
# Install BFG
sudo apt install bfg   # or download from https://rtyley.github.io/bfg-repo-cleaner/

# Remove file from all history
bfg --delete-files secrets.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Option B: git filter-branch (slower but built-in):**
```bash
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch secrets.txt" \
  --prune-empty --tag-name-filter cat -- --all

git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

3. **Force push (if already pushed to remote):**
```bash
# ⚠️ WARNING: Force push rewrites history! Notify team!
git push --force --all
```

4. **Rotate password IMMEDIATELY:**
```bash
# In real scenario: change password in database NOW!
echo "Password rotated: ProdSecret2024_NEW!" >> rotation_log.txt
```

5. **Add to .gitignore (prevent future leaks):**
```bash
echo "secrets.txt" >> .gitignore
git add .gitignore
git commit -m "fix: add secrets.txt to .gitignore after leak incident"
```

6. **Audit: Who committed?**
```bash
git log --all --oneline | grep "Add production secrets"
# Output: a1b2c3d Add production secrets
git show a1b2c3d   # See who, when, what
```

**Hans (после incident):**
> *"Вот почему `.gitignore` сначала, commit потом. НИКОГДА наоборот. Усвоили урок?"*

<details>
<summary>💡 Hint: git reflog (если удалил лишнее)</summary>

If you accidentally deleted wrong commits:

```bash
# View reflog (history of HEAD movements)
git reflog

# Restore:
git reset --hard HEAD@{N}   # N = number from reflog
```

But если уже `git push --force` — too late!

</details>

---

### Задание 9: Git Advanced Commands Mastery

**Миссия:** Практика с advanced Git commands для анализа repository.

**Задачи:**

#### 1. Repository Analysis

```bash
cd ~/operation-shadow-infrastructure

# Repository stats
echo "=== REPOSITORY STATISTICS ==="
echo "Total commits: $(git rev-list --count HEAD)"
echo "Total branches: $(git branch -a | wc -l)"
echo "Repository size: $(du -sh .git | cut -f1)"
echo "First commit: $(git log --reverse --oneline | head -1)"
echo "Latest commit: $(git log --oneline | head -1)"
```

#### 2. History Visualization

```bash
# Beautiful branch graph
git log --graph --oneline --all --decorate

# Last 20 commits with dates and authors
git log --oneline --date=short --pretty=format:"%h %ad %an: %s" -20
```

#### 3. Contributor Analysis

```bash
# Who contributed most?
git shortlog -sn

# Commits by specific author
git log --author="Max Sokolov" --oneline

# Commits in last week
git log --since="1 week ago" --oneline
```

#### 4. File History Forensics

```bash
# Who changed .gitignore?
git blame .gitignore

# History of specific file
git log --follow -- ansible/playbooks/webservers.yml

# Show changes in specific commit
git show a1b2c3d
```

#### 5. Security Audit

```bash
# Search for potential secrets in history
echo "=== SECURITY AUDIT ==="

# Check for 'password' in commits
if git log --all -S "password" --oneline | head -1 | grep -q .; then
    echo "⚠️ WARNING: Found 'password' in history!"
    git log --all -S "password" --oneline | head -5
else
    echo "✅ No 'password' in commit history"
fi

# Check for 'api_key'
if git log --all -S "api_key" --oneline | head -1 | grep -q .; then
    echo "⚠️ WARNING: Found 'api_key' in history!"
else
    echo "✅ No 'api_key' in history"
fi

# Verify .gitignore exists
if [ -f .gitignore ]; then
    echo "✅ .gitignore exists ($(wc -l < .gitignore) lines)"
else
    echo "❌ ERROR: .gitignore missing!"
fi
```

#### 6. Advanced: git reflog practice

```bash
# View ALL actions (even deleted commits)
git reflog

# Simulate: accidentally delete commit
git reset --hard HEAD~1  # Delete last commit

# Oops! Restore it:
git reflog  # Find deleted commit
git reset --hard HEAD@{1}  # Restore
```

#### 7. Advanced: git bisect demo

```bash
# If you had a bug, find which commit introduced it:
# git bisect start
# git bisect bad         # Current commit has bug
# git bisect good v1.0   # Old commit was good
# ... test each commit ...
# git bisect reset
```

**Hans:**
> *"Эти команды — ваш инструментарий профессионала. Используйте их ежедневно. Git — не только add/commit. Это forensics tool."*

<details>
<summary>💡 Hint: Полезные Git aliases</summary>

Добавь в `~/.gitconfig`:

```gitconfig
[alias]
    # Pretty log
    lg = log --graph --oneline --all --decorate

    # Show branches
    br = branch -a

    # Short status
    st = status -s

    # Last commit
    last = log -1 HEAD

    # Contributors
    contributors = shortlog -sn

    # Unstage
    unstage = reset HEAD --
```

Использование:
```bash
git lg          # instead of git log --graph...
git contributors
git last
```

</details>

---

## 🏆 Финальная проверка

**После выполнения всех 9 заданий у вас должно быть:**

✅ Git repository инициализирован
✅ Структура папок (ansible/, docker/, terraform/, scripts/, docs/)
✅ `.gitignore` настроен (secrets защищены)
✅ Branching strategy документирована
✅ 10+ коммитов с правильными сообщениями
✅ Merge conflict разрешён
✅ Secrets management настроен (.env.example)
✅ Leaked secret найден и удалён из истории
✅ Git advanced commands практика (reflog, bisect, blame)

**Запустите тест:**
```bash
cd ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control
./tests/test.sh
```

---

## 📖 Команды Git: Справочник

<details>
<summary><strong>🔹 Основные команды</strong></summary>

```bash
# Initialization
git init                    # Create new repo
git clone <url>             # Clone existing repo

# Status & Info
git status                  # Show working tree status
git log                     # Show commit history
git log --oneline           # Compact log
git log --graph --all       # Visual branch graph
git diff                    # Show changes

# Staging & Committing
git add <file>              # Stage file
git add .                   # Stage all changes
git commit -m "message"     # Commit with message
git commit                  # Commit with editor

# Branching
git branch                  # List branches
git branch <name>           # Create branch
git checkout <branch>       # Switch branch
git checkout -b <branch>    # Create + switch
git merge <branch>          # Merge branch
git branch -d <branch>      # Delete branch

# Remote
git remote add origin <url> # Add remote
git push origin <branch>    # Push to remote
git pull origin <branch>    # Pull from remote
git fetch                   # Fetch without merge

# Undo changes
git checkout -- <file>      # Discard changes in file
git reset <file>            # Unstage file
git reset --hard HEAD       # Discard all changes (dangerous!)
git revert <commit>         # Revert commit (safe)

# History manipulation (dangerous!)
git reset --hard <commit>   # Reset to commit (lose changes)
git filter-branch ...       # Rewrite history
```

</details>

<details>
<summary><strong>🔹 .gitignore patterns</strong></summary>

```gitignore
# Ignore specific file
secrets.txt

# Ignore all .log files
*.log

# Ignore directory
logs/

# Ignore in any subdirectory
**/secrets.txt

# Exception (do NOT ignore)
!important.log

# Comments
# This is a comment
```

</details>

<details>
<summary><strong>🔹 Conventional Commits</strong></summary>

```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

**Types:**
- `feat:` — new feature
- `fix:` — bug fix
- `docs:` — documentation
- `style:` — formatting
- `refactor:` — code refactoring
- `test:` — tests
- `chore:` — maintenance

**Examples:**
```
feat: add ansible playbook for nginx
fix: correct firewall rule for port 8080
docs: update README with deployment steps
```

</details>

---

## 🧪 Тестирование

Автоматические тесты проверят:

1. ✅ Git repository инициализирован
2. ✅ Directory structure создана
3. ✅ `.gitignore` существует и содержит secrets patterns
4. ✅ Минимум 10 commits
5. ✅ Минимум 3 branches
6. ✅ Conventional Commits формат
7. ✅ Secrets НЕ committed
8. ✅ Audit report сгенерирован

**Запуск тестов:**
```bash
cd ~/kernel-shadows/season-04-devops-automation/episode-13-git-version-control
./tests/test.sh
```

---

## 💬 Цитаты Episode 13

**Hans Müller:**
> "В Chaos Computer Club у нас три правила: 1) Hack the planet. 2) Share the knowledge. 3) Version control everything. Git — это не опция. Git — это жизнь."

**Dmitry:**
> "Макс, в России мы говорим: 'Работает — не трогай.' В DevOps мы говорим: 'Работает — автоматизируй, версионируй, тестируй.' Разница."

**LILITH:**
> "Git history — как русская зима. Суровая, беспощадная, но абсолютно необходимая для выживания. Коммить нужно мудро. Из логов ничего не удалишь."

**Hans (после инцидента с утечкой пароля):**
> "Вот почему `.gitignore` сначала, код потом. НИКОГДА наоборот. Git помнит всё. Даже когда ты хотел бы, чтобы не помнил."

**Max (evolution):**
- Start: "Зачем Git для конфигов? Я и так помню что менял."
- После инцидента: "Понял. Git — это не опция. Это инструмент выживания."

---

## 🎓 Что вы узнали

После Episode 13 вы умеете:

✅ Инициализировать Git repository
✅ Создавать и управлять branches
✅ Писать правильные commit messages (Conventional Commits)
✅ Разрешать merge conflicts
✅ Защищать secrets через `.gitignore`
✅ Находить и удалять leaked secrets из истории
✅ Использовать advanced Git commands (reflog, bisect, blame, stash)
✅ Infrastructure as Code принципы

**Эти навыки будут использоваться в:**
- Episode 14: Docker (Dockerfiles в Git)
- Episode 15: CI/CD (GitHub Actions workflows)
- Episode 16: Ansible (Playbooks в Git)
- Season 5: Security (Code review workflow)

---

## 🚀 Следующий шаг

**Episode 14: Docker Basics** (Amsterdam, Netherlands)

**Sophie van Dijk (видеозвонок в конце Episode 13):**
> *"Max, Dmitry, Hans сказал мне, что вы готовы. Приезжайте в Амстердам завтра. Мы контейнеризируем всё. Docker — это LEGO для инфраструктуры. Простые блоки, сложные системы. Увидимся в Science Park datacenter. — Sophie"*

**Alex (текстовое сообщение):**
> *"Предупреждение о supply chain attack. Docker images легко скомпрометировать. Будь осторожен. — A."*

---

<div align="center">

**Episode 13: Git & Version Control — COMPLETE!**

*"Code is law. Version control is constitution."*

🇩🇪 Berlin • Chaos Computer Club • Infrastructure as Code

[⬅️ Episode 12: Backup & Recovery](../../season-03-system-administration/episode-12-backup-recovery/README.md) | [⬆️ Season 4 Overview](../README.md) | [➡️ Episode 14: Docker Basics](../episode-14-docker-basics/README.md)

</div>


