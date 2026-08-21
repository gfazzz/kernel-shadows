#!/usr/bin/env bash
#
# s06e06 «План миссии» — тест валидатора маршрута (Type A).
#
# Ни одного зашитого вердикта: тест независимо вычисляет из планов в data/,
# какие точки нарушают простые правила (высота, нулевые координаты, кадр,
# последняя команда), и требует, чтобы валидатор назвал именно их.
# Геометрические правила проверяются иначе — подменой пределов: при
# ослабленных ограничениях нарушения обязаны исчезнуть, при ужесточённых —
# появиться. Валидатор с зашитыми числами это не пройдёт.
#
# Без root, без сети, без дрона.
#
# Выбор скрипта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
OKP="${D}/mission_ok.waypoints"
BADP="${D}/mission_bad.waypoints"
LIM="${D}/limits.txt"
NFL="${D}/nofly.txt"

if   [ -n "${SUBJECT:-}" ];                           then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/check_mission.sh" ]; then S="${SERIES_DIR}/artifacts/check_mission.sh"
elif [ -f "${SERIES_DIR}/check_mission.sh" ];         then S="${SERIES_DIR}/check_mission.sh"
else S="${SERIES_DIR}/solution/check_mission.sh"
     echo "ℹ️  Своего check_mission.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/check_mission.sh artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e06 tests — скрипт: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${OKP}" "${BADP}" "${LIM}" "${NFL}"; do [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }; done
