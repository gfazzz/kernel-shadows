# Season 1: Shell & Foundations

```
ОПЕРАЦИЯ: KERNEL SHADOWS
СЕЗОН: 1 — Shell & Foundations
ЛОКАЦИЯ: 🇷🇺 Новосибирск, Россия (Академгородок)
ДНИ ОПЕРАЦИИ: 1-8 (из 60) — День 1: вербовка в Москве, Дни 2-8: работа из Новосибирска
СТАТУС: v2.0 ✅ Season 1 полностью пересобран в 12 атомарных серий s01e01–12 (все тесты зелёные)
КАЧЕСТВО: 4.75/5 average (историческая оценка старых Episodes 01-04)
```

---

## 📖 О сезоне

**Season 1** — это введение в Ubuntu Linux и работу с терминалом. Вы научитесь базовым командам, навигации, работе с файлами, text processing и package management. **Type B подход:** Linux tools first, bash second.

**Педагогика:** Micro-cycles структура (10-15 мин), CS50-style (метафоры, ASCII диаграммы, "Aha!" моменты), LILITH интегрирована в теорию.

**Главный герой:** Максим "Макс" Соколов — 28 лет, системный администратор из Новосибирска, нанятый Виктором Петровым для критической операции.

**Локация:** 🇷🇺 Новосибирск, Академгородок — научный городок в Сибири. Октябрь 2025. Ранняя осень, +5°C до -5°C, первый снег, тишина.

**Контекст:** Макс работает удалённо из дома (квартира в Академгородке). Домашний home lab: Dell PowerEdge server, несколько Raspberry Pi. Первые задания от Виктора. Встречи с локальными сисадминами в кафе "Под Интегралом".

**Персонажи:**
- **Max Sokolov** — вы, главный герой
- **Viktor Petrov** — заказчик (видеозвонки)
- **LILITH** — AI-помощник, активируется в Episode 01
- **Сергей Иванов** (Episode 02) — локальный ментор по скриптингу, работал в институте ядерной физики, знал отца Макса
- **Ольга Петрова** (Episode 03) — data scientist из Yandex, эксперт по обработке логов
- **Дмитрий Орлов** (Episode 02+) — DevOps engineer, знакомый по Linux User Group (видеозвонки)

**Атмосфера:** Тишина сибирской осени. Гудение домашнего сервера. Кофе и терминал. Окно на желтый лес. Первый снег. Студенческое кафе с плакатами формул. НГУ campus. Unix традиции советской науки.

---

## 📚 Структура сезона

| Episode | Название | Type | Сложность | Время | Качество | Статус |
|---------|----------|------|-----------|-------|----------|--------|
| **01** | Terminal Awakening | B | ⭐☆☆☆☆ | 3-4ч | 4.73/5 | ✅ Refactored |
| **02** | Shell Scripting Basics | A* | ⭐⭐☆☆☆ | 3-4ч | 4.65/5 | ✅ Refactored |
| **03** | Text Processing Masters | B | ⭐⭐☆☆☆ | 3-4ч | 4.77/5 | ✅ Refactored |
| **04** | Package Management | B | ⭐⭐☆☆☆ | 2-2.5ч | 4.85/5 🏆 | ✅ Refactored |

**Общее время:** 11-14 часов
**Type B episodes:** 3/4 (Episodes 01, 03, 04 — Linux tools first)
**Type A justified:** 1/4 (Episode 02 — bash automation для мониторинга)

**Интеграция:** Навыки из каждого эпизода используются в следующих сезонах. Season 8 финал объединяет все навыки курса.

---

## 🆕 v2.0: атомарные серии (новый стандарт)

Рефакторинг v2.0 (см. [`V2.0_UPGRADE_PLAN.md`](../V2.0_UPGRADE_PLAN.md)) дробит тяжёлые
эпизоды на атомарные серии `sNNeNN`: **один концепт — одна задача**, README ≤ 650 строк,
`mission.md` с блоком «Требования среды», единая форма `starter/`, и **воспроизводимый
тест на фикстуре** (зелёный без root, идёт на Linux/macOS/WSL).

