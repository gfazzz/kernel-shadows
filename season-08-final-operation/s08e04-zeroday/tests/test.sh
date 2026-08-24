#!/usr/bin/env bash
#
# s08e04 «Нулевой день» — тест временной меры (Type B).
#
# Две группы проверок. Первая — свойства самого фрагмента: закрыты ли оба
# условия из бюллетеня, есть ли у меры срок и условие снятия, не выключен
# ли сервис целиком. Вторая — прогон корпуса запросов: ни одна попытка
# эксплуатации не должна пройти и ни один законный запрос не должен
# потеряться. Второе ломается чаще первого.
#
# Прогон корпуса — упрощённая модель: тест разбирает из фрагмента предел
# тела и проверку кодировки и применяет их к каждой строке корпуса. Полного
# nginx здесь нет и не требуется.
#
# Пороги берутся из data/advisory.txt, а не зашиты: поменяется бюллетень —
# поменяются ожидания.
#
# Без root, без сети, без nginx.
#
# Выбор фрагмента: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
ADV="${D}/advisory.txt"; MAP="${D}/service_map.txt"; COR="${D}/request_corpus.txt"

if   [ -n "${SUBJECT:-}" ];                                      then C="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/zeroday-mitigation.conf" ];   then C="${SERIES_DIR}/artifacts/zeroday-mitigation.conf"
elif [ -f "${SERIES_DIR}/zeroday-mitigation.conf" ];             then C="${SERIES_DIR}/zeroday-mitigation.conf"
else C="${SERIES_DIR}/solution/zeroday-mitigation.conf"
     echo "ℹ️  Своего zeroday-mitigation.conf не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/zeroday-mitigation.conf artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e04 tests — мера: ${C#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${ADV}" "${MAP}" "${COR}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
[ -f "${C}" ] || { echo "  FAIL: нет ${C}"; echo " Итог: 0 passed, 1 failed"; exit 1; }

adv() { awk -v k="$1" '$1==k {sub(/^[^ \t]+[ \t]+/,""); print; exit}' "${ADV}"; }
ADV_ID="$(adv advisory_id)"
T_PATH="$(adv trigger_path)"
T_KB="$(adv trigger_body_over_kb)"
ETA="$(adv patch_eta_days)"
DAY=57   # день операции, в который пришёл бюллетень

# ── исходные данные не выродились ────────────────────────────────────
echo ""
echo "── 0. Данные не выродились ──"
N_EXP=$(awk '$5=="exploit"' "${COR}" | grep -c . || true)
N_LEG=$(awk -v p="${T_PATH}" '$5=="legit" && $2==p' "${COR}" | grep -c . || true)
N_LEG_OTHER=$(awk -v p="${T_PATH}" '$5=="legit" && $2!=p' "${COR}" | grep -c . || true)
[ "${N_EXP}" -ge 5 ] && ok "в корпусе ${N_EXP} попыток эксплуатации" \
    || no "данные вырождены: попыток ${N_EXP}"
[ "${N_LEG}" -ge 5 ] && ok "и ${N_LEG} законных запросов к тому же пути — «запретить путь» не пройдёт" \
    || no "данные вырождены: законных запросов к ${T_PATH} всего ${N_LEG}"
[ "${N_LEG_OTHER}" -ge 5 ] && ok "плюс ${N_LEG_OTHER} законных запросов к другим путям" \
    || no "данные вырождены: другие пути в корпусе не представлены"
MAXLEG=$(awk -v p="${T_PATH}" '$5=="legit" && $2==p {if ($4+0>m) m=$4+0} END {print m+0}' "${COR}")
[ "${MAXLEG}" -lt "${T_KB}" ] && ok "самая крупная законная загрузка (${MAXLEG} КБ) меньше порога бюллетеня (${T_KB} КБ)" \
    || no "данные вырождены: законная загрузка ${MAXLEG} КБ не отличима от эксплуатации"

