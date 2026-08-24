#!/usr/bin/env bash
#
# s06e07 «Отказоустойчивость» — тест набора параметров (Type B).
#
# Ни одного зашитого числа: список обязательных параметров и их диапазоны
# берутся из data/param_reference.txt, пороги батареи считаются из
# data/airframe.txt, геозона сверяется с data/site_limits.txt, порог
# отказа по газу — с data/rc_calibration.txt.
#
# Отдельно проверяются связи между параметрами: критический порог ниже
# низкого, потолок геозоны не ниже высоты возврата, радиус геозоны больше
# маршрута. Каждая связь — это авария, которая не видна в отдельном
# параметре.
#
# Без root, без сети, без дрона.
#
# Выбор файла: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REF="${SERIES_DIR}/data/param_reference.txt"
AIR="${SERIES_DIR}/data/airframe.txt"
SITE="${SERIES_DIR}/data/site_limits.txt"
RC="${SERIES_DIR}/data/rc_calibration.txt"

if   [ -n "${SUBJECT:-}" ];                            then P="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/failsafe.params" ]; then P="${SERIES_DIR}/artifacts/failsafe.params"
elif [ -f "${SERIES_DIR}/failsafe.params" ];           then P="${SERIES_DIR}/failsafe.params"
else P="${SERIES_DIR}/solution/failsafe.params"
     echo "ℹ️  Своего failsafe.params не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/failsafe.params artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e07 tests — параметры: ${P#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${REF}" "${AIR}" "${SITE}" "${RC}"; do [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }; done
if [ -f "${P}" ]; then ok "failsafe.params найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

kv() { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {gsub(/[[:space:]]/,"",$2); print $2; exit}' "$2"; }
CELLS="$(kv battery_cells "${AIR}")"; CELLMIN="$(kv cell_min_volt "${AIR}")"
ROUTE="$(kv route_max_radius_m "${SITE}")"; REGALT="$(kv regulation_alt_max_m "${SITE}")"
OBST="$(kv obstacle_max_m "${SITE}")"
RC3MIN="$(awk '/^[[:space:]]*#/{next} $2=="throttle" {print $3; exit}' "${RC}")"
BATT_FLOOR="$(awk -v c="${CELLS}" -v v="${CELLMIN}" 'BEGIN{printf "%.2f", c*v}')"

# параметры пользователя
val() { awk -F, -v k="$1" '/^[[:space:]]*#/{next} $1==k {gsub(/[[:space:]]/,"",$2); print $2; exit}' "${P}"; }
names() { awk -F, '/^[[:space:]]*#/{next} NF>=2 && $1 ~ /^[A-Z]/ {gsub(/[[:space:]]/,"",$1); print $1}' "${P}"; }
refnames() { awk '/^[[:space:]]*#/{next} NF>=5 {print $1}' "${REF}"; }
refcol() { awk -v n="$1" -v c="$2" '/^[[:space:]]*#/{next} $1==n {print $c; exit}' "${REF}"; }

num() { awk -v a="$1" 'BEGIN{print (a+0==a && a!="") ? "y" : "n"}'; }
lt()  { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a+0 < b+0)}'; }
ge()  { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a+0 >= b+0)}'; }
le()  { awk -v a="$1" -v b="$2" 'BEGIN{exit !(a+0 <= b+0)}'; }

echo ""
echo "── Исходные данные ──"
if [ -n "${CELLS}" ] && [ -n "${ROUTE}" ] && [ -n "${RC3MIN}" ] && [ "$(refnames | grep -c .)" -ge 15 ]
then ok "данные разобраны: ${CELLS} банки (низ ${BATT_FLOOR} В), маршрут ${ROUTE} м, газ min ${RC3MIN}"
else no "не разобрались файлы в data/"; fi

echo ""
echo "── Полнота и корректность набора ──"
MISS=""; for n in $(refnames); do val "${n}" >/dev/null; [ -n "$(val "${n}")" ] || MISS="${MISS} ${n}"; done
[ -z "${MISS}" ] && ok "все обязательные параметры заданы" || no "не заданы:${MISS}"

UNK=""; for n in $(names); do refnames | grep -qx "${n}" || UNK="${UNK} ${n}"; done
[ -z "${UNK}" ] && ok "нет неизвестных параметров" \
                || no "неизвестные параметры:${UNK} — автопилот молча их проигнорирует, опечатка в имени не даёт ошибки"

DUP="$(names | sort | uniq -d | grep -c .)"
[ "${DUP}" -eq 0 ] && ok "нет дублей" || no "${DUP} параметров заданы дважды"

BAD=""
for n in $(refnames); do
    v="$(val "${n}")"; [ -n "${v}" ] || continue
    [ "$(num "${v}")" = y ] || { BAD="${BAD} ${n}(не число)"; continue; }
    lo="$(refcol "${n}" 3)"; hi="$(refcol "${n}" 4)"
    ge "${v}" "${lo}" && le "${v}" "${hi}" || BAD="${BAD} ${n}=${v}(вне ${lo}..${hi})"
done
[ -z "${BAD}" ] && ok "все значения в допустимых диапазонах справочника" || no "вне диапазона:${BAD}"

echo ""
echo "── Отказы включены ──"
for n in FS_THR_ENABLE FS_GCS_ENABLE FS_EKF_ACTION FENCE_ENABLE; do
    v="$(val "${n}")"
    if [ -n "${v}" ] && [ "${v%.*}" != 0 ]; then ok "${n}=${v} — реакция задана"
    else no "${n}=${v:-не задан}: ноль означает «продолжать полёт как ни в чём не бывало»"; fi
