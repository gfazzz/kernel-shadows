#!/usr/bin/env bash
#
# s04e01 «Что помнит репозиторий» — тест разведки (Type C).
#
# Тест САМ восстанавливает учебный репозиторий скриптом из data/ во временном
# каталоге и вычисляет по нему все ожидаемые значения. Репозиторий строится
# с фиксированными датами и авторами, поэтому получается побитово одинаковым
# при каждом запуске — включая хеши коммитов. Констант в тесте нет.
#
# Без root, без сети. Нужен `git` — для серии про git это честная зависимость.
#
# Выбор отчёта: SUBJECT=... | artifacts/history_report.txt | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILDER="${SERIES_DIR}/../data/build_shadow_iac.sh"

if   [ -n "${SUBJECT:-}" ];                                 then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/history_report.txt" ];   then REPORT="${SERIES_DIR}/artifacts/history_report.txt"
elif [ -f "${SERIES_DIR}/history_report.txt" ];             then REPORT="${SERIES_DIR}/history_report.txt"
else REPORT="${SERIES_DIR}/solution/history_report.txt"
     echo "ℹ️  Свой history_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/history_report.txt artifacts/history_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e01 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if ! command -v git >/dev/null 2>&1; then
    echo "  SKIP: git не установлен — серия про git его требует" >&2; exit 0
fi
if [ ! -f "${BUILDER}" ]; then
    echo "  FAIL: не найден сборщик репозитория: ${BUILDER}" >&2; exit 1
fi
if [ -f "${REPORT}" ]; then
    ok "отчёт history_report.txt найден"
else
    no "history_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
R="${TMP}/shadow_iac"
if bash "${BUILDER}" "${R}" >/dev/null 2>"${TMP}/err"; then
    ok "учебный репозиторий восстановлен из data/"
else
    no "сборщик репозитория упал: $(tail -1 "${TMP}/err")"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

g() { git -C "${R}" "$@"; }

# ---- эталон: вычисляется из репозитория --------------------------------------
exp_total=$(g rev-list --count HEAD)
exp_nomerge=$(g rev-list --count --no-merges HEAD)
exp_authors=$(g log --format='%an' | sort -u | grep -c .)
read -r exp_top_n exp_top_name <<EOF
$(g log --format='%an' | sort | uniq -c | sort -rn | head -1 | sed 's/^ *//' | sed 's/ /\t/' | tr '\t' ' ')
EOF
exp_top_name=$(g log --format='%an' | sort | uniq -c | sort -rn | head -1 | sed -E 's/^ *[0-9]+ //')
exp_top_n=$(g log --format='%an' | sort | uniq -c | sort -rn | head -1 | sed -E 's/^ *([0-9]+) .*/\1/')

root=$(g rev-list --max-parents=0 HEAD)
exp_first=$(g rev-parse --short=7 "${root}")
exp_first_date=$(g log -1 --format=%ad --date=short "${root}")

merge=$(g rev-list --merges -1 HEAD)
exp_merge=$(g rev-parse --short=7 "${merge}")
exp_branchpoint=$(g rev-parse --short=7 "$(g merge-base "${merge}^1" "${merge}^2")")
exp_files=$(g ls-files | grep -c .)

# файл, добавленный и позже удалённый, в котором есть похожее на пароль
exp_secret_file=$(g log --all --format='%H' --diff-filter=D --name-only \
    | grep -vE '^[0-9a-f]{40}$' | grep -v '^$' | sort -u | head -1)
exp_secret_add=$(g rev-parse --short=7 "$(g log --all --format='%H' --diff-filter=A -- "${exp_secret_file}" | tail -1)")
exp_secret_del=$(g rev-parse --short=7 "$(g log --all --format='%H' --diff-filter=D -- "${exp_secret_file}" | head -1)")
exp_password=$(g show "${exp_secret_add}:${exp_secret_file}" 2>/dev/null \
    | grep -iE 'password' | head -1 | cut -d= -f2-)

exp_largest=$(g log --no-merges --format='C %h' --numstat \
    | awk '/^C /{h=$2} /^[0-9]/{s[h]+=$1+$2} END{for(k in s) print s[k], k}' \
    | sort -rn | awk 'NR==1{print $2}')

