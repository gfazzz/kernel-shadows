#!/usr/bin/env bash
#
# dns_guard.sh — s02e05 «Ловим подмену DNS» (СТАРТЕР, капстоун ep06)
#
# Задача: по baseline (домен → правильный IP) резолвить каждый домен через dig
# и ловить расхождения (возможная DNS-подмена). Вывести итог OK/SPOOFED.
#
# Формат baseline: "домен  ожидаемый_IP" (# и пустые пропускать).
#
# Как проходить:
#   1. cp starter/dns_guard.sh artifacts/dns_guard.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (dig мокается — сеть не нужна)
#
# Требования среды: bash + dig. Критерии — в mission.md.

set -uo pipefail

baseline="${1:?Использование: dns_guard.sh BASELINE_FILE}"
[ -f "${baseline}" ] || { echo "Файл не найден: ${baseline}" >&2; exit 1; }

ok=0
spoofed=0

while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    domain="${line%% *}"
    expected="${line##* }"

    # TODO 1: резолвни domain (A-запись) через dig +short, возьми первую строку.
    #         actual="$(dig "${domain}" A +short 2>/dev/null | head -1)"
    actual=""

    # TODO 2: сравни actual с expected. Совпало → ✓, ok++. Иначе → ⚠️ подмена, spoofed++.
    :
done < "${baseline}"

echo "---"
echo "Проверено: OK=${ok} SPOOFED=${spoofed}"
# TODO 3: если spoofed > 0 — выведи ALERT в stderr.
