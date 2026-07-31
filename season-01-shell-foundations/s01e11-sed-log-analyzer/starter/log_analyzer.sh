#!/usr/bin/env bash
#
# log_analyzer.sh — s01e11 «Отчёт по атаке» (СТАРТЕР, капстоун ep03, Type B)
#
# Задача: из access.log собрать отчёт для Анны. Подход Type B — ONE-LINERS:
# 70% готовых инструментов (grep/awk/sort/uniq/sed), 30% bash-клея.
#
# Отчёт должен содержать:
#   - всего запросов (wc -l), уникальных IP (awk|sort -u|wc -l)
#   - первый/последний таймстамп (awk поле $4, sed вычищает скобки [ ])
#   - TOP-10 IP (awk|sort|uniq -c|sort -rn|head)
#   - распределение HTTP-статусов (awk '{print $9}'|sort|uniq -c|sort -rn)
#   - (если задан threats-файл) сверку известных IP с логом
#   - сохранить отчёт в REPORT_FILE
#
# Как проходить:
#   1. cp starter/log_analyzer.sh artifacts/log_analyzer.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash + coreutils + awk + sed. Критерии — в mission.md.
# Использование: ./log_analyzer.sh ACCESS_LOG [THREATS_FILE] [REPORT_FILE]

set -euo pipefail

log="${1:?Использование: log_analyzer.sh ACCESS_LOG [THREATS_FILE] [REPORT_FILE]}"
threats="${2:-}"
report="${3:-report.txt}"
[ -f "${log}" ] || { echo "Файл не найден: ${log}" >&2; exit 1; }

{
    echo "=== SECURITY INCIDENT REPORT ==="
    # TODO 1: всего запросов и уникальных IP (one-liners)
    # TODO 2: первый/последний таймстамп через awk '{print $4}' + sed 's/[][]//g'
    # TODO 3: TOP-10 IP (awk|sort|uniq -c|sort -rn|head -10)
    # TODO 4: распределение HTTP-статусов (awk '{print $9}'|...)
    # TODO 5: если threats задан и существует — сверить IP из него с логом
    echo "=== END OF REPORT ==="
} > "${report}"

echo "Отчёт сохранён: ${report}"
