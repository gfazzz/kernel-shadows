#!/usr/bin/env bash
#
# s06e08 «Разбор MQTT» — тест находок по журналу брокера (Type C).
#
# Ни одного зашитого ответа: всё пересчитывается из data/mqtt_dump.txt,
# включая сведения о брокере из шапки журнала. Подмени дамп — тест будет
# ждать другие значения.
#
# Без root, без сети, без брокера.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data/mqtt_dump.txt"

if   [ -n "${SUBJECT:-}" ];                            then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/mqtt_report.txt" ]; then REP="${SERIES_DIR}/artifacts/mqtt_report.txt"
elif [ -f "${SERIES_DIR}/mqtt_report.txt" ];           then REP="${SERIES_DIR}/mqtt_report.txt"
else REP="${SERIES_DIR}/solution/mqtt_report.txt"
     echo "ℹ️  Своего mqtt_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/mqtt_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e08 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${D}" ] || { echo "  FAIL: нет ${D}"; exit 1; }
if [ -f "${REP}" ]; then ok "mqtt_report.txt найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

got()   { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "${REP}"; }
check() { local k="$1" want="$2" why="$3" have; have="$(got "${k}")"
    if [ -z "${have}" ]; then no "${k}: не заполнено (${why})"
    elif [ "${have}" = "${want}" ]; then ok "${k}=${have}"
    else no "${k}=${have}, из журнала следует «${want}» — ${why}"; fi; }

# ── шапка журнала ────────────────────────────────────────────────────
meta() { awk -F= -v k="$1" '/^#/ {sub(/^#[[:space:]]*/,""); if ($1==k) {sub(/^[^=]*=/,""); gsub(/[[:space:]]/,""); print; exit}}' "${D}"; }
E_PORT="$(meta listener)"; E_TLS="$(meta tls)"

# ── тело журнала ─────────────────────────────────────────────────────
B="$(grep -v '^[[:space:]]*#' "${D}" | grep -v '^[[:space:]]*$')"
REC="$(grep ' Received ' <<<"${B}" || true)"
PUB="$(grep 'Received PUBLISH from' <<<"${B}" || true)"
SUB="$(grep 'Received SUBSCRIBE from' <<<"${B}" || true)"
CON="$(grep 'Received CONNECT from' <<<"${B}" || true)"

E_REC="$(grep -c . <<<"${REC}")"
E_CLI="$(sed -n 's/.* Received [A-Z]* from \([^ ]*\).*/\1/p' <<<"${REC}" | sort -u | grep -c .)"
E_PUBN="$(grep -c . <<<"${PUB}")"
E_SUBN="$(grep -c . <<<"${SUB}")"
# тема — это строка в кавычках ПЕРЕД «, ...» внутри скобок пакета;
# наивное «последнее в кавычках» поймает payload
topic_of() { sed -n "s/.*, '\([^']*\)', \.\.\..*/\1/p"; }
E_TOP="$(topic_of <<<"${PUB}" | sort -u | grep -c .)"

qn() { grep -c ", q$1," <<<"${PUB}"; }
E_Q0="$(qn 0)"; E_Q1="$(qn 1)"; E_Q2="$(qn 2)"
E_RET="$(grep -c ', r1,' <<<"${PUB}")"
E_CMDQ="$(grep '/cmd/' <<<"${PUB}" | sed -n 's/.*, q\([0-9]\),.*/\1/p' | sort -u | tr '\n' ' ' | sed 's/ $//')"

# у SUBSCRIBE своя форма записи темы: ('тема', QoS N)
sub_topic_of() { sed -n "s/.*('\([^']*\)', QoS.*/\1/p"; }
E_WILD="$(sub_topic_of <<<"${SUB}" | grep -c '[#+]')"
E_ROGUE="$(awk -F"'" '$2=="#" {print $0}' <<<"${SUB}" | sed -n 's/.* Received SUBSCRIBE from \([^ ]*\).*/\1/p' | head -1)"

