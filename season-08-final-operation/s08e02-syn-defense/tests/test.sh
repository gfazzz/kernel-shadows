#!/usr/bin/env bash
#
# s08e02 «Защита, которая держит» — тест конфигурации (Type B).
#
# Проверяются свойства, а не совпадение с эталоном: значения выводятся из
# снимков в data/, и любой набор, удовлетворяющий наблюдениям, проходит.
# Конкретное число разрешено в диапазоне, а не единственным вариантом.
#
# Отдельно проверяется, что данные не выродились: syn-cookies сейчас
# выключены, а очереди меньше обычного темпа новых соединений — иначе
# тюнить было бы нечего.
#
# nft и sysctl для прогона НЕ нужны: оба файла разбираются как текст.
# Без root, без сети.
#
# Выбор файлов: SYSCTL=... NFT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
CUR="${D}/current_sysctl.txt"; AVAIL="${D}/available_sysctl.txt"
BASE="${D}/conn_baseline.txt"; SVC="${D}/services.txt"; MGMT="${D}/mgmt_net.txt"
AFT="${D}/after_apply.txt"

pick() { # $1 — имя файла, $2 — переменная окружения
    local name="$1" env="$2"
    if   [ -n "${!env:-}" ];                      then printf '%s' "${!env}"
    elif [ -f "${SERIES_DIR}/artifacts/${name}" ]; then printf '%s' "${SERIES_DIR}/artifacts/${name}"
    elif [ -f "${SERIES_DIR}/${name}" ];           then printf '%s' "${SERIES_DIR}/${name}"
    else printf '%s' "${SERIES_DIR}/solution/${name}"; fi
}
SC="$(pick 99-syn-defense.conf SYSCTL)"
NF="$(pick syn-defense.nft NFT)"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

case "${SC}" in *solution*) echo "ℹ️  Своих файлов не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/* artifacts/"; echo "";; esac

echo "════════════════════════════════════════════════════════════"
echo " s08e02 tests — ${SC#"$SERIES_DIR"/} + ${NF#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${CUR}" "${AVAIL}" "${BASE}" "${SVC}" "${MGMT}" "${AFT}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
for f in "${SC}" "${NF}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; echo " Итог: ${PASS} passed, 1 failed"; exit 1; }
done