**Season 1 полностью пересобран: Episodes 01–04 → 12 атомарных серий ✅**
(старые папки `episode-01…04` сохранены до полной миграции Этапа 1):

| Серия | Из ep | Концепт | Задача (артефакт) | Type | Тест |
|-------|-------|---------|-------------------|------|------|
| [s01e01](s01e01-terminal-awakening/) | 01 | `pwd` — где я в дереве ФС | `whereami.sh` | A | 6/6 |
| [s01e02](s01e02-ls-look-around/) | 01 | `ls` — что вокруг (вкл. скрытое) | `look_around.sh` | A | 7/7 |
| [s01e03](s01e03-cd-cat-navigate/) | 01 | `cd` + `cat`/`less` — дойти и прочитать | `read_briefing.sh` | A | 7/7 |
| [s01e04](s01e04-find-automation/) | 01 | `find` + первый скрипт (капстоун) | `find_files.sh` | A | 8/8 |
| [s01e05](s01e05-variables-ping/) | 02 | переменные + exit code (`$?`) | `check_host.sh` | A | 8/8 |
| [s01e06](s01e06-conditions-loops/) | 02 | условия + циклы (`while read`) | `check_all.sh` | A | 9/9 |
| [s01e07](s01e07-logging-monitor/) | 02 | логирование + капстоун | `server_monitor.sh` | A | 9/9 |
| [s01e08](s01e08-grep-pipes/) | 03 | `grep` + конвейеры | `filter_attack.sh` | A | 7/7 |
| [s01e09](s01e09-awk-stats/) | 03 | `awk` + `sort`/`uniq` (статистика) | `top_attackers.sh` | A | 8/8 |
| [s01e10](s01e10-sed-log-analyzer/) | 03 | `sed` + отчёт (капстоун) | `log_analyzer.sh` | **B** | 10/10 |
| [s01e11](s01e11-apt-dpkg/) | 04 | `apt`/`dpkg` — управление пакетами | `pkg_check.sh` | **B** | 9/9 |
| [s01e12](s01e12-batch-report/) | 04 | `xargs` batch + отчёт (капстоун сезона) | `install_report_generator.sh` | **B** | 10/10 |

**Итого Season 1: 12 серий, 98 проверок — все зелёные без root.** Прогнать всё:
`for d in s01e*/; do bash "$d/tests/test.sh"; done`.

Приёмы воспроизводимости: ep02 сетевые серии мокают `ping`, ep04 — `dpkg` (mock-first §5.3);
ep03 работает на фикстурах-логах. **Закрытые forward-deps: T1 (`awk` — в s01e09, не в ep02)
и T3 (`docker-ce` не ставится заранее — Docker в Season 4).**
**В очереди:** Season 2 «Networking» (Episodes 05–08 → `s02e01+`).

---

## 🎯 Чему вы научитесь

### Episode 01: Terminal Awakening
- ✅ Подключение к серверу через SSH
- ✅ Навигация по файловой системе (`cd`, `pwd`, `ls`)
- ✅ Работа с файлами (`cat`, `less`, `head`, `tail`)
- ✅ Поиск файлов (`find`)
- ✅ Создание простых bash скриптов
- ✅ Понимание структуры Linux filesystem

### Episode 02: Shell Scripting Basics
- ✅ Структура bash скриптов (shebang, комментарии)
- ✅ Переменные в bash (`VAR="value"`, `$VAR`, `${VAR}`)
- ✅ Условия (`if`, `[[ ]]`, операторы сравнения)
- ✅ Циклы (`for`, `while`, `while read`)
- ✅ Функции (`function_name() {}`, `local`, `return`)
- ✅ Exit codes (`$?`, `exit 0/1`)
- ✅ Автоматизация мониторинга серверов

