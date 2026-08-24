#!/usr/bin/env bash
#
# s08e03 «Что отдать в blackhole» — тест программы (Type D).
#
# Тест не сверяет вывод с эталоном: он решает ту же задачу сам,
# независимым перебором в awk, и требует, чтобы потеря ценности совпала
# с наименьшей возможной. Любой набор, дающий ту же потерю, принимается —
# проверяется свойство решения, а не его форма.
#
# Отдельно проверяются края: канал, в который влезает всё (сбрасывать
# нечего), и канал, в который не влезает ничего (решение выше по течению).
#
# Без root, без сети. Нужен python3.
#
# Выбор программы: SUBJECT=... | artifacts/blackhole.py | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
PFX="${D}/prefixes.txt"; POL="${D}/policy.txt"

if   [ -n "${SUBJECT:-}" ];                          then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/blackhole.py" ];  then S="${SERIES_DIR}/artifacts/blackhole.py"
elif [ -f "${SERIES_DIR}/blackhole.py" ];            then S="${SERIES_DIR}/blackhole.py"
else S="${SERIES_DIR}/solution/blackhole.py"
     echo "ℹ️  Своего blackhole.py не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/blackhole.py artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e03 tests — программа: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

PY="$(command -v python3 || true)"
[ -n "${PY}" ] || { echo "  FAIL: не найден python3 — серия Type D требует Python 3.8+"
                    echo " Итог: 0 passed, 1 failed"; exit 1; }
