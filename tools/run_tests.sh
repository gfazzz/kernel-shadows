#!/usr/bin/env bash
#
# run_tests.sh — раннер unit-тестов всех серий курса (план §7).
#
# Зачем: до его появления прогнать курс одной командой было нельзя, поэтому
# регрессии миграции ловить было некому. Раннер обходит серии sNNeNN,
# запускает tests/test.sh каждой, пишет лог по сезонам и печатает сводку.
#
# Использование:
#   bash tools/run_tests.sh                      # все серии
#   bash tools/run_tests.sh season-01-*          # позиционный фильтр (сезон или маска)
#   SEASON=season-01-shell-foundations …         # то же через переменную (как в Makefile)
#   SERIES=s01e10 bash tools/run_tests.sh        # одна серия по подстроке имени
#   REPEAT=2 bash tools/run_tests.sh             # два прогона (воспроизводимость, §4.3)
#   VERBOSE=1 bash tools/run_tests.sh            # печатать вывод упавших серий целиком
#
# Логи: tests/logs/<сезон>.log — по одному файлу на сезон, перезаписывается
# при каждом прогоне (§7.3: лог должен переживать завершение раннера).
#
# Код возврата: 0 — все зелёные; 1 — есть падения или нечего запускать.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

REPEAT="${REPEAT:-1}"
VERBOSE="${VERBOSE:-0}"
SERIES_FILTER="${SERIES:-}"
filter="${1:-${SEASON:-}}"

LOGDIR="${ROOT}/tests/logs"
mkdir -p "${LOGDIR}"

# ---- поиск серий -----------------------------------------------------------
if [ -n "${filter}" ]; then
    # shellcheck disable=SC2086
    mapfile -t series < <(find ${filter} -maxdepth 1 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' 2>/dev/null | sort)
else
    mapfile -t series < <(find . -maxdepth 2 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' -not -path './personal/*' 2>/dev/null | sort)
fi

if [ -n "${SERIES_FILTER}" ]; then
    mapfile -t series < <(printf '%s\n' "${series[@]}" | grep -- "${SERIES_FILTER}" || true)
fi

if [ "${#series[@]}" -eq 0 ]; then
    echo "Серий не найдено (сезон: '${filter:-все}', серия: '${SERIES_FILTER:-все}')" >&2
    exit 1
fi

# ---- окружение прогона (§7.3: в CI нужно знать, на чём гоняли) -------------
env_line() {
    printf 'bash %s | %s | %s\n' \
        "${BASH_VERSION%%(*}" \
        "$(uname -srm)" \
        "LANG=${LANG:-unset} LC_ALL=${LC_ALL:-unset} TZ=${TZ:-unset}"
}

pass=0; fail=0; skip=0
failed_list=()
declare -A season_pass season_fail

echo "════════════════════════════════════════════════════════════"
echo " KERNEL SHADOWS — unit-тесты (${#series[@]} серий, повторов: ${REPEAT})"
echo " $(env_line)"
echo "════════════════════════════════════════════════════════════"

# Обнулить логи сезонов, которые будем трогать в этом прогоне.
for dir in "${series[@]}"; do
    season="$(basename "$(dirname "${dir}")")"
    : > "${LOGDIR}/${season}.log"
done

for run in $(seq 1 "${REPEAT}"); do
    [ "${REPEAT}" -gt 1 ] && echo "--- прогон ${run}/${REPEAT} ---"
    for dir in "${series[@]}"; do
        name="$(basename "${dir}")"
        season="$(basename "$(dirname "${dir}")")"
        log="${LOGDIR}/${season}.log"

        if [ ! -f "${dir}/tests/test.sh" ]; then
            printf '  SKIP  %s (нет tests/test.sh)\n' "${name}"
            printf '\n===== %s: SKIP (нет tests/test.sh) =====\n' "${name}" >> "${log}"
            [ "${run}" -eq 1 ] && skip=$((skip + 1))
            continue
        fi

        out="$(bash "${dir}/tests/test.sh" 2>&1)"; rc=$?
        res="$(printf '%s' "${out}" | grep -oE '[0-9]+ passed, [0-9]+ failed' | tail -1)"

        {
            printf '\n===== %s (прогон %s/%s) =====\n' "${name}" "${run}" "${REPEAT}"
            printf '%s\n' "${out}"
        } >> "${log}"

        if [ "${rc}" -eq 0 ]; then
            printf '  PASS  %-32s %s\n' "${name}" "${res}"
            pass=$((pass + 1))
            season_pass["${season}"]=$(( ${season_pass["${season}"]:-0} + 1 ))
        else
            printf '  FAIL  %-32s %s\n' "${name}" "${res:-нет сводки}"
            fail=$((fail + 1))
            failed_list+=("${season}/${name}")
            season_fail["${season}"]=$(( ${season_fail["${season}"]:-0} + 1 ))
            if [ "${VERBOSE}" = "1" ]; then
                printf '%s\n' "${out}" | sed 's/^/        │ /'
            else
                printf '%s\n' "${out}" | grep -E '^\s+FAIL' | sed 's/^/        │ /'
            fi
        fi
    done
done

echo "════════════════════════════════════════════════════════════"
echo " Итог: PASS=${pass}  FAIL=${fail}  SKIP=${skip}"

if [ "${fail}" -gt 0 ]; then
    echo " Упавшие серии:"
    printf '   %s\n' "${failed_list[@]}"
    echo
    echo " Воспроизвести одну серию:"
    echo "   make test SERIES=$(basename "${failed_list[0]#*/}")"
    echo " Полный вывод — в tests/logs/<сезон>.log"
fi

echo " Логи: ${LOGDIR#"${ROOT}"/}/"
echo "════════════════════════════════════════════════════════════"

[ "${fail}" -eq 0 ]
