#!/usr/bin/env bash
#
# s01e10 «Океан логов» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт attack_report.txt сверяется
# с реальным содержимым журнала data/access.log. Эталон вычисляется здесь же
# командами — в тесте нет ни одного захардкоженного числа, поэтому при замене
# учебных данных проверка не разъезжается с реальностью (§4.2, §4.3).
#
# Без root, без сети. Объект разведки лежит в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/attack_report.txt | <серия>/attack_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${SERIES_DIR}/../data/access.log"

if   [ -n "${SUBJECT:-}" ];                             then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/attack_report.txt" ];then REPORT="${SERIES_DIR}/artifacts/attack_report.txt"
elif [ -f "${SERIES_DIR}/attack_report.txt" ];          then REPORT="${SERIES_DIR}/attack_report.txt"
else REPORT="${SERIES_DIR}/solution/attack_report.txt"
     echo "ℹ️  Свой attack_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/attack_report.txt artifacts/attack_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e10 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- предусловия -----------------------------------------------------------
if [ ! -f "${LOG}" ]; then
    echo "  FAIL: объект разведки не найден: ${LOG}" >&2
    exit 1
fi
if [ -f "${REPORT}" ]; then
    ok "отчёт attack_report.txt найден"
else
    no "attack_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из журнала ----------------------------------------
status_count() { grep -c "\" $1 " "${LOG}" || true; }

exp_total=$(wc -l < "${LOG}" | tr -d ' ')
exp_200=$(status_count 200)
exp_susp=$(grep -vc '" 200 ' "${LOG}" || true)
exp_401=$(status_count 401)
exp_403=$(status_count 403)
exp_404=$(status_count 404)
exp_500=$(status_count 500)
exp_503=$(status_count 503)
exp_sqli=$(grep -c 'UNION SELECT' "${LOG}" || true)
exp_scanner=$(grep -c 'scanner' "${LOG}" || true)
exp_minute=$(grep -c '04/Oct/2025:03:47' "${LOG}" || true)

# ---- чтение отчёта студента ------------------------------------------------
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${REPORT}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- | tr -d ' \t\r'
}

check() {  # check <ключ> <эталон> <описание>
    local key="$1" want="$2" desc="$3" got
    got="$(val "${key}")"
    if [ -z "${got}" ]; then
        no "${desc}: значение не заполнено (${key}=)"
    elif [ "${got}" = "${want}" ]; then
        ok "${desc}: ${got}"
    else
        no "${desc}: указано '${got}', в журнале '${want}'"
    fi
}

check total_requests         "${exp_total}"   "всего запросов"
check requests_200           "${exp_200}"     "успешных (200)"
check suspicious_requests    "${exp_susp}"    "подозрительных (не 200)"
check count_401              "${exp_401}"     "статус 401"
check count_403              "${exp_403}"     "статус 403"
check count_404              "${exp_404}"     "статус 404"
check count_500              "${exp_500}"     "статус 500"
check count_503              "${exp_503}"     "статус 503"
check sqli_attempts          "${exp_sqli}"    "попыток SQL-инъекции"
check scanner_requests       "${exp_scanner}" "запросов от сканера"
check attack_minute_requests "${exp_minute}"  "запросов в минуту пика 03:47"

# ---- согласованность: части должны давать целое ----------------------------
sum_val=$(( $(val requests_200 2>/dev/null || echo 0) + $(val suspicious_requests 2>/dev/null || echo 0) ))
if [ "${sum_val}" -eq "${exp_total}" ]; then
    ok "самопроверка отчёта: 200 + не-200 = всего (${exp_total})"
else
    no "самопроверка отчёта: сумма успешных и подозрительных не равна общему числу"
fi

# ---- самопроверки: ловушки в данных существуют -----------------------------
naive_404=$(grep -c ' 404 ' "${LOG}" || true)
naive_500=$(grep -c ' 500 ' "${LOG}" || true)
if [ "${naive_404}" -ne "${exp_404}" ] && [ "${naive_500}" -ne "${exp_500}" ]; then
    ok "самопроверка данных: наивный шаблон завышает 404 (${naive_404}) и 500 (${naive_500})"
else
    no "самопроверка данных: ловушка «размер ответа как статус» исчезла, задание ослабло"
fi

if [ "${exp_sqli}" -gt 0 ] && [ "${exp_minute}" -gt 0 ]; then
    ok "самопроверка данных: следы инъекций и пик атаки в журнале присутствуют"
else
    no "самопроверка данных: в журнале нет ни инъекций, ни пика — задание вырождено"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
