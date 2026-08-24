#!/usr/bin/env bash
#
# s06e03 «Загрузка платы» — тест config.txt и cmdline.txt (Type B).
#
# Ни одного зашитого требования: какие шины включать — вычисляется из
# data/sensors.txt (что подключено, то и включаем), а PARTUUID, тип ФС,
# скорость консоли и семейство платы — из data/board_facts.txt.
# Подмени список датчиков — тест будет ждать другой набор шин.
#
# Разбор config.txt учитывает секции-фильтры: параметр действует от своего
# фильтра до следующего, и «после [pi4] без [all]» — не то же самое, что
# «для всех».
#
# Без root, без сети, без платы.
#
# Выбор файлов: SUBJECT_DIR=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FACTS="${SERIES_DIR}/data/board_facts.txt"
SENSORS="${SERIES_DIR}/data/sensors.txt"

if   [ -n "${SUBJECT_DIR:-}" ];                       then SD="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/config.txt" ];     then SD="${SERIES_DIR}/artifacts"
elif [ -f "${SERIES_DIR}/config.txt" ];               then SD="${SERIES_DIR}"
else SD="${SERIES_DIR}/solution"
     echo "ℹ️  Своего config.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/config.txt starter/cmdline.txt artifacts/"; echo ""
fi
CFG="${SD}/config.txt"
CMD="${SD}/cmdline.txt"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e03 tests — конфигурация: ${SD#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${FACTS}" "${SENSORS}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${CFG}" ]; then ok "config.txt найден"; else no "нет config.txt"; fi
if [ -f "${CMD}" ]; then ok "cmdline.txt найден"; else no "нет cmdline.txt"; fi
[ -f "${CFG}" ] && [ -f "${CMD}" ] || { echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

fact() { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "${FACTS}"; }

FAMILY="$(fact family)"
PARTUUID="$(fact root_partuuid)"
ROOTFS="$(fact rootfstype)"
SPEED="$(fact console_speed)"

# ── чего требуют датчики ─────────────────────────────────────────────
sensor_buses() { awk '/^[[:space:]]*#/{next} NF>=2 {print $2}' "${SENSORS}" | sort -u; }
W1_PIN="$(awk '/^[[:space:]]*#/{next} $2=="w1" {sub(/^gpio/,"",$3); print $3; exit}' "${SENSORS}")"

REQ=""
for b in $(sensor_buses); do
    case "${b}" in i2c|spi|w1) REQ="${REQ} ${b}" ;; esac
done
REQ="$(printf '%s\n' ${REQ} | sort -u | tr '\n' ' ')"

echo ""
echo "── Исходные данные ──"
if [ -n "${FAMILY}" ] && [ -n "${PARTUUID}" ] && [ -n "${SPEED}" ]
then ok "факты платы: ${FAMILY}, PARTUUID=${PARTUUID}, консоль ${SPEED}"
else no "не разобрался data/board_facts.txt"; fi
if [ "$(printf '%s\n' ${REQ} | grep -c .)" -ge 2 ]
then ok "датчики требуют шин: ${REQ}"; else no "в sensors.txt меньше двух шин — проверка вырождена"; fi

# ── разбор config.txt с учётом фильтров ──────────────────────────────
# На выходе строки вида: ФИЛЬТР<TAB>ключ<TAB>значение
parse_cfg() {
    awk '
        { line=$0
          sub(/[[:space:]]*#.*$/, "", line)            # комментарии
          gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
          if (line == "") next
          if (line ~ /^\[.*\]$/) {                     # секция-фильтр
              f=line; gsub(/^\[|\]$/, "", f); filter=f; next
          }
          if (line !~ /=/) next
          eq=index(line,"=")
          k=substr(line,1,eq-1); v=substr(line,eq+1)
          printf "%s\t%s\t%s\n", (filter=="" ? "all" : filter), k, v
        }' "$1"
}

CFGP="$(parse_cfg "${CFG}")"

# применяется ли к нашей плате: без фильтра, [all] или [семейство]
applies() { awk -F'\t' -v fam="${FAMILY}" '$1=="all" || $1==fam' <<<"${CFGP}"; }
# действует на любой плате (не спрятано в фильтр семейства)
universal() { awk -F'\t' '$1=="all"' <<<"${CFGP}"; }

has_kv() { awk -F'\t' -v k="$2" -v v="$3" '$2==k && $3==v {f=1} END{exit !f}' <<<"$1"; }
val_of()  { awk -F'\t' -v k="$2" '$2==k {print $3}' <<<"$1" | tail -1; }

APPL="$(applies)"; UNIV="$(universal)"

# какие шины реально включены (dtparam / dtoverlay)
bus_enabled() {
    case "$1" in
        i2c) awk -F'\t' '$2=="dtparam" && $3 ~ /^i2c(_arm)?=on$/ {f=1} END{exit !f}' <<<"${APPL}" ;;
        spi) awk -F'\t' '$2=="dtparam" && $3 ~ /^spi=on$/         {f=1} END{exit !f}' <<<"${APPL}" ;;
        w1)  awk -F'\t' '$2=="dtoverlay" && $3 ~ /^w1-gpio/       {f=1} END{exit !f}' <<<"${APPL}" ;;
        *) return 1 ;;
    esac
}

