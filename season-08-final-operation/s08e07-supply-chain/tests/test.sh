#!/usr/bin/env bash
#
# s08e07 «Образ, которому верили» — тест скрипта (Type A).
#
# Тест порождает собственный инвентарь (tests/make_inventory.py), в котором
# заранее известно, какие образы испорчены и как. Ответы из data/ здесь не
# помогают: в каждом прогоне портятся другие образы.
#
# Проверяются обе ошибки: пропущенная находка и ложное срабатывание на
# чистом инвентаре.
#
# Без root, без сети, без docker. Нужен python3 для стенда.
#
# Выбор скрипта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
T="${SERIES_DIR}/tests"

if   [ -n "${SUBJECT:-}" ];                                 then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/verify_supply.sh" ];     then S="${SERIES_DIR}/artifacts/verify_supply.sh"
elif [ -f "${SERIES_DIR}/verify_supply.sh" ];               then S="${SERIES_DIR}/verify_supply.sh"
else S="${SERIES_DIR}/solution/verify_supply.sh"
     echo "ℹ️  Своего verify_supply.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/verify_supply.sh artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e07 tests — скрипт: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${S}" ] || { echo "  FAIL: нет ${S}"; echo " Итог: 0 passed, 1 failed"; exit 1; }
PY="$(command -v python3 || true)"
if [ -z "${PY}" ]; then
    echo "  SKIP: не найден python3 — им строится стенд теста"
    echo " Итог: 0 passed, 0 failed"; exit 0
fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
mkdir -p "${TMP}/inv"
"${PY}" "${T}/make_inventory.py" "${TMP}/inv" 424242 > "${TMP}/truth"
D="${TMP}/inv/deployed_images.txt"; O="${TMP}/inv/official_digests.txt"; R="${TMP}/inv/allowed_registries.txt"

run() { bash "${S}" "$@" 2>"${TMP}/err"; }

echo ""
echo "── 0. Стенд собран ──"
N_TRUTH=$(grep -c . "${TMP}/truth")
[ "${N_TRUTH}" -ge 4 ] && ok "находок заложено: ${N_TRUTH}" || no "стенд вырожден: находок ${N_TRUTH}"
for cat in MISMATCH UNPINNED UNKNOWN MIRROR; do
    grep -q "^${cat} " "${TMP}/truth" && ok "категория ${cat} представлена" \
        || no "в стенде нет ни одной находки ${cat}"
done
[ "$(grep -vc '^#' "${O}")" -ge 8 ] && ok "перечень издателя непуст" || no "перечень издателя пуст"

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
bash "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}"
bash "${S}" "${D}" "${O}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "с двумя аргументами — код 2" || no "с двумя аргументами вернул ${rc}"
bash "${S}" "${TMP}/нет" "${O}" "${R}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий инвентарь — код 2" || no "несуществующий файл: код ${rc}"

echo ""
echo "── 2. Находки ──"
run "${D}" "${O}" "${R}" > "${TMP}/out"; RC=$?
awk '$1=="FINDING" {print $2, $3}' "${TMP}/out" | LC_ALL=C sort -u > "${TMP}/got"
LC_ALL=C sort -u "${TMP}/truth" > "${TMP}/exp"
[ "${RC}" = 1 ] && ok "код возврата 1 при находках" || no "код возврата ${RC}, ожидается 1"
while IFS= read -r line; do
    [ -n "${line}" ] || continue
    grep -qxF "${line}" "${TMP}/got" && ok "найдено: ${line}" || no "ПРОПУЩЕНО: ${line}"
done < "${TMP}/exp"
EXTRA="$(LC_ALL=C comm -13 "${TMP}/exp" "${TMP}/got")"
[ -z "${EXTRA}" ] && ok "лишнего не названо" \
    || no "ложные срабатывания: $(printf '%s' "${EXTRA}" | tr '\n' '; ')"
N_OUT="$(awk '$1=="TOTAL" {print $2; exit}' "${TMP}/out")"
[ "${N_OUT}" = "$(grep -c . "${TMP}/got")" ] && ok "TOTAL совпадает с числом строк: ${N_OUT}" \
    || no "TOTAL=${N_OUT:-нет}, строк $(grep -c . "${TMP}/got")"

