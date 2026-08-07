#!/usr/bin/env bash
#
# s02e10 «Труба в стене» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства ~/.ssh/config: читает его ровно так,
# как это делает ssh — блоки просматриваются сверху вниз, и для каждого
# параметра действует ПЕРВОЕ найденное значение. Отсюда главная проверка
# серии: блок `Host *` наверху молча перекрывает всё остальное.
#
# Без root, без сети: ssh не запускается, никуда не подключаемся.
#
# Выбор артефакта: SUBJECT=... | artifacts/config | <серия>/config | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STARTER="${SERIES_DIR}/starter/config"

if   [ -n "${SUBJECT:-}" ];                     then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/config" ];   then CFG="${SERIES_DIR}/artifacts/config"
elif [ -f "${SERIES_DIR}/config" ];             then CFG="${SERIES_DIR}/config"
else CFG="${SERIES_DIR}/solution/config"
     echo "ℹ️  Свой config не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/config artifacts/config"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e10 tests — конфиг: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${CFG}" ]; then
    ok "конфигурация клиента найдена"
else
    no "config не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- чтение так, как это делает ssh -----------------------------------------
# «шаблон<TAB>ключ<TAB>значение» по порядку следования в файле
ENTRIES="$(sed -e 's/\r$//' "${CFG}" | awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { line=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",line) }
    tolower(line) ~ /^host[[:space:]]/ {
        p=line; sub(/^[Hh][Oo][Ss][Tt][[:space:]]+/,"",p); pat=p; next }
    {
        k=line; sub(/[[:space:]].*$/,"",k)
        v=line; sub(/^[^[:space:]]+[[:space:]]+/,"",v)
        if (v==line) v=""
        print pat "\t" k "\t" v }')"

# соответствует ли имя хоста шаблону блока (шаблоны через пробел, * и ?)
matches() {
    awk -v host="$1" -v pats="$2" 'BEGIN {
        n = split(pats, a, /[[:space:]]+/)
        for (i = 1; i <= n; i++) {
            p = a[i]; if (p == "") continue
            gsub(/\./, "\\.", p); gsub(/\*/, ".*", p); gsub(/\?/, ".", p)
            if (host ~ ("^" p "$")) { print "yes"; exit }
        } }' | grep -q yes
}

# эффективное значение: ПЕРВОЕ совпадение сверху вниз
eff() {
    local host="$1" key="$2" pat k v
    while IFS="$(printf '\t')" read -r pat k v; do
        [ -n "${pat}" ] || continue
        [ "$(printf '%s' "${k}" | tr 'A-Z' 'a-z')" = "$(printf '%s' "${key}" | tr 'A-Z' 'a-z')" ] || continue
        matches "${host}" "${pat}" || continue
        printf '%s\n' "${v}"; return
    done <<EOF
${ENTRIES}
EOF
}
# все значения ключа для хоста (LocalForward можно повторять)
all_for() {
    local host="$1" key="$2" pat k v
    while IFS="$(printf '\t')" read -r pat k v; do
        [ -n "${pat}" ] || continue
        [ "$(printf '%s' "${k}" | tr 'A-Z' 'a-z')" = "$(printf '%s' "${key}" | tr 'A-Z' 'a-z')" ] || continue
        matches "${host}" "${pat}" && printf '%s\n' "${v}"
    done <<EOF
${ENTRIES}
EOF
}
patterns() { printf '%s\n' "${ENTRIES}" | awk -F'\t' 'NF{print $1}' | awk '!seen[$0]++'; }

# ---- 1. структура ------------------------------------------------------------
nblocks=$(patterns | grep -c . || true)
if [ "${nblocks}" -ge 2 ]; then
    ok "разобрано блоков Host: ${nblocks}"
else
    no "блоков Host меньше двух — проверять нечего"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

bad=$(sed -e 's/\r$//' "${CFG}" | grep -vE '^[[:space:]]*(#|$)' \
      | grep -vE '^[[:space:]]*[A-Za-z][A-Za-z0-9]*([[:space:]]+|=)' || true)
if [ -z "${bad}" ]; then
    ok "синтаксис: все активные строки — «ключ значение»"
else
    no "ssh не разобрал бы строку: $(printf '%s' "${bad}" | head -1)"
fi

# ---- 2. ГЛАВНОЕ: где стоит Host * -------------------------------------------
star_pos=$(patterns | grep -nx '\*' | head -1 | cut -d: -f1)
if [ -z "${star_pos}" ]; then
    no "нет блока «Host *» — общие настройки задать негде"
elif [ "${star_pos}" -eq "${nblocks}" ]; then
    ok "блок «Host *» стоит последним — он не перекрывает частные настройки"
else
    no "блок «Host *» стоит ${star_pos}-м из ${nblocks}: действует ПЕРВОЕ значение, и всё ниже него мертво"
fi

# ---- 3. хосты на месте -------------------------------------------------------
for h in bastion db moscow devbox; do
    if patterns | grep -qx "${h}"; then ok "описан хост ${h}"
    else no "нет блока для ${h}"; fi
done

# ---- 4. проход через бастион -------------------------------------------------
for h in db moscow devbox; do
    pj="$(eff "${h}" ProxyJump)"
    if [ -n "${pj}" ]; then
        ok "${h}: ProxyJump ${pj}"
    else
        no "${h}: нет ProxyJump — до внутренней машины напрямую не дойти"
    fi
