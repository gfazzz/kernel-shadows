#!/usr/bin/env bash
#
# find_files.sh — s01e04 «Детектив и автоматизация» (СТАРТЕР, капстоун ep01)
#
# Задача: скрипт должен САМ найти три файла (рекурсивно, через find),
# прочитать их (cat) и сохранить отчёт в report.txt.
#
# Как проходить:
#   1. cp starter/find_files.sh artifacts/find_files.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash + coreutils, без root. Критерии — в mission.md.
# Использование: ./find_files.sh [BASE_DIR] [REPORT_FILE]

set -euo pipefail

base="${1:-.}"
report="${2:-report.txt}"

# TODO 1: найди пути к трём файлам рекурсивно (подумай: find BASE -name '...').
#         briefing.txt, .secret_location, .next_server
# briefing="$(find "${base}" -name '...' 2>/dev/null | head -1)"

# TODO 2: собери отчёт (список найденных путей + их содержимое через cat)
#         и сохрани его в "${report}". Подсказка: группа { ... } | tee "${report}"

echo "TODO: реализуй поиск и отчёт"
