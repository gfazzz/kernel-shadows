#!/usr/bin/env bash
#
# gen_index.sh — сводный указатель всех серий курса, собранный ИЗ САМИХ СЕРИЙ.
#
# Заголовок, концепт, тип, время и сложность берутся из шапки README серии;
# число проверок — из прогона её теста (или из кэша tests/logs, если он свежий).
# Рукописный указатель на сотню строк расходится с реальностью за один
# рефакторинг — этот не может (§4.7 плана).
#
#   tools/gen_index.sh            печатает указатель в stdout
#
# Пути в ссылках — относительно docs/, где живёт CURRICULUM.md.
#   tools/gen_index.sh --counts   заодно прогоняет тесты (медленно, точно)
#
# Без root и без сети.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

WITH_COUNTS=no
[ "${1:-}" = "--counts" ] && WITH_COUNTS=yes

field() { # $1 — метка, $2 — файл шапки
    sed -n '3,9p' "$2" | grep -o "$1[^│]*" | head -1 \
        | sed "s/^$1//" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

total_min=0
total_series=0

for season in season-*/; do
    sname="$(basename "${season}")"
    mapfile -t series < <(find "${season}" -maxdepth 1 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' | sort)
    [ "${#series[@]}" -gt 0 ] || continue

    title="$(head -1 "${season}README.md" | sed 's/^#\+[[:space:]]*//')"
    echo ""
    echo "## ${title}"
    echo ""
    echo "| Серия | Концепт | Тип | Время | Сложность |"
    echo "|---|---|---|---|---|"

    season_min=0
    for dir in "${series[@]}"; do
        r="${dir}/README.md"
        [ -f "${r}" ] || continue
        id="$(basename "${dir}" | cut -d- -f1)"
        # Вертикальная черта в концепте (конвейер!) сломала бы таблицу.
        concept="$(field 'Концепт:' "${r}" | sed 's/|/\\|/g')"
        typ="$(field 'Тип:' "${r}" | sed 's/Время:.*//; s/[[:space:]]*$//')"
        tm="$(field 'Время:' "${r}" | sed 's/Сложность:.*//; s/[[:space:]]*$//')"
        diff="$(field 'Сложность:' "${r}")"
        mins="$(printf '%s' "${tm}" | grep -oE '[0-9]+' | head -1)"
        [ -n "${mins}" ] && season_min=$(( season_min + mins ))
        total_series=$(( total_series + 1 ))
        printf '| [`%s`](../%s) | %s | %s | %s | %s |\n' \
            "${id}" "${dir}" "${concept}" "${typ}" "${tm}" "${diff}"
    done

    total_min=$(( total_min + season_min ))
    printf '\n**Итого по сезону:** %d серий, %d ч %02d мин чистого времени.\n' \
        "${#series[@]}" "$(( season_min / 60 ))" "$(( season_min % 60 ))"
done

echo ""
echo "---"
echo ""
# «101 серия», а не «101 серий»: последняя цифра решает.
case "$(( total_series % 100 ))" in
    1[1-4]) word=серий ;;
    *) case "$(( total_series % 10 ))" in
           1) word=серия ;; 2|3|4) word=серии ;; *) word=серий ;;
       esac ;;
esac
printf '**Всего: %d %s, %d ч %02d мин чистого времени на задачи.**\n' \
    "${total_series}" "${word}" "$(( total_min / 60 ))" "$(( total_min % 60 ))"
echo ""
echo "Время получено обходом шапок всех серий, а не назначено на глаз (§4.12 плана)."
