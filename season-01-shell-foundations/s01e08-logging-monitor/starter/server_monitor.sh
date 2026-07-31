#!/usr/bin/env bash
#
# server_monitor.sh — s01e08 «Production-мониторинг» (СТАРТЕР, капстоун ep02)
#
# Задача: собрать production-скрипт мониторинга. Он должен:
#   - прочитать список серверов из файла (как в s01e07);
#   - пропинговать каждый, пометить UP/DOWN (условия);
#   - ЛОГИРОВАТЬ каждую строку с таймстампом в LOG_FILE (>> и date);
#   - вывести SUMMARY (UP=.. DOWN=..);
#   - если есть DOWN — выдать ALERT.
#
# Как проходить:
#   1. cp starter/server_monitor.sh artifacts/server_monitor.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (ping мокается — сеть не нужна)
#
# Требования среды: bash. Критерии — в mission.md.
# Использование: ./server_monitor.sh SERVERS_FILE [LOG_FILE]

set -uo pipefail

list="${1:?Использование: server_monitor.sh SERVERS_FILE [LOG_FILE]}"
log="${2:-monitor.log}"

# TODO 1: если файла list нет — сообщи в stderr и выйди с кодом 1.

# TODO 2: функция таймстампа. Подсказка: date '+%Y-%m-%d %H:%M:%S'
# ts() { ...; }

up=0
down=0

# TODO 3: пройди по списку (while IFS= read -r), пропусти пустые/комментарии,
#         host="${line%% *}", проверь ping, логируй строку с таймстампом
#         в "${log}" (через >> или tee -a) и считай up/down.

# TODO 4: залогируй SUMMARY: UP=.. DOWN=..
# TODO 5: если down > 0 — выведи ALERT (в лог и в stderr).

echo "TODO: реализуй мониторинг с логированием"
