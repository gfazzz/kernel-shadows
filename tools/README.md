# KERNEL SHADOWS: Tools
## Инструменты для студентов и разработчиков

Эта директория содержит CLI утилиты для работы с курсом.

---

## 🤖 lilith.sh — AI помощник

Интерактивный CLI tool для взаимодействия с LILITH.

### Использование:
```bash
./tools/lilith.sh <команда>
```

### Команды:

| Команда | Описание | Пример |
|---------|----------|--------|
| `help` | Справка | `./tools/lilith.sh help` |
| `quote` | Случайная цитата LILITH | `./tools/lilith.sh quote` |
| `hint <ep>` | Подсказка для эпизода | `./tools/lilith.sh hint 01` |
| `check <ep>` | Проверить решение | `./tools/lilith.sh check 01` |
| `status` | Статус текущего эпизода | `./tools/lilith.sh status` |
| `next` | Показать следующий эпизод | `./tools/lilith.sh next` |
| `version` | Версия курса | `./tools/lilith.sh version` |

### Примеры:

**Получить подсказку:**
```bash
cd season-01-shell-foundations/s01e01-terminal-awakening
../../tools/lilith.sh hint 01
```

**Проверить решение:**
```bash
../../tools/lilith.sh check 01
```

**Случайная цитата:**
```bash
./tools/lilith.sh quote
# > "Root — это не привилегия. Это оружие." — LILITH
```

---

## 🧪 Makefile — единый вход

Всё, что проверяется механически, запускается одной командой из корня проекта.
Логика живёт в скриптах этой папки, `Makefile` только даёт им имена.

```bash
make                 # список целей
make test            # unit-тесты всех серий (без root и сети)
make test SEASON=season-01-shell-foundations
make test SERIES=s01e10          # одна серия по подстроке имени
make test VERBOSE=1              # печатать вывод упавших серий целиком
make test-repeat                 # два прогона подряд — воспроизводимость
make test-locale                 # прогон под LC_ALL=C и чужим TZ
make test-integration            # тесты, которым нужен живой хост
make links                       # ссылки между документами
make tools                       # аудит forward-deps по инструментам
make check                       # links + tools + test — то, что гоняет CI
make progress                    # где я остановился
make clean-clone                 # приёмка на чистом клоне
```

---

## 🧪 run_tests.sh — прогон unit-тестов

Обходит серии `sNNeNN`, запускает `tests/test.sh` каждой, пишет лог по сезонам
и печатает сводку. При падении называет упавшие серии и команду для повтора.

```bash
bash tools/run_tests.sh                  # все серии
bash tools/run_tests.sh season-01-*      # позиционный фильтр
SEASON=season-02-networking bash tools/run_tests.sh
SERIES=s01e10 bash tools/run_tests.sh    # одна серия
REPEAT=2 bash tools/run_tests.sh         # два прогона подряд
VERBOSE=1 bash tools/run_tests.sh        # полный вывод упавших
```

**Логи:** `tests/logs/<сезон>.log` — по файлу на сезон, перезаписываются при
каждом прогоне. Каталог в `.gitignore`; в CI выкладывается артефактом, в том
числе при падении.

Код возврата: `0` — все зелёные, `1` — есть падения.

---

## 🧩 run_integration.sh — тесты, требующие живого хоста

Двухуровневая модель: unit обязателен и работает на фикстурах, integration
нужен там, где без systemd, Docker или root не обойтись. Такой тест объявляется
файлом `<серия>/tests/integration.sh` и декларацией требований в её `mission.md`.

**Сейчас интеграционных тестов нет:** все 23 серии S1–S2 проходят на unit-уровне.
Цель существует заранее — для S3 (systemd), S4 (Docker) и S6 (модуль ядра).

---

## 🔗 check_links.sh — проверка внутренних ссылок

Обходит все `.md` курса и проверяет, что цели markdown-ссылок существуют
. Ручная вычитка такие ошибки не ловит.

```bash
bash tools/check_links.sh
```

---

## 🛠 check_tools.sh — аудит forward-deps по инструментам

Проверяет, что команда или программа не используется в сериях раньше, чем
курс её объясняет. Ищет не по концептам, а именно по инструментам: редактор,
`cp`, `chmod`, `man`, `grep`, `>`, `ssh`, `systemctl`. Отличает честно
помеченный «предпросмотр» от нарушения.

```bash
bash tools/check_tools.sh
```

