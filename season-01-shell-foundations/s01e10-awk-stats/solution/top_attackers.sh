#!/usr/bin/env bash
#
# top_attackers.sh — s01e10 «Кто атакует чаще всех»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: awk (извлечь поле-IP) + sort | uniq -c | sort -rn (посчитать и ранжировать).
# Type A — Bash Automation (обёртка над классическим конвейером анализа логов).
#
# Требования среды: bash + awk + coreutils, без root, без сети.
#
# Классический идиом: "awk '{print $1}' | sort | uniq -c | sort -rn | head".

set -uo pipefail

log="${1:?Использование: top_attackers.sh ACCESS_LOG [N]}"
n="${2:-5}"
[ -f "${log}" ] || { echo "Файл не найден: ${log}" >&2; exit 1; }

echo "=== Топ-${n} IP по числу запросов ==="
# awk '{print $1}'  — первое поле каждой строки (IP) в Apache Combined Log
# sort              — сгруппировать одинаковые рядом (uniq считает только соседей)
# uniq -c           — посчитать повторы
# sort -rn          — по числу, по убыванию (-n числовой, -r обратный)
# head -n N         — верхушка рейтинга
awk '{print $1}' "${log}" | sort | uniq -c | sort -rn | head -n "${n}"
