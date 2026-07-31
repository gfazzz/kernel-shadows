#!/usr/bin/env bash
#
# check_all.sh — s01e07 «Проверить все серверы»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: условия (if/then) + циклы (while read по файлу).
# Type A — Bash Automation.
#
# Требования среды: bash. Живая сеть НЕ нужна для теста — он мокает ping.

set -uo pipefail

list="${1:?Использование: check_all.sh SERVERS_FILE}"

# Проверка входных данных условием -f (файл существует).
if [ ! -f "${list}" ]; then
    echo "Файл не найден: ${list}" >&2
    exit 1
fi

up=0
down=0

# Золотой паттерн чтения файла построчно: while IFS= read -r ... < файл.
while IFS= read -r line; do
    [ -z "${line}" ] && continue            # пропустить пустые строки
    case "${line}" in \#*) continue ;; esac # пропустить комментарии (#...)

    # Первое поле строки "имя IP" — имя хоста (до первого пробела).
    host="${line%% *}"

    if ping -c 1 -W 2 "${host}" >/dev/null 2>&1; then
        echo "[UP]   ${host}"
        up=$((up + 1))
    else
        echo "[DOWN] ${host}"
        down=$((down + 1))
    fi
done < "${list}"

echo "---"
echo "ИТОГО: UP=${up} DOWN=${down}"