ok "python3 найден ($("${PY}" -c 'import sys; print(".".join(map(str,sys.version_info[:3])))'))"
for f in "${PFX}" "${POL}"; do [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }; done
[ -f "${S}" ] && ok "blackhole.py найден" \
    || { no "blackhole.py не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

pol() { awk -v k="$1" '{sub(/#.*/,"")} $1==k {print $2; exit}' "${2:-${POL}}"; }
CAP="$(pol uplink_capacity_mbps)"; UTIL="$(pol max_util_pct)"
LIMIT=$(( CAP * UTIL / 100 ))
N=$(awk '{sub(/#.*/,"")} NF==6 {n++} END {print n+0}' "${PFX}")
TOTAL=$(awk '{sub(/#.*/,"")} NF==6 {s+=$3} END {print s+0}' "${PFX}")
CRIT=$(awk '{sub(/#.*/,"")} NF==6 && $6=="yes" {s+=$3} END {print s+0}' "${PFX}")
N_CRIT=$(awk '{sub(/#.*/,"")} NF==6 && $6=="yes" {n++} END {print n+0}' "${PFX}")

# ── независимое решение той же задачи: перебор подмножеств ───────────
# Печатает «наименьшая_потеря наименьший_законный жадная_потеря».
solve() { # $1 — файл префиксов, $2 — предел в мегабитах
    awk -v limit="$2" '
    # n инициализируется явно: в awk неинициализированная переменная как
    # индекс массива — это пустая строка, а не ноль, и первый элемент
    # уезжает в tot[""]. Перебор при этом идёт и даёт правдоподобный, но
    # неверный ответ.
    BEGIN { n = 0 }
    {sub(/#.*/,"")} NF==6 { sum+=$3
        if ($6=="yes") next                 # неприкосновенные в перебор не входят
        tot[n]=$3; leg[n]=$4; val[n]=$5; pfx[n]=$1; n++ }
    END {
        best=-1
        for (m = 0; m < 2^n; m++) {
            d=0; v=0; l=0
            for (i = 0; i < n; i++) if (int(m / 2^i) % 2 == 1) { d+=tot[i]; v+=val[i]; l+=leg[i] }
            if (sum - d > limit) continue
            if (best < 0 || v < best || (v == best && l < bleg)) { best=v; bleg=l }
        }
        # Жадный: сначала наименьшая ценность на мегабит.
        for (i = 0; i < n; i++) { key[i] = val[i] * 10000 / tot[i]; ord[i]=i }
        for (i = 0; i < n; i++) for (j = i+1; j < n; j++)
            if (key[ord[j]] < key[ord[i]] || (key[ord[j]] == key[ord[i]] && pfx[ord[j]] < pfx[ord[i]])) {
                t=ord[i]; ord[i]=ord[j]; ord[j]=t }
        gd=0; gv=0
        for (i = 0; i < n; i++) { if (sum - gd <= limit) break; gd += tot[ord[i]]; gv += val[ord[i]] }
        if (sum - gd > limit) gv = -1
        print best, bleg, gv
    }' "$1"
}
read -r E_VALUE E_LEGIT E_GREEDY <<<"$(solve "${PFX}" "${LIMIT}")"

echo ""
echo "── 0. Данные не выродились ──"
[ "${N}" -ge 6 ] && ok "префиксов в задаче: ${N}" || no "префиксов ${N} — перебирать нечего"
[ "${TOTAL}" -gt "${LIMIT}" ] \
    && ok "трафик (${TOTAL}) не влезает в допустимые ${LIMIT} — решение нужно" \
    || no "данные вырождены: всё и так влезает"
[ "${E_GREEDY}" -gt "${E_VALUE}" ] \
    && ok "жадный выбор хуже наилучшего (${E_GREEDY} против ${E_VALUE}) — задача не тривиальна" \
    || no "данные вырождены: жадный выбор совпадает с наилучшим, сравнивать нечего"
[ "${N_CRIT}" -ge 1 ] && [ "${CRIT}" -le "${LIMIT}" ] \
    && ok "неприкосновенных префиксов ${N_CRIT}, и сами по себе они в канал влезают" \
    || no "данные вырождены: неприкосновенных ${N_CRIT}, их трафик ${CRIT} против предела ${LIMIT}"

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
"${PY}" "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}"
"${PY}" "${S}" "${PFX}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "с одним аргументом — код 2" || no "с одним аргументом вернул ${rc}"
"${PY}" "${S}" "${TMP}/нет" "${POL}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий файл — код 2" || no "несуществующий файл: код ${rc}"
awk '{sub(/#.*/,"")} NF==6 {print $1, $2, $3, $4}' "${PFX}" > "${TMP}/broken.txt"
"${PY}" "${S}" "${TMP}/broken.txt" "${POL}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "строка не из шести полей отвергнута" || no "битый вход принят (код ${rc})"
sed 's/^uplink_capacity_mbps.*/uplink_capacity_mbps 0/' "${POL}" > "${TMP}/zerocap.txt"
"${PY}" "${S}" "${PFX}" "${TMP}/zerocap.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "нулевая ёмкость канала отвергнута как испорченный вход" \
    || no "нулевая ёмкость принята (код ${rc}) — дальше деление на ноль"

echo ""
echo "── 2. Основной прогон ──"
"${PY}" "${S}" "${PFX}" "${POL}" > "${TMP}/out" 2>"${TMP}/err"; RC=$?
[ "${RC}" = 0 ] && ok "код возврата 0" || no "код возврата ${RC}, ожидается 0"
[ -s "${TMP}/err" ] && no "пишет в stderr: $(head -1 "${TMP}/err")" || ok "stderr пуст"

N_OUT=$(grep -c '^PREFIX ' "${TMP}/out" || true)
[ "${N_OUT}" = "${N}" ] && ok "строк PREFIX столько же, сколько префиксов (${N})" \
    || no "строк PREFIX ${N_OUT}, ожидается ${N}"
diff <(awk '{sub(/#.*/,"")} NF==6 {print $1}' "${PFX}") \
     <(awk '$1=="PREFIX" {print $2}' "${TMP}/out") >/dev/null \
    && ok "порядок префиксов совпадает с входным файлом" \
    || no "порядок префиксов изменён — отчёт нельзя сверить с входом построчно"
BAD=$(awk '$1=="PREFIX" {for (i=1;i<=NF;i++) if ($i ~ /^action=/) { a=$i
              if (a != "action=keep" && a != "action=blackhole") n++ }} END {print n+0}' "${TMP}/out")
[ "${BAD}" -eq 0 ] && ok "у каждого префикса действие keep или blackhole" \
    || no "${BAD} строк с непонятным действием"

echo ""
echo "── 3. Решение оптимально ──"
field() { awk -v k="$1" '{for (i=1;i<=NF;i++) if ($i ~ ("^" k "=")) {sub(/^[^=]*=/,"",$i); print $i; exit}}'; }
LOST_V="$(grep '^LOST ' "${TMP}/out" | field value)"
LOST_L="$(grep '^LOST ' "${TMP}/out" | field legit_mbps)"
AFTER="$(grep '^TOTAL ' "${TMP}/out" | field after_mbps)"
BEFORE="$(grep '^TOTAL ' "${TMP}/out" | field before_mbps)"
LIM_OUT="$(grep '^TOTAL ' "${TMP}/out" | field limit_mbps)"
HEAD="$(grep '^TOTAL ' "${TMP}/out" | field headroom_pct)"

[ "${BEFORE}" = "${TOTAL}" ] && ok "before_mbps=${TOTAL}" || no "before_mbps=${BEFORE:-нет}, ожидается ${TOTAL}"
[ "${LIM_OUT}" = "${LIMIT}" ] && ok "limit_mbps=${LIMIT} (${UTIL} % от ${CAP})" \
    || no "limit_mbps=${LIM_OUT:-нет}, ожидается ${LIMIT}"

# Остаток, посчитанный по самим строкам вывода, а не по слову программы.
SUM_KEPT=$(awk '$1=="PREFIX" && /action=keep/ {for (i=1;i<=NF;i++) if ($i ~ /^total_mbps=/)
                 {sub(/^[^=]*=/,"",$i); s+=$i}} END {print s+0}' "${TMP}/out")
[ "${SUM_KEPT}" = "${AFTER}" ] && ok "after_mbps сходится с суммой оставленных префиксов" \
    || no "after_mbps=${AFTER:-нет}, а сумма оставленных ${SUM_KEPT}"
[ -n "${AFTER}" ] && [ "${AFTER}" -le "${LIMIT}" ] && ok "остаток укладывается в предел" \
    || no "остаток ${AFTER:-?} превышает предел ${LIMIT}"

SUM_LOSTV=$(awk '$1=="PREFIX" && /action=blackhole/ {for (i=1;i<=NF;i++) if ($i ~ /^value=/)
                 {sub(/^[^=]*=/,"",$i); s+=$i}} END {print s+0}' "${TMP}/out")
SUM_LOSTL=$(awk '$1=="PREFIX" && /action=blackhole/ {for (i=1;i<=NF;i++) if ($i ~ /^legit_mbps=/)
                 {sub(/^[^=]*=/,"",$i); s+=$i}} END {print s+0}' "${TMP}/out")
[ "${SUM_LOSTV}" = "${LOST_V}" ] && ok "LOST value сходится с отмеченными префиксами" \
    || no "LOST value=${LOST_V:-нет}, а по строкам ${SUM_LOSTV}"
[ "${SUM_LOSTL}" = "${LOST_L}" ] && ok "LOST legit_mbps сходится с отмеченными префиксами" \
    || no "LOST legit_mbps=${LOST_L:-нет}, а по строкам ${SUM_LOSTL}"

[ "${LOST_V}" = "${E_VALUE}" ] \
    && ok "потеря ценности ${LOST_V} — наименьшая возможная (проверено перебором)" \
    || no "потеря ценности ${LOST_V:-нет}, а наименьшая возможная ${E_VALUE}"
E_HEAD=$(( (CAP - AFTER) * 100 / CAP ))
[ "${HEAD}" = "${E_HEAD}" ] && ok "headroom_pct=${E_HEAD}" \
    || no "headroom_pct=${HEAD:-нет}, ожидается ${E_HEAD}"

# Минимальность: без любого из отданных префиксов остаток уже не влезает.
NOT_MINIMAL=$(awk -v after="${AFTER}" -v limit="${LIMIT}" '
    $1=="PREFIX" && /action=blackhole/ {
        for (i=1;i<=NF;i++) if ($i ~ /^total_mbps=/) { sub(/^[^=]*=/,"",$i)
            if (after + $i <= limit) n++ } } END {print n+0}' "${TMP}/out")
[ "${NOT_MINIMAL}" -eq 0 ] && ok "набор минимален: лишних префиксов не отдано" \
    || no "${NOT_MINIMAL} префиксов отданы напрасно — без них остаток тоже влезал"

GR_V="$(grep '^GREEDY ' "${TMP}/out" | field value)"
GR_W="$(grep '^GREEDY ' "${TMP}/out" | field worse_by)"
[ "${GR_V}" = "${E_GREEDY}" ] && ok "жадный выбор посчитан верно (${E_GREEDY})" \
    || no "GREEDY value=${GR_V:-нет}, ожидается ${E_GREEDY}"
[ "${GR_W}" = "$(( E_GREEDY - E_VALUE ))" ] \
    && ok "разница с жадным: ${GR_W}" || no "worse_by=${GR_W:-нет}, ожидается $(( E_GREEDY - E_VALUE ))"
[ "$(awk '$1=="VERDICT" {print $2}' "${TMP}/out")" = "fits" ] && ok "VERDICT fits" \
    || no "VERDICT $(awk '$1=="VERDICT" {print $2}' "${TMP}/out"), ожидается fits"

echo ""
echo "── 4. Края ──"
# Канал, в который влезает всё: отдавать нечего.
sed 's/^uplink_capacity_mbps.*/uplink_capacity_mbps 100000/' "${POL}" > "${TMP}/big.txt"
"${PY}" "${S}" "${PFX}" "${TMP}/big.txt" > "${TMP}/b" 2>/dev/null; rc=$?
[ "$(grep -c 'action=blackhole' "${TMP}/b" || true)" -eq 0 ] \
    && ok "при широком канале не отдано ничего" \
    || no "при широком канале что-то отдано напрасно"
[ "${rc}" = 0 ] && ok "и код возврата 0" || no "код возврата ${rc} при свободном канале"

# Канал уже неприкосновенного: решение здесь не принимается.
sed 's/^max_util_pct.*/max_util_pct 10/' "${POL}" > "${TMP}/tiny.txt"
"${PY}" "${S}" "${PFX}" "${TMP}/tiny.txt" > "${TMP}/z" 2>/dev/null; rc=$?
[ "$(awk '$1=="VERDICT" {print $2}' "${TMP}/z")" = "impossible" ] \
    && ok "когда неприкосновенное шире канала — приговор impossible" \
    || no "приговор «$(awk '$1=="VERDICT" {print $2}' "${TMP}/z")», ожидается impossible"
[ "${rc}" = 1 ] && ok "и код возврата 1" || no "код возврата ${rc}, ожидается 1"
[ "$(grep -c 'action=blackhole' "${TMP}/z" || true)" -eq 0 ] \
    && ok "и ничего не отдано: отдавать бесполезно" \
    || no "часть префиксов отдана, хотя это ничего не решает"


# Политика читается, а не зашита: ужесточение меняет решение.
sed 's/^max_util_pct.*/max_util_pct 40/' "${POL}" > "${TMP}/strict.txt"
"${PY}" "${S}" "${PFX}" "${TMP}/strict.txt" > "${TMP}/s" 2>/dev/null
read -r S_VALUE _ _ <<<"$(solve "${PFX}" $(( CAP * 40 / 100 )))"
S_OUT="$(grep '^LOST ' "${TMP}/s" | field value)"
[ "${S_OUT}" = "${S_VALUE}" ] && ok "ужесточение политики меняет решение (потеря ${S_VALUE})" \
    || no "при max_util_pct=40 потеря ${S_OUT:-нет}, ожидается ${S_VALUE}"

# Неприкосновенные не отдаются даже тогда, когда это дешевле всего.
BROKEN_CRIT=$(awk 'NR==FNR { if ($0 !~ /^#/ && NF==6 && $6=="yes") c[$1]=1; next }
                   $1=="PREFIX" && /action=blackhole/ && ($2 in c) {n++} END {print n+0}' \
                   "${PFX}" "${TMP}/s")
[ "${BROKEN_CRIT}" -eq 0 ] && ok "при жёсткой политике неприкосновенные всё равно не отданы" \
    || no "${BROKEN_CRIT} неприкосновенных префиксов отдано — договор нарушен"

echo ""
echo "── 5. Воспроизводимость ──"
"${PY}" "${S}" "${PFX}" "${POL}" > "${TMP}/out2" 2>/dev/null
cmp -s "${TMP}/out" "${TMP}/out2" && ok "два прогона дают один вывод" \
    || no "вывод меняется между прогонами — решение не воспроизводимо"
LC_ALL=C "${PY}" "${S}" "${PFX}" "${POL}" > "${TMP}/outc" 2>/dev/null
cmp -s "${TMP}/out" "${TMP}/outc" && ok "локаль на вывод не влияет" || no "вывод зависит от локали"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
