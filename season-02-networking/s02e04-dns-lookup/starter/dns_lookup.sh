#!/usr/bin/env bash
#
# dns_lookup.sh — s02e04 «Телефонная книга интернета» (СТАРТЕР)
#
# Задача: сделать DNS-запрос через dig и вывести значение записи.
# Принимает домен и (опционально) тип записи (A/AAAA/MX/NS/CNAME/TXT).
#
# Как проходить:
#   1. cp starter/dns_lookup.sh ./dns_lookup.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (dig подменяется мок-версией — сеть не нужна)
#
# Требования среды: bash + dig. Критерии — в mission.md.

set -uo pipefail

domain="${1:?Использование: dns_lookup.sh DOMAIN [TYPE]}"
type="${2:-A}"

# TODO 1: получи короткий ответ dig в переменную ans.
#         Подсказка: dig "${domain}" "${type}" +short
ans=""

# TODO 2: если ans пустой — сообщи «запись не найдена» и exit 1.

# TODO 3: иначе выведи заголовок, значения записи и их количество
#         (grep -c . по ans).
echo "=== ${domain} [${type}] ==="
