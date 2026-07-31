#!/usr/bin/env bash
#
# audit_tree.sh — s01e06 «Инвентаризация дампа» (СТАРТЕР)
#
# Задача: пройти дерево каталогов и напечатать четыре факта о нём:
#   files=<сколько всего обычных файлов, на любой глубине>
#   configs=<сколько из них с расширением .conf>
#   hidden=<сколько скрытых файлов (имя начинается с точки)>
#   largest=<имя самого большого файла, без пути>
#
# Формат вывода — строго «ключ=значение», по строке на факт: его читает тест.
#
# Как проходить:
#   1. cp starter/audit_tree.sh artifacts/audit_tree.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash + find + coreutils. Критерии — в mission.md.
# Использование: ./audit_tree.sh КАТАЛОГ

set -uo pipefail

dir="${1:?Использование: audit_tree.sh КАТАЛОГ}"
[ -d "${dir}" ] || { echo "Каталог не найден: ${dir}" >&2; exit 1; }

# TODO 1: сколько всего обычных файлов в дереве (рекурсивно).
#         Подсказка: find "${dir}" -type f | wc -l
files=0

# TODO 2: сколько файлов с именем вида *.conf
#         Подсказка: у find есть -name '*.conf'
configs=0

# TODO 3: сколько скрытых файлов (имя начинается с точки).
#         Подсказка: -name '.*'
hidden=0

# TODO 4: имя самого большого файла (без пути).
#         Подсказка: find ... -exec du -k {} + | sort -rn | head -1
#         затем отрезать путь: basename
largest=""

echo "files=${files}"
echo "configs=${configs}"
echo "hidden=${hidden}"
echo "largest=${largest}"
