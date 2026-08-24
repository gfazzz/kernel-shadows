#!/usr/bin/env bash
#
# s08e06 «Сложить время» — тест программы (Type D).
#
# Тест не сверяет вывод с записанными ответами. Он сам порождает журналы
# из списка событий с известным временем (tests/make_logs.py), перемешивает
# строки внутри файлов и сравнивает вывод программы с этой истиной.
#
# Отсюда следствие: программа, подогнанная под data/, тест не пройдёт —
# в его журналах и события другие, и порядок строк другой.
#
# Отдельно проверяется, что программа действительно берёт год, момент
# загрузки и смещение из конфигурации: каждое из трёх меняется, и вывод
# обязан сдвинуться ровно на предсказуемую величину.
#
# Без root, без сети. Нужен python3.
#
# Выбор программы: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
T="${SERIES_DIR}/tests"

if   [ -n "${SUBJECT:-}" ];                                then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/timeline.py" ];         then S="${SERIES_DIR}/artifacts/timeline.py"
elif [ -f "${SERIES_DIR}/timeline.py" ];                   then S="${SERIES_DIR}/timeline.py"
else S="${SERIES_DIR}/solution/timeline.py"
     echo "ℹ️  Своего timeline.py не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/timeline.py artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e06 tests — программа: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

PY="$(command -v python3 || true)"
if [ -z "${PY}" ]; then
    echo "  SKIP: не найден python3 — серия Type D требует Python 3.8+"
    echo " Итог: 0 passed, 0 failed"; exit 0