### Episode 03: Text Processing Masters
- ✅ Pipes и redirects (`|`, `>`, `>>`, `<`, `2>`)
- ✅ `grep` для поиска текста (regex, filters)
- ✅ `awk` для обработки колонок (fields, conditions)
- ✅ `sed` для замены текста (stream editing)
- ✅ `cut`, `sort`, `uniq`, `wc` для обработки данных
- ✅ Анализ логов (Apache Combined Log Format)
- ✅ Извлечение IP адресов и User-Agents
- ✅ TOP-N анализ (TOP-10 attackers)

### Episode 04: Package Management (Type B)
- ✅ **APT** (Advanced Package Tool): `apt install`, `apt update`, `apt upgrade`
- ✅ **DPKG** (Debian Package Manager): inspection и low-level контроль
- ✅ **Repositories**: `/etc/apt/sources.list`, добавление сторонних репозиториев
- ✅ **GPG keys**: безопасное добавление репозиториев (Docker example)
- ✅ **Batch operations**: установка списка пакетов через xargs
- ✅ **Verification**: проверка установленных пакетов (dpkg -l, which, --version)
- ✅ **Cleanup**: autoremove, clean, системная гигиена
- ✅ **Report generation**: ONE-LINER для отчёта (minimal bash)
- ✅ **Type B philosophy**: использовать apt/dpkg, не переписывать их в bash


---

## 🎬 Сюжет Season 1

### День 0 (1 октября): Звонок от Alex
Алекс Соколов (двоюродный брат Макса) звонит из Москвы:
> *"Макс, мне нужна твоя помощь. Серьёзное дело. Хорошие деньги. Приезжай в Москву."*

Макс отказывается (работа, дела). Алекс настаивает. Виктор готов платить $50,000 за 2 месяца работы.

### День 1 (2 октября): Встреча в Москве
Красная площадь, 14:00. Макс встречается с Виктором Петровым:
> *"Твой брат сказал, ты лучший сисадмин. Нам нужна инфраструктура. 50 серверов. Защищённые сети. Безопасность на уровне военных стандартов."*

Макс соглашается. $10K авансом. Виктор: *"Начнём с основ. Работай удалённо из Новосибирска. У тебя 24 часа."*

### Episode 01 (день 2): Первое задание
**Локация:** Квартира Max в Академгородке (home lab)

Макс возвращается в Новосибирск. Получает доступ к тестовому серверу Виктора. Задание: найти скрытые файлы с координатами.

LILITH активируется:
> *"Приветствую, Макс. Я LILITH. Твой проводник в тенях. Посмотрим, так ли ты хорош, как говорит Алекс."*

**Атмосфера:** Тишина сибирской осени. Желтые листья за окном, первый снег. Гудение домашнего сервера. Кофе и терминал. Первые шаги в операции.

### Episode 02 (дни 3-4): Автоматизация
**Локация:** Квартира + кафе "Под Интегралом"

Виктор: *"50 серверов нужно мониторить. Скрипты."*

Макс встречается с **Сергеем Ивановым** (52 года, работал в институте ядерной физики, знал отца Макса):
> *"Знал твоего отца. Он тоже любил автоматизацию. Покажу тебе старую школу скриптинга."*

Дмитрий Орлов (видеозвонок): *"Мы не можем проверять 50 серверов вручную. Автоматизация — наша сила."*

Макс создаёт `server_monitor.sh`. Сергей помогает с bash best practices.

**Атмосфера:** Кафе "Под Интегралом", плакаты с формулами, студенты, Wi-Fi. Первый снег за окном. Разговоры о Unix традициях советской науки.

### Episode 03 (дни 5-6): Анализ атаки
**Локация:** Квартира + НГУ campus

Анна Ковалёва (видеозвонок из Москвы):
> *"Нас атаковали вчера в 03:47. Найди IP атакующих в логах. Лог огромный (100MB+)."*

Макс в растерянности. Встреча с **Ольгой Петровой** (29 лет, data scientist из Yandex, эксперт по логам):
> *"10 миллионов строк? Это не много. awk справится за секунду. Смотри."*

