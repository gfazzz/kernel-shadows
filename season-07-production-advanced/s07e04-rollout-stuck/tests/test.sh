#!/usr/bin/env bash
#
# s07e04 «Выкат, который не едет» — тест скрипта (Type A).
#
# Скрипт прогоняется по четырём снимкам и обязан прийти к тому же выводу,
# что и настоящий `kubectl rollout status`, чей результат записан в
# truth.txt каждого случая. Сам truth.txt скрипту читать запрещено — тест
# проверяет это отдельно: смысл упражнения в том, чтобы отличать «идёт» от
# «встало» по состоянию, а не дожидаться таймаута.
#
# Числа (desired/updated/available) тест вычисляет из deploy.txt сам и
# сверяет с тем, что напечатал скрипт: констант в тесте нет.
#
# Без root, без сети, без кластера.
#
# Выбор скрипта: SUBJECT=... | artifacts/rollout_check.sh | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"

if   [ -n "${SUBJECT:-}" ];                                then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/rollout_check.sh" ];    then S="${SERIES_DIR}/artifacts/rollout_check.sh"
elif [ -f "${SERIES_DIR}/rollout_check.sh" ];              then S="${SERIES_DIR}/rollout_check.sh"
else S="${SERIES_DIR}/solution/rollout_check.sh"
     echo "ℹ️  Своего rollout_check.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/rollout_check.sh artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e04 tests — скрипт: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${S}" ]; then ok "rollout_check.sh найден"
else no "rollout_check.sh не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

CASES="$(cd "${D}" && ls -d case-* 2>/dev/null | sort)"
N_CASES="$(printf '%s\n' "${CASES}" | grep -c . || true)"
TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

echo ""
echo "── Исходные данные ──"
if [ "${N_CASES}" -ge 4 ]; then ok "снимков в data/: ${N_CASES}"
else no "снимков ${N_CASES}, ожидалось не меньше четырёх"; fi

VERDICTS="$(for c in ${CASES}; do awk '$1=="verdict" {print $2}' "${D}/${c}/truth.txt"; done | sort -u)"
CAUSES="$(for c in ${CASES}; do awk '$1=="cause" {print $2}' "${D}/${c}/truth.txt"; done | sort -u | grep -v '^none$' || true)"
if [ "$(grep -c . <<<"${VERDICTS}")" -ge 3 ]
then ok "в наборе есть все три исхода: $(tr '\n' ' ' <<<"${VERDICTS}")"
else no "данные вырождены: исходов всего $(grep -c . <<<"${VERDICTS}")"; fi
if [ "$(grep -c . <<<"${CAUSES}")" -ge 2 ]
then ok "остановки различаются по причине: $(tr '\n' ' ' <<<"${CAUSES}")"
else no "данные вырождены: у всех остановок одна причина"; fi

echo ""
echo "── 1. Скрипт не подглядывает ──"
if grep -q 'truth' "${S}"
then no "в тексте скрипта упоминается truth.txt — вывод должен получаться из состояния, а не из ответа"
else ok "truth.txt в скрипте не упоминается"; fi
if head -1 "${S}" | grep -q '^#!'
then ok "shebang на месте"
else no "нет строки #! в начале"; fi

echo ""
echo "── 2. Договор вызова ──"
out="$(bash "${S}" 2>/dev/null; echo "rc=$?")"
[ "${out##*rc=}" = "2" ] && ok "без аргумента — код 2" || no "без аргумента вернул ${out##*rc=}, ожидается 2"
out="$(bash "${S}" "${TMP}/нет-такого" 2>/dev/null; echo "rc=$?")"
[ "${out##*rc=}" = "2" ] && ok "несуществующий каталог — код 2" || no "несуществующий каталог: код ${out##*rc=}"

for c in ${CASES}; do
    echo ""
    echo "── ${c} ──"
    dir="${D}/${c}"
    bash "${S}" "${dir}" > "${TMP}/out" 2>"${TMP}/err"; rc=$?
    v_want="$(awk '$1=="verdict" {print $2}' "${dir}/truth.txt")"
    c_want="$(awk '$1=="cause"   {print $2}' "${dir}/truth.txt")"
    f() { awk -v k="$1" '$1==k {print $2; exit}' "${TMP}/out"; }

    [ "$(f VERDICT)" = "${v_want}" ] \
        && ok "VERDICT ${v_want}" \
        || no "VERDICT $(f VERDICT), а kubectl отработал как «${v_want}» (см. truth.txt)"
    [ "$(f CAUSE)" = "${c_want}" ] \
        && ok "CAUSE ${c_want}" \
        || no "CAUSE $(f CAUSE), ожидается ${c_want}"

    # Числа считаются из снимка независимо от скрипта.
    e_des="$(awk '$1=="replicas:" {print $2; exit}' "${dir}/deploy.txt")"
    e_upd="$(awk '$1=="updatedReplicas:" {print $2; exit}' "${dir}/deploy.txt")"
    e_avl="$(awk '$1=="availableReplicas:" {print $2; exit}' "${dir}/deploy.txt")"
    [ "$(f DESIRED)"   = "${e_des}" ] && ok "DESIRED ${e_des}"   || no "DESIRED $(f DESIRED), в снимке ${e_des}"
    [ "$(f UPDATED)"   = "${e_upd}" ] && ok "UPDATED ${e_upd}"   || no "UPDATED $(f UPDATED), в снимке ${e_upd}"
    [ "$(f AVAILABLE)" = "${e_avl}" ] && ok "AVAILABLE ${e_avl}" || no "AVAILABLE $(f AVAILABLE), в снимке ${e_avl}"

    # Новый ReplicaSet — самый молодой по AGE; старый обязан от него отличаться.
    e_new="$(grep -v '^[[:space:]]*#' "${dir}/rs.txt" | grep -v '^NAME' | awk 'NF>=5 {
        a=$5; n=a; sub(/[a-z]$/,"",n); n += 0   # без +0 сравнение пойдёт по строкам
        if (a ~ /m$/) n*=60; else if (a ~ /h$/) n*=3600; else if (a ~ /d$/) n*=86400
        if (best=="" || n<best) { best=n; name=$1 } } END {print name}')"
    [ "$(f NEW-RS)" = "${e_new}" ] && ok "NEW-RS ${e_new}" || no "NEW-RS $(f NEW-RS), самый молодой — ${e_new}"
    [ "$(f NEW-RS)" != "$(f OLD-RS)" ] && ok "старый и новый ReplicaSet различены" \
        || no "NEW-RS и OLD-RS совпали"

    if [ "${v_want}" = stuck ]; then
        [ "${rc}" = "1" ] && ok "код возврата 1 — шаг конвейера остановится" \
                          || no "код возврата ${rc}, у застрявшего выката ожидается 1"
    else
        [ "${rc}" = "0" ] && ok "код возврата 0" || no "код возврата ${rc}, ожидается 0"
    fi

    bash "${S}" "${dir}" > "${TMP}/out2" 2>/dev/null
    cmp -s "${TMP}/out" "${TMP}/out2" && ok "два прогона дают один вывод" \
        || no "вывод меняется между прогонами — в него попало что-то от среды"
    [ -s "${TMP}/err" ] && no "скрипт пишет в stderr на исправном снимке: $(head -1 "${TMP}/err")" \
                        || ok "stderr пуст"
done

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