key()  { awk -v k="$1" '{sub(/#.*/,"")} $1==k {print $2; exit}' "$2"; }
# Значение параметра из конфигурации студента: «ключ = значение».
sval() { awk -F= -v k="$1" '{sub(/#.*/,"")} {gsub(/[ \t]/,"",$1)}
             $1==k {gsub(/[ \t\r]/,"",$2); print $2; exit}' "${SC}"; }

CUR_COOKIES="$(key net.ipv4.tcp_syncookies "${CUR}")"
CUR_SYNBL="$(key net.ipv4.tcp_max_syn_backlog "${CUR}")"
CUR_SOMAX="$(key net.core.somaxconn "${CUR}")"
CUR_RETR="$(key net.ipv4.tcp_synack_retries "${CUR}")"
CUR_NETDEV="$(key net.core.netdev_max_backlog "${CUR}")"
CUR_CT="$(key net.netfilter.nf_conntrack_max "${CUR}")"
P99="$(key new_conn_per_sec_p99 "${BASE}")"
SRC_P99="$(key new_conn_per_source_p99 "${BASE}")"
SRC_MAX="$(key new_conn_per_source_max_seen "${BASE}")"
MGMT_CIDR="$(key mgmt_cidr "${MGMT}")"

echo ""
echo "── 0. Данные не выродились ──"
[ "${CUR_COOKIES}" = "0" ] && ok "syn-cookies сейчас выключены — есть что чинить" \
    || no "данные вырождены: syn-cookies уже включены"
[ "${CUR_SYNBL}" -lt "${P99}" ] && ok "очередь (${CUR_SYNBL}) меньше обычного темпа новых соединений (${P99})" \
    || no "данные вырождены: очередь и так больше нагрузки"
[ "${SRC_MAX}" -gt "${SRC_P99}" ] && ok "у обычного клиента есть всплески (${SRC_P99} против ${SRC_MAX})" \
    || no "данные вырождены: предел на источник не с чем соотнести"

# Замер после — часть данных, а не украшение: по нему видно, что мера
# подействовала, и что подействовала она не тем, что атака прекратилась.
aft() { awk -v k="$1" -v c="$2" '{sub(/#.*/,"")} $1==k {print (c=="before" ? $2 : $3); exit}' "${AFT}"; }
[ "$(aft TcpExtListenOverflows after)" -lt "$(aft TcpExtListenOverflows before)" ] \
    && ok "после правок очередь перестала переполняться" \
    || no "данные вырождены: переполнения не изменились, мера ничего не дала"
[ "$(aft TcpExtSyncookiesRecv after)" -gt 0 ] \
    && ok "возвраты syn-cookie пошли: за ними настоящие клиенты" \
    || no "данные вырождены: ни одна cookie не вернулась и после правок"
[ "$(aft sockets_estab after)" -gt "$(aft sockets_estab before)" ] \
    && ok "установленных соединений стало больше ($(aft sockets_estab before) -> $(aft sockets_estab after))" \
    || no "данные вырождены: соединений не прибавилось"
[ "$(aft TcpExtSyncookiesSent after)" -gt "$(aft TcpExtSyncookiesSent before)" ] \
    && ok "атака не прекратилась — cookies отправляются дальше" \
    || no "данные вырождены: поток иссяк сам, и проверять нечего"

echo ""
echo "── 1. Параметры существуют в этом ядре ──"
BAD=""
while read -r k; do
    grep -qx -- "${k}" "${AVAIL}" || BAD="${BAD} ${k}"
done < <(awk -F= '{sub(/#.*/,"")} /=/ {gsub(/[ \t]/,"",$1); if ($1 ~ /^net\./) print $1}' "${SC}")
[ -z "${BAD}" ] && ok "все параметры есть в ядре 5.15" \
    || no "ядро не знает таких параметров:${BAD} — строка молча не применится"

N_PARAM=$(awk -F= '{sub(/#.*/,"")} /^[ \t]*net\./ {n++} END {print n+0}' "${SC}")
[ "${N_PARAM}" -ge 6 ] && ok "параметров в файле: ${N_PARAM}" \
    || no "параметров всего ${N_PARAM} — часть решения не записана"

# Каждый параметр обязан быть объяснён: комментарий не дальше пяти строк выше.
UNCOMMENTED=$(awk '{ if ($0 ~ /^[ \t]*#/) last=NR
                     if ($0 ~ /^[ \t]*net\./) { if (NR-last > 5) n++ } }
                   END {print n+0}' "${SC}")
[ "${UNCOMMENTED}" -eq 0 ] && ok "каждый параметр снабжён причиной" \
    || no "${UNCOMMENTED} параметров без комментария — это суеверие, а не тюнинг"

echo ""
echo "── 2. Значения выводятся из наблюдений ──"
V="$(sval net.ipv4.tcp_syncookies)"
[ "${V}" = "1" ] && ok "tcp_syncookies=1 — включение по факту переполнения" \
    || no "tcp_syncookies=${V:-пусто}: 0 не защищает, 2 ломает опции TCP у всех"

V="$(sval net.ipv4.tcp_max_syn_backlog)"
if [ -n "${V}" ] && [ "${V}" -gt "${CUR_SYNBL}" ] && [ "${V}" -ge "${P99}" ]; then
    ok "tcp_max_syn_backlog=${V} — больше прежних ${CUR_SYNBL} и не ниже темпа ${P99}"
else no "tcp_max_syn_backlog=${V:-пусто}: нужно больше ${CUR_SYNBL} и не меньше ${P99}"; fi

V="$(sval net.core.somaxconn)"; SYNBL="$(sval net.ipv4.tcp_max_syn_backlog)"
if [ -n "${V}" ] && [ -n "${SYNBL}" ] && [ "${V}" -ge "${SYNBL}" ]; then
    ok "somaxconn=${V} не меньше очереди полуоткрытых — узкое место не переехало"
else no "somaxconn=${V:-пусто} ниже tcp_max_syn_backlog=${SYNBL:-?}: очередь просто сместится"; fi

V="$(sval net.ipv4.tcp_synack_retries)"
if [ -n "${V}" ] && [ "${V}" -lt "${CUR_RETR}" ] && [ "${V}" -ge 1 ]; then
    ok "tcp_synack_retries=${V} — меньше прежних ${CUR_RETR}, но не ноль"
else no "tcp_synack_retries=${V:-пусто}: нужно меньше ${CUR_RETR} и не меньше 1"; fi

V="$(sval net.ipv4.tcp_abort_on_overflow)"
[ "${V}" = "0" ] && ok "tcp_abort_on_overflow=0 — очередь под нагрузкой не рвёт клиентов" \
    || no "tcp_abort_on_overflow=${V:-пусто}: единица рвёт соединения настоящих клиентов"

V="$(sval net.core.netdev_max_backlog)"
if [ -n "${V}" ] && [ "${V}" -gt "${CUR_NETDEV}" ]; then
    ok "netdev_max_backlog=${V} — больше прежних ${CUR_NETDEV}"
else no "netdev_max_backlog=${V:-пусто}: при миллионах пакетов в секунду ${CUR_NETDEV} мало"; fi

V="$(sval net.ipv4.conf.all.rp_filter)"
[ "${V}" = "1" ] && ok "rp_filter=1 — часть подделанных адресов отсекается до фильтра" \
    || no "rp_filter=${V:-пусто}: обратная проверка маршрута выключена"

V="$(sval net.netfilter.nf_conntrack_max)"
if [ -n "${V}" ] && [ "${V}" -gt "${CUR_CT}" ]; then
    ok "nf_conntrack_max=${V} — больше прежних ${CUR_CT}"
else no "nf_conntrack_max=${V:-пусто}: переполнение таблицы выглядит как отказ сети"; fi

echo ""
echo "── 3. Правила: политика и порядок ──"
# Правило nft может занимать несколько строк через «\» в конце. Склеиваем
# продолжения и убираем комментарии, иначе номер строки перестаёт означать
# порядок правил, а величина находится не в том правиле.
code() { sed 's/#.*//' "${NF}" | awk '{ if (buf != "") { buf = buf " " $0 } else { buf = $0 }
        if (buf ~ /\\[ \t]*$/) { sub(/\\[ \t]*$/, "", buf); next }
        print buf; buf = "" } END { if (buf != "") print buf }'; }
lineof() { code | grep -nE "$1" | head -1 | cut -d: -f1; }

code | grep -qE 'hook input .*policy drop' \
    && ok "входная цепочка: политика drop" \
    || no "во входной цепочке нет policy drop — разрешено всё, что не запрещено"
code | grep -qE 'hook forward .*policy drop' \
    && ok "пересылка запрещена" || no "forward без policy drop"

L_EST="$(lineof 'ct state established')"
# Ограничитель темпа — то правило, которое смотрит на флаг SYN. Правил с
# «limit rate» в наборе бывает несколько (например, ICMP), и порядок надо
# сверять именно с этим.
L_LIM="$(lineof 'tcp flags syn')"
[ -n "${L_EST}" ] && ok "установленные соединения принимаются" \
    || no "нет правила ct state established,related accept"
if [ -n "${L_EST}" ] && [ -n "${L_LIM}" ] && [ "${L_EST}" -lt "${L_LIM}" ]; then
    ok "established стоит выше ограничителя темпа"
else no "ограничитель темпа стоит выше established: каждый пакет сессии считается за новый"; fi

code | grep -qE 'ct state invalid drop' && ok "мусорные пакеты отбрасываются сразу" \
    || no "нет ct state invalid drop"
code | grep -qE 'iif(name)? *"?lo"? *accept' && ok "петля не отрезана" \
    || no "нет iif lo accept — узел ломает сам себя"

echo ""
echo "── 4. Доступ, который обязан остаться ──"
for p in 80 443; do
    code | grep -E 'accept' | grep -qE "(dport|,) *\{?[^}]*\b${p}\b" \
        && ok "порт ${p} открыт" || no "порт ${p} закрыт — узел перестал делать то, ради чего стоит"
done
L_MGMT="$(code | grep -nF "${MGMT_CIDR}" | head -1 | cut -d: -f1)"
if [ -n "${L_MGMT}" ] && code | sed -n "${L_MGMT}p" | grep -qE '\b22\b'; then
    ok "SSH разрешён из управляющей сети ${MGMT_CIDR}"
else no "SSH из ${MGMT_CIDR} не разрешён — дежурный не попадёт на узел"; fi
if [ -n "${L_MGMT}" ] && [ -n "${L_LIM}" ] && [ "${L_MGMT}" -lt "${L_LIM}" ]; then
    ok "доступ дежурного выше ограничителя темпа"
else no "доступ дежурного ниже ограничителя: под атакой его отрежет вместе со всеми"; fi
if code | grep -E '\b9100\b' | grep -qF "${MGMT_CIDR}"; then
    ok "9100 открыт только управляющей сети"
else no "порт метрик 9100 открыт не только из ${MGMT_CIDR}"; fi

echo ""
echo "── 5. Ограничитель темпа ──"
if [ -n "${L_LIM}" ]; then ok "ограничитель темпа есть"; else no "ограничителя темпа нет"; fi
code | grep -E 'limit rate' | grep -qE 'ip saddr|meter|@' \
    && ok "предел считается на источник, а не общий" \
    || no "предел общий: под распределённой атакой он закрывает вход всем сразу"
code | grep -qE 'tcp flags syn' \
    && ok "ограничитель применяется к SYN, а не ко всем пакетам" \
    || no "не видно, что ограничивается именно установка соединений"
RATE="$(code | grep -E 'tcp flags syn' | grep -oE 'rate (over )?[0-9]+/second' | grep -oE '[0-9]+' | head -1)"
if [ -n "${RATE}" ] && [ "${RATE}" -gt "${SRC_P99}" ] && [ "${RATE}" -le $(( SRC_MAX * 2 )) ]; then
    ok "предел ${RATE}/с обоснован наблюдением (p99=${SRC_P99}, максимум ${SRC_MAX})"
else no "предел ${RATE:-нет}/с: должен быть выше ${SRC_P99} и не выше $(( SRC_MAX * 2 ))"; fi
code | grep -E 'limit rate' | grep -qE 'burst' \
    && ok "всплеск разрешён: браузер открывает несколько соединений разом" \
    || no "нет burst — клиент, открывший вкладку, попадёт под ограничитель"

echo ""
echo "── 6. Ловушки ──"
code | grep -qE '^\s*set .*\{' && code | grep -qE 'timeout [0-9]' \
    && ok "у множества есть время жизни записи" \
    || no "множество без timeout: под атакой оно растёт, пока не кончится память"
code | grep -qE 'size [0-9]+' && ok "у множества есть предел размера" \
    || no "множество без size — та же утечка, только медленнее"
N_SADDR=$(code | grep -cE 'ip saddr' || true)
[ "${N_SADDR}" -le 2 ] && ok "списка блокировки по адресам нет (${N_SADDR} правил с ip saddr)" \
    || no "${N_SADDR} правил по адресам источников — они подделаны (s08e01), список бесполезен"
grep -qE 'tcp_tw_recycle' "${SC}" \
    && no "tcp_tw_recycle: параметр удалён из ядра 4.12 и ломал клиентов за NAT" \
    || ok "нет tcp_tw_recycle — совета, пережившего своё ядро"

echo ""
echo "── 7. Форма ──"
head -1 "${NF}" | grep -q '^#!' && ok "shebang nft на месте" || no "нет строки #! в наборе правил"
grep -qE '^\s*#' "${SC}" && grep -qE '^\s*#' "${NF}" \
    && ok "комментарии сохранены в обоих файлах" || no "комментарии удалены"
grep -qE '^\s*flush ruleset' "${NF}" \
    && ok "набор применяется целиком, а не поверх прежнего" \
    || no "нет flush ruleset: правила лягут поверх старых и порядок станет непредсказуем"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
