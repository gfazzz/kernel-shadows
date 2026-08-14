#!/usr/bin/env bash
#
# s06e01 «Что это за плата» — тест паспорта платы (Type C).
#
# Ни одного ожидаемого значения не зашито: всё пересчитывается из снимков
# в data/. Имя ядра процессора берётся соединением cpuinfo со справочником
# arm_cpu_parts.txt, «запустится ли бинарник» — сравнением архитектур платы
# и собранного файла. Подмени снимки — тест ждёт другие ответы.
#
# Без root, без сети, без железа.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
CPU="${D}/cpuinfo_node7.txt"
DT="${D}/devicetree_node7.txt"
UN="${D}/uname_node7.txt"
BH="${D}/build_host.txt"
PARTS="${D}/arm_cpu_parts.txt"

if   [ -n "${SUBJECT:-}" ];                             then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/board_report.txt" ]; then REP="${SERIES_DIR}/artifacts/board_report.txt"
elif [ -f "${SERIES_DIR}/board_report.txt" ];           then REP="${SERIES_DIR}/board_report.txt"
else REP="${SERIES_DIR}/solution/board_report.txt"
     echo "ℹ️  Своего board_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/board_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e01 tests — паспорт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${CPU}" "${DT}" "${UN}" "${BH}" "${PARTS}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${REP}" ]; then ok "board_report.txt найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

got() { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "${REP}"; }

check() { local k="$1" want="$2" why="$3" have; have="$(got "${k}")"
    if [ -z "${have}" ]; then no "${k}: не заполнено (${why})"
    elif [ "${have}" = "${want}" ]; then ok "${k}=${have}"
    else no "${k}=${have}, из данных следует «${want}» — ${why}"; fi; }

check_ci() { local k="$1" want="$2" why="$3" have; have="$(got "${k}")"
    if [ -z "${have}" ]; then no "${k}: не заполнено (${why})"
    elif [ "$(printf '%s' "${have}" | tr 'A-Z' 'a-z')" = "$(printf '%s' "${want}" | tr 'A-Z' 'a-z')" ]; then ok "${k}=${have}"
    else no "${k}=${have}, из данных следует «${want}» — ${why}"; fi; }

# ── значения, вычисленные из снимков ────────────────────────────────
dt_val() { awk -F' = ' -v p="$1" '$1==p {print $2; exit}' "${DT}"; }
cpu_val() { awk -F':' -v k="$1" '$1 ~ "^"k"[ \t]*$" {v=$2; gsub(/^[[:space:]]+|[[:space:]]+$/,"",v); print v; exit}' "${CPU}"; }

E_MODEL="$(dt_val /proc/device-tree/model)"
E_SOC="$(cpu_val Hardware)"
E_SERIAL="$(cpu_val Serial)"
E_ARCH="$(grep -v '^[[:space:]]*#' "${UN}" | awk 'NF{print $(NF-1); exit}')"
E_CORES="$(grep -c '^processor' "${CPU}")"
E_PART="$(cpu_val 'CPU part')"
E_IMPL="$(cpu_val 'CPU implementer')"
E_CORE="$(awk -v i="${E_IMPL}" -v p="${E_PART}" '$1==i && $2==p {print $3; exit}' "${PARTS}")"

COMPAT="$(dt_val /proc/device-tree/compatible)"
E_CSPEC="$(printf '%s\n' "${COMPAT}" | awk '{print $1}')"
E_CGEN="$(printf '%s\n' "${COMPAT}" | awk '{print $NF}')"

E_GPIO="$(awk -F' = ' '$1 ~ /\/soc\/gpio@[0-9a-f]+\/status$/ {print $2; exit}' "${DT}")"
E_SPI="$(awk -F' = ' '$1 ~ /\/soc\/spi@[0-9a-f]+\/status$/ {print $2; exit}' "${DT}")"
E_OKAY="$(awk -F' = ' '$1 ~ /\/soc\/[^/]+\/status$/ && $2=="okay"' "${DT}" | grep -c .)"

