#!/usr/bin/env bash
#
# check_ports.sh — s02e02 «Что слушает на сервере»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: порты и сокеты — читаем LISTEN-порты через ss, ловим неожиданные.
# Type A — Bash Automation (обёртка-парсер над ss).
#
# Требования среды: bash + ss. В тесте ss подменяется мок-версией (без root/сети).
#
# Использование: ./check_ports.sh [ALLOWLIST_FILE]
#   ALLOWLIST_FILE — файл с разрешёнными портами (по одному на строку).

set -uo pipefail

allow="${1:-}"

# ss -tln: TCP (-t), только LISTEN (-l), числовой вывод (-n).
# 4-я колонка — "Local Address:Port". NR>1 пропускает заголовок.
listen="$(ss -tln 2>/dev/null | awk 'NR>1{print $4}')"

echo "=== Слушающие TCP (адрес:порт) ==="
printf '%s\n' "${listen}"

# Номер порта — после последнего двоеточия (работает и для 0.0.0.0:22, и для [::]:22).
ports="$(printf '%s\n' "${listen}" | sed 's/.*://' | grep -E '^[0-9]+$' | sort -un)"

if [ -n "${allow}" ] && [ -f "${allow}" ]; then
    echo "--- Проверка по allowlist (${allow}) ---"
    flagged=0
    for p in ${ports}; do
        if grep -qxE "${p}" "${allow}"; then
            echo "  ✓ ${p} — разрешён"
        else
            echo "  ⚠️ ${p} — НЕ в allowlist (неожиданный порт!)"
            flagged=$((flagged + 1))
        fi
    done
    echo "Неожиданных портов: ${flagged}"
fi