echo ""
echo "── config.txt: шины под датчики ──"
for b in i2c spi w1; do
    want=no; case " ${REQ} " in *" ${b} "*) want=yes ;; esac
    if bus_enabled "${b}"; then have=yes; else have=no; fi
    if [ "${want}" = "${have}" ]; then
        [ "${want}" = yes ] && ok "${b} включена — её требует датчик" \
                            || ok "${b} не включена — датчиков на ней нет"
    else
        [ "${want}" = yes ] && no "${b} нужна датчику из sensors.txt, но не включена" \
                            || no "${b} включена, хотя ни один датчик её не использует — лишние занятые ножки"
    fi
done

if [ -n "${W1_PIN}" ]; then
    if awk -F'\t' -v p="${W1_PIN}" '$2=="dtoverlay" && $3 ~ ("^w1-gpio") && $3 ~ ("gpiopin=" p "$|gpiopin=" p ",") {f=1} END{exit !f}' <<<"${APPL}"
    then ok "w1-gpio привязан к ножке ${W1_PIN} из sensors.txt"
    else no "w1-gpio без gpiopin=${W1_PIN} — номер ножки берётся из sensors.txt"; fi
fi

echo ""
echo "── config.txt: консоль и безголовый режим ──"
if has_kv "${UNIV}" enable_uart 1; then ok "enable_uart=1 действует для всех плат"
else no "enable_uart=1 не задан (или спрятан в фильтр) — узел без консоли не диагностируется"; fi

GPU="$(val_of "${APPL}" gpu_mem)"
if [ -n "${GPU}" ] && [ "${GPU}" -le 64 ] 2>/dev/null; then ok "gpu_mem=${GPU} — узел безголовый"
else no "gpu_mem=«${GPU:-не задан}» — на узле без монитора видеопамять не нужна"; fi

if [ -n "$(val_of "${APPL}" disable_splash)" ]; then ok "заставка отключена"
else no "disable_splash не задан"; fi
if [ -n "$(val_of "${APPL}" boot_delay)" ]; then ok "boot_delay задан"
else no "boot_delay не задан — лишняя пауза на каждом старте"; fi

echo ""
echo "── config.txt: секции-фильтры ──"
if grep -qE "^[[:space:]]*\[${FAMILY}\][[:space:]]*$" "${CFG}"; then ok "есть секция [${FAMILY}] для этой платы"
else no "нет секции [${FAMILY}] — платозависимые параметры должны быть в ней"; fi

