#!/usr/bin/env bash
#
# gen_bibliography.sh — библиография курса, СОБРАННАЯ ИЗ СЕРИЙ.
#
# Обходит `theory.md` всех серий, берёт разделы «Книги и справка» и «Куда
# смотреть дальше» и печатает сводный список: что читают и в каких сериях
# это упоминается. Умозрительный список «что полезно почитать по Linux»
# заменяется реальной опорой курса (§4.7 плана).
#
#   tools/gen_bibliography.sh
#
# Без root и без сети.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# Из каждого theory.md — строки списка после заголовка библиографии.
for f in season-*/s[0-9][0-9]e[0-9][0-9]-*/theory.md; do
    id="$(basename "$(dirname "${f}")" | cut -d- -f1)"
    awk -v id="${id}" '
        /^## .*(Книги и справка|Куда смотреть дальше|Книги, справка)/ { inside=1; next }
        /^## / { inside=0 }
        inside && /^[-*] / {
            line=$0
            sub(/^[-*][[:space:]]*/, "", line)
            # Внутренние ссылки курса — не библиография: пропускаем.
            if (line ~ /\]\(\.\.\//) next
            if (line ~ /RESOURCES\.md|PROJECTS\.md|V2\.0_UPGRADE_PLAN/) next
            # Ключ группировки — текст до первого тире-разделителя.
            key=line
            sub(/[[:space:]]*[—–-][[:space:]].*$/, "", key)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
            if (key != "") printf "%s\t%s\t%s\n", key, id, line
        }
    ' "${f}" >> "${TMP}/raw"
done

[ -s "${TMP}/raw" ] || { echo "источников не найдено" >&2; exit 1; }

# Схлопываем одинаковые источники, собираем серии через запятую.
LC_ALL=C sort "${TMP}/raw" | awk -F'\t' '
    { if ($1 != prev) { if (prev != "") print prev "\t" ids "\t" full; prev=$1; ids=$2; full=$3 }
      else if (index(ids, $2) == 0) { ids = ids ", " $2 } }
    END { if (prev != "") print prev "\t" ids "\t" full }
' > "${TMP}/grouped"

n_sources=$(grep -c . "${TMP}/grouped")
n_series=$(ls -d season-*/s[0-9][0-9]e[0-9][0-9]-* 2>/dev/null | wc -l)

echo "# RESOURCES — библиография курса"
echo ""
echo "**Собрано скриптом \`tools/gen_bibliography.sh\`** из разделов «Книги и справка»"
echo "и «Куда смотреть дальше» всех \`theory.md\` курса. Это не список «что полезно"
echo "почитать по Linux», а реальная опора серий: рядом с каждым источником указано,"
echo "где именно он нужен."
echo ""
printf '**Источников: %d. Серий, из которых собрано: %d.**\n' "${n_sources}" "${n_series}"
echo ""
echo "Пересобрать: \`bash tools/gen_bibliography.sh > RESOURCES.md\`"
echo ""
echo "---"
echo ""
echo "| Источник | Где нужен |"
echo "|---|---|"
awk -F'\t' '{
    src=$3
    gsub(/\|/, "\\|", src)
    gsub(/\|/, "\\|", $2)
    printf "| %s | %s |\n", src, $2
}' "${TMP}/grouped"
