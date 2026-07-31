#!/usr/bin/env bash
#
# run_tests.sh — раннер тестов всех серий курса (план §7).
#
# Зачем: до его появления прогнать курс одной командой было нельзя, поэтому
# регрессии миграции ловить было некому. Раннер обходит серии sNNeNN,
# запускает tests/test.sh каждой и печатает сводку.
#
# Использование:
#   bash tools/run_tests.sh                 # все серии
#   bash tools/run_tests.sh season-01-*     # только один сезон
#   REPEAT=2 bash tools/run_tests.sh        # два прогона подряд (проверка воспроизводимости, §4.3)
#
# Код возврата: 0 — все зелёные; 1 — есть падения.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

REPEAT="${REPEAT:-1}"
filter="${1:-}"

if [ -n "${filter}" ]; then
    mapfile -t series < <(find ${filter} -maxdepth 1 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' 2>/dev/null | sort)
else
    mapfile -t series < <(find . -maxdepth 2 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' -not -path './personal/*' 2>/dev/null | sort)
fi

if [ "${#series[@]}" -eq 0 ]; then
    echo "Серий не найдено (фильтр: '${filter:-все}')" >&2
    exit 1
fi

pass=0; fail=0; skip=0
failed_list=()

echo "════════════════════════════════════════════════════════════"
echo " KERNEL SHADOWS — прогон тестов (${#series[@]} серий, повторов: ${REPEAT})"
echo "════════════════════════════════════════════════════════════"

for run in $(seq 1 "${REPEAT}"); do
    [ "${REPEAT}" -gt 1 ] && echo "--- прогон ${run}/${REPEAT} ---"
    for dir in "${series[@]}"; do
        name="$(basename "${dir}")"
        if [ ! -f "${dir}/tests/test.sh" ]; then
            printf '  SKIP  %s (нет tests/test.sh)\n' "${name}"
            [ "${run}" -eq 1 ] && skip=$((skip + 1))
            continue
        fi
        if out="$(bash "${dir}/tests/test.sh" 2>&1)"; then
            res="$(printf '%s' "${out}" | grep -oE '[0-9]+ passed, [0-9]+ failed' | tail -1)"
            printf '  PASS  %-32s %s\n' "${name}" "${res}"
            pass=$((pass + 1))
        else
            res="$(printf '%s' "${out}" | grep -oE '[0-9]+ passed, [0-9]+ failed' | tail -1)"
            printf '  FAIL  %-32s %s\n' "${name}" "${res:-нет сводки}"
            fail=$((fail + 1))
            failed_list+=("${name}")
        fi
    done
done

echo "════════════════════════════════════════════════════════════"
echo " Итог: PASS=${pass}  FAIL=${fail}  SKIP=${skip}"
if [ "${fail}" -gt 0 ]; then
    echo " Упавшие серии:"
    printf '   %s\n' "${failed_list[@]}"
fi
echo "════════════════════════════════════════════════════════════"

[ "${fail}" -eq 0 ]
