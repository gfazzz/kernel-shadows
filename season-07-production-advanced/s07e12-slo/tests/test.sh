#!/usr/bin/env bash
#
# s07e12 «Бюджет ошибок» — тест программы (Type D), финал Season 7.
#
# Все ожидаемые величины тест считает сам, целочисленно, из data/slo.conf
# и data/measurements.txt. Констант нет: поменяется соглашение с
# заказчиком — поменяются и ожидания.
#
# Отдельно проверяется поведение на краях: идеальное окно даёт «ok»,
# окно без единого успешного запроса — «violated». Программа, всегда
# печатающая один и тот же приговор, эти два случая не пройдёт.
#
# Без root, без сети, без Prometheus. Нужен python3.
#
# Выбор программы: SUBJECT=... | artifacts/slo.py | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
CONF="${D}/slo.conf"; MEAS="${D}/measurements.txt"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

if   [ -n "${SUBJECT:-}" ];                      then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/slo.py" ];    then S="${SERIES_DIR}/artifacts/slo.py"
elif [ -f "${SERIES_DIR}/slo.py" ];              then S="${SERIES_DIR}/slo.py"
else S="${SERIES_DIR}/solution/slo.py"
     echo "ℹ️  Своего slo.py не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/slo.py artifacts/"; echo ""
fi

echo "════════════════════════════════════════════════════════════"
echo " s07e12 tests — программа: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

PY="$(command -v python3 || true)"
if [ -z "${PY}" ]; then
    echo "  FAIL: не найден python3 — серия Type D требует Python 3.8+"
    echo " Итог: 0 passed, 1 failed"; exit 1
fi
ok "python3 найден ($("${PY}" -c 'import sys; print(".".join(map(str,sys.version_info[:3])))'))"
for f in "${CONF}" "${MEAS}"; do [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }; done
if [ -f "${S}" ]; then ok "slo.py найден"
else no "slo.py не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
PPM=1000000

# ── соглашение ───────────────────────────────────────────────────────
c1() { awk -v k="$1" '{sub(/#.*/,"")} $1==k {print $2; exit}' "${CONF}"; }
WDAYS="$(c1 window_days)"; WARN="$(c1 budget_warn_pct)"
LONG="${WDAYS}d"
SLOS="$(awk '{sub(/#.*/,"")} $1=="slo" {print $2}' "${CONF}")"
slo_field() { awk -v n="$1" -v f="$2" '{sub(/#.*/,"")} $1=="slo" && $2==n {
                 for (i=3;i<=NF;i++) if (index($i, f "=")==1) {sub(/^[^=]*=/,"",$i); print $i; exit} }' "${CONF}"; }
BURNS="$(awk '{sub(/#.*/,"")} $1=="burn" {print $2}' "${CONF}")"
burn_thr() { awk -v w="$1" '{sub(/#.*/,"")} $1=="burn" && $2==w {
                 sub(/.*rate_x100=/,""); sub(/[^0-9].*/,""); print; exit}' "${CONF}"; }

# ── наблюдения: колонка зависит от показателя ────────────────────────
meas() { # $1 — окно, $2 — sli (requests|latency), печатает «total good»
    awk -v w="$1" -v s="$2" '{sub(/#.*/,"")} $1=="window" && $2==w {
        if (s=="requests") print $3, $4; else print $5, $6; exit}' "${MEAS}"; }

field() { awk -v k="$1" '{for (i=1;i<=NF;i++) if ($i ~ ("^" k "=")) {sub(/^[^=]*=/,"",$i); print $i; exit}}'; }

echo ""
echo "── Исходные данные ──"
N_SLO=$(grep -c . <<<"${SLOS}" || true)
[ "${N_SLO}" -ge 2 ] && ok "показателей в соглашении: ${N_SLO}" \
    || no "данные вырождены: показатель один, сравнивать нечего"
N_BURN=$(grep -c . <<<"${BURNS}" || true)
[ "${N_BURN}" -ge 2 ] && ok "окон скорости расхода: ${N_BURN}" \
    || no "данные вырождены: окно скорости одно"
