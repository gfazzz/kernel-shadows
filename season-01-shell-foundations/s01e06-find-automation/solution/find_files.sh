#!/usr/bin/env bash
#
# find_files.sh — s01e06 «Детектив и автоматизация» (КАПСТОУН ep01)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: find — рекурсивный поиск; сборка первого bash-скрипта, который
#          ищет файлы, читает их и сохраняет отчёт.
# Type A — Bash Automation.
#
# Требования среды: bash + coreutils (find, cat, tee), без root, без сети.
#
# Использование: ./find_files.sh [BASE_DIR] [REPORT_FILE]
#   BASE_DIR     — где искать (по умолчанию: текущая директория)
#   REPORT_FILE  — куда сохранить отчёт (по умолчанию: report.txt)

set -euo pipefail

base="${1:-.}"
report="${2:-report.txt}"

# find сканирует рекурсивно, включая скрытые файлы и вложенные директории.
briefing="$(find "${base}" -name 'briefing.txt'     2>/dev/null | head -1)"
secret="$(find "${base}"   -name '.secret_location' 2>/dev/null | head -1)"
server="$(find "${base}"   -name '.next_server'     2>/dev/null | head -1)"

# Собираем отчёт и одновременно печатаем на экран (tee).
{
    echo "KERNEL SHADOWS — Episode 01 Report"
    echo "Generated: $(date)"
    echo ""
    echo "=== FILES FOUND ==="
    echo "1. ${briefing:-НЕ НАЙДЕН}"
    echo "2. ${secret:-НЕ НАЙДЕН}"
    echo "3. ${server:-НЕ НАЙДЕН}"
    echo ""
    echo "=== CONTENTS ==="
    echo "--- briefing.txt ---"
    if [ -n "${briefing}" ]; then cat "${briefing}"; else echo "(не найден)"; fi
    echo "--- .secret_location ---"
    if [ -n "${secret}" ]; then cat "${secret}"; else echo "(не найден)"; fi
    echo "--- .next_server ---"
    if [ -n "${server}" ]; then cat "${server}"; else echo "(не найден)"; fi
} | tee "${report}"

echo ""
echo "=== Готово. Отчёт сохранён: ${report} ==="
