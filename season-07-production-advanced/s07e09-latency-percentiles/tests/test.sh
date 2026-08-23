#!/usr/bin/env bash
#
# s07e09 «Перцентиль и его разрешение» — тест программы (Type D).
#
# Проверяет поведение latency.py на трёх снимках гистограммы. Ожидаемые
# перцентили и границы корзин тест считает сам, независимой реализацией на
# awk: констант нет, поменяются данные — поменяются и ожидания.
#
# Отдельно проверяется главное свойство серии: сравнение идёт по границам
# корзин, а не по интерполированным числам. Снимок noise отличается от
# base на восемь процентов и лежит в той же корзине — вывод обязан быть
# «сказать нельзя», а не «стало хуже».
#
# Без root, без сети, без Prometheus. Нужен python3.
#
# Выбор программы: SUBJECT=... | artifacts/latency.py | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

if   [ -n "${SUBJECT:-}" ];                          then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/latency.py" ];    then S="${SERIES_DIR}/artifacts/latency.py"
elif [ -f "${SERIES_DIR}/latency.py" ];              then S="${SERIES_DIR}/latency.py"
else S="${SERIES_DIR}/solution/latency.py"
     echo "ℹ️  Своего latency.py не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/latency.py artifacts/"; echo ""
fi

echo "════════════════════════════════════════════════════════════"
echo " s07e09 tests — программа: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

PY="$(command -v python3 || true)"
if [ -z "${PY}" ]; then
    echo "  FAIL: не найден python3 — серия Type D требует Python 3.8+"
    echo "        macOS: xcode-select --install | Debian: apt install python3"
    echo " Итог: 0 passed, 1 failed"; exit 1
fi
ok "python3 найден ($("${PY}" -c 'import sys; print(".".join(map(str,sys.version_info[:3])))'))"
if [ -f "${S}" ]; then ok "latency.py найден"
else no "latency.py не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── независимый счёт перцентиля по гистограмме ───────────────────────
# Печатает «значение_мс нижняя_мс верхняя_мс» для заданного квантиля.
q_of() {
    awk -v q="$2" '
      /^[[:space:]]*#/ { next }
      /_bucket\{le="/ {
          le = $0; sub(/.*le="/, "", le); sub(/".*/, "", le)
          cnt = $NF
          n++
          bound[n] = (le == "+Inf") ? -1 : le + 0
          cum[n]   = cnt + 0
      }
      /_count[[:space:]]/ { total = $NF + 0 }
      END {
          if (total == 0) total = cum[n]
          target = q * total
          lo = 0; locnt = 0
          for (i = 1; i <= n; i++) {
              if (cum[i] >= target) {
                  if (bound[i] < 0) { printf "%d %d inf\n", lo*1000, lo*1000; exit }
                  if (cum[i] == locnt) { printf "%d %d %d\n", lo*1000, lo*1000, bound[i]*1000; exit }
                  f = (target - locnt) / (cum[i] - locnt)
                  printf "%d %d %d\n", (lo + (bound[i]-lo)*f)*1000, lo*1000, bound[i]*1000
                  exit
              }
              lo = bound[i]; locnt = cum[i]
          }
      }' "$1"
}

field() { awk -v k="$1" '{for (i=1;i<=NF;i++) if ($i ~ ("^" k "=")) {sub(/^[^=]*=/,"",$i); print $i; exit}}'; }

echo ""
echo "── Исходные данные ──"
read -r B_VAL B_LO B_HI <<<"$(q_of "${D}/base.txt" 0.95)"
read -r N_VAL N_LO N_HI <<<"$(q_of "${D}/noise.txt" 0.95)"
read -r R_VAL R_LO R_HI <<<"$(q_of "${D}/regression.txt" 0.95)"
if [ "${B_VAL}" != "${N_VAL}" ] && [ "${B_LO}" = "${N_LO}" ] && [ "${B_HI}" = "${N_HI}" ]
then ok "noise отличается от base по числу (${B_VAL} против ${N_VAL} мс) и лежит в той же корзине [${B_LO},${B_HI}]"
else no "данные вырождены: снимок noise не демонстрирует разницу внутри корзины"; fi
if [ "${R_LO}" -ge "${B_HI}" ]
then ok "regression лежит в корзине выше базовой: [${R_LO},${R_HI}] против [${B_LO},${B_HI}]"
else no "данные вырождены: регрессия неотличима от базы"; fi

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
"${PY}" "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}, ожидается 2"
"${PY}" "${S}" "${D}/base.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "с одним аргументом — код 2" || no "с одним аргументом вернул ${rc}"
"${PY}" "${S}" "${TMP}/нет" "${D}/base.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий файл — код 2" || no "несуществующий файл: код ${rc}"
grep -v '+Inf' "${D}/base.txt" > "${TMP}/no_inf.txt"
"${PY}" "${S}" "${TMP}/no_inf.txt" "${D}/base.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "гистограмма без корзины +Inf отвергнута" \
    || no "гистограмма без +Inf принята (код ${rc}): хвост неизвестен, перцентиль по ней не считается"

