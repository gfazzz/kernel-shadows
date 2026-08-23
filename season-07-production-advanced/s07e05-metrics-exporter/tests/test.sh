#!/usr/bin/env bash
#
# s07e05 «Метрики, которые можно читать» — тест скрипта (Type A).
#
# Скрипт прогоняется по двум выдачам /metrics. На «грязной» он обязан
# найти ровно те нарушения, что нашёл promtool (записаны в answers.txt),
# на «чистой» — ни одного. Сам answers.txt скрипту читать запрещено:
# тест ищет это слово в его тексте.
#
# Пороги и списки единиц берутся из data/limits.txt — ни в тесте, ни в
# скрипте констант нет: поменяется соглашение команды, поменяются и оба.
#
# Без root, без сети, без Prometheus.
#
# Выбор скрипта: SUBJECT=... | artifacts/check_metrics.sh | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"; LIM="${D}/limits.txt"

if   [ -n "${SUBJECT:-}" ];                               then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/check_metrics.sh" ];   then S="${SERIES_DIR}/artifacts/check_metrics.sh"
elif [ -f "${SERIES_DIR}/check_metrics.sh" ];             then S="${SERIES_DIR}/check_metrics.sh"
else S="${SERIES_DIR}/solution/check_metrics.sh"
     echo "ℹ️  Своего check_metrics.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/check_metrics.sh artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e05 tests — скрипт: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${LIM}" ] || { echo "  FAIL: нет ${LIM}"; exit 1; }
if [ -f "${S}" ]; then ok "check_metrics.sh найден"
else no "check_metrics.sh не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
MAXLV=$(awk '$1=="max_label_values" {print $2; exit}' "${LIM}")