if awk -F'\t' -v fam="${FAMILY}" '$1==fam && $2=="dtoverlay" && $3 ~ /disable-bt/ {f=1} END{exit !f}' <<<"${CFGP}"
then ok "disable-bt внутри секции [${FAMILY}] — консоль получает нормальный UART"
elif awk -F'\t' '$2=="dtoverlay" && $3 ~ /disable-bt/ {f=1} END{exit !f}' <<<"${CFGP}"
then no "disable-bt есть, но не в секции [${FAMILY}] — на других платах он не нужен"
else no "нет dtoverlay=disable-bt: на ${FAMILY} консоль останется на mini-UART с плавающей скоростью"; fi

LASTF="$(grep -oE '^[[:space:]]*\[[a-zA-Z0-9_+-]+\][[:space:]]*$' "${CFG}" | tail -1 | tr -d ' []')"
NAFTER="$(awk 'f && !/^[[:space:]]*($|#)/ {c++} /^[[:space:]]*\[[a-zA-Z0-9_+-]+\][[:space:]]*$/ {f=1; c=0} END{print c+0}' "${CFG}")"
if [ -z "${LASTF}" ]; then no "в файле нет ни одной секции-фильтра"
elif [ "${LASTF}" = "all" ]; then ok "файл завершается секцией [all]"
elif [ "${NAFTER}" -eq 0 ]; then ok "после последнего фильтра [${LASTF}] ничего не дописано"
else no "файл кончается секцией [${LASTF}], и ниже ещё ${NAFTER} параметров — они молча достанутся только этой плате"; fi

DUP="$(awk -F'\t' '$2!="dtoverlay" && $2!="dtparam" {print $1"\t"$2}' <<<"${CFGP}" | sort | uniq -d | wc -l)"
[ "${DUP}" -eq 0 ] && ok "нет дублирующихся параметров в одной секции" \
                   || no "${DUP} параметров заданы дважды в одной секции — результат зависит от порядка"

echo ""
echo "── cmdline.txt: одна строка ──"
NLINES="$(grep -vc '^[[:space:]]*$' "${CMD}")"
[ "${NLINES}" -eq 1 ] && ok "ровно одна непустая строка" \
                      || no "непустых строк: ${NLINES} — ядро читает только первую, остальное молча теряется"
if grep -qE '^[[:space:]]*#' "${CMD}"; then no "есть строки-комментарии — cmdline.txt их не поддерживает"
else ok "нет комментариев"; fi

LINE="$(grep -v '^[[:space:]]*$' "${CMD}" | head -1)"
kv() { printf '%s\n' "${LINE}" | tr ' ' '\n' | awk -F= -v k="$1" '$1==k {sub(/^[^=]*=/,""); print; exit}'; }
hasw() { printf '%s\n' "${LINE}" | tr ' ' '\n' | grep -qx "$1"; }

echo ""
echo "── cmdline.txt: параметры ──"
if [ "$(kv root)" = "PARTUUID=${PARTUUID}" ]; then ok "root=PARTUUID=${PARTUUID}"
else no "root=«$(kv root)», а PARTUUID платы — ${PARTUUID}"; fi
if [ "$(kv rootfstype)" = "${ROOTFS}" ]; then ok "rootfstype=${ROOTFS}"
else no "rootfstype=«$(kv rootfstype)», в фактах платы — ${ROOTFS}"; fi
if hasw rootwait; then ok "rootwait — ядро дождётся носителя"
else no "нет rootwait: SD-карта появляется не мгновенно, без него — гонка при старте"; fi
if [ "$(kv console)" = "serial0,${SPEED}" ]; then ok "console=serial0,${SPEED}"
else no "console=«$(kv console)», скорость из фактов платы — ${SPEED}"; fi
if [ "$(kv fsck.repair)" = "yes" ]; then ok "fsck.repair=yes — чинить без вопросов"
else no "нет fsck.repair=yes: спрашивать на безголовом узле некого, он повиснет на проверке ФС"; fi
if printf '%s' "${LINE}" | grep -q 'init_resize'; then no "остался init=…init_resize.sh — одноразовый шаг первой загрузки"
else ok "нет одноразового init_resize"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