# ---- чтение отчёта студента --------------------------------------------------
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${REPORT}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r//'
}
check() {
    local key="$1" want="$2" desc="$3" got
    got="$(val "${key}")"
    if [ -z "${got}" ];            then no "${desc}: значение не заполнено (${key}=)"
    elif [ "${got}" = "${want}" ]; then ok "${desc}: ${got}"
    else                                no "${desc}: указано '${got}', в репозитории '${want}'"
    fi
}

check total_commits      "${exp_total}"        "коммитов всего"
check commits_no_merges  "${exp_nomerge}"      "коммитов без слияний"
check authors            "${exp_authors}"      "разных авторов"
check top_author         "${exp_top_name}"     "автор с наибольшим числом коммитов"
check top_author_commits "${exp_top_n}"        "сколько у него коммитов"
check first_commit       "${exp_first}"        "первый коммит"
check first_commit_date  "${exp_first_date}"   "его дата"
check branch_point       "${exp_branchpoint}"  "точка расхождения ветки"
check merge_commit       "${exp_merge}"        "коммит слияния"
check files_tracked      "${exp_files}"        "отслеживаемых файлов"
check secret_file        "${exp_secret_file}"  "файл с попавшим в репозиторий паролем"
check secret_added_in    "${exp_secret_add}"   "коммит, где он появился"
check secret_removed_in  "${exp_secret_del}"   "коммит, где его убрали"
check secret_password    "${exp_password}"     "сам пароль, добытый из истории"
check largest_commit     "${exp_largest}"      "коммит с наибольшим числом изменений"

# ---- согласованность отчёта -------------------------------------------------
if [ "$(val total_commits)" -gt "$(val commits_no_merges)" ] 2>/dev/null; then
    ok "самопроверка отчёта: со слияниями коммитов больше, чем без них"
else
    no "самопроверка отчёта: слияние не учтено — числа совпали"
fi

if [ "$(val secret_added_in)" != "$(val secret_removed_in)" ]; then
    ok "самопроверка отчёта: появление и удаление секрета — разные коммиты"
else
    no "самопроверка отчёта: секрет якобы появился и исчез в одном коммите"
fi

if printf '%s' "$(val first_commit)" | grep -qE '^[0-9a-f]{7}$'; then
    ok "самопроверка отчёта: хеши записаны семью символами"
else
    no "самопроверка отчёта: '$(val first_commit)' не похож на короткий хеш из семи символов"
fi

# ---- самопроверки: репозиторий устроен как задумано --------------------------
if [ ! -e "${R}/${exp_secret_file}" ] && g cat-file -e "${exp_secret_add}:${exp_secret_file}" 2>/dev/null; then
    ok "самопроверка данных: секрета нет в рабочем дереве, но он есть в истории"
else
    no "самопроверка данных: секрет либо остался на диске, либо исчез из истории — смысл серии пропал"
fi

if [ "$(g rev-list --count HEAD)" -ne "$(g rev-list --count --no-merges HEAD)" ]; then
    ok "самопроверка данных: слияние в истории есть"
else
    no "самопроверка данных: слияния нет, ловушка с подсчётом исчезла"
fi

bp_naive=$(g rev-parse --short=7 "$(g merge-base main monitoring 2>/dev/null || echo "${merge}")")
if [ "${bp_naive}" != "${exp_branchpoint}" ]; then
    ok "самопроверка данных: merge-base main monitoring даёт ${bp_naive} вместо ${exp_branchpoint} — ловушка на месте"
else
    no "самопроверка данных: точка расхождения стала вычисляться наивно"
fi

if [ "$(bash "${BUILDER}" "${TMP}/again" >/dev/null 2>&1; git -C "${TMP}/again" rev-parse HEAD 2>/dev/null)" \
   = "$(g rev-parse HEAD)" ]; then
    ok "самопроверка данных: повторная сборка даёт тот же хеш — репозиторий воспроизводим"
else
    no "самопроверка данных: сборка не воспроизводима, хеши в вопросах бессмысленны"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
