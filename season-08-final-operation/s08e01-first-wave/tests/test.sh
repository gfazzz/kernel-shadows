#!/usr/bin/env bash
#
# s08e01 «Первая волна» — тест находок (Type C).
#
# Проверяет разбор, а не скрипт: каждое значение отчёта пересчитывается из
# снимков в data/. Констант нет — поменяются снимки, поменяются ожидания.
#
# Отдельно проверяется, что данные не выродились: полоса НЕ насыщена
# (иначе приговор читался бы с одного числа), запросы приложения падают
# при растущих пакетах (иначе не отличить от наплыва) и среди источников
# есть настоящие клиенты (иначе доля рукопожатий была бы ровно нулём).
#
# Все величины целые: проценты с плавающей точкой между машинами и
# локалями не сравнивают (§4.3 плана).
#
# Без root, без сети.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
TR="${D}/traffic_5m.txt"; HT="${D}/http_rate.txt"; BS="${D}/baseline.txt"
NS="${D}/nstat.txt";      SS="${D}/ss_state.txt"; SRC="${D}/sources.txt"
LIM="${D}/limits.txt"

if   [ -n "${SUBJECT:-}" ];                                 then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/traffic_verdict.txt" ];  then REP="${SERIES_DIR}/artifacts/traffic_verdict.txt"
elif [ -f "${SERIES_DIR}/traffic_verdict.txt" ];            then REP="${SERIES_DIR}/traffic_verdict.txt"
else REP="${SERIES_DIR}/solution/traffic_verdict.txt"
     echo "ℹ️  Своего traffic_verdict.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/traffic_verdict.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e01 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${TR}" "${HT}" "${BS}" "${NS}" "${SS}" "${SRC}" "${LIM}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
[ -f "${REP}" ] || { echo "  FAIL: нет ${REP}"; echo " Итог: 0 passed, 1 failed"; exit 1; }

# ── чтение отчёта студента ───────────────────────────────────────────
val() { awk -F= -v k="$1" '{sub(/#.*/,"")} $1==k {gsub(/[ \t\r]/,"",$2); print $2; exit}' "${REP}"; }

# ── величины из снимков ──────────────────────────────────────────────
# Пик берётся по пакетам: это та строка, в которой атака сильнее всего.
read -r P_PPS P_MBPS P_SYN <<<"$(awk '{sub(/#.*/,"")} NF>=4 && $2+0>0 {
    if ($2+0 > m) { m=$2+0; a=$2; b=$3; c=$4 } } END {print a, b, c}' "${TR}")"
key() { awk -v k="$1" '{sub(/#.*/,"")} $1==k {print $2; exit}' "$2"; }

B_PPS="$(key pps_p50 "${BS}")";        B_HTTP="$(key http_rps_p50 "${BS}")"
B_ESTAB="$(key estab_p50 "${BS}")"
UPLINK="$(key uplink_capacity_mbps "${LIM}")"; BACKLOG="$(key listen_backlog "${LIM}")"
NICPPS="$(key nic_pps_capacity "${LIM}")"
CK_SENT="$(key TcpExtSyncookiesSent "${NS}")"; CK_RECV="$(key TcpExtSyncookiesRecv "${NS}")"
OVERFLOW="$(key TcpExtListenOverflows "${NS}")"
SYNRECV="$(key SYN-RECV "${SS}")";     ESTAB="$(key ESTAB "${SS}")"
HTTP_NOW="$(awk '{sub(/#.*/,"")} NF>=3 {r=$2} END {print r}' "${HT}")"

E_GROWTH=$(( P_PPS / B_PPS ))
E_AVGB=$(( P_MBPS * 1000000 / 8 / P_PPS ))
E_SYNPCT=$(( P_SYN * 100 / P_PPS ))
E_UPLINK=$(( P_MBPS * 100 / UPLINK ))
E_NIC=$(( P_PPS * 100 / NICPPS ))
E_CKPCT=$(( CK_RECV * 100 / CK_SENT ))
E_ESTABDROP=$(( (B_ESTAB - ESTAB) * 100 / B_ESTAB ))
E_HTTPDROP=$(( (B_HTTP - HTTP_NOW) * 100 / B_HTTP ))

