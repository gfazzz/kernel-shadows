#!/usr/bin/env bash
#
# pkg_check.sh — s01e11 «Что уже стоит?» (СТАРТЕР)
#
# Задача: по списку пакетов проверить, какие установлены (через dpkg),
# и вывести итог (установлено / отсутствует).
#
# Формат списка: строка = "имя  # комментарий". Строки-# и пустые пропускать.
#
# Как проходить:
#   1. cp starter/pkg_check.sh ./pkg_check.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (dpkg подменяется мок-версией — root/apt не нужны)
#
# Требования среды: bash + dpkg. Критерии — в mission.md.

set -uo pipefail

list="${1:?Использование: pkg_check.sh TOOLS_FILE}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

installed=0
missing=0

while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    pkg="${line%% *}"

    # TODO: проверь, установлен ли pkg.
    #   dpkg -l "${pkg}" печатает строку, начинающуюся с "ii", для установленных.
    #   if dpkg -l "${pkg}" 2>/dev/null | grep -q '^ii'; then ... else ... fi
    #   считай installed / missing и печатай статус по каждому пакету.
    :
done < "${list}"

echo "---"
echo "Установлено: ${installed} | Отсутствует: ${missing}"