# ── 1. заголовок меры ────────────────────────────────────────────────
echo ""
echo "── 1. У меры есть срок и условие снятия ──"
hdr() { awk -v k="$1" 'tolower($0) ~ ("^# *" k ":") {sub(/^[^:]*: */,""); print; exit}' "${C}"; }
H_ADV="$(hdr advisory)"; H_EXP="$(hdr expires)"; H_RM="$(hdr remove-when)"
[ -n "${H_ADV}" ] && ok "указан бюллетень: ${H_ADV}" || no "нет строки advisory: — меру не найти по идентификатору"
[ "${H_ADV}" = "${ADV_ID}" ] && ok "идентификатор совпадает с бюллетенем" \
    || no "advisory: «${H_ADV}», в бюллетене ${ADV_ID}"
EXP_DAY="$(printf '%s' "${H_EXP}" | grep -oE '[0-9]+' | head -1)"
if [ -n "${EXP_DAY}" ]; then
    if [ "${EXP_DAY}" -gt "${DAY}" ]; then ok "срок в будущем: день ${EXP_DAY}"
    else no "срок «день ${EXP_DAY}» уже прошёл: сегодня ${DAY}-й"; fi
    LIMIT=$(( DAY + 4 * ETA ))
    if [ "${EXP_DAY}" -le "${LIMIT}" ]; then ok "срок разумен: не дальше дня ${LIMIT} (четыре обещанных срока патча)"
    else no "срок «день ${EXP_DAY}» дальше дня ${LIMIT} — это уже не временная мера"; fi
else no "нет строки expires: с номером дня — мера станет постоянной"; fi
[ -n "${H_RM}" ] && ok "названо условие снятия" || no "нет строки remove-when: — снимать будет некому и не по чему"

# ── 2. свойства фрагмента ────────────────────────────────────────────
echo ""
echo "── 2. Закрыто ровно то, что нужно ──"
# Тело фрагмента без комментариев.
BODY="$(sed 's/#.*//' "${C}")"
grep -qE "location[ \t]*=[ \t]*${T_PATH}[ \t]*\{" <<<"${BODY}" \
    && ok "есть точное совпадение пути: location = ${T_PATH}" \
    || no "нет блока location = ${T_PATH} — мера не адресует уязвимый путь"
CMBS="$(grep -oiE 'client_max_body_size[ \t]+[0-9]+[kKmM]?' <<<"${BODY}" | head -1)"
CMBS_N="$(printf '%s' "${CMBS}" | grep -oE '[0-9]+' | head -1)"
case "${CMBS,,}" in *m) CMBS_KB=$(( CMBS_N * 1024 ));; *) CMBS_KB="${CMBS_N:-0}";; esac
if [ -n "${CMBS_N}" ]; then
    ok "предел тела задан: ${CMBS}"
    [ "${CMBS_KB}" -le "${T_KB}" ] && ok "предел (${CMBS_KB} КБ) не выше порога бюллетеня (${T_KB} КБ)" \
        || no "предел ${CMBS_KB} КБ выше порога ${T_KB} КБ — первое условие не закрыто"
    [ "${CMBS_KB}" -gt "${MAXLEG}" ] && ok "и выше самой крупной законной загрузки (${MAXLEG} КБ)" \
        || no "предел ${CMBS_KB} КБ режет законные загрузки до ${MAXLEG} КБ"
else no "нет client_max_body_size — тело не ограничено"; fi
grep -qiE '\$http_transfer_encoding' <<<"${BODY}" \
    && ok "проверяется заголовок Transfer-Encoding" \
    || no "второе условие бюллетеня (chunked) не закрыто"
grep -qiE 'chunked' <<<"${BODY}" && ok "именно на значение chunked" || no "значение chunked в проверке не названо"
grep -qiE 'return[ \t]+(403|444)' <<<"${BODY}" \
    && ok "совпадение отклоняется явным кодом" \
    || no "нет return 403 (или 444) — совпадение ничем не заканчивается"
grep -qiE 'access_log' <<<"${BODY}" \
    && ok "срабатывания пишутся в журнал" \
    || no "нет access_log — узнать, работает ли мера, будет нечем"
