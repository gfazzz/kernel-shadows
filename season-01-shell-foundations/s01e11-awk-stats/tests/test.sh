#!/usr/bin/env bash
#
# s01e11 «Кто стучался чаще всех» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт attackers_report.txt сверяется
# с реальным содержимым журнала data/access.log. Эталон вычисляется здесь же
# командами — в тесте нет ни одного захардкоженного значения (§4.2, §4.3).
#
# Без root, без сети. Объект разведки лежит в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/attackers_report.txt | <серия>/attackers_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${SERIES_DIR}/../data/access.log"

if   [ -n "${SUBJECT:-}" ];                                then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/attackers_report.txt" ];then REPORT="${SERIES_DIR}/artifacts/attackers_report.txt"
elif [ -f "${SERIES_DIR}/attackers_report.txt" ];          then REPORT="${SERIES_DIR}/attackers_report.txt"
else REPORT="${SERIES_DIR}/solution/attackers_report.txt"
     echo "ℹ️  Свой attackers_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/attackers_report.txt artifacts/attackers_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e11 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- предусловия -----------------------------------------------------------
if [ ! -f "${LOG}" ]; then
    echo "  FAIL: объект разведки не найден: ${LOG}" >&2
    exit 1
fi
if [ -f "${REPORT}" ]; then
    ok "отчёт attackers_report.txt найден"
else
    no "attackers_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из журнала ----------------------------------------
ip_rank() { awk '{print $1}' "${LOG}" | sort | uniq -c | sort -rn; }
statuses() { awk -F'"' '{print $3}' "${LOG}" | awk '{print $1}'; }

exp_unique=$(awk '{print $1}' "${LOG}" | sort -u | wc -l | tr -d ' ')
exp_top_ip=$(ip_rank | head -1 | awk '{print $2}')
exp_top_req=$(ip_rank | head -1 | awk '{print $1}')
exp_top3=$(ip_rank | head -3 | awk '{print $2}' | paste -sd, - | tr -d ' ')
exp_top_url=$(awk -F'"' '{print $2}' "${LOG}" | awk '{print $2}' \
                | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
exp_403_naive=$(awk '{print $9}' "${LOG}" | grep -c '^403$' || true)
exp_403_true=$(statuses | grep -c '^403$' || true)
exp_distinct=$(statuses | sort -u | wc -l | tr -d ' ')
exp_peak_ip=$(grep '04/Oct/2025:03:47' "${LOG}" | awk '{print $1}' \
                | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')
exp_peak_req=$(grep '04/Oct/2025:03:47' "${LOG}" | awk '{print $1}' \
                | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')

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

check unique_ips           "${exp_unique}"    "уникальных адресов"
check top_ip               "${exp_top_ip}"    "самый активный адрес"
check top_ip_requests      "${exp_top_req}"   "его запросов"
check top3_ips             "${exp_top3}"      "тройка лидеров"
check top_url              "${exp_top_url}"   "самый запрашиваемый путь"
check status_403_by_field9 "${exp_403_naive}" "403 по полю \$9 (наивно)"
check status_403_correct   "${exp_403_true}"  "403 при разборе по кавычкам"
check distinct_statuses    "${exp_distinct}"  "разных статусов"
check peak_top_ip          "${exp_peak_ip}"   "лидер минуты пика"
check peak_top_ip_requests "${exp_peak_req}"  "его запросов за минуту"

# ---- согласованность отчёта ------------------------------------------------
got_naive="$(val status_403_by_field9)"; got_true="$(val status_403_correct)"
if [ -n "${got_naive}" ] && [ -n "${got_true}" ] && [ "${got_naive}" != "${got_true}" ]; then
    ok "самопроверка отчёта: два способа подсчёта дали разные числа — расхождение замечено"
else
    no "самопроверка отчёта: наивный и правильный подсчёт совпали — один из них взят не тем способом"
fi

first_of_top3="$(val top3_ips | cut -d, -f1)"
if [ "${first_of_top3}" = "$(val top_ip)" ]; then
    ok "самопроверка отчёта: первый в тройке совпадает с лидером"
else
    no "самопроверка отчёта: тройка лидеров не согласована с top_ip"
fi

# ---- самопроверки: ловушка в данных существует -----------------------------
if [ "${exp_403_naive}" -ne "${exp_403_true}" ]; then
    ok "самопроверка данных: поле \$9 теряет $(( exp_403_true - exp_403_naive )) запросов из-за пробелов в запросе"
else
    no "самопроверка данных: строк со сдвигом полей нет, задание вырождено"
fi

naive_distinct=$(awk '{print $9}' "${LOG}" | sort -u | wc -l | tr -d ' ')
if [ "${naive_distinct}" -gt "${exp_distinct}" ]; then
    ok "самопроверка данных: наивный разбор выдаёт ${naive_distinct} «статусов» вместо ${exp_distinct}"
else
    no "самопроверка данных: мусорные значения статуса исчезли, задание ослабло"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