Ольга обучает Макса grep/awk/sed. Анализ логов на НГУ campus (лаборатория с Linux серверами).

Найдено: 185.220.101.47 (Tor exit node) + 10 других IP. Первые следы противника.

LILITH: *"Логи не врут. Люди — врут."*

**Атмосфера:** НГУ, научная традиция Unix, белые доски с формулами, старые Sun Microsystems серверы, запах кофе и паяльников.

### Episode 04 (дни 7-8): Инструменты (Type B)
**Локация:** Квартира Max

Виктор: *"Тебе нужны инструменты для операции. Вот список."* (nmap, tcpdump, wireshark, docker, etc.)

Макс начинает устанавливать пакеты вручную через apt. LILITH останавливает:
> *"Стоп. apt существует 27 лет. Не переписывай apt в bash. Используй инструмент."*

Макс изучает package management: apt для установки, dpkg для инспекции, GPG keys для безопасности, batch operations через xargs. Docker installation вручную (custom repository).

LILITH: *"Type B. Используй готовые инструменты. apt для workstation. Ansible для 50 серверов (Season 4). Bash wrapper = костыль."*

**Результат:** Виктор доволен. Макс научился НЕ переизобретать велосипед:
> *"Хорошо. Ты понял главное — администратор знает какой инструмент использовать, не пишет обёртки. Приезжай в Москву. Встретишься с командой."*

Макс: *"Я справился. Может быть, я готов к чему-то большему..."*

### Season 1 завершается
Max собирает вещи. Прощается с Новосибирском (пока). Билет на самолёт в Москву.

**Cliffhanger → Season 2:**
Звонок от Алекса:
> *"Макс, у нас проблема. Крылов знает о нас. Приезжай быстрее."*

Экран гаснет. Первая реальная угроза. Операция переходит на новый уровень.

---

## 🌍 Season 1 как часть глобальной операции

**Season 1** — это только начало. Max доказывает свою компетентность удалённо из Новосибирска.

**Далее (Seasons 2-8):**
- Season 2: Москва → Стокгольм (networking, первая международная поездка)
- Season 3: СПб → Таллин (system administration)
- Season 4: Амстердам → Берлин (DevOps)
- Season 5: Цюрих + Женева (security & pentesting)
- Season 6: Шэньчжэнь, Китай (embedded Linux)
- Season 7: Рейкьявик, Исландия (production infrastructure)
- Season 8: Глобальная (финальная битва во всех локациях)

**Путешествие:** 8+ стран, 35,000+ км, 60 дней, от Новосибирска до Рейкьявика.

---

## 🚀 Как начать

### Episode 01 — Terminal Awakening (Type B):

```bash
cd season-01-shell-foundations/episode-01-terminal-awakening/

# 1. Прочитайте README.md — 8 micro-cycles (сюжет + теория + практика)
less README.md

# 2. Следуйте циклам с практикой каждые 10-15 минут
# Cycle 1: Первый вход (ssh, pwd, ls)
# Cycle 2: Навигация (cd, ls -la, tree)
# ... и так далее

# 3. Скопируйте тестовую среду
cp -r artifacts/test_environment ~/
cd ~/test_environment/

# 4. Практикуйте команды (следуйте README.md)
pwd
ls -la
find . -name "briefing.txt"
cat documents/briefing.txt
# ... и так далее

# 5. Финальное задание: создайте скрипт (Cycle 8)
cp ~/kernel-shadows/season-01-shell-foundations/episode-01-terminal-awakening/starter.sh ./find_files.sh
chmod +x find_files.sh
nano find_files.sh

# 6. Запустите тесты
cd ~/kernel-shadows/season-01-shell-foundations/episode-01-terminal-awakening/tests/
./test.sh
```

### Episode 02 — Shell Scripting Basics (Type A — justified):