grep -qiE 'proxy_pass' <<<"${BODY}" \
    && ok "то, что прошло, передаётся приложению" \
    || no "нет proxy_pass — блок перехватил путь и никуда его не отдал"

echo ""
echo "── 3. Сервис не выключен целиком ──"
grep -qiE '^[ \t]*deny[ \t]+all[ \t]*;' <<<"${BODY}" && DENY_TOP=yes || DENY_TOP=no
if grep -qiE 'limit_except' <<<"${BODY}"; then
    ok "deny all стоит внутри limit_except — ограничены методы, а не путь"
else
    [ "${DENY_TOP}" = no ] && ok "нет безусловного deny all" \
        || no "deny all вне limit_except выключает путь целиком — это тоже отказ в обслуживании"
fi
grep -qiE 'user_agent' <<<"${BODY}" \
    && no "мера опирается на User-Agent — заголовок задаёт нападающий" \
    || ok "мера не опирается на User-Agent"
grep -qiE 'location[ \t]*/[ \t]*\{' <<<"${BODY}" \
    && no "фрагмент переопределяет location / — он подключается рядом, а не вместо" \
    || ok "общий location / не тронут"

# ── 4. прогон корпуса ────────────────────────────────────────────────
echo ""
echo "── 4. Прогон корпуса запросов ──"
# Модель: блокируется, если путь совпал и (кодировка chunked при наличии
# проверки) или (тело больше заданного предела).
CHK=no; grep -qiE '\$http_transfer_encoding' <<<"${BODY}" && grep -qiE 'chunked' <<<"${BODY}" && CHK=yes
ONLY_POST=no; grep -qiE 'limit_except[ \t]+POST' <<<"${BODY}" && ONLY_POST=yes
read -r EXP_BLOCKED EXP_TOTAL LEG_BLOCKED LEG_TOTAL BORD_BLOCKED <<<"$(
awk -v p="${T_PATH}" -v lim="${CMBS_KB:-0}" -v chk="${CHK}" -v onlypost="${ONLY_POST}" '
    {sub(/#.*/,"")} NF<5 {next}
    {
        blocked = 0
        if ($2 == p) {
            if (chk == "yes" && tolower($3) == "chunked") blocked = 1
            if (lim > 0 && $4+0 > lim)                    blocked = 1
            if (onlypost == "yes" && $1 != "POST")        blocked = 1
        }
        if ($5 == "exploit")    { et++; if (blocked) eb++ }
        if ($5 == "legit")      { lt++; if (blocked) lb++ }
        if ($5 == "borderline") {       if (blocked) bb++ }
    }
    END { print eb+0, et+0, lb+0, lt+0, bb+0 }' "${COR}")"

[ "${EXP_BLOCKED}" = "${EXP_TOTAL}" ] \
    && ok "отклонены все попытки эксплуатации: ${EXP_BLOCKED} из ${EXP_TOTAL}" \
    || no "прошло $(( EXP_TOTAL - EXP_BLOCKED )) попыток из ${EXP_TOTAL}"
[ "${LEG_BLOCKED}" = 0 ] \
    && ok "не потеряно ни одного законного запроса (проверено ${LEG_TOTAL})" \
    || no "заблокировано ${LEG_BLOCKED} законных запросов из ${LEG_TOTAL} — мера бьёт по своим"
[ "${BORD_BLOCKED}" -gt 0 ] \
    && ok "пограничные запросы (одно условие из двух) тоже отклонены: ${BORD_BLOCKED} — осознанная цена меры вендора" \
    || no "пограничные запросы проходят: мера уже́ описания уязвимости"

echo ""
echo "── 5. Форма ──"
grep -q '^#' "${C}" && ok "комментарии сохранены: меру будет снимать другой человек" \
    || no "комментариев нет — через три дня никто не вспомнит, зачем этот блок"
awk 'BEGIN{o=0;c=0} {gsub(/#.*/,""); o+=gsub(/\{/,"{"); c+=gsub(/\}/,"}")} END{exit !(o==c && o>0)}' "${C}" \
    && ok "скобки сбалансированы" || no "скобки не сбалансированы — nginx такой конфиг не прочитает"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
