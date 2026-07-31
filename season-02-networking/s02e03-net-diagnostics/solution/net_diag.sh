#!/usr/bin/env bash
#
# net_diag.sh — s02e03 «Диагностика сети» (КАПСТОУН ep05)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: диагностика доступности — ping (жив ли хост) + разбор RTT из вывода.
# Объединяет Season 1 (ping/exit code, цикл по файлу, sed) в сетевой аудит.
# Type A — Bash Automation.
#
# Требования среды: bash + ping. В тесте ping мокается (без root/сети).
#
# Использование: ./net_diag.sh HOSTS_FILE

set -uo pipefail

list="${1:?Использование: net_diag.sh HOSTS_FILE}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

up=0
down=0

printf '%-22s %-7s %s\n' "HOST" "STATUS" "RTT"
printf '%-22s %-7s %s\n' "----" "------" "---"

while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    host="${line%% *}"

    # один пакет, таймаут 2с; из вывода вытаскиваем "time=<число>"
    out="$(ping -c 1 -W 2 "${host}" 2>/dev/null)"
    if [ $? -eq 0 ]; then
        rtt="$(printf '%s' "${out}" | sed -n 's/.*time=\([0-9.]*\).*/\1/p' | head -1)"
        printf '%-22s %-7s %s ms\n' "${host}" "UP" "${rtt:-?}"
        up=$((up + 1))
    else
        printf '%-22s %-7s %s\n' "${host}" "DOWN" "-"
        down=$((down + 1))
    fi
done < "${list}"

echo "---"
echo "Итог: UP=${up} DOWN=${down}"
[ "${down}" -gt 0 ] && echo "ALERT: ${down} хост(ов) недоступно" >&2
exit 0