```bash
cd season-01-shell-foundations/episode-02-shell-scripting/

# 1. Прочитайте README.md — 8 micro-cycles
less README.md

# 2. Следуйте циклам (переменные → условия → циклы → функции)
# Type A episode: bash scripting для автоматизации (мониторинг 50 серверов)

# 3. Скопируйте артефакты
cp artifacts/servers.txt .

# 4. Создайте server_monitor.sh (следуя TODOs в starter.sh)
cp starter.sh server_monitor.sh
chmod +x server_monitor.sh
nano server_monitor.sh

# 5. Тестируйте функции по отдельности
./server_monitor.sh  # Проверяет серверы, создаёт логи

# 6. Проверьте результаты
cat monitor.log
cat alerts.txt

# 7. Запустите автотесты
./tests/test.sh
```

### Episode 03 — Text Processing Masters (Type B):

```bash
cd season-01-shell-foundations/episode-03-text-processing/

# 1. Прочитайте README.md — 7 micro-cycles
less README.md

# 2. Следуйте циклам (grep → pipes → awk → sort+uniq → sed → combinations)
# Type B episode: 73% Linux tools (grep, awk, pipes), 27% bash (minimal glue)

# 3. Скопируйте артефакты
mkdir -p ~/log_analysis
cp artifacts/access.log ~/log_analysis/
cp artifacts/suspicious_ips.txt ~/log_analysis/
cd ~/log_analysis/

# 4. Практикуйте ONE-LINERS (следуйте циклам в README.md)
grep "03:47" access.log | head
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -10
grep "03:47" access.log | awk -F'"' '{print $6}' | sort | uniq -c

# 5. Финал: создайте log_analyzer.sh (8 ONE-LINERS, minimal bash)
cp ~/kernel-shadows/season-01-shell-foundations/episode-03-text-processing/starter.sh ./log_analyzer.sh
nano log_analyzer.sh  # Заполни 10 TODOs

# 6. Запустите анализ
chmod +x log_analyzer.sh
./log_analyzer.sh access.log suspicious_ips.txt final_report.txt

# 7. Проверьте результаты
cat final_report.txt
cat top_attackers.txt

# 8. Запустите автотесты
cd ~/kernel-shadows/season-01-shell-foundations/episode-03-text-processing/tests
./test.sh
```

### Episode 04 — Package Management (Type B):

```bash
cd season-01-shell-foundations/episode-04-package-management/

# 1. Прочитайте README.md — 7 micro-cycles с теорией + практикой
less README.md

# 2. Изучите список инструментов
cat artifacts/required_tools.txt

# 3. Cycle 1-2: apt basics (следуйте README.md)
sudo apt update
apt search nmap
apt show nmap
sudo apt install -y nmap

# 4. Cycle 3: dpkg inspection
dpkg -l nmap
dpkg -L nmap
dpkg -S /usr/bin/nmap

# 5. Cycle 4: Docker repository (manual installation)
# Добавление GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавление repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# 6. Cycle 5: Batch installation (ONE-LINER!)
grep -v '^#' artifacts/required_tools.txt | grep -v '^$' | xargs sudo apt install -y

# 7. Cycle 6: Verification
while read pkg; do
  [[ "$pkg" =~ ^# || -z "$pkg" ]] && continue
  dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" && echo "✓ $pkg" || echo "✗ $pkg"
done < artifacts/required_tools.txt

# 8. Cleanup
sudo apt autoremove -y
sudo apt clean

# 9. Cycle 7: Generate report (ФИНАЛЬНОЕ ЗАДАНИЕ)
# Вариант 1: Используй starter.sh (заполни TODOs)
cp starter.sh install_report_generator.sh
nano install_report_generator.sh
bash install_report_generator.sh

# Вариант 2: Используй ONE-LINER из artifacts/README.md
# (см. artifacts/README.md → "Generate report" section)

# 10. Проверь результат
cat install_report.txt
```

