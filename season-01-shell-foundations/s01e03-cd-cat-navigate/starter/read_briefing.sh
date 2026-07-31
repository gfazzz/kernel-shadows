#!/usr/bin/env bash
#
# read_briefing.sh — s01e03 «Дойти и прочитать» (СТАРТЕР)
#
# Задача: зайти на "сервер" (директория base) и прочитать три файла:
#   documents/briefing.txt, .secret_location, .next_server
#
# Как проходить:
#   1. cp starter/read_briefing.sh artifacts/read_briefing.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash + coreutils, без root. Критерии — в mission.md.

set -euo pipefail

base="${1:-.}"

# TODO 1: перейди внутрь base (навигация). Подумай: cd.
# cd ...

echo "=== Я здесь: $(pwd) ==="

# TODO 2: прочитай documents/briefing.txt (относительный путь).

# TODO 3: прочитай скрытые файлы .secret_location и .next_server
#         (они рядом, в текущей директории).
