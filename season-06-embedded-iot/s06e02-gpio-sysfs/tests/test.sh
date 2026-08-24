#!/usr/bin/env bash
#
# s06e02 «GPIO через sysfs» — тест управления ножками (Type A).
#
# Платы нет. Вместо неё — макет sysfs во временном каталоге и функция
# sim(), которая делает ровно то, что делает ядро: увидев номер в файле
# export, создаёт каталог gpioN с файлами direction и value; увидев номер
# в unexport — удаляет каталог. Скрипт при этом работает с настоящими
# файлами настоящими средствами: он не знает, что перед ним не ядро.
#
# Ни одного зашитого ответа: занятость ножек берётся из карты гребёнки,
# и тест отдельно проверяет, что подмена карты меняет поведение скрипта.
#
# Без root, без сети, без железа.
#
# Выбор скрипта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
MAP="${SERIES_DIR}/data/gpio_map.txt"

if   [ -n "${SUBJECT:-}" ];                          then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/gpio_ctl.sh" ];   then S="${SERIES_DIR}/artifacts/gpio_ctl.sh"
elif [ -f "${SERIES_DIR}/gpio_ctl.sh" ];             then S="${SERIES_DIR}/gpio_ctl.sh"
else S="${SERIES_DIR}/solution/gpio_ctl.sh"
     echo "ℹ️  Своего gpio_ctl.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/gpio_ctl.sh artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e02 tests — скрипт: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${MAP}" ] || { echo "  FAIL: нет ${MAP}"; exit 1; }
