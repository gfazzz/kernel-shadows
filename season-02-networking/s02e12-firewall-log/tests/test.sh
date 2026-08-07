#!/usr/bin/env bash
#
# s02e12 «Стена молчит» (финал Season 2) — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт fwlog_report.txt сверяется
# с журналом фаервола и списком правил из data/. Эталон вычисляется здесь
# же — констант в тесте нет (§4.2, §4.3).
#
# Без root, без сети: разбирается копия вывода journalctl и ufw status.
#
# Выбор отчёта: SUBJECT=... | artifacts/fwlog_report.txt | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
L="${DATA}/ufw_log_moscow1.txt"
S="${DATA}/ufw_status_moscow1.txt"

if   [ -n "${SUBJECT:-}" ];                               then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/fwlog_report.txt" ];   then REPORT="${SERIES_DIR}/artifacts/fwlog_report.txt"
elif [ -f "${SERIES_DIR}/fwlog_report.txt" ];             then REPORT="${SERIES_DIR}/fwlog_report.txt"
else REPORT="${SERIES_DIR}/solution/fwlog_report.txt"
     echo "ℹ️  Свой fwlog_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/fwlog_report.txt artifacts/fwlog_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e12 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${L}" "${S}"; do
    if [ ! -f "${f}" ]; then echo "  FAIL: не найден объект разведки: ${f}" >&2; exit 1; fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт fwlog_report.txt найден"
else
    no "fwlog_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- эталон: вычисляется из журнала -----------------------------------------
noc()   { grep -vE '^[[:space:]]*#|^[[:space:]]*$' "$1"; }
rows()  { noc "${L}"; }
blk()   { rows | grep '\[UFW BLOCK\]'; }
field() { grep -oE "$1=[^ ]+" | cut -d= -f2; }

exp_blocked=$(blk | grep -c . || true)
exp_limit=$(rows | grep -c '\[UFW LIMIT BLOCK\]' || true)
exp_allow=$(rows | grep -c '\[UFW ALLOW\]' || true)
naive_block=$(rows | grep -c 'BLOCK' || true)
exp_uniq=$(rows | field SRC | sort -u | grep -c . || true)

read -r exp_top_hits exp_top_src <<EOF
$(blk | field SRC | sort | uniq -c | sort -rn | head -1)
EOF
exp_top_port=$(blk | field DPT | sort | uniq -c | sort -rn | awk 'NR==1{print $2}')
naive_port=$(blk | grep -oE 'PT=[0-9]+' | cut -d= -f2 | sort | uniq -c | sort -rn | awk 'NR==1{print $2}')

exp_limit_port=$(rows | grep '\[UFW LIMIT BLOCK\]' | field DPT | sort -u | head -1)
exp_limit_src=$(rows | grep '\[UFW LIMIT BLOCK\]' | field SRC | sort -u | head -1)

vpn_line=$(rows | grep 'DPT=51820' | head -1)
exp_vpn_proto=$(printf '%s' "${vpn_line}" | field PROTO | head -1)
exp_vpn_src=$(printf '%s' "${vpn_line}" | field SRC | head -1)

exp_allow_src=$(rows | grep '\[UFW ALLOW\]' | field SRC | sort -u | head -1)
# правило, по которому он проходит: строка ufw status с его подсетью
exp_allow_rule=$(grep -vE '^[[:space:]]*#' "${S}" \
  | awk -v ip="${exp_allow_src}" '
      { n=split(ip, o, "."); pref=o[1]"."o[2]"."o[3] }
      $0 ~ pref { for (i=1;i<=NF;i++) if ($i ~ ("^" pref "\\.")) { print $i; exit } }')

# атакующий: адрес, по которому сработало ограничение частоты
exp_attacker="${exp_limit_src}"
exp_last=$(rows | grep -F "${exp_attacker}" | tail -1 | awk '{printf "%s %s %s", $1, $2, $3}')

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
    else                                no "${desc}: указано '${got}', в журнале '${want}'"
    fi
}

check blocked         "${exp_blocked}"    "записей UFW BLOCK"
check limit_blocked   "${exp_limit}"      "записей UFW LIMIT BLOCK"
check allowed         "${exp_allow}"      "записей UFW ALLOW"
check unique_sources  "${exp_uniq}"       "разных адресов в журнале"
check top_source      "${exp_top_src}"    "адрес с наибольшим числом блокировок"
check top_source_hits "${exp_top_hits}"   "сколько раз он заблокирован"
check top_port        "${exp_top_port}"   "самый атакуемый порт назначения"
check limit_port      "${exp_limit_port}" "порт под ограничением частоты"
check limit_source    "${exp_limit_src}"  "адрес, по которому сработал limit"
check vpn_scan_proto  "${exp_vpn_proto}"  "протокол сканирования порта VPN"
check vpn_scan_source "${exp_vpn_src}"    "адрес сканера VPN"
check allowed_source  "${exp_allow_src}"  "адрес, чьи пакеты пропускались"
check allowed_by_rule "${exp_allow_rule}" "правило, по которому он проходит"
check attacker        "${exp_attacker}"   "адрес атакующего"
check attacker_last_seen "${exp_last}"    "последняя его запись в журнале"

# ---- согласованность отчёта -------------------------------------------------
if [ "$(val allowed_source)" != "$(val top_source)" ]; then
    ok "самопроверка отчёта: пропущенный адрес и самый шумный — разные"
else
    no "самопроверка отчёта: пропущенный адрес совпал с самым блокируемым"
fi

if [ "$(val blocked)" -gt "$(val limit_blocked)" ] 2>/dev/null; then
    ok "самопроверка отчёта: обычных блокировок больше, чем ограничений частоты"
else
    no "самопроверка отчёта: соотношение BLOCK и LIMIT BLOCK неправдоподобно"
fi

# ---- самопроверки: ловушки в данных на месте --------------------------------
if [ "${naive_block}" -gt "${exp_blocked}" ]; then
    ok "самопроверка данных: grep BLOCK даёт ${naive_block} против ${exp_blocked} — LIMIT BLOCK попадает под шаблон"
else
    no "самопроверка данных: записи LIMIT BLOCK исчезли, различать нечего"
fi

if [ "${naive_port}" != "${exp_top_port}" ]; then
    ok "самопроверка данных: подсчёт по 'PT=' даёт ${naive_port} вместо ${exp_top_port} — SPT портит картину"
else
    no "самопроверка данных: SPT перестал мешать наивному подсчёту"
fi

if rows | grep -q '\[UFW ALLOW\]' && grep -q '185\.14\.29' "${S}"; then
    ok "самопроверка данных: пропускающее правило есть и в журнале, и в ufw status"
else
    no "самопроверка данных: связь журнала с правилами из s02e06 потеряна"
fi

late=$(rows | grep -F "${exp_attacker}" | awk '$2==15 || $2==16' | grep -c . || true)
if [ "${late}" -eq 0 ]; then
    ok "самопроверка данных: после 14 октября атакующий в журнале не появляется"
else
    no "самопроверка данных: атакующий засветился и позже — сюжетный вывод серии ломается"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