done
if grep -qiE '^[[:space:]]*ProxyCommand' "${CFG}"; then
    no "используется ProxyCommand: то же самое делает ProxyJump одной строкой и умеет цепочки"
else
    ok "ProxyCommand не используется"
fi

# ---- 5. туннели --------------------------------------------------------------
lf="$(all_for db LocalForward | grep . | head -1)"
if [ -z "${lf}" ]; then
    no "db: нет LocalForward — до базы не добраться"
elif printf '%s' "${lf}" | awk '{exit !($1 ~ /^[0-9]+$/ && $1 != "5432")}'; then
    ok "db: LocalForward ${lf}"
else
    no "db: LocalForward ${lf} — локальный порт должен отличаться от 5432, чтобы не конфликтовать со своей базой"
fi

rf="$(all_for devbox RemoteForward | grep . | head -1)"
if [ -z "${rf}" ]; then
    no "devbox: нет RemoteForward — свой сервис туда не отдать"
elif printf '%s' "${rf}" | grep -qE '^(127\.0\.0\.1|localhost):[0-9]+'; then
    ok "devbox: RemoteForward привязан к localhost сервера — ${rf}"
else
    no "devbox: RemoteForward '${rf}' без явного 127.0.0.1 — при GatewayPorts yes сервис окажется открыт в сеть"
fi

df="$(all_for moscow DynamicForward | grep . | head -1)"
if [ -z "${df}" ]; then
    no "moscow: нет DynamicForward — SOCKS для браузера не поднимется"
elif printf '%s' "${df}" | grep -qE '^(127\.0\.0\.1|localhost):[0-9]+'; then
    ok "moscow: DynamicForward привязан к localhost — ${df}"
else
    no "moscow: DynamicForward '${df}' слушает на всех адресах — через вашу машину сможет ходить кто угодно"
fi

# ---- 6. клиент не отдаёт ключ ------------------------------------------------
bad_agent=""
for h in bastion db moscow devbox; do
    v="$(eff "${h}" ForwardAgent | tr 'A-Z' 'a-z')"
    case "${v}" in no|"") : ;; *) bad_agent="${bad_agent} ${h}" ;; esac
done
if [ -z "${bad_agent}" ]; then
    ok "ForwardAgent выключен везде — ключ не уезжает на чужую машину"
else
    no "ForwardAgent включён для:${bad_agent} — root на бастионе сможет ходить вашим ключом"
fi

shk="$(eff bastion StrictHostKeyChecking | tr 'A-Z' 'a-z')"
case "${shk}" in
  no|off) no "StrictHostKeyChecking ${shk} — отключена единственная защита от подмены сервера" ;;
  yes|ask|accept-new) ok "StrictHostKeyChecking = ${shk}" ;;
  "")   no "StrictHostKeyChecking не задан явно" ;;
  *)    no "StrictHostKeyChecking = ${shk} — недопустимое значение" ;;
esac

io="$(eff db IdentitiesOnly | tr 'A-Z' 'a-z')"
if [ "${io}" = "yes" ]; then
    ok "IdentitiesOnly = yes — агент не будет перебирать все ключи подряд"
else
    no "IdentitiesOnly = ${io:-не задан}: агент предложит все ключи, и MaxAuthTries 3 из s02e09 оборвёт вход"
fi

idf="$(eff db IdentityFile)"
if [ -n "${idf}" ]; then ok "IdentityFile задан: ${idf}"
else no "IdentityFile не задан — при IdentitiesOnly yes входить будет нечем"; fi

sai="$(eff db ServerAliveInterval)"
if printf '%s' "${sai}" | grep -qE '^[0-9]+$' && [ "${sai}" -ge 5 ] && [ "${sai}" -le 120 ]; then
    ok "ServerAliveInterval = ${sai} — туннель за NAT не умрёт молча"
else
    no "ServerAliveInterval = ${sai:-не задан}: простаивающий туннель разорвётся без уведомления"
fi

# ---- 7. эффективный пользователь --------------------------------------------
u_db="$(eff db User)"
u_star=$(printf '%s\n' "${ENTRIES}" | awk -F'\t' '$1=="*" && tolower($2)=="user" {print $3; exit}')
if [ -n "${u_db}" ] && { [ -z "${u_star}" ] || [ "${u_db}" != "${u_star}" ] || [ "${star_pos}" = "${nblocks}" ]; }; then
    ok "эффективный пользователь для db: ${u_db}"
else
    no "для db действует User из «Host *» (${u_star}) — частная настройка перекрыта"
fi

# ---- 8. самопроверки ---------------------------------------------------------
if [ -f "${STARTER}" ] && [ "$(sed -e 's/\r$//' "${STARTER}" | grep -ciE '^[[:space:]]*Host[[:space:]]+\*')" -eq 1 ] \
   && [ "$(sed -e 's/\r$//' "${STARTER}" | grep -niE '^[[:space:]]*Host[[:space:]]' | head -1 | grep -c '\*')" -eq 1 ]; then
    ok "самопроверка: в стартере «Host *» стоит первым — ловушка на месте"
else
    no "самопроверка: стартер больше не содержит перевёрнутого порядка блоков"
fi

if [ -f "${STARTER}" ] && grep -qiE '^[[:space:]]*ForwardAgent[[:space:]]+yes' "${STARTER}"; then
    ok "самопроверка: в стартере включён проброс агента — вторая ловушка на месте"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
