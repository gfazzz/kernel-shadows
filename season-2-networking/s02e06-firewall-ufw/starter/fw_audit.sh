#!/usr/bin/env bash
#
# fw_audit.sh — s02e06 «Читаем стену» (СТАРТЕР)
#
# Задача: прочитать вывод `ufw status` (из файла) и найти опасные ALLOW —
# чувствительные порты (БД/кэши), открытые наружу («Anywhere»).
#
# Как проходить:
#   1. cp starter/fw_audit.sh ./fw_audit.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash. Критерии — в mission.md.

set -uo pipefail

rules="${1:?Использование: fw_audit.sh UFW_STATUS_FILE}"
[ -f "${rules}" ] || { echo "Файл не найден: ${rules}" >&2; exit 1; }

sensitive="3306 5432 6379 27017 9200 11211"

issues=0
echo "=== ALLOW-правила ==="
while IFS= read -r line; do
    # TODO 1: пропусти строки без ALLOW (case "${line}" in *ALLOW*) ;; *) continue ;; esac)
    # TODO 2: возьми порт как первое поле, отрежь /tcp (port="${port%%/*}")
    # TODO 3: если порт из списка sensitive И в строке есть "Anywhere" —
    #         выведи предупреждение и issues++.
    :
done < "${rules}"

echo "---"
echo "Проблем: ${issues}"