**⚠️ ВАЖНО для Episode 04 (Type B):**
- Episode 04 = **Type B** (95% apt/dpkg commands, 5% bash для отчёта)
- **НЕ создавай bash wrapper** для установки пакетов! (apt делает это)
- Финальное задание: minimal ONE-LINER для отчёта (40-80 строк)
- Философия: "apt exists — use it, don't rewrite it"
- Для 50 серверов используй Ansible (Season 4, Episode 16), не bash
- Читай artifacts/README.md для workflow каждого цикла


---

## 📊 Прогресс сезона

**Версия:** v0.4.5.4 (Type B Refactoring Complete)
**Статус:** Season 1 Complete! 🎉
**Обновление:** Episodes 01-04 полностью рефакторены с Type B подходом (95% Linux tools, 5% bash), micro-cycles структурой, CS50-style педагогикой.

- [x] **Episode 01** — Complete + Type B refactored (4.73/5) ✅
- [x] **Episode 02** — Complete + Type A justified (4.65/5) ✅
- [x] **Episode 03** — Complete + Type B refactored (4.77/5) ✅
- [x] **Episode 04** — Complete + Type B refactored (4.85/5) 🏆 **ЭТАЛОН**
- [x] **Season README** — Updated with Type B workflow

**Type B Refactoring (v0.4.5.x):**
- Episodes 01, 03, 04 = Type B (Linux tools first, bash second)
- Episode 02 = Type A (bash automation justified — monitoring требует скрипт)
- Micro-cycles структура (10-15 мин переключение внимания)
- CS50-style педагогика (метафоры, ASCII диаграммы, "Aha!" моменты)
- LILITH интегрирована в теорию (не только сюжет)

**См. также:**
- [SCENARIO.md](../SCENARIO.md) — полный сценарий операции KERNEL SHADOWS
- [CHARACTERS.md](../CHARACTERS.md) — биографии всех персонажей (27+)
- [LOCATIONS.md](../LOCATIONS.md) — детальные описания всех локаций
- [CURRICULUM.md](../CURRICULUM.md) — полный учебный план (8 сезонов)
- [STATUS.md](../STATUS.md) — детальный прогресс рефакторинга

---

## 🤖 LILITH в Season 1

LILITH активируется в Episode 01 и сопровождает вас через весь сезон:

**Episode 01:**
> *"Я LILITH. Твой проводник в тенях. Покажи, на что ты способен, Max."*

**Стиль:** Циничная, прямолинейная, помогает через вопросы (не даёт прямых ответов).

**Фразы:**
- *"Логи не врут. Люди — врут."*
- *"Ты видишь shell. Я вижу тени."*
- *"`ls -la` — твоя первая команда на любом сервере."*

---

## 📁 Структура файлов

```
season-01-shell-foundations/
├── README.md                          # Этот файл (карта серий — выше)
│
├── data/                              # Учебные данные для практики (см. data/README.md)
│   ├── test_environment/              # «сервер»-песочница: briefing + скрытые файлы
│   ├── access.log                     # реальный лог атаки (~4400 строк)
│   ├── servers.txt · suspicious_ips.txt · required_tools.txt · report_template.txt
│   └── generate_log.sh                # генератор access.log
│
├── s01e01-terminal-awakening/         # каждая серия — единый шаблон v2.0:
│   ├── README.md                      #   cold open → теория(1 концепт) → задача → debrief
│   ├── mission.md                     #   ТЗ + критерии + блок «Требования среды»
│   ├── starter/                       #   каркас с TODO
│   ├── solution/                      #   эталон (после попытки)
│   ├── theory.md                      #   углубление + вынесенные дампы
│   ├── tests/test.sh                  #   воспроизводимый тест (зелёный без root)
│   └── artifacts/                     #   рабочая папка студента
│
└── s01e02-… … s01e12-batch-report/    # ещё 11 серий той же структуры (см. карту выше)
```

---

## 💡 Советы для успеха

### 1. Читайте man pages
```bash
man ls
man find
man bash
```

### 2. Экспериментируйте
Создайте тестовую папку и пробуйте команды:
```bash
mkdir ~/test_practice
cd ~/test_practice
# Экспериментируйте здесь!
```

