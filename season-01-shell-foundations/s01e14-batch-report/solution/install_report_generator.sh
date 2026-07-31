#!/usr/bin/env bash
#
# install_report_generator.sh — s01e14 «Отчёт о готовности» (КАПСТОУН Season 1)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Type B — Linux Tools: ~90% dpkg/awk/date, ~10% bash-клея.
# Это НЕ обёртка для apt! Установка — через `sudo apt install` напрямую.
# Скрипт лишь читает список и генерирует отчёт о статусе.
#
# Требования среды: bash + dpkg + awk (в тесте dpkg мокается — без root/apt).
#
# Использование: ./install_report_generator.sh TOOLS_FILE [REPORT_FILE]

set -uo pipefail

list="${1:?Использование: install_report_generator.sh TOOLS_FILE [REPORT_FILE]}"
report="${2:-install_report.txt}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

installed=0
required=0

{
    echo "=== PACKAGE INSTALLATION REPORT ==="
    echo "Дата: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Архитектура: $(dpkg --print-architecture 2>/dev/null || echo N/A)"
    echo "Для: Viktor Petrov (OPERATION KERNEL SHADOWS)"
    echo ""
    echo "--- ПАКЕТЫ ИЗ СПИСКА ---"
    while IFS= read -r line; do
        [ -z "${line}" ] && continue
        case "${line}" in \#*) continue ;; esac
        pkg="${line%% *}"
        required=$((required + 1))
        if dpkg -l "${pkg}" 2>/dev/null | grep -q '^ii'; then
            ver="$(dpkg -l "${pkg}" 2>/dev/null | awk '/^ii/{print $3; exit}')"
            echo "  ✓ ${pkg} (${ver})"
            installed=$((installed + 1))
        else
            echo "  ✗ ${pkg} — НЕ установлен"
        fi
    done < "${list}"

    echo ""
    echo "--- СТАТИСТИКА ---"
    echo "Установлено из списка: ${installed} / ${required}"
    echo ""
    echo "--- УСТАНОВИТЬ НЕДОСТАЮЩЕЕ (batch, one-liner) ---"
    echo "grep -v '^#' ${list} | awk '{print \$1}' | xargs sudo apt install -y"
    echo "=== END OF REPORT ==="
} > "${report}"

echo "Отчёт сохранён: ${report}"
echo "Установлено из списка: ${installed} / ${required}"
