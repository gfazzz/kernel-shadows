#!/usr/bin/env bash
#
# s02e11 «Своя сеть поверх чужой» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства wg0.conf. Главная проверка — та, из-за
# которой конфиг стартера «работает, но не работает»: AllowedIPs двух
# пиров не должны пересекаться, иначе один из них не получит ни пакета.
# Пересечение считается по подсетям, а не сравнением строк.
#
# Без root, без сети: wg не запускается, интерфейс не поднимается.
#
# Выбор артефакта: SUBJECT=... | artifacts/wg0.conf | <серия>/wg0.conf | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STARTER="${SERIES_DIR}/starter/wg0.conf"

if   [ -n "${SUBJECT:-}" ];                       then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/wg0.conf" ];   then CFG="${SERIES_DIR}/artifacts/wg0.conf"
elif [ -f "${SERIES_DIR}/wg0.conf" ];             then CFG="${SERIES_DIR}/wg0.conf"
else CFG="${SERIES_DIR}/solution/wg0.conf"
     echo "ℹ️  Свой wg0.conf не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/wg0.conf artifacts/wg0.conf"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e11 tests — конфиг: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${CFG}" ]; then
    ok "конфигурация wg0.conf найдена"
else
    no "wg0.conf не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- разбор: «номер_секции<TAB>имя<TAB>ключ<TAB>значение» --------------------