### 3. Используйте `--help`
```bash
ls --help
find --help
```

### 4. История команд
```bash
history          # Показать последние команды
!123             # Повторить команду #123
!!               # Повторить последнюю команду
```

### 5. Tab completion
Нажимайте `Tab` для автодополнения имён файлов и команд.

---

## 🎓 Дополнительные ресурсы

- **explainshell.com** — объяснение bash команд
- **shellcheck.net** — проверка bash скриптов
- `man bash` — полная документация Bash
- `/usr/share/doc/` — документация установленных программ

---

## 🔄 Следующие шаги

### После завершения Episode 01 (Type B):
1. ✅ Освоили базовые команды (pwd, ls, cd, find, cat)
2. ✅ Поняли структуру Linux filesystem
3. ✅ Создали скрипт `find_files.sh` (10% задания, 90% — команды)
4. ✅ Прошли все тесты (`./tests/test.sh`)
5. ➡️ Переходите к Episode 02

### После завершения Episode 02 (Type A — justified):
1. ✅ Освоили bash scripting (переменные, условия, циклы, функции)
2. ✅ Создали `server_monitor.sh` для автоматизации мониторинга
3. ✅ Поняли когда bash scripting оправдан (автоматизация, нет готовых tools)
4. ✅ Прошли все тесты (`./tests/test.sh`)
5. ➡️ Переходите к Episode 03

### После завершения Episode 03 (Type B):
1. ✅ Освоили text processing tools (grep, awk, sed, pipes, sort, uniq)
2. ✅ Научились строить ONE-LINERS (73% tools, 27% bash)
3. ✅ Проанализировали логи атаки через commands (4400+ строк)
4. ✅ Создали `log_analyzer.sh` (8 ONE-LINERS, minimal bash wrapper)
5. ✅ Нашли TOP-10 атакующих IP (включая Tor exit node)
6. ✅ Прошли все тесты (`./tests/test.sh`)
7. ➡️ Переходите к Episode 04

### После завершения Episode 04:
1. ✅ Освоили package management (APT, DPKG) как **инструменты**
2. ✅ Научились добавлять репозитории безопасно (GPG keys)
3. ✅ Установили пакеты через apt commands (batch operations с xargs)
4. ✅ Создали minimal ONE-LINER для генерации отчёта (НЕ bash wrapper!)
5. ✅ Поняли **Type B philosophy**: используй apt, не переписывай apt в bash
6. ✅ Установили security & networking tools для операции
7. 🎉 **Season 1 ЗАВЕРШЁН!**

### Переход к Season 2:
Макс садится в самолёт Новосибирск → Москва. Впереди — встреча с командой Виктора, новые локации (Москва → Стокгольм), первая реальная угроза (полковник Крылов).

**Следующий сезон:**
- **Season 2:** Networking (TCP/IP, DNS, Firewalls, VPN, SSH)
- **Локации:** Москва 🇷🇺 → Стокгольм 🇸🇪
- **Новые персонажи:** Алекс (лично), Анна (лично), Erik Johansson, Katarina Lindström
- **Дни операции:** 9-16 (из 60)

**→ Continue: [Season 2 README](../season-02-networking/README.md)**

---

## 🐛 Нашли баг?

Создайте issue в репозитории или напишите в discussions.

---

<div align="center">

**OPERATION KERNEL SHADOWS**
*Season 1 — Shell & Foundations*

*🇷🇺 Новосибирск, Россия (Академгородок)*
*Дни 2-8 из 60 • Первый шаг из 35,000 км*

---

*"Ты видишь shell. Я вижу тени."* — LILITH

*"В мои времена не было StackOverflow. Был man и мозг."* — Сергей Иванов

---

**Следующая остановка:** Season 2 → Москва → Стокгольм 🇸🇪
**Новые персонажи:** Алекс Соколов, Анна Ковалёва, Erik Johansson
**Новая угроза:** Полковник Krylov

*Путешествие только начинается...*

[⬆ К началу](#season-01-shell--foundations)

</div>

