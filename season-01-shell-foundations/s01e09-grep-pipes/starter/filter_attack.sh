#!/usr/bin/env bash
#
# filter_attack.sh — s01e09 «Фильтрация логов атаки» (СТАРТЕР)
#
# Задача: из access.log выделить подозрительные запросы (HTTP-статус не 200)
# и посчитать их количество через конвейер (pipe).
#
# Как проходить:
#   1. cp starter/filter_attack.sh artifacts/filter_attack.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash + grep. Критерии — в mission.md.

set -uo pipefail

log="${1:?Использование: filter_attack.sh ACCESS_LOG}"
[ -f "${log}" ] || { echo "Файл не найден: ${log}" >&2; exit 1; }

echo "=== Подозрительные запросы (HTTP-статус не 200) ==="
# TODO 1: выведи строки лога, где НЕ статус 200 (подсказка: grep -v).

echo "---"
# TODO 2: посчитай подозрительные строки через конвейер (grep ... | wc -l)
#         и выведи "Подозрительных запросов: N".
