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
cd season-1-shell-foundations/s01e01-terminal-awakening
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

## 📊 progress.sh — Отслеживание прогресса

Показывает ваш прогресс по эпизодам курса.

### Использование:
```bash
./tools/progress.sh [команда]
```

### Команды:

| Команда | Описание | Пример |
|---------|----------|--------|
| (нет) | Общий прогресс | `./tools/progress.sh` |
| `all` | Все сезоны | `./tools/progress.sh all` |
| `season <N>` | Прогресс сезона | `./tools/progress.sh season 1` |
| `start <S> <E>` | Отметить как начатый | `./tools/progress.sh start 1 01` |
| `complete <S> <E>` | Отметить как завершённый | `./tools/progress.sh complete 1 01` |
| `reset` | Сбросить прогресс | `./tools/progress.sh reset` |

### Примеры:

**Общий прогресс:**
```bash
./tools/progress.sh

# Output:
# ╔══════════════════════════════════════════════════════════════╗
# ║  KERNEL SHADOWS - Progress Tracker                           ║
# ╚══════════════════════════════════════════════════════════════╝
#
# Общий прогресс:
#   [████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░] 12% (4/32 эпизодов)
#
# Статистика:
#   ✅ Завершено: 4
#   ⏳ В процессе: 1
#   ⭕ Не начато: 27
```

**Прогресс Season 1:**
```bash
./tools/progress.sh season 1

# Output:
# ╔══════════════════════════════════════════════════════════════╗
# ║  Season 1 Progress                                           ║
# ╚══════════════════════════════════════════════════════════════╝
#
#   ✅  Episode 01: Terminal Awakening
#   ⏳  Episode 02: Shell Scripting Basics
#   ⭕  Episode 03: Text Processing Masters
#   ⭕  Episode 04: Package Management
```

**Отметить эпизод завершённым:**
```bash
./tools/progress.sh complete 1 01
# ✅ Episode 01 помечен как 'завершён'!
```

---

## 🔧 Интеграция с редакторами

### Cursor / VSCode

Все инструменты интегрированы через `.vscode/tasks.json`.

**Быстрые клавиши:**
- `Ctrl+Shift+B` (или `Cmd+Shift+B` на macOS) — Запустить текущий скрипт
- `Ctrl+Shift+P` → `Tasks: Run Task` → выбрать задачу

**Доступные задачи:**
- 🧪 Run Episode Tests
- ▶️ Run Current Script
- 🔍 Shellcheck Current File
- 🚀 Run Starter Script
- 🤖 LILITH Help
- 📊 Show Progress
- 🧹 Clean Test Environment
- 📝 Format Current Shell Script

---

## 📝 .progress файл

Прогресс сохраняется в `.progress` (в корне проекта).

**Формат:**
```
s1-e01:completed:2025-10-04
s1-e02:in_progress:2025-10-05
```

**Статусы:**
- `not_started` — не начат
- `in_progress` — в процессе
- `completed` — завершён

**Примечание:** Файл автоматически создаётся при первом запуске `progress.sh`.

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

