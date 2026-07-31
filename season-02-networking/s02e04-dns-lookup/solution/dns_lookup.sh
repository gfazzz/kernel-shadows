#!/usr/bin/env bash
#
# dns_lookup.sh — s02e04 «Телефонная книга интернета»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: DNS-резолвинг через dig; типы записей (A/AAAA/MX/NS/CNAME/TXT).
# Type B — Linux Tools: работу делает dig, bash лишь оформляет запрос/вывод.
#
# Требования среды: bash + dig. В тесте dig подменяется мок-версией (без сети).
#
# Использование: ./dns_lookup.sh DOMAIN [TYPE]   (TYPE по умолчанию A)

set -uo pipefail

domain="${1:?Использование: dns_lookup.sh DOMAIN [TYPE]}"
type="${2:-A}"

# dig DOMAIN TYPE +short — короткий ответ (только значения записи).
ans="$(dig "${domain}" "${type}" +short 2>/dev/null)"

if [ -z "${ans}" ]; then
    echo "${domain} [${type}]: запись не найдена (NXDOMAIN или пусто)"
    exit 1
fi

echo "=== ${domain} [${type}] ==="
printf '%s\n' "${ans}"
echo "Записей: $(printf '%s\n' "${ans}" | grep -c .)"