if [ -f "${S}" ]; then ok "check_mission.sh найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi
bash -n "${S}" 2>/dev/null && ok "синтаксис bash корректен" || { no "синтаксическая ошибка"; bash -n "${S}"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

run() { bash "${S}" --limits "$1" --nofly "$2" "$3" >"${TMP}/out" 2>"${TMP}/err"; echo $?; }
out() { cat "${TMP}/out"; }
count() { awk -F': ' '/^Нарушений: /{print $2+0; exit}' "${TMP}/out"; }

lim() { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {gsub(/[[:space:]]/,"",$2); print $2; exit}' "${LIM}"; }

# ── независимый расчёт «простых» нарушений в плохом плане ────────────
rowsof() { grep -v '^QGC' "$1" | awk 'NF>=12'; }
ALT_MAX="$(lim alt_max_m)"; ALT_MIN="$(lim alt_min_m)"
E_ALT_IDX="$(rowsof "${BADP}" | awk -v hi="${ALT_MAX}" -v lo="${ALT_MIN}" 'NR>1 && $4!=20 && $4!=21 && ($11+0>hi+0 || $11+0<lo+0) {print $1}')"
E_ZERO_IDX="$(rowsof "${BADP}" | awk '$9+0==0 && $10+0==0 {print $1}')"
E_FRAME_IDX="$(rowsof "${BADP}" | awk 'NR==2 {f=$3} NR>1 && $3+0!=f+0 {print $1}')"
E_LASTCMD="$(rowsof "${BADP}" | awk 'END{print $4}')"

echo ""
echo "── Исходные данные ──"
if [ -n "${E_ALT_IDX}" ] && [ -n "${E_ZERO_IDX}" ] && [ -n "${E_FRAME_IDX}" ]
then ok "в плохом плане есть нарушения высоты (${E_ALT_IDX//$'\n'/,}), нулевые точки (${E_ZERO_IDX//$'\n'/,}), чужой кадр (${E_FRAME_IDX//$'\n'/,})"
else no "плохой план вырожден — проверять нечего"; fi

# ── 1. Аргументы ─────────────────────────────────────────────────────
echo ""
echo "── 1. Аргументы ──"
bash "${S}" >/dev/null 2>&1; c=$?; [ "$c" = 1 ] && ok "без аргументов -> 1" || no "без аргументов -> ${c}"
bash "${S}" --help >/dev/null 2>&1; c=$?; [ "$c" = 0 ] && ok "--help -> 0" || no "--help -> ${c}"
c="$(run "${LIM}" "${NFL}" "${TMP}/нет-такого.waypoints")"
[ "$c" = 2 ] && ok "нет файла плана -> 2" || no "нет файла плана -> ${c}, ждали 2"
printf 'lat,lon,alt\n22.5,114.0,60\n' > "${TMP}/чужое.csv"
c="$(run "${LIM}" "${NFL}" "${TMP}/чужое.csv")"
[ "$c" = 2 ] && ok "чужой формат -> 2 (заголовок проверен до разбора)" || no "чужой формат -> ${c}, ждали 2"

# ── 2. Корректный план ───────────────────────────────────────────────
echo ""
echo "── 2. Корректный план ──"
c="$(run "${LIM}" "${NFL}" "${OKP}")"
if [ "$c" = 0 ] && [ "$(count)" = 0 ]; then ok "mission_ok: 0 нарушений, код 0"
else no "mission_ok: код ${c}, нарушений $(count) — ложные срабатывания:"; out | grep 'НАРУШЕНИЕ' | sed 's/^/        /'; fi

# ── 3. Плохой план: что именно найдено ───────────────────────────────
echo ""
echo "── 3. Плохой план ──"
c="$(run "${LIM}" "${NFL}" "${BADP}")"
BADN="$(count)"
[ "$c" = 3 ] && ok "mission_bad -> код 3" || no "mission_bad -> код ${c}, ждали 3"
[ "${BADN:-0}" -ge 6 ] && ok "найдено нарушений: ${BADN}" || no "найдено только ${BADN:-0} нарушений"

named() { out | grep -q "$1" ; }
for i in ${E_ALT_IDX};   do named "точка ${i}" && ok "названа точка ${i} (высота вне пределов)" || no "точка ${i} с недопустимой высотой не названа"; done
for i in ${E_ZERO_IDX};  do named "точка ${i}" && ok "названа точка ${i} (координаты 0,0)"      || no "нулевая точка ${i} не названа"; done
for i in ${E_FRAME_IDX}; do named "точка ${i}" && ok "названа точка ${i} (чужой кадр высоты)"   || no "точка ${i} с другим FRAME не названа"; done
out | grep -qiE 'посадк|возврат' && ok "сказано про отсутствие посадки (последняя команда ${E_LASTCMD})" \
                                 || no "не сказано, что план не заканчивается посадкой или возвратом"
out | grep -qi "$(awk '/^[[:space:]]*#/{next} NF>=4 {print $1; exit}' "${NFL}")" \
    && ok "названа запретная зона по имени" || no "запретная зона не названа"

# ── 4. Пределы — из данных, а не из кода ─────────────────────────────
echo ""
echo "── 4. Пределы из данных ──"
sed -e 's/^alt_max_m=.*/alt_max_m=300/' -e 's/^leg_max_m=.*/leg_max_m=9000/' \
    -e 's/^total_max_m=.*/total_max_m=90000/' -e 's/^geofence_radius_m=.*/geofence_radius_m=9000/' \
    -e 's/^alt_min_m=.*/alt_min_m=0/' "${LIM}" > "${TMP}/loose.txt"
c="$(run "${TMP}/loose.txt" "${NFL}" "${BADP}")"
LOOSEN="$(count)"
if [ "${LOOSEN:-99}" -lt "${BADN:-0}" ]
then ok "ослабленные пределы: нарушений ${LOOSEN} вместо ${BADN}"
else no "ослабление пределов ничего не изменило (${LOOSEN}) — числа зашиты в коде"; fi
out | grep -qE 'НАРУШЕНИЕ \[(высота|плечо|дальность|геозона)\]' \
    && no "при ослабленных пределах остались геометрические нарушения" \
    || ok "геометрические нарушения исчезли вместе с пределами"

sed 's/^alt_max_m=.*/alt_max_m=50/' "${LIM}" > "${TMP}/tight.txt"
c="$(run "${TMP}/tight.txt" "${NFL}" "${OKP}")"
if [ "$c" = 3 ] && [ "$(count)" -gt 0 ]
then ok "ужесточение предела высоты делает корректный план негодным"
else no "при alt_max_m=50 корректный план всё ещё проходит (код ${c}) — предел не читается"; fi

: > "${TMP}/empty_nofly.txt"
c="$(run "${LIM}" "${TMP}/empty_nofly.txt" "${BADP}")"
if [ "$(count)" -lt "${BADN}" ]; then ok "пустой список зон убирает нарушение по зоне"
else no "нарушение по запретной зоне не зависит от файла зон"; fi

# ── 5. Повторяемость ─────────────────────────────────────────────────
echo ""
echo "── 5. Повторяемость ──"
A="$(bash "${S}" --limits "${LIM}" --nofly "${NFL}" "${BADP}" 2>/dev/null)"
B="$(bash "${S}" --limits "${LIM}" --nofly "${NFL}" "${BADP}" 2>/dev/null)"
[ "${A}" = "${B}" ] && ok "два прогона дают одинаковый вывод" || no "вывод меняется между прогонами"
C="$(LC_ALL=C TZ=Asia/Tokyo bash "${S}" --limits "${LIM}" --nofly "${NFL}" "${BADP}" 2>/dev/null)"
[ "${A}" = "${C}" ] && ok "вывод не зависит от локали и часового пояса" \
                    || no "при LC_ALL=C / чужом TZ вывод другой (десятичная точка? сортировка?)"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
