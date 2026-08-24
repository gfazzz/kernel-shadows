#!/usr/bin/env bash
#
# s07e07 «Восемь звонков про одну аварию» — тест конфигурации (Type B).
#
# Проверяются свойства маршрутизации: попадает ли каждая важность в свой
# приёмник, существуют ли приёмники, на которые ссылаются маршруты, есть
# ли приёмник по умолчанию, склеиваются ли оповещения одной аварии,
# подавляются ли следствия причиной и не лежит ли в файле адрес с токеном.
#
# Требования берутся из data/policy.txt, метки оповещений — из
# data/alert_labels.txt. Констант в тесте нет.
#
# Без root, без сети, без Alertmanager.
#
# Выбор файла: SUBJECT=... | artifacts/alertmanager.yml | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
POL="${D}/policy.txt"; LAB="${D}/alert_labels.txt"
NIGHT="${D}/night.txt"; CUR="${D}/current_alertmanager.yml"

if   [ -n "${SUBJECT:-}" ];                               then A="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/alertmanager.yml" ];   then A="${SERIES_DIR}/artifacts/alertmanager.yml"
elif [ -f "${SERIES_DIR}/alertmanager.yml" ];             then A="${SERIES_DIR}/alertmanager.yml"
else A="${SERIES_DIR}/solution/alertmanager.yml"
     echo "ℹ️  Своего alertmanager.yml не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/alertmanager.yml artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e07 tests — настройка: ${A#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${POL}" "${LAB}" "${NIGHT}" "${CUR}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${A}" ]; then ok "alertmanager.yml найден"
else no "alertmanager.yml не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

