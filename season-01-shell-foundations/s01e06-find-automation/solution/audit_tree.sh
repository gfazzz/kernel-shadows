#!/usr/bin/env bash
#
# audit_tree.sh — s01e06 «Инвентаризация дампа»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: find — рекурсивный обход дерева с условиями.
# Type A — Automation: инструмент, который повторяет одну и ту же инвентаризацию
# на любом дереве, вместо ручного обхода каталогов.
#
# Переносимость: используются только POSIX-совместимые приёмы. GNU-расширение
# find -printf здесь НЕ применяется — его нет на macOS/BSD, и тест бы «поехал»
# на другой платформе (план §4.3).
#
# Использование: ./audit_tree.sh КАТАЛОГ

set -uo pipefail

dir="${1:?Использование: audit_tree.sh КАТАЛОГ}"
[ -d "${dir}" ] || { echo "Каталог не найден: ${dir}" >&2; exit 1; }

# -type f — только обычные файлы (не каталоги и не ссылки)
files=$(find "${dir}" -type f | wc -l | tr -d ' ')

# -name работает с шаблоном по ИМЕНИ, а не по пути; кавычки обязательны,
# иначе шаблон раскроет оболочка, а не find
configs=$(find "${dir}" -type f -name '*.conf' | wc -l | tr -d ' ')

# скрытые файлы: имя начинается с точки
hidden=$(find "${dir}" -type f -name '.*' | wc -l | tr -d ' ')

# самый большой файл: du -k даёт размер в килобайтах, sort -rn ставит крупные
# наверх; -exec ... + собирает аргументы пачками, а не запускает du на каждый файл
largest=$(find "${dir}" -type f -exec du -k {} + 2>/dev/null \
          | sort -rn | head -1 | cut -f2- | xargs -r basename 2>/dev/null)

echo "files=${files}"
echo "configs=${configs}"
echo "hidden=${hidden}"
echo "largest=${largest}"
