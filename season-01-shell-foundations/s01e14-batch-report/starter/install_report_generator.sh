#!/usr/bin/env bash
#
# install_report_generator.sh — s01e14 «Отчёт о готовности» (СТАРТЕР, капстоун S1)
#
# Задача (Type B): по списку пакетов сгенерировать отчёт для Виктора:
#   - по каждому пакету: установлен (✓ + версия) или нет (✗);
#   - статистика: установлено / всего в списке;
#   - one-liner для batch-установки недостающего (xargs).
#
# Как проходить:
#   1. cp starter/install_report_generator.sh artifacts/install_report_generator.sh
#   2. заменить TODO
#   3. bash tests/test.sh   (dpkg мокается — root/apt не нужны)
#
# Требования среды: bash + dpkg + awk. Критерии — в mission.md.
# Использование: ./install_report_generator.sh TOOLS_FILE [REPORT_FILE]

set -uo pipefail

list="${1:?Использование: install_report_generator.sh TOOLS_FILE [REPORT_FILE]}"
report="${2:-install_report.txt}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

installed=0
required=0

{
    echo "=== PACKAGE INSTALLATION REPORT ==="
    echo "Дата: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "--- ПАКЕТЫ ИЗ СПИСКА ---"
    # TODO 1: пройди по списку (пропуская # и пустые), для каждого пакета
    #         проверь dpkg -l | grep '^ii'; выведи ✓ pkg (версия) или ✗ pkg;
    #         считай installed и required. Версия: dpkg -l pkg | awk '/^ii/{print $3}'.

    echo ""
    echo "--- СТАТИСТИКА ---"
    # TODO 2: выведи "Установлено из списка: ${installed} / ${required}"

    echo ""
    echo "--- УСТАНОВИТЬ НЕДОСТАЮЩЕЕ (batch) ---"
    # TODO 3: выведи one-liner batch-установки (grep -v '^#' ... | awk ... | xargs sudo apt install -y)
    echo "=== END OF REPORT ==="
} > "${report}"

echo "Отчёт сохранён: ${report}"