cat > "${TMP}/flat.awk" <<'AWK'
{
    line = $0
    sub(/\r$/, "", line)
    if (line ~ /^[[:space:]]*#/) next
    if (line ~ /^[[:space:]]*$/) next
    sub(/[[:space:]]+$/, "", line)
    if (line == "" || line ~ /^---/) next
    match(line, /^ */); ind = RLENGTH
    body = substr(line, ind + 1)
    item = 0
    if (body == "-") { item = 1; body = ""; ind += 2 }
    else if (body ~ /^- /) { item = 1; sub(/^- +/, "", body); ind += 2 }
    popto = item ? ind - 1 : ind
    while (top > 0 && sind[top] >= popto) top--
    prefix = (top > 0) ? spath[top] : ""
    if (item) {
        n = cnt[prefix]++
        prefix = prefix "[" n "]"
        top++; sind[top] = ind - 1; spath[top] = prefix
        if (body == "") next
    }
    if (body ~ /^[^:]+:$/) {
        key = body; sub(/:$/, "", key)
        top++; sind[top] = ind
        spath[top] = (prefix == "") ? key : prefix "." key
        next
    }
    if (body ~ /^[^:]+:[[:space:]]/) {
        key = body; sub(/:.*$/, "", key)
        val = body; sub(/^[^:]*:[[:space:]]*/, "", val)
        gsub(/^["']|["']$/, "", val)
        print ((prefix == "") ? key : prefix "." key) "=" val
        next
    }
    if (item) print prefix "=" body
}
AWK
# Значения содержат «=» (matchers вида «severity = page»), поэтому разбор
# идёт по ПЕРВОМУ знаку равенства: путь и значение разделяются табуляцией.
awk -f "${TMP}/flat.awk" "${A}" | awk '{ sub(/=/, "\t"); print }' > "${TMP}/f"

g()   { awk -F'\t' -v k="$1" '$1==k {print $2; exit}' "${TMP}/f"; }
keys(){ awk -F'\t' -v p="$1" 'index($1,p)==1 {print $1}' "${TMP}/f"; }
pol() { awk -v k="$1" '/^[[:space:]]*#/{next} $1==k {print $2; exit}' "${POL}"; }
dur_s(){ awk -v d="$1" 'BEGIN{ n=d; sub(/[a-z]$/,"",n); n+=0
    if      (d ~ /s$/) print n
    else if (d ~ /m$/) print n*60
    else if (d ~ /h$/) print n*3600
    else if (d ~ /d$/) print n*86400
    else print -1 }'; }

RECEIVERS="$(awk -F'\t' '$1 ~ /^receivers\[[0-9]+\]\.name$/ {print $2}' "${TMP}/f")"
have_recv(){ grep -qxF "$1" <<<"${RECEIVERS}"; }

echo ""
echo "── Исходные данные ──"
N_CALLS=$(awk '/^[0-9][0-9]:[0-9][0-9]:/ {c++} END{print c+0}' "${NIGHT}")
if [ "${N_CALLS}" -ge 5 ]
then ok "в журнале ночи ${N_CALLS} звонков про одну аварию"
else no "данные вырождены: звонков ${N_CALLS}, склеивать нечего"; fi
# Разброс первой очереди: пять оповещений одной аварии подряд.
SPREAD=$(awk '/^[0-9][0-9]:[0-9][0-9]:/ {split($1,t,":"); s=t[1]*3600+t[2]*60+t[3]
              n++; if (n==1) first=s; if (n==5) { print s - first; exit } }' "${NIGHT}")
MGW=$(dur_s "$(pol min_group_wait)")
if [ "${SPREAD}" -le "${MGW}" ] && [ "${SPREAD}" -gt 0 ]
then ok "разброс первых оповещений ${SPREAD} с укладывается в требуемые $(pol min_group_wait)"
else no "данные вырождены: разброс ${SPREAD} с не связан с требуемым окном"; fi
if [ "$(awk '$1=="inhibit"' "${POL}" | grep -c . || true)" -ge 3 ]
then ok "политика требует подавления следствий: $(awk '$1=="inhibit"' "${POL}" | grep -c . || true) правила"
else no "данные вырождены: подавлять нечего"; fi

echo ""
echo "── 1. Корень маршрута ──"
ROOT_RECV="$(g route.receiver)"
if [ -z "${ROOT_RECV}" ]
then no "у корневого маршрута нет receiver: оповещение, не подошедшее ни под одну ветку, исчезнет молча"
elif [ "${ROOT_RECV}" = "$(pol default_receiver)" ]
then ok "приёмник по умолчанию — ${ROOT_RECV}, как в политике"
else no "приёмник по умолчанию «${ROOT_RECV}», а политика требует $(pol default_receiver): ночью будить по неизвестному оповещению не договаривались"; fi
have_recv "${ROOT_RECV}" && ok "приёмник ${ROOT_RECV} описан" \
    || no "приёмника «${ROOT_RECV}» нет в receivers — Alertmanager не запустится"

echo ""
echo "── 2. Группировка ──"
GB="$(awk -F'\t' '$1 ~ /^route\.group_by\[[0-9]+\]$/ {print $2}' "${TMP}/f" | sort)"
WANT_GB="$(awk '$1=="group_by" {print $2}' "${POL}" | sort)"
if [ "${GB}" = "${WANT_GB}" ]
then ok "склеивание по $(tr '\n' ' ' <<<"${WANT_GB}")"
else no "group_by = «$(tr '\n' ' ' <<<"${GB}")», политика требует «$(tr '\n' ' ' <<<"${WANT_GB}")»"; fi
if grep -qx 'alertname' <<<"${GB}"
then no "в group_by попал alertname: он склеивает ОДИНАКОВЫЕ оповещения разных аварий и разносит РАЗНЫЕ оповещения одной"
else ok "alertname в группировке не участвует"; fi

for k in group_wait group_interval repeat_interval; do
    have="$(g "route.${k}")"; want="$(pol "min_${k}")"
    if [ -z "${have}" ]; then no "${k} не задан"
    elif [ "$(dur_s "${have}")" -ge "$(dur_s "${want}")" ]
    then ok "${k} = ${have} не меньше требуемых ${want}"
    else no "${k} = ${have} меньше требуемых ${want}"; fi
done

echo ""
echo "── 3. Ветки по важности ──"
while read -r _ sel recv; do
    sev="${sel#severity=}"; want="${recv#receiver=}"
    idx="$(awk -F'\t' -v s="severity = ${sev}" -v s2="severity=${sev}" '
        $1 ~ /^route\.routes\[[0-9]+\]\.matchers\[[0-9]+\]$/ && ($2==s || $2==s2) {
            p=$1; sub(/\.matchers.*$/,"",p); print p; exit }' "${TMP}/f")"
    if [ -z "${idx}" ]; then
        no "нет ветки для severity=${sev}: всё уйдёт в приёмник по умолчанию"
        continue
    fi
    got="$(g "${idx}.receiver")"
    [ "${got}" = "${want}" ] && ok "severity=${sev} → ${want}" \
        || no "severity=${sev} уходит в «${got}», а по политике в ${want}"
    have_recv "${got}" && ok "приёмник ${got} описан" \
        || no "приёмника «${got}» нет в receivers"
done < <(awk '$1=="route"' "${POL}")

echo ""
echo "── 4. Подавление следствий ──"
while read -r _ src tgt eq; do
    src="${src#source=}"; tgt="${tgt#target=}"; eq="${eq#equal=}"
    idx="$(awk -F'\t' -v s="alertname = ${src}" -v s2="alertname=${src}" '
        $1 ~ /^inhibit_rules\[[0-9]+\]\.source_matchers\[[0-9]+\]$/ && ($2==s || $2==s2) {
            p=$1; sub(/\.source_matchers.*$/,"",p); print p }' "${TMP}/f")"
    found=""
    for p in ${idx}; do
        if awk -F'\t' -v pre="${p}.target_matchers" -v t="alertname = ${tgt}" -v t2="alertname=${tgt}" \
               'index($1,pre)==1 && ($2==t || $2==t2) {f=1} END{exit !f}' "${TMP}/f"
        then found="${p}"; break; fi
    done
    if [ -z "${found}" ]; then
        no "${src} не подавляет ${tgt}: следствие придёт отдельным сообщением, как в ночь с восемью звонками"
    else
        ok "${src} подавляет ${tgt}"
        if awk -F'\t' -v pre="${found}.equal" -v v="${eq}" 'index($1,pre)==1 && $2==v {f=1} END{exit !f}' "${TMP}/f"
        then ok "  подавление ограничено равенством ${eq}"
        else no "  нет equal: ${eq} — одна упавшая цель заглушит оповещения всех остальных"; fi
    fi
done < <(awk '$1=="inhibit"' "${POL}")

echo ""
echo "── 5. Приёмники ──"
N_RECV="$(grep -c . <<<"${RECEIVERS}" || true)"
[ "${N_RECV}" -ge 2 ] && ok "приёмников описано: ${N_RECV}" || no "приёмников ${N_RECV}, нужны как минимум телефон и трекер"
EMPTY=""
for i in $(seq 0 $(( N_RECV - 1 )) ); do
    n="$(g "receivers[${i}].name")"
    [ -n "$(keys "receivers[${i}]." | grep -v '\.name$' | head -1)" ] || EMPTY="${EMPTY} ${n}"
done
[ -z "${EMPTY}" ] && ok "у каждого приёмника есть способ доставки" \
    || no "приёмники без единой настройки доставки:${EMPTY} — сообщения уйдут в никуда, и Alertmanager не возразит"

if grep -qE 'url:[[:space:]]*https?://[^[:space:]]*(token|key|secret|password)=' "${A}"
then no "в файле адрес с учётными данными: он попадёт в git вместе с настройкой"
else ok "адресов с токенами в файле нет"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
