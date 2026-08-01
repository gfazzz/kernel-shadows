#!/usr/bin/env bash
#
# progress.sh — «где я остановился» (план §7.5).
#
# Серия считается пройденной по ФАКТУ, а не по самоотметке:
#   1) в <серия>/artifacts/ лежит работа студента, и
#   2) тест серии на этой работе зелёный.
#
# Наличие solution/ не засчитывается никогда: эталон лежит в репозитории
# с самого начала, и учитывать его — значит показывать курс пройденным
# у человека, который не открыл ни одного файла.
#
# Прежняя версия читала файл .progress, то есть верила отметкам «я сделал».
# Отметка и результат — разные вещи; здесь считается результат.
#
# Использование:
#   bash tools/progress.sh            # полная картина
#   bash tools/progress.sh --quiet    # только следующая цель (для скриптов)
#   SEASON=season-02-networking …     # ограничиться одним сезоном
#
# Код возврата: 0 всегда — это отчёт, а не проверка.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1
filter="${SEASON:-}"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    G=$'\033[0;32m'; Y=$'\033[1;33m'; D=$'\033[0;90m'; B=$'\033[1m'; N=$'\033[0m'
else
    G=""; Y=""; D=""; B=""; N=""
fi

# ---- сбор сезонов ----------------------------------------------------------
if [ -n "${filter}" ]; then
    mapfile -t seasons < <(find . -maxdepth 1 -type d -name "${filter}" | sort)
else
    mapfile -t seasons < <(find . -maxdepth 1 -type d -name 'season-[0-9][0-9]-*' | sort)
fi

if [ "${#seasons[@]}" -eq 0 ]; then
    echo "Сезонов не найдено (фильтр: '${filter:-все}')" >&2
    exit 0
fi

# ---- статус одной серии ----------------------------------------------------
# not_started — в artifacts/ пусто
# in_progress — работа есть, но тест на ней красный
# done        — работа есть и тест зелёный
series_status() {
    local dir="$1"
    local work_count
    work_count=$(find "${dir}/artifacts" -mindepth 1 -maxdepth 1 \
                   ! -name '.gitkeep' ! -name '.DS_Store' 2>/dev/null | wc -l | tr -d ' ')
    if [ "${work_count:-0}" -eq 0 ]; then
        echo "not_started"; return
    fi
    if [ ! -f "${dir}/tests/test.sh" ]; then
        echo "in_progress"; return
    fi
    if bash "${dir}/tests/test.sh" >/dev/null 2>&1; then
        echo "done"
    else
        echo "in_progress"
    fi
}

bar() {  # bar <сделано> <всего>
    local done_n="${1:-0}" total="${2:-1}" width=12 filled i
    [ "${total}" -eq 0 ] && total=1
    filled=$(( done_n * width / total ))
    # Начатый сезон не должен выглядеть как нетронутый.
    [ "${done_n}" -gt 0 ] && [ "${filled}" -eq 0 ] && filled=1
    printf '['
    for ((i = 0; i < width; i++)); do
        if [ "${i}" -lt "${filled}" ]; then printf '#'; else printf '.'; fi
    done
    printf ']'
}

total_all=0; done_all=0
next_target=""

[ "${QUIET}" -eq 0 ] && {
    echo "════════════════════════════════════════════════════════════"
    echo " KERNEL SHADOWS — прогресс"
    echo "════════════════════════════════════════════════════════════"
}

not_migrated=()

for season in "${seasons[@]}"; do
    mapfile -t series < <(find "${season}" -maxdepth 1 -type d -name 's[0-9][0-9]e[0-9][0-9]-*' | sort)
    if [ "${#series[@]}" -eq 0 ]; then
        # Сезон ещё на схеме episode-NN: считать по сериям нечего.
        not_migrated+=("$(basename "${season}")")
        continue
    fi

    s_total=${#series[@]}; s_done=0
    lines=()

    for dir in "${series[@]}"; do
        name="$(basename "${dir}")"
        st="$(series_status "${dir}")"
        case "${st}" in
            done)        s_done=$((s_done + 1)); lines+=("   ${G}[x]${N} ${name}") ;;
            in_progress) lines+=("   ${Y}[~]${N} ${name} ${D}(работа есть, тест красный)${N}")
                         [ -z "${next_target}" ] && next_target="${season#./}/${name}" ;;
            *)           lines+=("   ${D}[ ] ${name}${N}")
                         [ -z "${next_target}" ] && next_target="${season#./}/${name}" ;;
        esac
    done

    total_all=$(( total_all + s_total ))
    done_all=$(( done_all + s_done ))

    if [ "${QUIET}" -eq 0 ]; then
        title="$(basename "${season}" | sed 's/^season-[0-9]*-//; s/-/ /g')"
        printf '  %-28s %s %s/%s\n' "${title}" "$(bar "${s_done}" "${s_total}")" "${s_done}" "${s_total}"
        # Подробности — только по сезону, который уже начат, но не закончен.
        if [ "${s_done}" -lt "${s_total}" ] && [ "${s_done}" -gt 0 ]; then
            printf '%s\n' "${lines[@]}"
        fi
    fi
done

if [ "${QUIET}" -eq 1 ]; then
    printf '%s\n' "${next_target:-курс пройден}"
    exit 0
fi

if [ "${#not_migrated[@]}" -gt 0 ]; then
    echo "  ${D}Ещё не разбиты на серии (схема episode-NN):${N}"
    for s in "${not_migrated[@]}"; do
        printf '    %s%s%s\n' "${D}" "${s}" "${N}"
    done
fi

echo "────────────────────────────────────────────────────────────"
printf '  Всего: %s %s/%s серий\n' "$(bar "${done_all}" "${total_all}")" "${done_all}" "${total_all}"
if [ -n "${next_target}" ]; then
    echo
    echo "  ${B}Следующая цель:${N} ${next_target}"
    echo "  ${D}Начать:  cd ${next_target} && cat README.md${N}"
else
    echo
    echo "  ${G}Все серии пройдены.${N}"
fi
echo "════════════════════════════════════════════════════════════"
echo " ${D}Засчитывается только работа в artifacts/ с зелёным тестом;${N}"
echo " ${D}наличие solution/ прогрессом не считается.${N}"