# ── независимый разбор выдачи: только то, что нужно для самопроверок ──
families() { awk '/^[[:space:]]*#/{next} /^[[:space:]]*$/{next}
                  {n=$1; sub(/[{ ].*$/,"",n); sub(/_bucket$|_sum$|_count$/,"",n); print n}' "$1" | sort -u; }
series_n() { awk '/^[[:space:]]*#/{next} /^[[:space:]]*$/{next} {c++} END{print c+0}' "$1"; }
label_max() { # наибольшее число разных значений одной метки во всей выдаче
    awk '/^[[:space:]]*#/{next} {
        s=$0; if (s !~ /\{/) next; sub(/^[^{]*\{/,"",s); sub(/\}.*$/,"",s)
        while (match(s, /[a-zA-Z_][a-zA-Z0-9_]*="[^"]*"/)) {
            p=substr(s,RSTART,RLENGTH); s=substr(s,RSTART+RLENGTH)
            k=p; sub(/=.*$/,"",k)
            if (k=="le" || k=="quantile") continue
            if (!(p in seen)) { seen[p]; cnt[k]++ } } }
      END { for (k in cnt) if (cnt[k]>b) b=cnt[k]; print b+0 }' "$1"; }

echo ""
echo "── Исходные данные ──"
DIRTY_CODES="$(awk '/^[[:space:]]*#/{next} NF==2 {print $1}' "${D}/dirty/answers.txt" | sort -u)"
N_CODES="$(grep -c . <<<"${DIRTY_CODES}" || true)"
if [ "${N_CODES}" -ge 5 ]
then ok "в грязной выдаче ${N_CODES} разных нарушений: $(tr '\n' ' ' <<<"${DIRTY_CODES}")"
else no "данные вырождены: нарушений всего ${N_CODES} вида"; fi
if [ "$(awk '/^[[:space:]]*#/{next} NF==2' "${D}/clean/answers.txt" | grep -c . || true)" -eq 0 ]
then ok "у чистой выдачи список нарушений пуст"
else no "чистая выдача не чиста — сравнивать не с чем"; fi
if [ "$(label_max "${D}/dirty/metrics.txt")" -gt "${MAXLV}" ]
then ok "в грязной выдаче есть метка с $(label_max "${D}/dirty/metrics.txt") значениями при пороге ${MAXLV}"
else no "данные вырождены: взрыва кардинальности в них нет"; fi
if [ "$(label_max "${D}/clean/metrics.txt")" -le "${MAXLV}" ]
then ok "в чистой выдаче кардинальность в пределах порога"
else no "чистая выдача сама нарушает порог"; fi

echo ""
echo "── 1. Скрипт не подглядывает ──"
grep -q 'answers' "${S}" && no "в тексте скрипта упоминается answers.txt — нарушения надо находить, а не читать" \
                         || ok "answers.txt в скрипте не упоминается"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"

echo ""
echo "── 2. Договор вызова ──"
bash "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}, ожидается 2"
bash "${S}" "${TMP}/нет" "${LIM}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующая выдача — код 2" || no "несуществующая выдача: код ${rc}"
bash "${S}" "${D}/clean/metrics.txt" "${TMP}/нет" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующие соглашения — код 2" || no "несуществующие соглашения: код ${rc}"

for case in clean dirty; do
    echo ""
    echo "── ${case} ──"
    src="${D}/${case}/metrics.txt"; ans="${D}/${case}/answers.txt"
    bash "${S}" "${src}" "${LIM}" > "${TMP}/out" 2>"${TMP}/err"; rc=$?

    awk '$1=="ISSUE" {print $2, $3}' "${TMP}/out" | sort > "${TMP}/got"
    awk '/^[[:space:]]*#/{next} NF==2 {print $1, $2}' "${ans}" | sort > "${TMP}/want"

    if diff -q "${TMP}/got" "${TMP}/want" >/dev/null; then
        ok "нарушения совпали с разбором promtool ($(grep -c . "${TMP}/want" || true) шт.)"
    else
        no "расхождение с answers.txt:"
        comm -23 "${TMP}/got" "${TMP}/want" | sed 's/^/        лишнее: /'
        comm -13 "${TMP}/got" "${TMP}/want" | sed 's/^/        не найдено: /'
    fi

    n_want="$(grep -c . "${TMP}/want" || true)"
    if [ "${n_want}" -gt 0 ]
    then [ "${rc}" = 1 ] && ok "код возврата 1" || no "код возврата ${rc}, при нарушениях ожидается 1"
    else [ "${rc}" = 0 ] && ok "код возврата 0" || no "код возврата ${rc}, на чистой выдаче ожидается 0"; fi

    sm="$(awk '$1=="SUMMARY" {print}' "${TMP}/out")"
    if [ -n "${sm}" ]; then
        ok "сводка напечатана"
        e_fam="$(families "${src}" | grep -c . || true)"; e_ser="$(series_n "${src}")"
        grep -q "${e_fam} metrics" <<<"${sm}" && ok "семейств в сводке ${e_fam}" \
            || no "в сводке «${sm}», а семейств в выдаче ${e_fam}"
        grep -q "${e_ser} series" <<<"${sm}" && ok "рядов в сводке ${e_ser}" \
            || no "в сводке «${sm}», а рядов в выдаче ${e_ser}"
        grep -q "${n_want} issues" <<<"${sm}" && ok "число нарушений в сводке ${n_want}" \
            || no "в сводке «${sm}», а нарушений ${n_want}"
    else no "нет строки SUMMARY"; fi

    bash "${S}" "${src}" "${LIM}" > "${TMP}/out2" 2>/dev/null
    cmp -s "${TMP}/out" "${TMP}/out2" && ok "два прогона дают один вывод" \
        || no "вывод меняется между прогонами"
    [ -s "${TMP}/err" ] && no "скрипт пишет в stderr: $(head -1 "${TMP}/err")" || ok "stderr пуст"
done

echo ""
echo "── 3. Соглашения читаются, а не зашиты ──"
# Порог кардинальности поднимается выше наблюдаемого — взрыв перестаёт
# быть нарушением. Скрипт с зашитой двадцаткой этого не заметит.
# Вывод сначала складывается в файл: у скрипта ненулевой код возврата при
# найденных нарушениях, и в конвейере с pipefail он бы забил результат grep.
sed "s/^max_label_values .*/max_label_values 9999/" "${LIM}" > "${TMP}/lim2"
bash "${S}" "${D}/dirty/metrics.txt" "${TMP}/lim2" > "${TMP}/o2" 2>/dev/null || true
if grep -q '^ISSUE cardinality' "${TMP}/o2"
then no "порог из файла не используется: кардинальность всё ещё нарушение при пороге 9999"
else ok "поднятый порог убирает нарушение кардинальности"; fi

# И наоборот: единица, объявленная плохой, начинает ловиться.
sed "s/^bad_unit ms$/bad_unit bytes/" "${LIM}" > "${TMP}/lim3"
bash "${S}" "${D}/clean/metrics.txt" "${TMP}/lim3" > "${TMP}/o3" 2>/dev/null || true
if grep -q '^ISSUE unit aurora_cache_size_bytes' "${TMP}/o3"
then ok "список единиц читается из файла"
else no "объявление bytes плохой единицей ничего не изменило — список зашит в скрипт"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
