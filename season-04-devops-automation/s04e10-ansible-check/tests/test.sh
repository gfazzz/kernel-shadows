#!/usr/bin/env bash
#
# s04e10 «Что изменится» — тест находок (Type C).
#
# Ни одного ожидаемого значения не зашито: каждое пересчитывается из
# data/ansible_check_prod.txt прямо здесь и сравнивается с тем, что написал
# студент. Подмените снимок — изменятся и эталонные ответы.
#
# Отдельно проверяется, что задача не выродилась: в снимке должны
# оставаться недоступные хосты, пропущенные задачи и разрыв между
# «задачей, которая меняется чаще всего» и «хостом, где меняется больше всего».
#
# Без root, без сети, **без ansible**.
#
# Выбор отчёта: SUBJECT=... | artifacts/plan_report.txt | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data/ansible_check_prod.txt"
STARTER="${SERIES_DIR}/starter/plan_report.txt"

if   [ -n "${SUBJECT:-}" ];                                then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/plan_report.txt" ];     then REP="${SERIES_DIR}/artifacts/plan_report.txt"
elif [ -f "${SERIES_DIR}/plan_report.txt" ];               then REP="${SERIES_DIR}/plan_report.txt"
else REP="${SERIES_DIR}/solution/plan_report.txt"
     echo "ℹ️  Своего plan_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/plan_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e10 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${D}" ] || { echo "  FAIL: нет снимка ${D}"; exit 1; }
if [ -f "${REP}" ]; then ok "plan_report.txt найден"
else no "plan_report.txt не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