E_OFF="$(sed -n 's/.*Socket error on client \([^,]*\),.*/\1/p' <<<"${B}" | head -1)"
OFFSHORT="$(printf '%s' "${E_OFF}" | sed 's/.*-//')"
E_STOPIC="$(grep ", r1," <<<"${PUB}" | grep "from ${E_OFF} " | topic_of | tail -1)"
E_SVAL="$(grep ", r1," <<<"${PUB}" | grep "from ${E_OFF} " | sed -n "s/.*payload='\([^']*\)'.*/\1/p" | tail -1)"

E_DUP="$(sed -n 's/.*Client \([^ ]*\) already connected.*/\1/p' <<<"${B}" | sort -u | head -1)"
E_DUPN="$(grep -c 'already connected' <<<"${B}")"
E_LWT="$(grep -c "will '" <<<"${CON}")"
E_PASS="$(sed -n "s/.*p'\([^']*\)'.*/\1/p" <<<"${CON}" | sort -u | head -1)"

echo ""
echo "── Исходные данные ──"
if [ "${E_REC}" -gt 20 ] && [ -n "${E_ROGUE}" ] && [ -n "${E_OFF}" ] && [ -n "${E_DUP}" ]
then ok "журнал разобран: ${E_REC} принятых пакетов, ${E_CLI} клиентов"
else no "журнал не разобрался (rogue=${E_ROGUE:-?}, offline=${E_OFF:-?}, dup=${E_DUP:-?})"; fi
if [ -n "${E_STOPIC}" ] && [ -n "${E_SVAL}" ]
then ok "у отвалившегося клиента есть retained-сообщение (${E_STOPIC}=${E_SVAL})"
else no "в данных нет застрявшего retained — ключевая ловушка отсутствует"; fi

echo ""
echo "── 1. Обзор ──"
check total_received  "${E_REC}"  "строки «Received …»"
check clients         "${E_CLI}"  "уникальные имена после «from»"
check unique_topics   "${E_TOP}"  "разные темы в PUBLISH"
check publish_count   "${E_PUBN}" "строки «Received PUBLISH»"
check subscribe_count "${E_SUBN}" "строки «Received SUBSCRIBE»"

echo ""
echo "── 2. Кто слушает ──"
check wildcard_subs "${E_WILD}"  "подписки с + или #"
check rogue_client  "${E_ROGUE}" "подписан на голую «#»"

echo ""
echo "── 3. Доставка ──"
check qos0_publishes "${E_Q0}"   "поле q0"
check qos1_publishes "${E_Q1}"   "поле q1"
check qos2_publishes "${E_Q2}"   "поле q2"
check cmd_qos        "${E_CMDQ}" "QoS у тем с /cmd/"
check retained_count "${E_RET}"  "флаг r1"

echo ""
echo "── 4. Ловушки ──"
check offline_node         "${E_OFF}"    "строка «Socket error on client»"
check stale_retained_topic "${E_STOPIC}" "его последняя публикация с r1"
check stale_retained_value "${E_SVAL}"   "то, что брокер отдаёт новым подписчикам до сих пор"
check dup_client_id        "${E_DUP}"    "«already connected, closing old connection»"
check dup_disconnects      "${E_DUPN}"   "сколько раз это случилось"
check lwt_clients          "${E_LWT}"    "CONNECT с объявленным will"

echo ""
echo "── 5. Что видно постороннему ──"
check listener_port     "${E_PORT}" "из шапки журнала"
check tls_enabled       "${E_TLS}"  "из шапки журнала"
check plaintext_password "${E_PASS}" "поле p'…' в CONNECT — оно там открытым текстом"

echo ""
echo "── Выводы ──"
if [ "${E_Q0}" -gt "${E_Q1}" ]; then ok "в данных преобладает QoS 0 (${E_Q0} против ${E_Q1}) — есть о чём писать в выводах"
else no "данные вырождены: QoS 0 не преобладает"; fi
grep -qE '^[[:space:]]*#' "${REP}" && ok "пояснения в файле остались" \
                                   || no "все комментарии вырезаны — отчёт должен объяснять, откуда значения"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