# Ровно один показатель обязан быть нарушен, иначе финал сезона ничему не учит.
N_VIOL=0
for n in ${SLOS}; do
    read -r t g <<<"$(meas "${LONG}" "$(slo_field "${n}" sli)")"
    tgt="$(slo_field "${n}" target_ppm)"
    allowed=$(( t * (PPM - tgt) / PPM )); bad=$(( t - g ))
    [ "${bad}" -gt "${allowed}" ] && N_VIOL=$(( N_VIOL + 1 ))
done
[ "${N_VIOL}" -eq 1 ] && ok "за окно ${LONG} нарушен ровно один показатель" \
    || no "данные вырождены: нарушено ${N_VIOL} показателей"

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
"${PY}" "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}"
"${PY}" "${S}" "${CONF}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "с одним аргументом — код 2" || no "с одним аргументом вернул ${rc}"
"${PY}" "${S}" "${TMP}/нет" "${MEAS}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующее соглашение — код 2" || no "несуществующее соглашение: код ${rc}"
grep -v '^window' "${MEAS}" > "${TMP}/empty.txt"
"${PY}" "${S}" "${CONF}" "${TMP}/empty.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "наблюдения без окон отвергнуты" || no "пустые наблюдения приняты (код ${rc})"

echo ""
echo "── 2. Бюджет за окно ${LONG} ──"
"${PY}" "${S}" "${CONF}" "${MEAS}" > "${TMP}/out" 2>"${TMP}/err"; RC=$?
EXP_VIOL=0
for n in ${SLOS}; do
    sli="$(slo_field "${n}" sli)"; tgt="$(slo_field "${n}" target_ppm)"
    read -r t g <<<"$(meas "${LONG}" "${sli}")"
    e_actual=$(( g * PPM / t ))
    e_allowed=$(( t * (PPM - tgt) / PPM ))
    e_bad=$(( t - g ))
    e_pct=$(( e_bad * 100 / e_allowed ))
    if   [ "${e_bad}" -gt "${e_allowed}" ]; then e_verdict=violated; EXP_VIOL=1
    elif [ "${e_pct}" -ge "${WARN}" ];      then e_verdict=burning
    else e_verdict=met; fi

    line="$(awk -v n="${n}" '$1=="SLO" && $2==n' "${TMP}/out")"
    if [ -z "${line}" ]; then no "нет строки SLO ${n}"; continue; fi
    for pair in "target_ppm ${tgt}" "actual_ppm ${e_actual}" "budget_allowed ${e_allowed}" \
                "budget_spent ${e_bad}" "budget_pct ${e_pct}" "verdict ${e_verdict}"; do
        set -- ${pair}
        got="$(printf '%s' "${line}" | field "$1")"
        [ "${got}" = "$2" ] && ok "SLO ${n}: $1=$2" || no "SLO ${n}: $1=${got:-нет}, ожидается $2"
    done
done

echo ""
echo "── 3. Скорость расхода ──"
EXP_ALERT=0
for w in ${BURNS}; do
    thr="$(burn_thr "${w}")"
    for n in ${SLOS}; do
        sli="$(slo_field "${n}" sli)"; tgt="$(slo_field "${n}" target_ppm)"
        read -r t g <<<"$(meas "${w}" "${sli}")"
        [ -n "${t}" ] || continue
        bad=$(( t - g )); allowed_ppm=$(( PPM - tgt ))
        e_rate=$(( bad * PPM * 100 / (t * allowed_ppm) ))
        e_alert=no; [ "${e_rate}" -ge "${thr}" ] && { e_alert=yes; EXP_ALERT=1; }
        line="$(awk -v n="${n}" -v w="window=${w}" '$1=="BURN" && $2==n && $3==w' "${TMP}/out")"
        if [ -z "${line}" ]; then no "нет строки BURN ${n} ${w}"; continue; fi
        got="$(printf '%s' "${line}" | field rate_x100)"
        [ "${got}" = "${e_rate}" ] && ok "BURN ${n} ${w}: rate_x100=${e_rate}" \
            || no "BURN ${n} ${w}: rate_x100=${got:-нет}, ожидается ${e_rate}"
        got="$(printf '%s' "${line}" | field alert)"
        [ "${got}" = "${e_alert}" ] && ok "BURN ${n} ${w}: alert=${e_alert}" \
            || no "BURN ${n} ${w}: alert=${got:-нет}, ожидается ${e_alert}"
    done