fi
ok "python3 найден ($("${PY}" -c 'import sys; print(".".join(map(str,sys.version_info[:3])))'))"
[ -f "${S}" ] || { no "нет ${S}"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
mkdir -p "${TMP}/logs"
"${PY}" "${T}/make_logs.py" "${TMP}/logs" 771113 > "${TMP}/truth"
CONF="${TMP}/logs/sources.conf"

echo ""
echo "── 0. Стенд собран ──"
[ "$(grep -c . "${TMP}/truth")" -ge 10 ] && ok "событий в стенде: $(grep -c . "${TMP}/truth")" \
    || no "стенд не собрался"
[ "$(ls "${TMP}/logs"/*.log | wc -l)" -eq 5 ] && ok "источников: 5, форматы разные" || no "источников не 5"
# Журналы намеренно не отсортированы: программа не имеет права полагаться
# на порядок строк в файле.
if cmp -s <(grep -v '^#' "${TMP}/logs/audit.log" | LC_ALL=C sort) \
          <(grep -v '^#' "${TMP}/logs/audit.log"); then
    no "строки в журнале оказались отсортированы — стенд слишком лёгкий"
else ok "строки внутри журналов перемешаны"; fi

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
"${PY}" "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}"
"${PY}" "${S}" "${TMP}/logs" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "с одним аргументом — код 2" || no "с одним аргументом вернул ${rc}"
"${PY}" "${S}" "${TMP}/нет" "${CONF}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий каталог — код 2" || no "несуществующий каталог: код ${rc}"
"${PY}" "${S}" "${TMP}/logs" "${TMP}/нет.conf" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующая конфигурация — код 2" || no "нет конфигурации: код ${rc}"

echo ""
echo "── 2. Хронология восстановлена ──"
"${PY}" "${S}" "${TMP}/logs" "${CONF}" > "${TMP}/out" 2>"${TMP}/err"; RC=$?
[ "${RC}" = 0 ] && ok "код возврата 0" || no "код возврата ${RC}"
awk '$1=="EVENT" {sub(/^EVENT /,""); print}' "${TMP}/out" > "${TMP}/got"
if cmp -s "${TMP}/truth" "${TMP}/got"; then
    ok "все события восстановлены и совпали с истиной побайтово"
else
    no "расхождение с истиной: $(diff "${TMP}/truth" "${TMP}/got" | grep -c '^[<>]') строк"
    diff "${TMP}/truth" "${TMP}/got" | head -6 | sed 's/^/        /'
fi
N_TRUTH=$(grep -c . "${TMP}/truth"); N_GOT=$(grep -c . "${TMP}/got")
[ "${N_GOT}" = "${N_TRUTH}" ] && ok "событий ${N_GOT} — ни одно не потеряно и не задвоено" \
    || no "событий ${N_GOT}, ожидается ${N_TRUTH}"
awk '{print $1}' "${TMP}/got" | LC_ALL=C sort -c -n 2>/dev/null \
    && ok "порядок по времени не убывает" || no "хронология не отсортирована"

echo ""
echo "── 3. Итоговая строка ──"
sum() { awk -v k="$1" '$1=="SUMMARY" {for (i=2;i<=NF;i++) {split($i,a,"="); if (a[1]==k) print a[2]}}' "${TMP}/out"; }
E_FIRST=$(head -1 "${TMP}/truth" | awk '{print $1}')
E_LAST=$(tail -1 "${TMP}/truth" | awk '{print $1}')
[ "$(sum first)"  = "${E_FIRST}" ] && ok "first=${E_FIRST}"  || no "first=$(sum first), ожидается ${E_FIRST}"
[ "$(sum last)"   = "${E_LAST}" ]  && ok "last=${E_LAST}"    || no "last=$(sum last), ожидается ${E_LAST}"
[ "$(sum events)" = "${N_TRUTH}" ] && ok "events=${N_TRUTH}" || no "events=$(sum events), ожидается ${N_TRUTH}"
[ "$(sum sources)" = 5 ]           && ok "sources=5"         || no "sources=$(sum sources), ожидается 5"

echo ""
echo "── 4. Конфигурация читается, а не зашита ──"
shift_of() { # $1 — источник, $2 — файл вывода: средний сдвиг относительно истины
    awk -v s="$1" 'NR==FNR {if ($2==s) {t[++n]=$1}; next}
                   $1=="EVENT" && $3==s {d=$2-t[++m]; if (first=="") first=d; if (d!=first) bad=1}
                   END {print (bad ? "разный" : first+0)}' "${TMP}/truth" "$2"; }

# Год: 2025 -> 2024. От 22 ноября 2024 до 22 ноября 2025 — ровно 365 суток.
sed 's/^year 2025/year 2024/' "${CONF}" > "${TMP}/c_year.conf"
"${PY}" "${S}" "${TMP}/logs" "${TMP}/c_year.conf" > "${TMP}/o_year" 2>/dev/null
D_AUTH="$(shift_of auth "${TMP}/o_year")"
[ "${D_AUTH}" = "-31536000" ] && ok "год из конфигурации применён: syslog сдвинулся ровно на 365 суток" \
    || no "смена года дала сдвиг «${D_AUTH}», ожидается -31536000"
D_AUDIT="$(shift_of audit "${TMP}/o_year")"
[ "${D_AUDIT}" = "0" ] && ok "и не задел источники, где год есть в строке" \
    || no "смена года сдвинула audit на ${D_AUDIT} — год взят не оттуда"

# Момент загрузки: +1000 секунд. Сдвинуться обязан только журнал ядра.
awk '{if ($1=="boot_epoch") {print $1, $2+1000} else print}' "${CONF}" > "${TMP}/c_boot.conf"
"${PY}" "${S}" "${TMP}/logs" "${TMP}/c_boot.conf" > "${TMP}/o_boot" 2>/dev/null
D_FW="$(shift_of firewall "${TMP}/o_boot")"
[ "${D_FW}" = "1000" ] && ok "момент загрузки применён: журнал ядра сдвинулся ровно на 1000 с" \
    || no "смена boot_epoch дала сдвиг «${D_FW}», ожидается 1000"
D_K8S="$(shift_of k8s "${TMP}/o_boot")"
[ "${D_K8S}" = "0" ] && ok "и не задел остальные источники" \
    || no "смена boot_epoch сдвинула k8s на ${D_K8S}"

# Смещение: +0100 -> +0200. Местные часы ушли вперёд, значит момент по UTC
# наступил на час раньше.
sed 's/tz=+0100/tz=+0200/' "${CONF}" > "${TMP}/c_tz.conf"
"${PY}" "${S}" "${TMP}/logs" "${TMP}/c_tz.conf" > "${TMP}/o_tz" 2>/dev/null
D_TZ="$(shift_of auth "${TMP}/o_tz")"
[ "${D_TZ}" = "-3600" ] && ok "смещение применено и в верную сторону: -3600 с" \
    || no "смена смещения дала «${D_TZ}», ожидается -3600 (знак — половина задачи)"

echo ""
echo "── 5. Воспроизводимость ──"
"${PY}" "${S}" "${TMP}/logs" "${CONF}" > "${TMP}/out2" 2>/dev/null
cmp -s "${TMP}/out" "${TMP}/out2" && ok "два прогона дают один вывод" || no "вывод меняется между прогонами"
mkdir -p "${TMP}/logs2"
"${PY}" "${T}/make_logs.py" "${TMP}/logs2" 990211 > "${TMP}/truth2"
"${PY}" "${S}" "${TMP}/logs2" "${TMP}/logs2/sources.conf" \
    | awk '$1=="EVENT" {sub(/^EVENT /,""); print}' > "${TMP}/got2"
cmp -s "${TMP}/truth2" "${TMP}/got2" && ok "на другом наборе журналов — тоже совпадение" \
    || no "на втором наборе расхождение: программа подогнана под первый"
[ -s "${TMP}/err" ] && no "пишет в stderr при успешном разборе: $(head -1 "${TMP}/err")" || ok "stderr пуст"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
