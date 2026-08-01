#!/usr/bin/env bash
#
# s02e06 «Что у нас вообще открыто» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт fw_report.txt сверяется с реальным
# содержимым объекта разведки — снимка `ufw status verbose` из data/, плюс снимка
# `ss -tuln` из s02e02. Эталон вычисляется здесь же командами: в тесте нет ни одного
# захардкоженного значения (§4.2, §4.3).
#
# Без root, без сети. Объект разведки лежит в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/fw_report.txt | <серия>/fw_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
FW="${DATA}/ufw_status_moscow1.txt"
SNAP="${DATA}/ss_listen_moscow1.txt"

if   [ -n "${SUBJECT:-}" ];                         then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/fw_report.txt" ];then REPORT="${SERIES_DIR}/artifacts/fw_report.txt"
elif [ -f "${SERIES_DIR}/fw_report.txt" ];          then REPORT="${SERIES_DIR}/fw_report.txt"
else REPORT="${SERIES_DIR}/solution/fw_report.txt"
     echo "ℹ️  Свой fw_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/fw_report.txt artifacts/fw_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e06 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- предусловия -----------------------------------------------------------
for f in "${FW}" "${SNAP}"; do
    if [ ! -f "${f}" ]; then
        echo "  FAIL: не найден объект разведки: ${f}" >&2
        exit 1
    fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт fw_report.txt найден"
else
    no "fw_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из снимков ----------------------------------------
allow_rules() { grep -E '[[:space:]]ALLOW' "${FW}"; }
port_col()    { awk '{print $1}' | sed 's|/.*||' | grep -E '^[0-9]+$'; }

exp_default=$(grep -i '^Default:' "${FW}" | sed 's/.*Default: *//' | tr ',' '\n' \
                | grep -i 'incoming' | awk '{print $1}' | tr -d ' ')
exp_allow=$(grep -cE '[[:space:]]ALLOW' "${FW}" | tr -d ' ')
exp_deny=$(grep -cE '[[:space:]]DENY' "${FW}" | tr -d ' ')
exp_world=$(allow_rules | grep -E 'Anywhere' | port_col | sort -un | paste -sd, - | tr -d ' ')
exp_lan=$(allow_rules | grep -E '10\.50\.0\.0/24' | port_col | sort -un | paste -sd, - | tr -d ' ')
exp_blanket=$(allow_rules | awk '$1=="Anywhere"{print $NF}' | head -1 | tr -d ' ')

sensitive="3306 5432 6379 9200 27017 11211"
exp_sens=""
for p in $(allow_rules | grep -E 'Anywhere' | port_col | sort -un); do
    for s in ${sensitive}; do [ "${p}" = "${s}" ] && exp_sens="${exp_sens},${p}"; done
done
exp_sens="${exp_sens#,}"

ruled=$(allow_rules | port_col | sort -un)
exp_unruled=""
for p in $(awk '/^LISTEN/{print $4}' "${SNAP}" | grep -E '^(0\.0\.0\.0|\[::\]):' \
             | sed 's/.*://' | grep -E '^[0-9]+$' | sort -un); do
    printf '%s\n' "${ruled}" | grep -qxF "${p}" || exp_unruled="${exp_unruled},${p}"
done
exp_unruled="${exp_unruled#,}"

# Фаервол защищает что-либо только при политике deny для входящих.
if printf '%s' "${exp_default}" | grep -qi '^deny$'; then exp_effective="yes"; else exp_effective="no"; fi

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

check default_incoming      "${exp_default}"   "политика по умолчанию (входящие)"
check allow_lines           "${exp_allow}"     "строк ALLOW"
check deny_lines            "${exp_deny}"      "строк DENY"
check open_to_world         "${exp_world}"     "порты, открытые из интернета"
check open_to_lan           "${exp_lan}"       "порты только для внутренней сети"
check exposed_sensitive     "${exp_sens}"      "чувствительные наружу"
check blanket_allow_from    "${exp_blanket}"   "источник правила «разрешить всё»"
check listening_but_unruled "${exp_unruled}"   "слушают наружу, но правил нет"
check firewall_effective    "${exp_effective}" "защищает ли фаервол при такой политике"

# ---- самопроверки: задание не должно быть вырожденным ----------------------
uniq_ports=$(allow_rules | port_col | sort -un | wc -l | tr -d ' ')
if [ "${exp_allow}" -gt "${uniq_ports}" ]; then
    ok "самопроверка: ${exp_allow} строк ALLOW против ${uniq_ports} портов — дубли (v6) есть"
else
    no "самопроверка: в снимке нет дублей (v6), задание вырождено"
fi

if [ -n "${exp_blanket}" ]; then
    ok "самопроверка: правило «разрешить всё с подсети» в снимке присутствует"
else
    no "самопроверка: в снимке нет правила без указания порта, задание вырождено"
fi

if [ -n "${exp_unruled}" ]; then
    ok "самопроверка: снимки ss и ufw расходятся (${exp_unruled}) — есть что найти"
else
    no "самопроверка: расхождения между ss и ufw нет, задание вырождено"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
