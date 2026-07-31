#!/usr/bin/env bash
#
# top_attackers.sh — s01e09 «Кто атакует чаще всех» (СТАРТЕР)
#
# Задача: из access.log вывести топ-N IP по числу запросов.
# Формат Apache Combined Log: первое поле ($1) — IP.
#
# Как проходить:
#   1. cp starter/top_attackers.sh artifacts/top_attackers.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash + awk + coreutils. Критерии — в mission.md.

set -uo pipefail

log="${1:?Использование: top_attackers.sh ACCESS_LOG [N]}"
n="${2:-5}"
[ -f "${log}" ] || { echo "Файл не найден: ${log}" >&2; exit 1; }

echo "=== Топ-${n} IP по числу запросов ==="

# TODO: построй конвейер:
#   1) awk извлекает первое поле (IP) из каждой строки
#   2) sort группирует одинаковые IP рядом
#   3) uniq -c считает повторы
#   4) sort -rn ранжирует по числу (по убыванию)
#   5) head -n "${n}" берёт верхушку
# awk '{print $1}' "${log}" | ... | head -n "${n}"