BOOTARGS="$(dt_val /proc/device-tree/chosen/bootargs)"
E_CONSOLE="$(printf '%s\n' "${BOOTARGS}" | tr ' ' '\n' | awk -F= '$1=="console"{print $2; exit}')"

E_HOST="$(awk '/^\$ uname -m$/{getline; print; exit}' "${BH}")"
E_BIN="$(awk -F'build\\/collector: ' '/^build\/collector: /{split($2,a,","); print a[2]; exit}' "${BH}" | tr -d ' ')"
E_CROSS="$(awk '/-dumpmachine/{cmd=$2} /^[a-z0-9_]+-linux-gnu$/{last=$0} END{print last}' "${BH}")"
# «запустится ли» — из сравнения архитектур, без зашитого ответа
norm_arch() { printf '%s' "$1" | tr 'A-Z_' 'a-z-'; }
if [ "$(norm_arch "${E_BIN}")" = "$(norm_arch "${E_ARCH}")" ]; then E_RUNS="yes"; else E_RUNS="no"; fi

# ── проверки целостности самих данных ───────────────────────────────
echo ""
echo "── Снимки ──"
[ -n "${E_MODEL}" ] && ok "дерево устройств прочитано (model непустой)" || no "не разобрался /proc/device-tree/model"
[ "${E_CORES}" -gt 0 ] 2>/dev/null && ok "cpuinfo прочитан (ядер: ${E_CORES})" || no "не посчитались processor в cpuinfo"
[ -n "${E_CORE}" ] && ok "справочник ARM сошёлся (${E_IMPL}/${E_PART})" || no "нет строки ${E_IMPL} ${E_PART} в arm_cpu_parts.txt"
DT_SERIAL="$(dt_val /proc/device-tree/serial-number)"
[ "${DT_SERIAL}" = "${E_SERIAL}" ] && ok "серийный номер совпал в двух источниках" || no "serial расходится: cpuinfo=${E_SERIAL}, дерево=${DT_SERIAL}"

echo ""
echo "── 1. Что за плата ──"
check    model       "${E_MODEL}"  "строка /proc/device-tree/model целиком"
check    soc         "${E_SOC}"    "поле Hardware в cpuinfo"
check    serial      "${E_SERIAL}" "поле Serial в cpuinfo (и serial-number в дереве)"
check    board_arch  "${E_ARCH}"   "архитектура из uname платы, а не ноутбука"
check    cores       "${E_CORES}"  "число строк processor в cpuinfo"

echo ""
echo "── 2. Ядро процессора ──"
check_ci cpu_part    "${E_PART}"   "поле CPU part в cpuinfo"
check    cpu_core    "${E_CORE}"   "справочник: ${E_IMPL} + ${E_PART}"

echo ""
echo "── 3. compatible ──"
check    compatible_specific "${E_CSPEC}" "первый элемент — самое частное описание"
check    compatible_generic  "${E_CGEN}"  "последний элемент — самое общее описание"
if [ "${E_CSPEC}" = "${E_CGEN}" ]; then no "в данных compatible из одного элемента — проверка вырождена"
else ok "частное и общее в compatible различаются"; fi

echo ""
echo "── 4. Что включено ──"
check    gpio_status "${E_GPIO}"    "status узла gpio@"
check    spi_status  "${E_SPI}"     "status узла spi@ — узел выключен в дереве"
check    buses_okay  "${E_OKAY}"    "узлов soc/*/status = okay"
check    console     "${E_CONSOLE}" "значение console= из bootargs целиком"

echo ""
echo "── 5. Сборка ──"
check    host_arch    "${E_HOST}"  "uname -m рабочей машины"
check_ci binary_arch  "${E_BIN}"   "как file называет архитектуру build/collector"
check_ci runs_on_board "${E_RUNS}" "бинарник ${E_BIN} против платы ${E_ARCH}"
check    cross_prefix "${E_CROSS}" "-dumpmachine кросс-компилятора"

echo ""
echo "── Комментарии сохранены ──"
if grep -qE '^[[:space:]]*#' "${REP}"; then ok "пояснения в файле остались"
else no "все комментарии вырезаны — отчёт должен объяснять, откуда значения"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