ENTRIES="$(sed -e 's/\r$//' "${CFG}" | awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*$/ { next }
    { line=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",line) }
    line ~ /^\[.*\]$/ { sec=line; gsub(/^\[|\]$/,"",sec); n++; next }
    /=/ { k=line; sub(/[[:space:]]*=.*$/,"",k)
          v=line; sub(/^[^=]*=[[:space:]]*/,"",v)
          print n "\t" sec "\t" k "\t" v; next }
    { print n "\t" sec "\t!BAD!\t" line }')"

sec_nums()  { printf '%s\n' "${ENTRIES}" | awk -F'\t' -v s="$1" 'tolower($2)==tolower(s){print $1}' | awk '!x[$0]++'; }
field()     { printf '%s\n' "${ENTRIES}" | awk -F'\t' -v n="$1" -v k="$2" \
                'int($1)==int(n) && tolower($3)==tolower(k) {print $4; exit}'; }

iface_n="$(sec_nums Interface | head -1)"
peer_ns="$(sec_nums Peer)"
n_iface=$(sec_nums Interface | grep -c . || true)
n_peers=$(printf '%s\n' "${peer_ns}" | grep -c . || true)

# ---- 1. структура ------------------------------------------------------------
b="$(printf '%s\n' "${ENTRIES}" | awk -F'\t' '$3=="!BAD!"{print $4}')"
if [ -z "${b}" ]; then ok "синтаксис: все строки — секции или «ключ = значение»"
else no "wg-quick не разобрал бы строку: $(printf '%s' "${b}" | head -1)"; fi

if [ "${n_iface}" -eq 1 ]; then ok "ровно одна секция [Interface]"
else no "секций [Interface] ${n_iface}, должна быть одна"; fi

if [ "${n_peers}" -ge 2 ]; then ok "секций [Peer]: ${n_peers}"
else no "секций [Peer] ${n_peers} — нужны и шлюз, и прямой пир"; fi

if [ "${n_peers}" -lt 2 ] || [ "${n_iface}" -ne 1 ]; then
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- 2. [Interface] ----------------------------------------------------------
addr="$(field "${iface_n}" Address)"
if printf '%s' "${addr}" | grep -qE '^10\.|^172\.(1[6-9]|2[0-9]|3[01])\.|^192\.168\.'; then
    if printf '%s' "${addr}" | grep -qE '/32([[:space:]]*,|$)'; then
        ok "Address = ${addr} — маска /32: на интерфейсе живёт только свой адрес"
    else
        no "Address = ${addr}: маска не /32 — ядро создаст маршрут на всю подсеть и вступит в спор с AllowedIPs пиров"
    fi
else
    no "Address = ${addr:-не задан}: нужен адрес из приватного диапазона с маской"
fi

pk="$(field "${iface_n}" PrivateKey)"
if printf '%s' "${pk}" | grep -qE '^[A-Za-z0-9+/]{43}=$'; then
    ok "PrivateKey задан и похож на ключ WireGuard"
else
    no "PrivateKey = ${pk:-не задан}: ожидается 44 символа base64"
fi

dns="$(field "${iface_n}" DNS)"
if [ -n "${dns}" ]; then
    ok "DNS = ${dns} — внутренние имена будут разрешаться"
else
    no "DNS не задан: адреса из сети операции доступны, а имена (db.internal) не разрешатся"
fi

lp="$(field "${iface_n}" ListenPort)"
if [ -z "${lp}" ]; then
    ok "ListenPort не задан — узлу, который сам инициирует соединения, фиксированный порт не нужен"
else
    no "ListenPort = ${lp}: постоянный порт нужен только тому, к кому приходят; он же облегчает наблюдение"
fi

# ---- 3. пиры -----------------------------------------------------------------
missing=""; keys=""; allowed_pairs=""
for n in ${peer_ns}; do
    k="$(field "${n}" PublicKey)"
    a="$(field "${n}" AllowedIPs)"
    [ -n "${k}" ] || missing="${missing} PublicKey(секция ${n})"
    [ -n "${a}" ] || missing="${missing} AllowedIPs(секция ${n})"
    keys="${keys}${k}"$'\n'
    allowed_pairs="${allowed_pairs}${n}|${a}"$'\n'
done
if [ -z "${missing}" ]; then ok "у каждого пира есть PublicKey и AllowedIPs"
else no "не хватает:${missing}"; fi

uniq_keys=$(printf '%s' "${keys}" | grep -c . || true)
uniq_sorted=$(printf '%s' "${keys}" | grep . | sort -u | grep -c . || true)
if [ "${uniq_keys}" -eq "${uniq_sorted}" ]; then
    ok "публичные ключи пиров различны"
else
    no "два пира имеют одинаковый PublicKey — это один и тот же узел"
fi

mypub_seed="$(field "${iface_n}" PrivateKey)"
if printf '%s' "${keys}" | grep -qxF "${mypub_seed}"; then
    no "в списке пиров стоит собственный приватный ключ"
else
    ok "собственный ключ среди пиров не встречается"
fi

# ---- 4. ГЛАВНОЕ: AllowedIPs не пересекаются ---------------------------------
overlap="$(printf '%s' "${allowed_pairs}" | grep . | awk -F'|' '
    function tonum(ip,  a, n) { n = split(ip, a, "."); return ((a[1]*256+a[2])*256+a[3])*256+a[4] }
    function base(ip, m,  b, sh) { b = tonum(ip); sh = 32 - m
        if (sh >= 32) return 0
        return int(b / (2 ^ sh)) * (2 ^ sh) }
    function size(m) { return 2 ^ (32 - m) }
    {
        peer = $1; nets = $2
        cnt = split(nets, arr, /[[:space:]]*,[[:space:]]*/)
        for (i = 1; i <= cnt; i++) {
            s = arr[i]; gsub(/^[[:space:]]+|[[:space:]]+$/, "", s)
            if (s == "") continue
            split(s, p, "/"); ip = p[1]; m = (p[2] == "") ? 32 : p[2] + 0
            P[++T] = peer; B[T] = base(ip, m); E[T] = base(ip, m) + size(m) - 1; S[T] = s
        }
    }
    END {
        for (i = 1; i <= T; i++) for (j = i + 1; j <= T; j++) {
            if (P[i] == P[j]) continue
            if (B[i] <= E[j] && B[j] <= E[i]) { print S[i] " ↔ " S[j]; exit }
        }
    }')"
if [ -z "${overlap}" ]; then
    ok "AllowedIPs пиров не пересекаются — каждый получит свой трафик"
else
    no "AllowedIPs пересекаются (${overlap}): пакет уйдёт первому подходящему пиру, второй мёртв"
fi

# ---- 5. шлюз и прямой пир ----------------------------------------------------
gw_n=""; direct_n=""
for n in ${peer_ns}; do
    if [ -n "$(field "${n}" Endpoint)" ]; then gw_n="${n}"; else direct_n="${n}"; fi
done
if [ -n "${gw_n}" ]; then
    ep="$(field "${gw_n}" Endpoint)"
    if printf '%s' "${ep}" | grep -qE ':[0-9]+$'; then
        ok "у шлюза задан Endpoint с портом: ${ep}"
    else
        no "Endpoint '${ep}' без порта — WireGuard не знает, куда стучаться"
    fi
    ga="$(field "${gw_n}" AllowedIPs)"
    if printf '%s' "${ga}" | grep -q '10\.50\.'; then
        ok "через шлюз маршрутизируется сеть операции: ${ga}"
    else
        no "AllowedIPs шлюза (${ga}) не включает сеть операции 10.50.0.0/16"
    fi
    if printf '%s' "${ga}" | grep -qE '(^|[[:space:]])0\.0\.0\.0/0'; then
        no "AllowedIPs шлюза 0.0.0.0/0 — это полный туннель; при нескольких пирах остальные становятся недостижимы"
    else
        ok "полный туннель не включён — почта и браузер идут обычным путём"
    fi
else
    no "ни у одного пира нет Endpoint — до шлюза не дойти"
fi
if [ -n "${direct_n}" ]; then
    ok "есть пир без Endpoint — его адрес узнается из первого пакета"
else
    no "нет прямого пира: у всех задан Endpoint"
fi

# ---- 6. жизнь за NAT ---------------------------------------------------------
bad_ka=""
for n in ${peer_ns}; do
    ka="$(field "${n}" PersistentKeepalive)"
    if ! printf '%s' "${ka}" | grep -qE '^[0-9]+$' || [ "${ka}" -lt 10 ] || [ "${ka}" -gt 30 ]; then
        bad_ka="${bad_ka} секция ${n}:${ka:-нет}"
    fi
done
if [ -z "${bad_ka}" ]; then
    ok "PersistentKeepalive задан у всех пиров в разумных пределах"
else
    no "PersistentKeepalive:${bad_ka} — запись в NAT живёт 30–120 с, после простоя снаружи до нас не достучаться"
fi

# ---- 7. самопроверки ---------------------------------------------------------
if [ -f "${STARTER}" ] && [ "$(grep -c '^AllowedIPs = 0\.0\.0\.0/0' "${STARTER}")" -ge 2 ]; then
    ok "самопроверка: в стартере два пира с 0.0.0.0/0 — ловушка на месте"
else
    no "самопроверка: пересечение AllowedIPs в стартере исчезло — чинить нечего"
fi
if [ -f "${STARTER}" ] && ! grep -q 'PersistentKeepalive' "${STARTER}"; then
    ok "самопроверка: в стартере нет keepalive — вторая ловушка на месте"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
