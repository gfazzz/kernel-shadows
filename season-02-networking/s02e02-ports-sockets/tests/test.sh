#!/usr/bin/env bash
#
# s02e02 «Что слушает на сервере» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт ports_report.txt сверяется
# с реальным содержимым объекта разведки — снимка `ss -tuln`, лежащего в data/.
# Эталон вычисляется здесь же командами: в тесте нет ни одного захардкоженного
# числа, поэтому правка учебных данных не разъезжается с проверкой.
#
# Без root, без сети. Объект разведки лежит в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/ports_report.txt | <серия>/ports_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
SNAP="${DATA}/ss_listen_moscow1.txt"
ALLOW="${DATA}/allowed_ports.txt"
KNOWN="${DATA}/known_services.txt"

if   [ -n "${SUBJECT:-}" ];                            then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/ports_report.txt" ];then REPORT="${SERIES_DIR}/artifacts/ports_report.txt"
elif [ -f "${SERIES_DIR}/ports_report.txt" ];          then REPORT="${SERIES_DIR}/ports_report.txt"
else REPORT="${SERIES_DIR}/solution/ports_report.txt"
     echo "ℹ️  Свой ports_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/ports_report.txt artifacts/ports_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e02 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- предусловия -----------------------------------------------------------
for f in "${SNAP}" "${ALLOW}" "${KNOWN}"; do
    if [ ! -f "${f}" ]; then
        echo "  FAIL: не найден объект разведки: ${f}" >&2
        exit 1
    fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт ports_report.txt найден"
else
    no "ports_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из снимка -----------------------------------------
listen_addrs() { awk '/^LISTEN/{print $4}' "${SNAP}"; }
ports_of()     { sed 's/.*://' | grep -E '^[0-9]+$'; }

exp_lines=$(grep -c '^LISTEN' "${SNAP}" | tr -d ' ')
exp_unique=$(listen_addrs | ports_of | sort -un | wc -l | tr -d ' ')
exp_all=$(listen_addrs | ports_of | sort -un | paste -sd, - | tr -d ' ')
exp_public=$(listen_addrs | grep -E '^(0\.0\.0\.0|\[::\]):' | ports_of | sort -un | paste -sd, - | tr -d ' ')
exp_loop=$(listen_addrs | grep -E '^127\.0\.0\.' | ports_of | sort -un | paste -sd, - | tr -d ' ')
exp_metrics=$(listen_addrs | grep ':9100$' | head -1 | tr -d ' ')

allow_list=$(grep -vE '^[[:space:]]*(#|$)' "${ALLOW}" | tr -d ' ')
known_list=$(awk '!/^[[:space:]]*#/ && NF {print $1}' "${KNOWN}")

exp_unexp=""
for p in $(listen_addrs | ports_of | sort -un); do
    printf '%s\n' "${allow_list}" | grep -qxF "${p}" || exp_unexp="${exp_unexp},${p}"
done
exp_unexp="${exp_unexp#,}"

sensitive="3306 5432 6379 9200 27017 11211"
exp_sens=""
for p in $(listen_addrs | grep -E '^(0\.0\.0\.0|\[::\]):' | ports_of | sort -un); do
    for s in ${sensitive}; do [ "${p}" = "${s}" ] && exp_sens="${exp_sens},${p}"; done
done
exp_sens="${exp_sens#,}"

exp_suspect=""
for p in $(listen_addrs | grep -E '^(0\.0\.0\.0|\[::\]):' | ports_of | sort -un); do
    printf '%s\n' "${known_list}" | grep -qxF "${p}" || exp_suspect="${exp_suspect},${p}"
done
exp_suspect="${exp_suspect#,}"

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

check listen_lines      "${exp_lines}"    "строк LISTEN в снимке"
check unique_ports      "${exp_unique}"   "уникальных портов"
check all_ports         "${exp_all}"      "все порты"
check public_ports      "${exp_public}"   "порты, открытые наружу"
check loopback_ports    "${exp_loop}"     "порты только на петле"
check unexpected_ports  "${exp_unexp}"    "портов нет в allowlist"
check exposed_sensitive "${exp_sens}"     "чувствительные наружу"
check metrics_bind      "${exp_metrics}"  "привязка экспортёра метрик"
check suspect_port      "${exp_suspect}"  "порт, который никто не поднимал"

# ---- самопроверки: задание не должно быть вырожденным ----------------------
if [ "${exp_lines}" -gt "${exp_unique}" ]; then
    ok "самопроверка: строк ${exp_lines} против ${exp_unique} портов — дубли IPv6 присутствуют"
else
    no "самопроверка: в снимке нет дублей IPv4/IPv6, задание вырождено"
fi

if printf '%s' "${exp_public}" | grep -q . && printf '%s' "${exp_loop}" | grep -q .; then
    ok "самопроверка: в снимке есть и публичные, и локальные привязки"
else
    no "самопроверка: снимок не различает привязки, задание вырождено"
fi

# метрики привязаны к адресу интерфейса — значит, не попадают ни в один из двух списков
mport="${exp_metrics##*:}"
if ! printf '%s' "${exp_public},${exp_loop}" | tr ',' '\n' | grep -qx "${mport}"; then
    ok "самопроверка: порт ${mport} привязан к адресу интерфейса, а не к 0.0.0.0 или петле"
else
    no "самопроверка: привязка к конкретному адресу в снимке отсутствует"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