Таблица инструментов и серий, где они вводятся, — в начале самого скрипта;
найденные нарушения записываются в [`THEORY_MAP.md`](../docs/THEORY_MAP.md) под номером `T`.

---

## 📊 progress.sh — где я остановился

Считает прогресс **по факту**, а не по самоотметке. Серия пройдена,
если выполнены оба условия:

1. в `<серия>/artifacts/` лежит работа студента;
2. тест серии на этой работе зелёный.

Наличие `solution/` не засчитывается никогда — эталон лежит в репозитории
с самого начала.

```bash
bash tools/progress.sh                 # полная картина
bash tools/progress.sh --quiet         # только следующая цель (для скриптов)
SEASON=season-02-networking bash tools/progress.sh
```

```
  shell foundations            [####........] 4/14
   [x] s01e01-terminal-awakening
   [~] s01e05-editing-files   (работа есть, тест красный)
   [ ] s01e06-find-automation
  Следующая цель: season-01-shell-foundations/s01e05-editing-files
```

Прежняя версия вела учёт в файле `.progress` командами `start`/`complete`.
Этот способ верил отметкам «я сделал»; теперь считается результат, и файл
`.progress` больше не используется.

---

## 🔧 Интеграция с редакторами

### Cursor / VSCode

Все инструменты интегрированы через `.vscode/tasks.json`.

**Быстрые клавиши:**
- `Ctrl+Shift+B` (или `Cmd+Shift+B` на macOS) — Запустить текущий скрипт
- `Ctrl+Shift+P` → `Tasks: Run Task` → выбрать задачу

**Доступные задачи:**
- 🧪 Run Series Tests (`make test`)
- ▶️ Run Current Script
- 🔍 Shellcheck Current File
- 🚀 Run Starter Script
- 🤖 LILITH Help
- 📊 Show Progress (`make progress`)
- 🧹 Clean Test Environment
- 📝 Format Current Shell Script

---

## 🎨 Цвета и эмодзи

Инструменты используют ANSI цвета для улучшения читаемости:

| Цвет | Значение |
|------|----------|
| 🟢 Зелёный | Успех, завершено |
| 🟡 Жёлтый | Предупреждение, в процессе |
| 🔴 Красный | Ошибка |
| 🔵 Синий | Информация |
| 🟣 Фиолетовый | LILITH, заголовки |
| 🔵 Cyan | Названия разделов |

---

## 🚀 Установка (опционально)

Для быстрого доступа можно добавить алиасы в `~/.bashrc`:

```bash
# KERNEL SHADOWS aliases
alias lilith='bash ~/projects/kernel-shadows/tools/lilith.sh'
alias ksprogress='bash ~/projects/kernel-shadows/tools/progress.sh'

# Перезагрузить конфиг
source ~/.bashrc
```

Теперь можно использовать просто:
```bash
lilith quote
ksprogress
```

---

## 📚 Технические детали

### Зависимости:
- **Bash 4.0+** (для associative arrays)
- **GNU coreutils** (ls, grep, sed, awk)
- **Git** (для определения корня проекта)

### Структура кода:
- `set -euo pipefail` — строгий режим
- Цвета через ANSI escape codes
- Автоопределение путей через `$(dirname "${BASH_SOURCE[0]}")`

---

## 🐛 Troubleshooting

### Проблема: "Permission denied"
**Решение:**
```bash
chmod +x tools/lilith.sh tools/progress.sh
```

### Проблема: Цвета не отображаются
**Причина:** Терминал не поддерживает ANSI цвета.

**Решение:** Используйте современный терминал (GNOME Terminal, Alacritty, iTerm2).

### Проблема: "Episode not found"
**Причина:** Вы в неправильной директории.

**Решение:** Перейдите в корень проекта:
```bash
cd ~/projects/kernel-shadows
./tools/lilith.sh status
```

---

## 🤝 Вклад

Хотите улучшить инструменты?
1. Fork репозиторий
2. Создайте ветку: `git checkout -b feature/improve-lilith`
3. Commit изменения: `git commit -am 'Add new feature'`
4. Push: `git push origin feature/improve-lilith`
5. Создайте Pull Request

---

## 📜 Лицензия

GPL v3 — как и весь курс KERNEL SHADOWS.

---

<div align="center">

**"Автоматизация — не лень. Это выживание."** — LILITH

[⬆ Наверх](#kernel-shadows-tools)

</div>