got() { awk -F= -v k="$1" '
    /^[[:space:]]*#/ {next}
    $1 == k {sub(/^[^=]*=/, ""); gsub(/^[[:space:]]+|[[:space:]]+$/, ""); print; exit}' "${REP}"; }

check() {  # check <ключ> <ожидание> <пояснение>
    local k="$1" want="$2" why="$3" have
    have="$(got "${k}")"
    if [ -z "${have}" ]; then
        no "${k}: не заполнено (${why})"
    elif [ "${have}" = "${want}" ]; then
        ok "${k}=${have}"
    else
        no "${k}=${have}, а из снимка следует ${want} — ${why}"
    fi
}

# ---- пересчёт из снимка -------------------------------------------------------
RECAP="$(awk '/^PLAY RECAP \*/ {r=1; next} r' "${D}" | grep 'changed=')"

E_HOSTS="$(printf '%s\n' "${RECAP}" | grep -c .)"
E_UNREACH="$(printf '%s\n' "${RECAP}" | grep -c 'unreachable=[1-9]')"
E_CHANGED="$(printf '%s\n' "${RECAP}" | grep -vc 'changed=0')"
E_ZERO="$(printf '%s\n' "${RECAP}" | grep 'changed=0' | grep -c 'unreachable=0')"
E_TASKS="$(grep -c '^TASK \[' "${D}")"
E_REACH=$((E_HOSTS - E_UNREACH))

# задачи, пропущенные на всех доступных хостах
SKIPPED_TASKS="$(awk -v n="${E_REACH}" '
    /^TASK \[/ {t = $0; gsub(/^TASK \[|[[:space:]]*\].*$/, "", t)}
    /^skipping: \[/ {s[t]++}
    END {for (k in s) if (s[k] == n) print k}' "${D}" | sort)"
E_SKIPPED="$(printf '%s\n' "${SKIPPED_TASKS}" | grep -c . || true)"

# модуль этих задач — из фрагмента playbook в конце снимка
E_MODULE="$(for t in ${SKIPPED_TASKS}; do
        short="${t##*: }"
        awk -v n="${short}" '
            $0 ~ ("- name: " n "$") {f=1; next}
            f && /ansible\.builtin\./ {
                match($0, /ansible\.builtin\.[a-z_]+/)
                s = substr($0, RSTART, RLENGTH); sub(/ansible\.builtin\./, "", s)
                print s; exit}' "${D}"
    done | sort -u)"

# задача с наибольшим числом изменений
TOP="$(awk '
    /^TASK \[/ {t = $0; gsub(/^TASK \[|[[:space:]]*\].*$/, "", t)}
    /^changed: \[/ {c[t]++}
    END {for (k in c) printf "%d\t%s\n", c[k], k}' "${D}" | sort -rn | head -1)"
E_TOPN="$(printf '%s' "${TOP}" | cut -f1)"
E_TOP="$(printf '%s' "${TOP}" | cut -f2)"; E_TOP="${E_TOP##*: }"

# хост с наибольшим числом изменившихся задач
DRIFT="$(printf '%s\n' "${RECAP}" | awk '
    {n = $0; sub(/.*changed=/, "", n); sub(/[^0-9].*/, "", n)
     h = $1
     if (n + 0 > best) {best = n + 0; bh = h}}
    END {printf "%d\t%s\n", best, bh}')"
E_DRIFTN="$(printf '%s' "${DRIFT}" | cut -f1)"
E_DRIFT="$(printf '%s' "${DRIFT}" | cut -f2)"

# находки из diff
E_KEY="$(grep -E '^-ssh-(ed25519|rsa) ' "${D}" | head -1 | awk '{print $NF}')"
E_SSHD="$(awk '/sshd_config/ {f=1} f && /^-[A-Za-z]/ {sub(/^-/, ""); print $1; exit}' "${D}")"
E_MODE="$(awk '/etc\/ssl\/private/ {f=1} f && /^-.*"mode"/ {
              match($0, /[0-7]{4}/); print substr($0, RSTART, RLENGTH); exit}' "${D}")"

# ---- сверка -------------------------------------------------------------------
check hosts_in_recap    "${E_HOSTS}"   "в PLAY RECAP столько строк; по строкам задач хостов меньше — недоступные в них не участвуют"
check unreachable_hosts "${E_UNREACH}" "строки с unreachable=1 в PLAY RECAP"
check changed_hosts     "${E_CHANGED}" "строки PLAY RECAP, где changed НЕ равно нулю"
check unchanged_hosts   "${E_ZERO}"    "доступные хосты с changed=0: они уже совпадают с описанием"
check tasks_total       "${E_TASKS}"   "строк TASK [ в снимке"
check tasks_skipped_all "${E_SKIPPED}" "задач, пропущенных на всех ${E_REACH} доступных хостах"
check blind_module      "${E_MODULE}"  "модуль этих задач по фрагменту playbook в конце снимка"
check top_task          "${E_TOP}"     "задача с наибольшим числом строк changed:"
check top_task_changed  "${E_TOPN}"    "на стольких хостах она меняется"
check drift_host        "${E_DRIFT}"   "строка PLAY RECAP с наибольшим changed="
check drift_tasks       "${E_DRIFTN}"  "столько задач изменилось бы на этом хосте"
check unknown_key_comment "${E_KEY}"   "последнее поле строки ключа, которую ansible убрал бы"
check sshd_directive    "${E_SSHD}"    "имя директивы в строке diff со знаком минус"
check ssl_mode_current  "${E_MODE}"    "текущие права каталога с закрытыми ключами"

# ---- форма отчёта -------------------------------------------------------------
KEYS="hosts_in_recap unreachable_hosts changed_hosts unchanged_hosts tasks_total
tasks_skipped_all blind_module top_task top_task_changed drift_host drift_tasks
unknown_key_comment sshd_directive ssl_mode_current"
missing=""
for k in ${KEYS}; do grep -qE "^${k}=" "${REP}" || missing="${missing} ${k}"; done
if [ -z "${missing}" ]; then ok "все 14 ключей на месте"
else no "нет ключей:${missing}"; fi
if grep -qE '^[a-z_]+=[[:space:]]*(TODO|\?|-)[[:space:]]*$' "${REP}"; then
    no "остались заглушки вместо значений"
else
    ok "заглушек не осталось"
fi

# ---- самопроверки: задача не выродилась ---------------------------------------
if [ "${E_UNREACH}" -ge 1 ]; then
    ok "самопроверка: в снимке есть недоступные хосты (${E_UNREACH}) — счёт по задачам их теряет"
else
    no "самопроверка: недоступных хостов нет, ловушка на подсчёт по задачам не работает"
fi
if [ "${E_SKIPPED}" -ge 1 ] && [ -n "${E_MODULE}" ]; then
    ok "самопроверка: пропущенные задачи в снимке есть, и модуль по playbook определяется"
else
    no "самопроверка: пропущенных задач в снимке не осталось"
fi
if [ "${E_TOPN}" -gt "${E_DRIFTN}" ] && [ "${E_TOP}" != "${E_DRIFT}" ]; then
    ok "самопроверка: «задача меняется чаще всего» (${E_TOPN}) и «на хосте меняется больше всего» (${E_DRIFTN}) — разные вопросы"
else
    no "самопроверка: два вопроса совпали, различать нечего"
fi
if [ "$(grep -c 'changed' "${D}")" -gt "${E_CHANGED}" ]; then
    ok "самопроверка: наивный grep -c changed даёт $(grep -c 'changed' "${D}") вместо ${E_CHANGED}"
else
    no "самопроверка: ловушка наивного подсчёта исчезла из снимка"
fi
if [ -f "${STARTER}" ] && [ -z "$(SUBJECT="${STARTER}" bash -c 'awk -F= "/^hosts_in_recap=/ {print \$2}" "$0"' "${STARTER}")" ]; then
    ok "самопроверка: стартер пуст — заполнять есть что"
else
    no "самопроверка: в стартере уже стоят ответы"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
