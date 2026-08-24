#!/usr/bin/env bash
#
# s02e04 «Кто отвечает на вопрос где» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт dns_report.txt сверяется
# с записанными ответами dig из data/dig_capture_ops.txt. Эталон вычисляется
# здесь же командами — констант в тесте нет.
#
# Без root, без сети: ответы DNS уже получены и лежат в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/dns_report.txt | <серия>/dns_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CAP="${SERIES_DIR}/../data/dig_capture_ops.txt"

if   [ -n "${SUBJECT:-}" ];                          then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/dns_report.txt" ];then REPORT="${SERIES_DIR}/artifacts/dns_report.txt"
elif [ -f "${SERIES_DIR}/dns_report.txt" ];          then REPORT="${SERIES_DIR}/dns_report.txt"
else REPORT="${SERIES_DIR}/solution/dns_report.txt"
     echo "ℹ️  Свой dns_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/dns_report.txt artifacts/dns_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e04 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- предусловия -----------------------------------------------------------
if [ ! -f "${CAP}" ]; then
    echo "  FAIL: объект разведки не найден: ${CAP}" >&2
    exit 1
fi
if [ -f "${REPORT}" ]; then
    ok "отчёт dns_report.txt найден"
else
    no "dns_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из записанных ответов -----------------------------
sec() {  # sec "<домен> <тип>" — вырезать одну секцию снимка
    awk -v h=";; ===== dig $1 =====" '$0==h{f=1;next} /^;; =====/{f=0} f' "${CAP}"
}

exp_a=$(sec "ops.internal A" | awk '$4=="A"{print $5}' | sort -t. -k4 -n | paste -sd, - | tr -d ' ')
exp_mx_count=$(sec "ops.internal MX" | awk '$4=="MX"' | wc -l | tr -d ' ')
exp_mx_primary=$(sec "ops.internal MX" | awk '$4=="MX"{print $5, $6}' | sort -n | head -1 | awk '{print $2}')
exp_ns_count=$(sec "ops.internal NS" | awk '$4=="NS"' | wc -l | tr -d ' ')
exp_spf=$(sec "ops.internal TXT" | awk '$4=="TXT"' | tr -d '"' | awk '{print $NF}')
exp_cname=$(sec "www.ops.internal A" | awk '$4=="CNAME"{print $5}')
exp_s5_ip=$(sec "shadow-05.ops.internal A" | awk '$4=="A"{print $5}')
exp_s5_ttl=$(sec "shadow-05.ops.internal A" | awk '$4=="A"{print $2}')

# имя секции, где сервер ответил NXDOMAIN
exp_nx=$(awk '/^;; ===== dig /{name=$4} /status: NXDOMAIN/{print name; exit}' "${CAP}")
# тип запроса, где NOERROR при нулевом ANSWER
exp_empty=$(awk '/^;; ===== dig /{name=$4; type=$5; st=""}
                 /status: NOERROR/{st="ok"}
                 st=="ok" && /ANSWER: 0/{print type; exit}' "${CAP}")

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
        no "${desc}: указано '${got}', в снимке '${want}'"
    fi
}

check a_records          "${exp_a}"          "адреса зоны"
check mx_count           "${exp_mx_count}"   "записей MX"
check mx_primary         "${exp_mx_primary}" "основной почтовый сервер"
check ns_count           "${exp_ns_count}"   "серверов имён"
check spf_policy         "${exp_spf}"        "политика SPF"
check www_cname_target   "${exp_cname}"      "цель CNAME для www"
check shadow05_ip        "${exp_s5_ip}"      "адрес shadow-05"
check shadow05_ttl       "${exp_s5_ttl}"     "TTL записи shadow-05"
check nxdomain_name      "${exp_nx}"         "имя с ответом NXDOMAIN"
check noerror_empty_type "${exp_empty}"      "тип с NOERROR и нулём ответов"

# ---- согласованность отчёта ------------------------------------------------
if [ "$(val nxdomain_name)" != "$(val noerror_empty_type)" ]; then
    ok "самопроверка отчёта: два разных «нет» различены"
else
    no "самопроверка отчёта: NXDOMAIN и пустой NOERROR записаны одинаково"
fi

# ---- самопроверки: снимок содержит то, ради чего написан -------------------
if [ -n "${exp_nx}" ] && [ -n "${exp_empty}" ]; then
    ok "самопроверка данных: в снимке есть и NXDOMAIN, и пустой NOERROR"
else
    no "самопроверка данных: одного из двух «нет» в снимке нет, задание вырождено"
fi

mx_first_in_file=$(sec "ops.internal MX" | awk '$4=="MX"{print $6; exit}')
if [ "${mx_first_in_file}" != "${exp_mx_primary}" ]; then
    ok "самопроверка данных: первая строка MX в ответе — не приоритетный сервер"
else
    no "самопроверка данных: порядок MX совпал с приоритетом, ловушка исчезла"
fi

ttl_other=$(sec "ops.internal A" | awk '$4=="A"{print $2; exit}')
if [ "${exp_s5_ttl}" -lt "${ttl_other}" ]; then
    ok "самопроверка данных: TTL у shadow-05 (${exp_s5_ttl}) короче обычного (${ttl_other})"
else
    no "самопроверка данных: аномально короткий TTL исчез, зацепка для s02e05 потеряна"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