for pair in "base base no-change 0" "base regression regression 1" \
            "base noise inconclusive 0" "regression base improvement 0"; do
    set -- ${pair}
    before="$1"; after="$2"; want="$3"; want_rc="$4"
    echo ""
    echo "── ${before} → ${after} ──"
    "${PY}" "${S}" "${D}/${before}.txt" "${D}/${after}.txt" > "${TMP}/out" 2>"${TMP}/err"; rc=$?

    got_verdict="$(awk '$1=="VERDICT" {print $2; exit}' "${TMP}/out")"
    [ "${got_verdict}" = "${want}" ] && ok "VERDICT ${want}" \
        || no "VERDICT ${got_verdict:-нет}, ожидается ${want}"
    [ "${rc}" = "${want_rc}" ] && ok "код возврата ${want_rc}" \
        || no "код возврата ${rc}, ожидается ${want_rc}"

    for q in 50 95 99; do
        qq="0.${q}"
        read -r e_val e_lo e_hi <<<"$(q_of "${D}/${before}.txt" "${qq}")"
        read -r a_val a_lo a_hi <<<"$(q_of "${D}/${after}.txt" "${qq}")"
        g_before="$(awk '$1=="BEFORE"' "${TMP}/out" | field "p${q}")"
        g_after="$(awk '$1=="AFTER"'  "${TMP}/out" | field "p${q}")"
        [ "${g_before}" = "${e_val}" ] && ok "BEFORE p${q}=${e_val}" \
            || no "BEFORE p${q}=${g_before:-нет}, по гистограмме ${e_val}"
        [ "${g_after}" = "${a_val}" ] && ok "AFTER p${q}=${a_val}" \
            || no "AFTER p${q}=${g_after:-нет}, по гистограмме ${a_val}"
        line="$(awk -v q="p${q}" '$1=="BOUNDS" && $2==q' "${TMP}/out")"
        if [ -z "${line}" ]; then no "нет строки BOUNDS p${q}"
        else
            gb="$(printf '%s' "${line}" | field before)"; ga="$(printf '%s' "${line}" | field after)"
            [ "${gb}" = "[${e_lo},${e_hi}]" ] && ok "границы до: ${gb}" \
                || no "границы до ${gb}, ожидаются [${e_lo},${e_hi}]"
            [ "${ga}" = "[${a_lo},${a_hi}]" ] && ok "границы после: ${ga}" \
                || no "границы после ${ga}, ожидаются [${a_lo},${a_hi}]"
        fi
    done

    p50="$(awk '$1=="AFTER"' "${TMP}/out" | field p50)"
    p95="$(awk '$1=="AFTER"' "${TMP}/out" | field p95)"
    p99="$(awk '$1=="AFTER"' "${TMP}/out" | field p99)"
    if [ -n "${p50}" ] && [ "${p50}" -le "${p95}" ] && [ "${p95}" -le "${p99}" ]
    then ok "перцентили не убывают: ${p50} ≤ ${p95} ≤ ${p99}"
    else no "перцентили нарушают порядок: ${p50}, ${p95}, ${p99}"; fi

    "${PY}" "${S}" "${D}/${before}.txt" "${D}/${after}.txt" > "${TMP}/out2" 2>/dev/null
    cmp -s "${TMP}/out" "${TMP}/out2" && ok "два прогона дают один вывод" \
        || no "вывод меняется между прогонами"
    [ -s "${TMP}/err" ] && no "пишет в stderr: $(head -1 "${TMP}/err")" || ok "stderr пуст"
done

echo ""
echo "── 2. Порядок строк выдачи не важен ──"
# Prometheus не гарантирует порядок строк в /metrics: разбор не должен на
# него опираться.
sort -r "${D}/base.txt" > "${TMP}/shuffled.txt"
"${PY}" "${S}" "${TMP}/shuffled.txt" "${D}/base.txt" > "${TMP}/sh" 2>/dev/null
if [ "$(awk '$1=="VERDICT" {print $2}' "${TMP}/sh")" = "no-change" ]
then ok "перевёрнутый файл разобран так же"
else no "разбор зависит от порядка строк: та же гистограмма в другом порядке дала «$(awk '$1=="VERDICT" {print $2}' "${TMP}/sh")»"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
