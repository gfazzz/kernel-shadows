#!/usr/bin/env bash
#
# net_diag.sh — s02e03 «Диагностика сети» (СТАРТЕР, капстоун ep05)
#
# Задача: по списку хостов проверить доступность (ping) и вывести таблицу
# HOST / STATUS (UP|DOWN) / RTT (мс из вывода ping), плюс итог UP/DOWN.
#
# Как проходить:
#   1. cp starter/net_diag.sh ./net_diag.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (ping мокается — root/сеть не нужны)
#
# Требования среды: bash + ping. Критерии — в mission.md.

set -uo pipefail

list="${1:?Использование: net_diag.sh HOSTS_FILE}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

up=0
down=0

printf '%-22s %-7s %s\n' "HOST" "STATUS" "RTT"

while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    host="${line%% *}"

    # TODO 1: пропингуй host (один пакет, таймаут), сохрани вывод в out.
    #         out="$(ping -c 1 -W 2 "${host}" 2>/dev/null)"
    # TODO 2: если ping успешен ($? == 0) — вытащи RTT из out
    #         (sed -n 's/.*time=\([0-9.]*\).*/\1/p') и печатай UP + rtt, up++;
    #         иначе печатай DOWN, down++.
    :
done < "${list}"

echo "---"
echo "Итог: UP=${up} DOWN=${down}"
