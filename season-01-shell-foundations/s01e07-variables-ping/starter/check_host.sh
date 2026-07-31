#!/usr/bin/env bash
#
# check_host.sh — s01e07 «Первый умный скрипт» (СТАРТЕР)
#
# Задача: проверить доступность хоста через ping и положить результат
# в переменные (host, status, exit code). Напечатать статус.
#
# Как проходить:
#   1. cp starter/check_host.sh artifacts/check_host.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (тест сам подменит ping — живая сеть не нужна)
#
# Требования среды: bash. Критерии — в mission.md.

set -uo pipefail   # без -e: неудачный ping не должен ронять скрипт

host="${1:?Использование: check_host.sh HOST}"

# TODO 1: пропингуй host одним пакетом с таймаутом, вывод отправь в /dev/null.
#         Подсказка: ping -c 1 -W 2 "${host}" >/dev/null 2>&1

# TODO 2: сохрани exit code последней команды в переменную code.
#         Подсказка: специальная переменная $?
code=1   # <-- замени

# TODO 3: если code == 0 → status="UP", иначе status="DOWN".

# TODO 4: напечатай HOST / STATUS / EXIT_CODE (значения — из переменных).
echo "HOST: ${host}"
