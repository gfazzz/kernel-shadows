#!/usr/bin/env bash
#
# log_analyzer.sh — s01e12 «Отчёт по атаке» (КАПСТОУН ep03)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Type B — Linux Configuration/Tools: ~70% готовых инструментов (grep/awk/sort/uniq/sed),
# ~30% bash-клея. Фокус на ONE-LINERS, а не на программировании на bash.
#
# Требования среды: bash + coreutils + awk + sed, без root, без сети.
#
# Использование: ./log_analyzer.sh ACCESS_LOG [THREATS_FILE] [REPORT_FILE]

set -euo pipefail

log="${1:?Использование: log_analyzer.sh ACCESS_LOG [THREATS_FILE] [REPORT_FILE]}"
threats="${2:-}"
report="${3:-report.txt}"
[ -f "${log}" ] || { echo "Файл не найден: ${log}" >&2; exit 1; }

# --- Генерация отчёта: почти целиком из one-liner'ов ------------------------
{
    echo "=== SECURITY INCIDENT REPORT ==="
    echo "Дата анализа: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Аналитик: Max Соколов | Для: Anna Ковалёва (forensics)"
    echo ""
    echo "--- ОБЩАЯ СТАТИСТИКА ---"
    echo "Всего запросов: $(wc -l < "${log}")"
    echo "Уникальных IP:  $(awk '{print $1}' "${log}" | sort -u | wc -l)"
    # sed вычищает квадратные скобки из поля времени [04/Oct/2025:03:47:23 +0000]
    echo "Первый запрос:  $(awk '{print $4}' "${log}" | head -1 | sed 's/[][]//g')"
    echo "Последний:      $(awk '{print $4}' "${log}" | tail -1 | sed 's/[][]//g')"
    echo ""
    echo "--- TOP-10 IP ПО ЗАПРОСАМ ---"
    awk '{print $1}' "${log}" | sort | uniq -c | sort -rn | head -10
    echo ""
    echo "--- РАСПРЕДЕЛЕНИЕ HTTP-СТАТУСОВ ---"
    awk '{print $9}' "${log}" | sort | uniq -c | sort -rn
    echo ""

    # Сверка с базой известных угроз (единственное место, где нужен цикл).
    if [ -n "${threats}" ] && [ -f "${threats}" ]; then
        echo "--- СВЕРКА С БАЗОЙ УГРОЗ ---"
        while IFS= read -r ip; do
            [ -z "${ip}" ] && continue
            case "${ip}" in \#*) continue ;; esac
            # -w: совпадение как целое слово, иначе 10.0.0.5 найдётся внутри 10.0.0.50
            count=$(grep -cw "${ip}" "${log}" || true)
            [ "${count}" -gt 0 ] && echo "  FOUND: ${ip} (${count} запросов)"
        done < "${threats}"
        echo ""
    fi

    echo "--- РЕКОМЕНДАЦИИ ---"
    echo "1. Заблокировать топ-IP (iptables -A INPUT -s <ip> -j DROP)."
    echo "2. Включить rate limiting (nginx limit_req / fail2ban) — разберём в S2/S5."
    echo "=== END OF REPORT ==="
} > "${report}"

# --- Краткая сводка на экран ------------------------------------------------
echo "Отчёт сохранён: ${report}"
echo "Всего запросов: $(wc -l < "${log}") | Уникальных IP: $(awk '{print $1}' "${log}" | sort -u | wc -l)"
echo "TOP-3 IP:"
awk '{print $1}' "${log}" | sort | uniq -c | sort -rn | head -3