read -r S_TOTAL S_ZERO S_ASN S_TOP <<<"$(awk '{sub(/#.*/,"")} NF>=5 {
        n++; if ($3+0==0) z++; c[$4]++ }
    END { m=0; for (a in c) { k++; if (c[a]>m) m=c[a] }
          print n, z*100/n, k, m*100/n }' "${SRC}")"
S_ZERO=${S_ZERO%.*}; S_TOP=${S_TOP%.*}

echo ""
echo "── 0. Данные не выродились ──"
[ "${E_UPLINK}" -lt 50 ] && ok "полоса не насыщена (${E_UPLINK} %) — приговор нельзя прочитать с одного числа" \
    || no "данные вырождены: канал занят на ${E_UPLINK} %, разбирать нечего"
[ "${E_AVGB}" -lt 100 ] && ok "средний пакет мелкий (${E_AVGB} Б) — нагрузки в трафике нет" \
    || no "данные вырождены: пакеты по ${E_AVGB} Б, это не флуд заголовками"
[ "${HTTP_NOW}" -lt "${B_HTTP}" ] && ok "запросы приложения упали при растущих пакетах" \
    || no "данные вырождены: запросы не упали, наплыв не отличить от атаки"
[ "${S_ZERO}" -gt 50 ] && [ "${S_ZERO}" -lt 100 ] \
    && ok "среди источников есть и подделанные, и настоящие (${S_ZERO} % без рукопожатий)" \
    || no "данные вырождены: доля адресов без рукопожатий ${S_ZERO} %"
[ "${S_ASN}" -ge 10 ] && ok "источники размазаны по ${S_ASN} автономным системам" \
    || no "данные вырождены: всего ${S_ASN} сетей, источник читается сразу"

echo ""
echo "── 1. Что показывает сеть ──"
check() { # $1 ключ, $2 ожидание, $3 подпись
    got="$(val "$1")"
    [ "${got}" = "$2" ] && ok "$1=$2${3:+ ($3)}" || no "$1=${got:-пусто}, ожидается $2${3:+ ($3)}"
}
check peak_pps        "${P_PPS}"
check peak_mbps       "${P_MBPS}"
check pps_growth_x    "${E_GROWTH}"    "пик / обычное"
check avg_packet_bytes "${E_AVGB}"     "полоса / пакеты"
check syn_share_pct   "${E_SYNPCT}"

echo ""
echo "── 2. Что не исчерпано ──"
check uplink_util_pct "${E_UPLINK}"
check bandwidth_saturated no          "полоса занята на ${E_UPLINK} %"
check nic_pps_util_pct "${E_NIC}"

echo ""
echo "── 3. Что исчерпано ──"
check listen_backlog  "${BACKLOG}"
check syn_recv_now    "${SYNRECV}"
check accept_queue_full yes           "SYN-RECV равен backlog"
check listen_overflows "${OVERFLOW}"
check syncookies_sent "${CK_SENT}"
check syncookies_returned_pct "${E_CKPCT}"

echo ""
echo "── 4. Настоящие пользователи ──"
check estab_now       "${ESTAB}"
check estab_drop_pct  "${E_ESTABDROP}"
check http_rps_now    "${HTTP_NOW}"
check http_rps_drop_pct "${E_HTTPDROP}"

echo ""
echo "── 5. Источники ──"
check sources_sampled "${S_TOTAL}"
check sources_zero_handshake_pct "${S_ZERO}"
check sources_distinct_asn "${S_ASN}"
check top_asn_share_pct "${S_TOP}"
check spoofed_likely  yes             "рукопожатий нет, cookies не возвращаются"
check blocklist_effective no          "адреса подделаны и меняются"

echo ""
echo "── 6. Приговор ──"
check verdict         attack
check attack_type     syn-flood
check exhausted_resource accept-queue "не полоса: она занята на ${E_UPLINK} %"
check flash_crowd_ruled_out_by http-rps-drop "пакеты вверх, запросы вниз"

echo ""
echo "── 7. Комментарии и форма ──"
grep -q '^#' "${REP}" && ok "комментарии в отчёте сохранены" \
    || no "комментарии удалены — по такому отчёту не разберётся сменщик"
if grep -nE '^[a-z_]+= *$' "${REP}" >/dev/null; then
    no "есть незаполненные ключи: $(grep -cE '^[a-z_]+= *$' "${REP}")"
else ok "незаполненных ключей нет"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