if [ -f "${S}" ]; then ok "gpio_ctl.sh найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi
bash -n "${S}" 2>/dev/null && ok "синтаксис bash корректен" || { no "синтаксическая ошибка"; bash -n "${S}"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── значения, вычисленные из карты (ничего не зашито) ────────────────
map_free()  { awk '/^[[:space:]]*#/{next} NF>=2 && $2=="free" {print $1}'  "$1"; }
map_busy()  { awk '/^[[:space:]]*#/{next} NF>=2 && $2!="free" {print $1}'  "$1"; }
map_maxpin(){ awk '/^[[:space:]]*#/{next} NF>=2 {if($1+0>m) m=$1+0} END{print m}' "$1"; }

FREE1="$(map_free "${MAP}" | sed -n '1p')"
FREE2="$(map_free "${MAP}" | sed -n '2p')"
BUSY1="$(map_busy "${MAP}" | sed -n '1p')"
BUSY_FN="$(awk -v p="${BUSY1}" '/^[[:space:]]*#/{next} $1==p {print $2; exit}' "${MAP}")"
NOPIN=$(( $(map_maxpin "${MAP}") + 5 ))

if [ -n "${FREE1}" ] && [ -n "${FREE2}" ] && [ -n "${BUSY1}" ]; then
    ok "карта разобрана: свободные ${FREE1}, ${FREE2}; занят ${BUSY1} (${BUSY_FN})"
else
    no "в карте нет двух свободных и одной занятой ножки — проверка вырождена"
fi

# ── макет sysfs и «ядро» ─────────────────────────────────────────────
mkroot() { local r="$1"; rm -rf "${r}"; mkdir -p "${r}"; : > "${r}/export"; : > "${r}/unexport"; }

# sim: то, что делает ядро в ответ на запись в export/unexport
sim() {
    local r="$1" pin
    pin="$(tr -d '[:space:]' < "${r}/export")"
    if [ -n "${pin}" ]; then
        mkdir -p "${r}/gpio${pin}"
        printf 'in\n' > "${r}/gpio${pin}/direction"
        printf '0\n'  > "${r}/gpio${pin}/value"
        : > "${r}/export"
    fi
    pin="$(tr -d '[:space:]' < "${r}/unexport")"
    if [ -n "${pin}" ]; then
        rm -rf "${r}/gpio${pin}"
        : > "${r}/unexport"
    fi
}

R="${TMP}/sys"
run() { bash "${S}" --root "${R}" --map "${MAP}" "$@" >"${TMP}/out" 2>"${TMP}/err"; echo $?; }
out() { cat "${TMP}/out"; }

# ── 1. Аргументы и справка ───────────────────────────────────────────
echo ""
echo "── 1. Аргументы ──"
mkroot "${R}"
c="$(run)";                    [ "$c" = 1 ] && ok "без команды -> 1" || no "без команды -> ${c}, ждали 1"
c="$(run --help)";             [ "$c" = 0 ] && ok "--help -> 0"      || no "--help -> ${c}, ждали 0"
if bash "${S}" --help 2>/dev/null | grep -q 'export' && \
   bash "${S}" --help 2>/dev/null | grep -q 'direction' && \
   bash "${S}" --help 2>/dev/null | grep -q 'status'
then ok "справка перечисляет команды"; else no "в справке нет перечня команд"; fi
c="$(run frobnicate 1)";       [ "$c" = 1 ] && ok "неизвестная команда -> 1" || no "неизвестная команда -> ${c}"
c="$(run export abc)";         [ "$c" = 1 ] && ok "нечисловой пин -> 1"      || no "нечисловой пин -> ${c}"

# ── 2. Проверки до записи ────────────────────────────────────────────
echo ""
echo "── 2. Что проверяется до записи ──"
c="$(run export "${NOPIN}")";  [ "$c" = 3 ] && ok "пина ${NOPIN} нет на гребёнке -> 3" || no "нет такого пина -> ${c}, ждали 3"
c="$(run export "${BUSY1}")";  [ "$c" = 5 ] && ok "занятый ${BUSY1} (${BUSY_FN}) -> 5" || no "занятый пин -> ${c}, ждали 5"
if [ -z "$(tr -d '[:space:]' < "${R}/export")" ]; then ok "в export ничего не записано при отказе"
else no "скрипт записал занятый пин в export — проверка после действия бесполезна"; fi
c="$(run --root "${TMP}/нет-такого" export "${FREE1}")"
[ "$c" = 2 ] && ok "нет sysfs -> 2" || no "нет sysfs -> ${c}, ждали 2"

# ── 3. Экспорт и идемпотентность ─────────────────────────────────────
echo ""
echo "── 3. Экспорт ──"
mkroot "${R}"
c="$(run export "${FREE1}")"
if [ "$c" = 0 ] && [ "$(tr -d '[:space:]' < "${R}/export")" = "${FREE1}" ]
then ok "export ${FREE1}: номер записан в export"; else no "export ${FREE1}: код ${c}, в файле «$(cat "${R}/export")»"; fi
sim "${R}"
[ -d "${R}/gpio${FREE1}" ] && ok "ядро создало gpio${FREE1}/" || no "макет не создал каталог пина"

c="$(run export "${FREE1}")"
if [ "$c" = 0 ] && [ -z "$(tr -d '[:space:]' < "${R}/export")" ]
then ok "повторный export идемпотентен: 0 и ничего не записано"
else no "повторный export: код ${c}, в export «$(cat "${R}/export")» — на живом ядре это EBUSY"; fi

# ── 4. Направление ───────────────────────────────────────────────────
echo ""
echo "── 4. Направление ──"
c="$(run direction "${FREE2}" out)"; [ "$c" = 4 ] && ok "direction без export -> 4" || no "direction без export -> ${c}, ждали 4"
c="$(run direction "${FREE1}" вверх)"; [ "$c" = 1 ] && ok "чужое направление -> 1" || no "чужое направление -> ${c}, ждали 1"
c="$(run direction "${FREE1}" out)"
if [ "$c" = 0 ] && [ "$(tr -d '[:space:]' < "${R}/gpio${FREE1}/direction")" = "out" ]
then ok "direction ${FREE1} out записано"; else no "direction: код ${c}, в файле «$(cat "${R}/gpio${FREE1}/direction")»"; fi

# ── 5. Запись и чтение ───────────────────────────────────────────────
echo ""
echo "── 5. Значение ──"
c="$(run write "${FREE1}" 2)"; [ "$c" = 1 ] && ok "значение 2 -> 1" || no "значение 2 -> ${c}, ждали 1"
c="$(run write "${FREE1}" 1)"
if [ "$c" = 0 ] && [ "$(tr -d '[:space:]' < "${R}/gpio${FREE1}/value")" = "1" ]
then ok "write ${FREE1} 1 -> value=1"; else no "write: код ${c}, value=«$(cat "${R}/gpio${FREE1}/value")»"; fi

c="$(run read "${FREE1}")"
if [ "$c" = 0 ] && [ "$(out | tr -d '[:space:]')" = "1" ]
then ok "read печатает только значение"; else no "read: код ${c}, вывод «$(out)»"; fi

# вход: писать нельзя
printf 'in\n' > "${R}/gpio${FREE1}/direction"
printf '0\n'  > "${R}/gpio${FREE1}/value"
c="$(run write "${FREE1}" 1)"
if [ "$c" = 4 ] && [ "$(tr -d '[:space:]' < "${R}/gpio${FREE1}/value")" = "0" ]
then ok "запись во вход -> 4, значение не тронуто"
else no "запись во вход: код ${c}, value=«$(cat "${R}/gpio${FREE1}/value")» — направление проверяется ДО записи"; fi

c="$(run read "${FREE2}")"; [ "$c" = 4 ] && ok "read неэкспортированного -> 4" || no "read неэкспортированного -> ${c}, ждали 4"

# ── 6. Статус ────────────────────────────────────────────────────────
echo ""
echo "── 6. Статус ──"
c="$(run status)"
if [ "$c" = 0 ] && out | grep -q "${FREE1}"; then ok "status показывает занятую ножку ${FREE1}"
else no "status: код ${c}, вывод «$(out)»"; fi
mkroot "${R}"
c="$(run status)"
if [ "$c" = 0 ] && [ -n "$(out)" ]; then ok "status на пустом корне -> 0 и сообщение"
else no "status на пустом корне: код ${c}, вывод «$(out)»"; fi

# ── 7. Освобождение ──────────────────────────────────────────────────
echo ""
echo "── 7. Освобождение ──"
run export "${FREE2}" >/dev/null; sim "${R}"
c="$(run unexport "${FREE2}")"
if [ "$c" = 0 ] && [ "$(tr -d '[:space:]' < "${R}/unexport")" = "${FREE2}" ]
then ok "unexport ${FREE2}: номер записан"; else no "unexport: код ${c}, в файле «$(cat "${R}/unexport")»"; fi
sim "${R}"
[ -d "${R}/gpio${FREE2}" ] && no "каталог пина остался после unexport" || ok "каталог пина исчез"
c="$(run unexport "${FREE2}")"
if [ "$c" = 0 ] && [ -z "$(tr -d '[:space:]' < "${R}/unexport")" ]
then ok "повторный unexport идемпотентен"; else no "повторный unexport: код ${c}"; fi

# ── 8. Занятость берётся из карты, а не из кода ──────────────────────
echo ""
echo "── 8. Данные, а не догадки ──"
ALT="${TMP}/alt_map.txt"
awk -v f="${FREE1}" -v b="${BUSY1}" '
    /^[[:space:]]*#/ {print; next}
    NF>=2 && $1==f {print $1, "swapped-bus"; next}
    NF>=2 && $1==b {print $1, "free"; next}
    {print}' "${MAP}" > "${ALT}"
mkroot "${R}"
c="$(bash "${S}" --root "${R}" --map "${ALT}" export "${FREE1}" >/dev/null 2>&1; echo $?)"
[ "$c" = 5 ] && ok "по другой карте ${FREE1} стал занят -> 5" || no "подмена карты не изменила ответ (код ${c}) — занятость зашита в коде"
c="$(bash "${S}" --root "${R}" --map "${ALT}" export "${BUSY1}" >/dev/null 2>&1; echo $?)"
[ "$c" = 0 ] && ok "по другой карте ${BUSY1} стал свободен -> 0" || no "подмена карты не изменила ответ (код ${c})"

# ── 9. Повторяемость ─────────────────────────────────────────────────
echo ""
echo "── 9. Повторяемость ──"
mkroot "${R}"
cycle() {
    bash "${S}" --root "${R}" --map "${MAP}" export "${FREE1}"      >/dev/null 2>&1 || return 1
    sim "${R}"
    bash "${S}" --root "${R}" --map "${MAP}" direction "${FREE1}" out >/dev/null 2>&1 || return 1
    bash "${S}" --root "${R}" --map "${MAP}" write "${FREE1}" 1       >/dev/null 2>&1 || return 1
    bash "${S}" --root "${R}" --map "${MAP}" unexport "${FREE1}"      >/dev/null 2>&1 || return 1
    sim "${R}"
}
if cycle && cycle; then ok "полный цикл проходит дважды подряд"
else no "второй прогон цикла сломался — не идемпотентно"; fi
if LC_ALL=C TZ=Asia/Tokyo cycle; then ok "цикл не зависит от локали и часового пояса"
else no "цикл сломался при LC_ALL=C / чужом TZ"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
