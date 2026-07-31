#!/usr/bin/env bash
#
# check_host.sh — s01e05 «Первый умный скрипт»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: bash-переменные (коробки с наклейками) + exit code ($?).
# Type A — Bash Automation.
#
# Требования среды: bash + ping. Живая сеть НЕ нужна для теста —
# он подменяет ping мок-версией (см. tests/test.sh, принцип mock-first §5.3).

set -uo pipefail   # намеренно без -e: неудачный ping не должен ронять скрипт

# $1 — первый аргумент (хост). :? даёт понятную ошибку, если аргумента нет.
host="${1:?Использование: check_host.sh HOST}"

# ping: -c 1 (один пакет), -W 2 (таймаут 2 сек). Вывод не нужен — важен exit code.
ping -c 1 -W 2 "${host}" >/dev/null 2>&1
code=$?             # $? — exit code последней команды; 0 = успех, иначе — проблема

# Кладём человекочитаемый статус в переменную (коробку с наклейкой status).
if [ "${code}" -eq 0 ]; then
    status="UP"
else
    status="DOWN"
fi

echo "HOST: ${host}"
echo "STATUS: ${status}"
echo "EXIT_CODE: ${code}"
