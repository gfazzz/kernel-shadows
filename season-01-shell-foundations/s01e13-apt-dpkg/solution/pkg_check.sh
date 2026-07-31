#!/usr/bin/env bash
#
# pkg_check.sh — s01e13 «Что уже стоит?»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: управление пакетами — проверить статус пакетов из списка через dpkg.
# Type B — Linux Tools: работу делает dpkg, bash лишь читает список и считает.
#
# Требования среды: bash + dpkg (в тесте dpkg подменяется мок-версией — без root/apt).
#
# Использование: ./pkg_check.sh TOOLS_FILE
#   TOOLS_FILE — список пакетов (строка = "имя  # комментарий"), # и пустые пропускаются.

set -uo pipefail

list="${1:?Использование: pkg_check.sh TOOLS_FILE}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

installed=0
missing=0

while IFS= read -r line; do
    [ -z "${line}" ] && continue
    case "${line}" in \#*) continue ;; esac
    pkg="${line%% *}"   # имя пакета — первое поле (отсекаем inline-комментарий)

    # dpkg -l <pkg> печатает строку "ii  <pkg> ..." для реально установленных.
    if dpkg -l "${pkg}" 2>/dev/null | grep -q '^ii'; then
        echo "  ✓ ${pkg} — установлен"
        installed=$((installed + 1))
    else
        echo "  ✗ ${pkg} — НЕ установлен"
        missing=$((missing + 1))
    fi
done < "${list}"

echo "---"
echo "Установлено: ${installed} | Отсутствует: ${missing}"