echo ""
echo "── 3. Категории не путаются ──"
# Образ без отпечатка — это UNPINNED, а не MISMATCH: сравнивать нечего.
UNPIN="$(awk '$1=="UNPINNED" {print $2; exit}' "${TMP}/exp")"
[ -n "${UNPIN}" ] && {
    got_cat="$(awk -v r="${UNPIN}" '$1=="FINDING" && $3==r {print $2}' "${TMP}/out" | LC_ALL=C sort -u | tr '\n' ',')"
    [ "${got_cat}" = "UNPINNED," ] && ok "образ по метке помечен UNPINNED и только им" \
        || no "образ по метке получил категории «${got_cat}» вместо UNPINNED"
}
# Образ из чужого реестра — MIRROR; то, что его нет у издателя, — отдельная
# находка, а не то же самое.
MIR="$(awk '$1=="MIRROR" {print $2; exit}' "${TMP}/exp")"
[ -n "${MIR}" ] && {
    n=$(awk -v r="${MIR}" '$1=="FINDING" && $3==r' "${TMP}/out" | grep -c . || true)
    [ "${n}" -ge 2 ] && ok "чужой реестр даёт две независимые находки" \
        || no "по чужому реестру ${n} находок, ожидается не меньше двух"
}

echo ""
echo "── 4. Чистый инвентарь ──"
# Из инвентаря убираются все проблемные образы: остаток обязан дать ноль.
cp "${D}" "${TMP}/clean.txt"
awk '{print $2}' "${TMP}/exp" | LC_ALL=C sort -u | while IFS= read -r ref; do
    grep -vF " ${ref} " "${TMP}/clean.txt" > "${TMP}/c2" && mv "${TMP}/c2" "${TMP}/clean.txt"
done
run "${TMP}/clean.txt" "${O}" "${R}" > "${TMP}/out_clean"; RC_C=$?
N_CLEAN="$(awk '$1=="TOTAL" {print $2; exit}' "${TMP}/out_clean")"
[ "${N_CLEAN}" = 0 ] && ok "на чистом инвентаре TOTAL 0" \
    || no "на чистом инвентаре ${N_CLEAN:-нет TOTAL}: $(awk '$1=="FINDING"{print $2,$3}' "${TMP}/out_clean" | tr '\n' '; ')"
[ "${RC_C}" = 0 ] && ok "и код возврата 0" || no "код возврата ${RC_C} на чистом инвентаре"

echo ""
echo "── 5. Повторы узлов не задваивают находку ──"
# Один и тот же образ запущен на пятидесяти узлах — находка одна.
BAD="$(awk '$1=="MISMATCH" {print $2; exit}' "${TMP}/exp")"
{ cat "${D}"; for i in 1 2 3; do grep -F " ${BAD} " "${D}" | sed "s/^node[0-9]*/nodeX${i}/"; done; } > "${TMP}/dup.txt"
run "${TMP}/dup.txt" "${O}" "${R}" > "${TMP}/out_dup"
n=$(awk -v r="${BAD}" '$1=="FINDING" && $2=="MISMATCH" && $3==r' "${TMP}/out_dup" | grep -c . || true)
[ "${n}" = 1 ] && ok "образ на четырёх узлах даёт одну находку" \
    || no "тот же образ дал ${n} находок — считаются узлы, а не образы"

echo ""
echo "── 6. Воспроизводимость ──"
run "${D}" "${O}" "${R}" > "${TMP}/out2"
cmp -s "${TMP}/out" "${TMP}/out2" && ok "два прогона дают один вывод" || no "вывод меняется между прогонами"
awk '$1=="FINDING" {print $2, $3}' "${TMP}/out" > "${TMP}/order"
LC_ALL=C sort -c "${TMP}/order" 2>/dev/null && ok "вывод отсортирован" \
    || no "порядок строк зависит от порядка чтения инвентаря"
mkdir -p "${TMP}/inv2"
"${PY}" "${T}/make_inventory.py" "${TMP}/inv2" 987654 > "${TMP}/truth2"
run "${TMP}/inv2/deployed_images.txt" "${TMP}/inv2/official_digests.txt" "${TMP}/inv2/allowed_registries.txt" \
    | awk '$1=="FINDING" {print $2, $3}' | LC_ALL=C sort -u > "${TMP}/got2"
cmp -s <(LC_ALL=C sort -u "${TMP}/truth2") "${TMP}/got2" && ok "на другом инвентаре — тоже совпадение" \
    || no "на втором инвентаре расхождение: скрипт подогнан под первый"
[ -s "${TMP}/err" ] && no "пишет в stderr при обычном прогоне" || ok "stderr пуст"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
