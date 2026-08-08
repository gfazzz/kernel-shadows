#!/usr/bin/env bash
#
# check_tools.sh — аудит forward-deps по ИНСТРУМЕНТАМ (план §8, THEORY_MAP).
#
# Зачем: курс легко ловит forward-deps по концептам (awk, systemd), но молча
# пропускает ИНСТРУМЕНТЫ, которыми студент пользуется с первой серии и которым
# его никто не учил: редактор, cp, chmod, sudo, man, pipes. Один такой (редактор)
# нашёлся только на ревизии и стоил новой серии.
#
# Что делает: для каждого инструмента находит серию первого УПОМИНАНИЯ в
# README/mission (то есть где студент его встречает) и сравнивает с серией, где
# он ВВОДИТСЯ (задаётся таблицей ниже). Если используется раньше — это forward-dep.
#
# Использование: bash tools/check_tools.sh
# Код возврата: 0 — нарушений нет; 1 — есть (список в stdout).

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

# инструмент|регулярка поиска|серия, где вводится (или NONE — не преподаётся нигде)
TOOLS='
cp|\bcp\s|s01e04
mv|\bmv\s|s01e04
mkdir|\bmkdir\b|s01e04
touch|\btouch\b|s01e04
rm|\brm\s+-|s01e04
chmod|\bchmod\b|s01e15
sudo|sudo (apt|systemctl|ufw)|s01e16
man|\bman\s+[a-z]|s01e04
pipe|\|\s*(wc|grep|sort|head|awk)|s01e10
wc|\bwc\s+-l|s01e10
grep|\bgrep\b|s01e10
sort|\bsort\b|s01e11
redirect|>\s*[a-z_]+\.(txt|log|conf)|s01e09
editor|\b(nano|vim|vi)\b|s01e05
ssh|\bssh\s|s02e08
tar|\btar\s+-|s03e11
curl|curl -[a-zA-Z]|NONE
'

echo "════════════════════════════════════════════════════════════"
echo " Аудит forward-deps по инструментам"
echo "════════════════════════════════════════════════════════════"

# порядок серий курса
mapfile -t SERIES < <(find . -maxdepth 2 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' | sed 's|.*/||' | sort)

violations=0

printf '%-10s %-12s %-12s %s\n' "ИНСТРУМЕНТ" "ИСПОЛЬЗ. С" "ВВОДИТСЯ В" "ВЕРДИКТ"
printf '%-10s %-12s %-12s %s\n' "----------" "----------" "----------" "-------"

while IFS='|' read -r tool re intro; do
    [ -z "${tool}" ] && continue
    first=""
    for s in "${SERIES[@]}"; do
        dir=$(find . -maxdepth 2 -type d -name "${s}" | head -1)
        if grep -qE "${re}" "${dir}/README.md" "${dir}/mission.md" 2>/dev/null; then
            first="${s%%-*}"
            break
        fi
    done
    [ -z "${first}" ] && continue   # инструмент вообще не встречается

    # Помечен ли ранний показ как осознанный предпросмотр? Правило THEORY_MAP
    # разрешает использовать инструмент раньше ввода, если рядом стоит пометка
    # «предпросмотр» и он не входит в зачётный код.
    preview=0
    early_dir=$(find . -maxdepth 2 -type d -name "${first}-*" | head -1)
    if [ -n "${early_dir}" ] && grep -qi 'предпросмотр' "${early_dir}/README.md" "${early_dir}/mission.md" 2>/dev/null; then
        preview=1
    fi

    if [ "${intro}" = "NONE" ]; then
        if [ "${preview}" -eq 1 ]; then
            printf '%-10s %-12s %-12s %s\n' "${tool}" "${first}" "—" "предпросмотр (помечен)"
        else
            printf '%-10s %-12s %-12s %s\n' "${tool}" "${first}" "—" "НЕ ПРЕПОДАЁТСЯ"
            violations=$((violations + 1))
        fi
    elif [[ "${first}" < "${intro}" ]]; then
        if [ "${preview}" -eq 1 ]; then
            printf '%-10s %-12s %-12s %s\n' "${tool}" "${first}" "${intro}" "предпросмотр (помечен)"
        else
            printf '%-10s %-12s %-12s %s\n' "${tool}" "${first}" "${intro}" "РАНЬШЕ ВВОДА"
            violations=$((violations + 1))
        fi
    else
        printf '%-10s %-12s %-12s %s\n' "${tool}" "${first}" "${intro}" "ok"
    fi
done <<< "${TOOLS}"

echo "════════════════════════════════════════════════════════════"
if [ "${violations}" -eq 0 ]; then
    echo " Нарушений нет."
else
    echo " Найдено проблем: ${violations}"
    echo " Каждую занести в THEORY_MAP: либо ввести инструмент, либо пометить"
    echo " «предпросмотр, разберём в sNNeNN», либо убрать из зачётного кода."
fi
echo "════════════════════════════════════════════════════════════"
[ "${violations}" -eq 0 ]