done

FSTHR="$(val FS_THR_VALUE)"
if [ -n "${FSTHR}" ] && lt "${FSTHR}" "${RC3MIN}"
then ok "FS_THR_VALUE=${FSTHR} ниже минимума канала газа (${RC3MIN})"
else no "FS_THR_VALUE=${FSTHR:-не задан} не ниже ${RC3MIN} — порог внутри рабочего диапазона сработает при обычном сбросе газа"; fi

echo ""
echo "── Батарея: два порога ──"
LOWV="$(val BATT_LOW_VOLT)"; CRTV="$(val BATT_CRT_VOLT)"
if [ -n "${LOWV}" ] && [ -n "${CRTV}" ] && lt "${CRTV}" "${LOWV}"
then ok "BATT_CRT_VOLT=${CRTV} < BATT_LOW_VOLT=${LOWV}"
else no "критический порог ${CRTV:-?} не ниже низкого ${LOWV:-?} — мягкая реакция не наступит никогда"; fi
if [ -n "${LOWV}" ] && ge "${LOWV}" "${BATT_FLOOR}"
then ok "BATT_LOW_VOLT=${LOWV} не ниже ${BATT_FLOOR} В (${CELLS} × ${CELLMIN})"
else no "BATT_LOW_VOLT=${LOWV:-?} ниже ${BATT_FLOOR} В — предупреждение придёт после того, как банки уже сядут"; fi
if [ -n "${CRTV}" ] && ge "${CRTV}" "${BATT_FLOOR}"
then ok "BATT_CRT_VOLT=${CRTV} не ниже физического низа ${BATT_FLOOR} В"
else no "BATT_CRT_VOLT=${CRTV:-?} ниже ${BATT_FLOOR} В — до срабатывания батарея успеет разрядиться в ноль"; fi

LACT="$(val BATT_FS_LOW_ACT)"; CACT="$(val BATT_FS_CRT_ACT)"
if [ "${LACT}" = 2 ] && [ "${CACT}" = 1 ]
then ok "низкий заряд -> возврат (2), критический -> посадка (1)"
else no "реакции ${LACT:-?}/${CACT:-?}: на низкий заряд возврат (2), на критический посадка на месте (1) — мягче раньше, жёстче позже"; fi

echo ""
echo "── Геозона и возврат ──"
FTYPE="$(val FENCE_TYPE)"
if [ -n "${FTYPE}" ] && [ $(( ${FTYPE%.*} & 1 )) -ne 0 ] && [ $(( ${FTYPE%.*} & 2 )) -ne 0 ]
then ok "FENCE_TYPE=${FTYPE} — ограничены и потолок (бит 1), и радиус (бит 2)"
else no "FENCE_TYPE=${FTYPE:-не задан}: нужна маска с битами 1 и 2, иначе одно из двух направлений открыто"; fi

FRAD="$(val FENCE_RADIUS)"
if [ -n "${FRAD}" ] && awk -v a="${FRAD}" -v b="${ROUTE}" 'BEGIN{exit !(a > b*1.2)}'
then ok "FENCE_RADIUS=${FRAD} м больше маршрута (${ROUTE} м) с запасом"
else no "FENCE_RADIUS=${FRAD:-?} м мал против маршрута ${ROUTE} м — штатный полёт сам вызовет срабатывание"; fi

FALT="$(val FENCE_ALT_MAX)"; RALT="$(val RTL_ALT)"
if [ -n "${FALT}" ] && le "${FALT}" "${REGALT}"
then ok "FENCE_ALT_MAX=${FALT} м не выше регламента (${REGALT} м)"
else no "FENCE_ALT_MAX=${FALT:-?} м выше регламентного потолка ${REGALT} м"; fi

if [ -n "${FALT}" ] && [ -n "${RALT}" ]; then
    RALT_M="$(awk -v v="${RALT}" 'BEGIN{printf "%.1f", v/100}')"
    if ge "${FALT}" "${RALT_M}"
    then ok "потолок геозоны ${FALT} м не ниже высоты возврата (${RALT} см = ${RALT_M} м)"
    else no "RTL_ALT=${RALT} см = ${RALT_M} м выше потолка геозоны ${FALT} м — возврат сам нарушит геозону"; fi
    if ge "${RALT_M}" "${OBST}"
    then ok "высота возврата ${RALT_M} м выше препятствия (${OBST} м)"
    else no "RTL_ALT=${RALT} см = ${RALT_M} м ниже препятствия ${OBST} м — проверь единицы: RTL_ALT в САНТИМЕТРАХ"; fi
fi

RFIN="$(val RTL_ALT_FINAL)"
if [ "${RFIN%.*}" = 0 ] && [ -n "${RFIN}" ]
then ok "RTL_ALT_FINAL=${RFIN} — после возврата аппарат садится"
else no "RTL_ALT_FINAL=${RFIN:-не задан}: ненулевое значение оставит аппарат висеть над домом и тратить остаток заряда"; fi

echo ""
echo "── Комментарии ──"
grep -qE '^[[:space:]]*#' "${P}" && ok "пояснения в файле остались" \
                                 || no "комментарии вырезаны — набор параметров должен объяснять сам себя"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
