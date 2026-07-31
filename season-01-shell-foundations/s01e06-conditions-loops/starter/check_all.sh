#!/usr/bin/env bash
#
# check_all.sh — s01e06 «Проверить все серверы» (СТАРТЕР)
#
# Задача: прочитать список серверов из файла (по строке на сервер),
# пропинговать каждый и вывести статус + итог (сколько UP/DOWN).
#
# Формат строки: "имя IP" (например: shadow-server-01 185.192.45.118).
# Пустые строки и строки-комментарии (#...) пропускать.
#
# Как проходить:
#   1. cp starter/check_all.sh artifacts/check_all.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (ping мокается — сеть не нужна)
#
# Требования среды: bash. Критерии — в mission.md.

set -uo pipefail

list="${1:?Использование: check_all.sh SERVERS_FILE}"

# TODO 1: если файла list нет — сообщи в stderr и выйди с кодом 1 (условие -f).

up=0
down=0

# TODO 2: пройди по файлу построчно золотым паттерном:
#         while IFS= read -r line; do ... done < "${list}"
#   - пропусти пустые строки и комментарии (#...)
#   - возьми имя хоста как первое поле: host="${line%% *}"
#   - if ping -c 1 -W 2 "${host}" >/dev/null 2>&1; then ... else ... fi
#   - считай up/down: up=$((up + 1))

echo "---"
echo "ИТОГО: UP=${up} DOWN=${down}"
