#!/usr/bin/env bash
#
# server_monitor.sh — s01e07 «Production-мониторинг» (КАПСТОУН ep02)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Собирает воедино весь ep02: переменные, ping+exit code, условия, цикл по файлу,
# и добавляет ЛОГИРОВАНИЕ с таймстампами + алерт на недоступные серверы.
# Type A — Bash Automation.
#
# Требования среды: bash. Живая сеть НЕ нужна для теста — он мокает ping.
#
# Использование: ./server_monitor.sh SERVERS_FILE [LOG_FILE]

set -uo pipefail

list="${1:?Использование: server_monitor.sh SERVERS_FILE [LOG_FILE]}"
log="${2:-monitor.log}"

if [ ! -f "${list}" ]; then
    echo "Файл не найден: ${list}" >&2
    exit 1
fi

# Таймстамп одной функцией — чтобы формат был единым во всём логе.
ts() { date '+%Y-%m-%d %H:%M:%S'; }

up=0
down=0

echo "[$(ts)] === START monitoring: ${list} ===" >> "${log}"

while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    host="${line%% *}"

    if ping -c 1 -W 2 "${host}" >/dev/null 2>&1; then
        echo "[$(ts)] [UP]   ${host}" | tee -a "${log}"
        up=$((up + 1))
    else
        echo "[$(ts)] [DOWN] ${host}" | tee -a "${log}"
        down=$((down + 1))
    fi
done < "${list}"

echo "[$(ts)] SUMMARY: UP=${up} DOWN=${down}" | tee -a "${log}"

# Алерт: если есть недоступные — заметный сигнал (и в лог, и в stderr).
if [ "${down}" -gt 0 ]; then
    echo "[$(ts)] ALERT: ${down} server(s) DOWN!" | tee -a "${log}" >&2
fi
