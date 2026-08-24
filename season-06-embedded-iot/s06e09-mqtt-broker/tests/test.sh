#!/usr/bin/env bash
#
# s06e09 «Брокер» — тест mosquitto.conf и acl (Type B).
#
# Ни одного зашитого пути и порта: всё берётся из data/broker_host.txt и
# data/tls_material.txt. Роли и их потребности — из data/roles.txt,
# закрываемые находки — из data/findings.txt.
#
# Правила ACL проверяются не текстуально, а по смыслу: тест моделирует
# разрешение темы для нескольких клиентов (узел, чужой узел, панель,
# посторонний) и требует нужного ответа.
#
# Без root, без сети, без брокера.
#
# Выбор файлов: SUBJECT_DIR=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"

if   [ -n "${SUBJECT_DIR:-}" ];                        then SD="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/mosquitto.conf" ];  then SD="${SERIES_DIR}/artifacts"
elif [ -f "${SERIES_DIR}/mosquitto.conf" ];            then SD="${SERIES_DIR}"
else SD="${SERIES_DIR}/solution"
     echo "ℹ️  Своего mosquitto.conf не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/mosquitto.conf starter/acl artifacts/"; echo ""
fi
CONF="${SD}/mosquitto.conf"; ACL="${SD}/acl"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e09 tests — конфигурация: ${SD#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${D}/broker_host.txt" "${D}/tls_material.txt" "${D}/roles.txt" "${D}/findings.txt"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
[ -f "${CONF}" ] && ok "mosquitto.conf найден" || no "нет mosquitto.conf"
[ -f "${ACL}" ]  && ok "acl найден"            || no "нет acl"
[ -f "${CONF}" ] && [ -f "${ACL}" ] || { echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

kv() { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "$2"; }
TLSPORT="$(kv mqtt_tls_port "${D}/broker_host.txt")"
PLAINPORT="$(kv mqtt_plain_port "${D}/broker_host.txt")"
PWFILE="$(kv password_file "${D}/broker_host.txt")"
ACLFILE="$(kv acl_file "${D}/broker_host.txt")"
PERSLOC="$(kv persistence_location "${D}/broker_host.txt")"
LOGFILE="$(kv log_file "${D}/broker_host.txt")"
MAXQ="$(kv max_queued "${D}/broker_host.txt")"
CAF="$(kv ca_file "${D}/tls_material.txt")"
CRT="$(kv cert_file "${D}/tls_material.txt")"
KEY="$(kv key_file "${D}/tls_material.txt")"
MINTLS="$(kv min_tls_version "${D}/tls_material.txt")"

# ── разбор mosquitto.conf ────────────────────────────────────────────
# комментарии — только целыми строками: в теме «#» это подстановочный знак
C="$(grep -v '^[[:space:]]*#' "${CONF}" | awk 'NF')"
dv()  { awk -v d="$1" '$1==d {sub(/^[^[:space:]]+[[:space:]]+/,""); print; exit}' <<<"${C}"; }
dall(){ awk -v d="$1" '$1==d {sub(/^[^[:space:]]+[[:space:]]+/,""); print}' <<<"${C}"; }
has() { awk -v d="$1" '$1==d {f=1} END{exit !f}' <<<"${C}"; }

echo ""
echo "── Исходные данные ──"
if [ -n "${TLSPORT}" ] && [ -n "${CAF}" ] && [ "$(awk '!/^#/&&NF{print}' "${D}/roles.txt" | grep -c .)" -ge 4 ]
then ok "данные разобраны: TLS-порт ${TLSPORT}, 4 роли, ${MINTLS}"
else no "не разобрались файлы в data/"; fi

echo ""
echo "── Слушатель и TLS ──"
LISTENERS="$(dall listener | awk '{print $1}')"
if grep -qx "${TLSPORT}" <<<"${LISTENERS}"; then ok "слушатель на ${TLSPORT}"
else no "нет listener ${TLSPORT} (есть: $(tr '\n' ' ' <<<"${LISTENERS}"))"; fi
if grep -qx "${PLAINPORT}" <<<"${LISTENERS}"
then no "остался listener ${PLAINPORT} — незашифрованный порт «на время миграции» сводит TLS на нет"
else ok "порта ${PLAINPORT} нет вовсе"; fi
NLIS="$(grep -c . <<<"${LISTENERS}")"
[ "${NLIS}" = 1 ] && ok "слушатель ровно один" || no "слушателей ${NLIS} — каждый лишний нужно защищать отдельно"

for pair in "cafile:${CAF}" "certfile:${CRT}" "keyfile:${KEY}"; do
    d="${pair%%:*}"; want="${pair#*:}"; have="$(dv "${d}")"
    [ "${have}" = "${want}" ] && ok "${d} ${have}" || no "${d}=«${have:-не задан}», в data/ указан ${want}"
done
TV="$(dv tls_version)"
if [ "${TV}" = "${MINTLS}" ]; then ok "tls_version ${TV}"
else no "tls_version=«${TV:-не задан}», требуется не ниже ${MINTLS}"; fi

echo ""
echo "── Кто подключается ──"
AA="$(dv allow_anonymous)"
[ "${AA}" = false ] && ok "allow_anonymous false" || no "allow_anonymous=«${AA:-не задан}» — подключиться сможет кто угодно"
[ "$(dv password_file)" = "${PWFILE}" ] && ok "password_file ${PWFILE}" || no "password_file=«$(dv password_file)», в data/ ${PWFILE}"
[ "$(dv acl_file)" = "${ACLFILE}" ] && ok "acl_file ${ACLFILE}" || no "acl_file=«$(dv acl_file)», в data/ ${ACLFILE}"

echo ""
echo "── Сессии, очереди, журнал ──"
[ "$(dv persistence)" = true ] && ok "persistence true" || no "persistence=«$(dv persistence)» — при перезапуске теряются сессии и очереди"
[ "$(dv persistence_location)" = "${PERSLOC}" ] && ok "persistence_location ${PERSLOC}" || no "persistence_location=«$(dv persistence_location)»"
MQ="$(dv max_queued_messages)"
if [ -n "${MQ}" ] && [ "${MQ}" -le "${MAXQ}" ] 2>/dev/null
then ok "max_queued_messages ${MQ} (не больше ${MAXQ})"
else no "max_queued_messages=«${MQ:-не задан}» — очередь пропавшего узла съест память брокера"; fi
if dall log_dest | grep -q "${LOGFILE}"; then ok "журнал пишется в ${LOGFILE}"
else no "log_dest не указывает на ${LOGFILE}"; fi
has log_type && ok "log_type задан" || no "log_type не задан — в журнале не будет нужных уровней"
[ "$(dv connection_messages)" = true ] && ok "connection_messages true — видно, кто подключается" \
    || no "connection_messages=«$(dv connection_messages)»: без имён клиентов разбор вроде s06e08 невозможен"

DUPD="$(awk '{print $1}' <<<"${C}" | grep -vx 'log_type\|topic\|listener' | sort | uniq -d | grep -c .)"
[ "${DUPD}" -eq 0 ] && ok "нет дублирующихся директив" || no "${DUPD} директив заданы дважды"

# ── разбор acl: моделируем разрешение ────────────────────────────────
A="$(grep -v '^[[:space:]]*#' "${ACL}" | awk 'NF')"

echo ""
echo "── ACL: структура ──"
ANON="$(awk '$1=="user"||$1=="pattern"{stop=1} !stop && $1=="topic"{n++} END{print n+0}' <<<"${A}")"
[ "${ANON}" -eq 0 ] && ok "нет правил для анонимных клиентов" \
    || no "${ANON} строк topic стоят до первого user/pattern — это правила для АНОНИМНЫХ клиентов"

if awk '$1=="topic"||$1=="pattern" {for(i=2;i<=NF;i++) if ($i=="#") f=1} END{exit !f}' <<<"${A}"
then no "есть правило на голую «#» — ровно то, что делал посторонний клиент в s06e08"
else ok "ни одного правила на голую «#»"; fi

if awk '$1=="pattern" && $0 ~ /%u/ {f=1} END{exit !f}' <<<"${A}"
then ok "есть правила с подстановкой %u — тема привязана к имени клиента"
else no "нет ни одного pattern с %u: без подстановки узел получит доступ к чужим темам"; fi

for r in $(awk '/^[[:space:]]*#/{next} NF>=2 && $2=="user" {print $1}' "${D}/roles.txt"); do
    awk -v u="${r}" '$1=="user" && $2==u {f=1} END{exit !f}' <<<"${A}" \
        && ok "роль ${r} описана" || no "роль ${r} из roles.txt не описана в acl"
done

# ── ACL: модель разрешений ───────────────────────────────────────────
# Возвращает allow/deny для (пользователь, доступ, тема).
allowed() {
    awk -v U="$1" -v ACC="$2" -v T="$3" '
    function mtopic(pat, top,   p, t, i, np, nt) {
        np = split(pat, p, "/"); nt = split(top, t, "/")
        for (i = 1; i <= np; i++) {
            if (p[i] == "#") return 1
            if (i > nt) return 0
            if (p[i] != "+" && p[i] != t[i]) return 0
        }
        return (np == nt)
    }
    function acc_ok(rule, want) {
        if (rule == "readwrite") return 1
        return (rule == want)
    }
    $1 == "user"    { cur = $2; next }
    # тема — третье поле: в темах MQTT пробелов не бывает
    $1 == "topic"   { if (cur != U) next
                      if (acc_ok($2, ACC) && mtopic($3, T)) { print "allow"; done=1; exit } next }
    $1 == "pattern" { pat = $3; gsub(/%u/, U, pat)
                      if (acc_ok($2, ACC) && mtopic(pat, T)) { print "allow"; done=1; exit } next }
    END { if (!done) print "deny" }
    ' <<<"${A}"
}
verdict() { local got; got="$(allowed "$1" "$2" "$3")"; [ -z "${got}" ] && got=deny; printf '%s' "${got}"; }
expect() { # пользователь доступ тема ожидание пояснение
    local v; v="$(verdict "$1" "$2" "$3")"
    if [ "${v}" = "$4" ]; then ok "$5"
    else no "$5 — получилось ${v}, ожидалось $4 ($1 $2 $3)"; fi
}

echo ""
echo "── ACL: что кому реально можно ──"
N1=shadow-node-07; N2=shadow-node-12
expect "${N1}" write "shadow/${N1}/telemetry/temp" allow "узел пишет свою телеметрию"
expect "${N1}" write "shadow/${N2}/telemetry/temp" deny  "узел НЕ пишет чужую телеметрию"
expect "${N1}" read  "shadow/${N1}/cmd/led"        allow "узел читает свои команды"
expect "${N1}" read  "shadow/${N2}/cmd/led"        deny  "узел НЕ читает чужие команды"
expect "${N1}" write "shadow/${N1}/cmd/led"        deny  "узел НЕ отдаёт команды сам себе"
expect dashboard read  "shadow/${N1}/telemetry/temp" allow "панель читает телеметрию"
expect dashboard write "shadow/${N1}/cmd/led"        allow "панель отдаёт команды"
expect dashboard write "shadow/${N1}/telemetry/temp" deny  "панель НЕ пишет телеметрию"
expect recorder  read  "shadow/${N1}/telemetry/temp" allow "архиватор читает телеметрию"
expect recorder  write "shadow/${N1}/cmd/led"        deny  "архиватор ничего не пишет"
expect monitor   read  '$SYS/broker/clients/connected' allow "наблюдатель читает \$SYS"
expect dashboard read  '$SYS/broker/clients/connected' deny  "панели \$SYS не положен"
expect mqtt-explorer-9f2a read "shadow/${N1}/telemetry/temp" deny "посторонний не читает ничего"

echo ""
echo "── Находки s06e08 закрыты ──"
closed_plaintext()  { ! grep -qx "${PLAINPORT}" <<<"${LISTENERS}" && [ -n "$(dv cafile)" ]; }
closed_anonymous()  { [ "${AA}" = false ]; }
closed_no_acl()     { [ -n "$(dv acl_file)" ] && [ "$(grep -c . <<<"${A}")" -ge 4 ]; }
closed_wildcard_sub() { ! awk '$1=="topic"||$1=="pattern" {for(i=2;i<=NF;i++) if ($i=="#") f=1} END{exit !f}' <<<"${A}"; }
closed_shared_password() { awk '$1=="pattern" && $0 ~ /%u/ {f=1} END{exit !f}' <<<"${A}"; }
closed_no_persistence() { [ "$(dv persistence)" = true ]; }
while read -r id _; do
    case "${id}" in ''|\#*) continue ;; esac
    if "closed_${id}" 2>/dev/null; then ok "закрыта находка: ${id}"
    else no "находка ${id} не закрыта"; fi
done < "${D}/findings.txt"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
