#!/usr/bin/env bash
#
# dns_guard.sh — s02e05 «Ловим подмену DNS» (КАПСТОУН ep06)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: обнаружение DNS-спуфинга/cache poisoning — сверка резолва с эталоном.
# Идея: у нас есть baseline (домен → известный правильный IP). Резолвим сейчас (dig)
# и сравниваем. Расхождение = возможная подмена (трафик уводят на чужой сервер).
# Type B — Linux Tools (dig + минимум bash).
#
# Требования среды: bash + dig. В тесте dig мокается (без сети).
#
# Использование: ./dns_guard.sh BASELINE_FILE
#   BASELINE_FILE: строки "домен  ожидаемый_IP" (# и пустые — пропускаются).

set -uo pipefail

baseline="${1:?Использование: dns_guard.sh BASELINE_FILE}"
[ -f "${baseline}" ] || { echo "Файл не найден: ${baseline}" >&2; exit 1; }

ok=0
spoofed=0

while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    domain="${line%% *}"      # первое поле — домен
    expected="${line##* }"    # последнее поле — эталонный IP

    actual="$(dig "${domain}" A +short 2>/dev/null | head -1)"

    if [ "${actual}" = "${expected}" ]; then
        echo "  ✓ ${domain} → ${actual} (совпадает с эталоном)"
        ok=$((ok + 1))
    else
        echo "  ⚠️ ${domain} → ${actual:-нет ответа} (ОЖИДАЛОСЬ ${expected}) — ВОЗМОЖНА ПОДМЕНА!"
        spoofed=$((spoofed + 1))
    fi
done < "${baseline}"

echo "---"
echo "Проверено: OK=${ok} SPOOFED=${spoofed}"
if [ "${spoofed}" -gt 0 ]; then
    echo "ALERT: обнаружена возможная подмена DNS (${spoofed}) — проверь резолвер и /etc/hosts" >&2
fi
exit 0