done
[ "${EXP_ALERT}" = 1 ] && ok "хотя бы одно окно горит быстрее порога" \
    || no "данные вырождены: скорость расхода нигде не превышена"

echo ""
echo "── 4. Общий приговор ──"
if   [ "${EXP_VIOL}" = 1 ]; then e_all=violated; e_rc=1
elif [ "${EXP_ALERT}" = 1 ]; then e_all=at-risk; e_rc=0
else e_all=ok; e_rc=0; fi
got="$(awk '$1=="VERDICT" {print $2; exit}' "${TMP}/out")"
[ "${got}" = "${e_all}" ] && ok "VERDICT ${e_all}" || no "VERDICT ${got:-нет}, ожидается ${e_all}"
[ "${RC}" = "${e_rc}" ] && ok "код возврата ${e_rc}" || no "код возврата ${RC}, ожидается ${e_rc}"

echo ""
echo "── 5. Края ──"
# Идеальное окно: ни одного плохого запроса. Приговор обязан стать ok.
awk '{sub(/#.*/,""); if ($1=="window") print $1, $2, $3, $3, $5, $5; else print}' "${MEAS}" > "${TMP}/perfect.txt"
"${PY}" "${S}" "${CONF}" "${TMP}/perfect.txt" > "${TMP}/p" 2>/dev/null; rc=$?
[ "$(awk '$1=="VERDICT" {print $2}' "${TMP}/p")" = "ok" ] && ok "идеальное окно даёт ok" \
    || no "на идеальном окне приговор «$(awk '$1=="VERDICT" {print $2}' "${TMP}/p")»"
[ "${rc}" = 0 ] && ok "и код возврата 0" || no "код возврата ${rc} при полном порядке"

# Полный отказ: ни одного успешного запроса.
awk '{sub(/#.*/,""); if ($1=="window") print $1, $2, $3, 0, $5, 0; else print}' "${MEAS}" > "${TMP}/dead.txt"
"${PY}" "${S}" "${CONF}" "${TMP}/dead.txt" > "${TMP}/d" 2>/dev/null; rc=$?
[ "$(awk '$1=="VERDICT" {print $2}' "${TMP}/d")" = "violated" ] && ok "полный отказ даёт violated" \
    || no "на полном отказе приговор «$(awk '$1=="VERDICT" {print $2}' "${TMP}/d")»"
[ "${rc}" = 1 ] && ok "и код возврата 1" || no "код возврата ${rc} при нарушенном SLO"

echo ""
echo "── 6. Соглашение читается, а не зашито ──"
# Ужесточаем цель до недостижимой: нарушены должны стать оба показателя.
sed 's/target_ppm=995000/target_ppm=999999/' "${CONF}" > "${TMP}/strict.conf"
"${PY}" "${S}" "${TMP}/strict.conf" "${MEAS}" > "${TMP}/s" 2>/dev/null
n_viol=$(awk '$1=="SLO" && /verdict=violated/' "${TMP}/s" | grep -c . || true)
[ "${n_viol}" -ge 2 ] && ok "ужесточение цели в файле меняет приговор (${n_viol} нарушено)" \
    || no "цель из файла не используется: при 99.9999 % нарушено ${n_viol} показателей"

echo ""
echo "── 7. Воспроизводимость ──"
"${PY}" "${S}" "${CONF}" "${MEAS}" > "${TMP}/out2" 2>/dev/null
cmp -s "${TMP}/out" "${TMP}/out2" && ok "два прогона дают один вывод" \
    || no "вывод меняется между прогонами"
[ -s "${TMP}/err" ] && no "пишет в stderr: $(head -1 "${TMP}/err")" || ok "stderr пуст"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
