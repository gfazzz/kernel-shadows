#!/usr/bin/env bash
#
# gen_timeline.sh — сквозная таблица «день, время, место» по всем сериям.
#
# Собирается из шапок README и нужна ровно для одного: ловить логистические
# расхождения, которые не поймает ни тест, ни линтер, — серия кончается в
# 03:10 в Москве, а следующая начинается в 04:12 в Петербурге (§4.6 плана).
#
#   tools/gen_timeline.sh            печатает таблицу
#   tools/gen_timeline.sh --check    только проверки; код 1, если есть подозрения
#
# Без root и без сети.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

CHECK_ONLY=no
[ "${1:-}" = "--check" ] && CHECK_ONLY=yes

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

for d in season-*/s[0-9][0-9]e[0-9][0-9]-*/; do
    r="${d}README.md"
    [ -f "${r}" ] || continue
    id="$(basename "${d}" | cut -d- -f1)"
    loc_line="$(grep -m1 '^Локация:' "${r}" | sed 's/^Локация:[[:space:]]*//')"
    # День и время — из той же строки; место — всё до слова «День».
    day="$(printf '%s' "${loc_line}" | grep -oE 'Д(ень|ни|ня)[^,]*' | grep -oE '[0-9]+' | head -1)"
    time="$(printf '%s' "${loc_line}" | grep -oE '[0-9]{2}:[0-9]{2}' | head -1)"
    place="$(printf '%s' "${loc_line}" | sed -E 's/[[:space:]]*Д(ень|ни|ня).*//' | sed 's/[[:space:]]*$//')"
    printf '%s\t%s\t%s\t%s\n' "${id}" "${day:-—}" "${time:-—}" "${place}" >> "${TMP}/rows"
done

[ -s "${TMP}/rows" ] || { echo "серий не найдено" >&2; exit 1; }

# ── проверки ─────────────────────────────────────────────────────────
warn=0
prev_id=""; prev_day=""; prev_time=""; prev_place=""
while IFS=$'\t' read -r id day time place; do
    if [ -n "${prev_id}" ] && [ "${day}" != "—" ] && [ "${prev_day}" != "—" ]; then
        # День не должен уходить назад.
        if [ "${day}" -lt "${prev_day}" ]; then
            echo "  ⚠ ${prev_id} (день ${prev_day}) → ${id} (день ${day}): время идёт назад"
            warn=$((warn+1))
        fi
        # В пределах одного дня время тоже не должно уходить назад.
        if [ "${day}" = "${prev_day}" ] && [ "${time}" != "—" ] && [ "${prev_time}" != "—" ]; then
            if [[ "${time}" < "${prev_time}" ]]; then
                echo "  ⚠ ${prev_id} (${prev_time}) → ${id} (${time}), день ${day}: время идёт назад"
                warn=$((warn+1))
            fi
        fi
        # Смена ГОРОДА внутри одного дня — повод посмотреть на расстояние.
        # Перемещение внутри города (кафе → лаборатория) поводом не является,
        # как и работа с чужой площадкой удалённо или по снимку.
        city="$(printf '%s' "${place}"      | sed 's/,.*//; s/[^[:alpha:]].*$//')"
        pcity="$(printf '%s' "${prev_place}" | sed 's/,.*//; s/[^[:alpha:]].*$//')"
        remote=no
        case "${place}${prev_place}" in *удалённо*|*снимок*) remote=yes ;; esac
        if [ "${day}" = "${prev_day}" ] && [ "${city}" != "${pcity}" ] && [ "${remote}" = no ]; then
            echo "  ⚠ ${prev_id} → ${id}: смена города внутри дня ${day} (${pcity} → ${city})"
            warn=$((warn+1))
        fi
    fi
    prev_id="${id}"; prev_day="${day}"; prev_time="${time}"; prev_place="${place}"
done < "${TMP}/rows"

if [ "${CHECK_ONLY}" = yes ]; then
    if [ "${warn}" -eq 0 ]; then
        echo "Хронология: расхождений не найдено, серий — $(grep -c . "${TMP}/rows")."
        exit 0
    fi
    echo "Хронология: подозрений — ${warn}. Каждое надо посмотреть глазами."
    exit 1
fi

echo "# Хронология курса"
echo ""
echo "Собрано \`tools/gen_timeline.sh\` из шапок серий. Таблица нужна для проверки"
echo "канона после каждого сезона: логистику не ловит ни один тест (§4.6 плана)."
echo ""
echo "| Серия | День | Время | Место |"
echo "|---|---|---|---|"
awk -F'\t' '{printf "| `%s` | %s | %s | %s |\n", $1, $2, $3, $4}' "${TMP}/rows"
echo ""
if [ "${warn}" -eq 0 ]; then
    echo "**Расхождений не найдено.**"
else
    echo "**Подозрений: ${warn}** — см. вывод \`tools/gen_timeline.sh --check\`."
fi
