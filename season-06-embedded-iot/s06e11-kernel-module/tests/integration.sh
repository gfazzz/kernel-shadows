#!/usr/bin/env bash
#
# s06e11 — интеграционный тест: собрать настоящий .ko и загрузить его.
#
# Требует того, чего нет у большинства: Linux, заголовки работающего ядра
# и права root. Поэтому он вынесен из основного прогона и запускается
# отдельно:
#
#   make test-integration
#
# Если условий нет, тест честно сообщает, чего именно не хватает, и
# завершается успешно: отсутствие ядра под рукой — не ошибка студента.
# Логика модуля при этом уже проверена юнит-тестами в tests/test.sh.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT_DIR:-}" ];                      then SD="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/shadow_mod.c" ];  then SD="${SERIES_DIR}/artifacts"
else SD="${SERIES_DIR}/solution"; fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }
skip(){ echo "  SKIP: $1"; }

echo "════════════════════════════════════════════════════════════"
echo " s06e11 integration — сборка и загрузка модуля"
echo "════════════════════════════════════════════════════════════"

finish() {
    echo ""
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    echo "════════════════════════════════════════════════════════════"
    [ "${FAIL}" -eq 0 ]
}

# ── условия ──────────────────────────────────────────────────────────
if [ "$(uname -s)" != "Linux" ]; then
    skip "не Linux ($(uname -s)) — модуль ядра Linux собрать негде"
    echo "     Логика проверена юнит-тестами: bash tests/test.sh"
    finish; exit $?
fi

KDIR="${KDIR:-/lib/modules/$(uname -r)/build}"
if [ ! -d "${KDIR}" ]; then
    skip "нет заголовков ядра в ${KDIR}"
    echo "     Debian/Ubuntu: apt install linux-headers-\$(uname -r)"
    echo "     Raspberry Pi:  apt install raspberrypi-kernel-headers"
    finish; exit $?
fi
ok "заголовки ядра найдены: ${KDIR}"

# ── сборка ───────────────────────────────────────────────────────────
BUILD="$(mktemp -d)"
trap 'rm -rf "${BUILD}"' EXIT
cp "${SD}"/shadow_mod.c "${SD}"/shadow_ring.c "${SD}"/shadow_ring.h "${SD}"/Makefile "${BUILD}/" 2>/dev/null

if make -C "${KDIR}" M="${BUILD}" modules >"${BUILD}/build.log" 2>&1; then
    ok "модуль собрался"
else
    no "сборка не прошла:"
    sed 's/^/        /' "${BUILD}/build.log" | tail -25
    finish; exit $?
fi

KO="$(find "${BUILD}" -maxdepth 1 -name '*.ko' | head -1)"
[ -n "${KO}" ] && ok "получен $(basename "${KO}")" || { no "нет .ko после сборки"; finish; exit $?; }

# ── метаданные ───────────────────────────────────────────────────────
if command -v modinfo >/dev/null 2>&1; then
    INFO="$(modinfo "${KO}" 2>/dev/null)"
    grep -qE '^license:[[:space:]]*GPL' <<<"${INFO}" && ok "modinfo: лицензия GPL" \
        || no "modinfo не показывает лицензию GPL"
    grep -qE '^parm:[[:space:]]*depth' <<<"${INFO}" && ok "modinfo: параметр depth описан" \
        || no "параметр depth не виден в modinfo"
    grep -qE '^description:' <<<"${INFO}" && ok "modinfo: описание есть" || no "нет описания"
else
    skip "нет modinfo"
fi

# ── загрузка ─────────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
    skip "не root — загрузка модуля пропущена (sudo make test-integration)"
    finish; exit $?
fi

MODNAME="$(basename "${KO}" .ko)"
rmmod "${MODNAME}" 2>/dev/null || true

DMESG_BEFORE="$(dmesg | wc -l)"
if insmod "${KO}" depth=8 node_id=shadow-node-07 2>"${BUILD}/insmod.log"; then
    ok "модуль загрузился с depth=8"
else
    no "insmod не прошёл: $(cat "${BUILD}/insmod.log")"
    finish; exit $?
fi

lsmod | grep -q "^${MODNAME}" && ok "модуль виден в lsmod" || no "модуля нет в lsmod"

PARAM="/sys/module/${MODNAME}/parameters/depth"
if [ -r "${PARAM}" ]; then
    ok "параметр доступен в sysfs: $(cat "${PARAM}")"
    [ "$(cat "${PARAM}")" = "8" ] && ok "значение параметра принято" \
        || no "в sysfs $(cat "${PARAM}"), а передавали 8"
else
    no "нет ${PARAM} — права параметра должны быть 0444"
fi

dmesg | tail -n +"${DMESG_BEFORE}" | grep -qi 'shadow' \
    && ok "модуль отчитался в журнале ядра" \
    || no "в dmesg нет сообщений модуля"

# ── проверка обрезки параметра ───────────────────────────────────────
rmmod "${MODNAME}" && ok "модуль выгрузился" || no "rmmod не прошёл"
if insmod "${KO}" depth=100000 2>/dev/null; then
    VAL="$(cat "/sys/module/${MODNAME}/parameters/depth" 2>/dev/null)"
    ok "depth=100000 не уронил ядро (в параметре ${VAL})"
    dmesg | tail -20 | grep -qi 'depth' && ok "о выходе за границы сказано в журнале" \
        || no "нет предупреждения о некорректном параметре"
    rmmod "${MODNAME}" 2>/dev/null || true
else
    no "модуль не загрузился с большим depth — параметр должен обрезаться, а не отвергаться"
fi

finish
