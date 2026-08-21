#!/usr/bin/env bash
#
# s06e12 — интеграционный тест: собрать .ko, загрузить и ПРОЧИТАТЬ
# /dev/shadow0 обычными средствами.
#
# Здесь проверяется то, чего не даст ни один юнит-тест: что устройство
# действительно появляется в /dev, что cat дочитывает его до конца и не
# зацикливается, и что чтение по кускам (head -c) отдаёт ровно начало.
#
# Требует Linux, заголовки работающего ядра и root. Без них честно
# сообщает, чего не хватает, и завершается успешно.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if   [ -n "${SUBJECT_DIR:-}" ];                      then SD="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/shadow_dev.c" ];  then SD="${SERIES_DIR}/artifacts"
else SD="${SERIES_DIR}/solution"; fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }
skip(){ echo "  SKIP: $1"; }
finish(){ echo ""; echo " Итог: ${PASS} passed, ${FAIL} failed"
          echo "════════════════════════════════════════════════════════════"
          [ "${FAIL}" -eq 0 ]; }

echo "════════════════════════════════════════════════════════════"
echo " s06e12 integration — /dev/shadow0"
echo "════════════════════════════════════════════════════════════"

if [ "$(uname -s)" != "Linux" ]; then
    skip "не Linux ($(uname -s)) — модуль ядра Linux собрать негде"
    echo "     Логика проверена юнит-тестами: bash tests/test.sh"
    finish; exit $?
fi

KDIR="${KDIR:-/lib/modules/$(uname -r)/build}"
if [ ! -d "${KDIR}" ]; then
    skip "нет заголовков ядра в ${KDIR}"
    echo "     Debian/Ubuntu: apt install linux-headers-\$(uname -r)"
    finish; exit $?
fi
ok "заголовки ядра найдены"

BUILD="$(mktemp -d)"; trap 'rm -rf "${BUILD}"' EXIT
cp "${SD}"/shadow_dev.c "${SD}"/shadow_view.c "${SD}"/shadow_ring.c \
   "${SD}"/shadow_view.h "${SD}"/shadow_ring.h "${SD}"/Makefile "${BUILD}/" 2>/dev/null

if make -C "${KDIR}" M="${BUILD}" modules >"${BUILD}/build.log" 2>&1
then ok "модуль собрался"
else no "сборка не прошла:"; tail -25 "${BUILD}/build.log" | sed 's/^/        /'; finish; exit $?; fi

KO="$(find "${BUILD}" -maxdepth 1 -name '*.ko' | head -1)"
[ -n "${KO}" ] && ok "получен $(basename "${KO}")" || { no "нет .ko"; finish; exit $?; }

if [ "$(id -u)" -ne 0 ]; then
    skip "не root — загрузка пропущена (sudo bash tests/integration.sh)"
    finish; exit $?
fi

MOD="$(basename "${KO}" .ko)"
rmmod "${MOD}" 2>/dev/null || true
if insmod "${KO}" depth=8; then ok "модуль загрузился"
else no "insmod не прошёл"; finish; exit $?; fi

DEVNODE=/dev/shadow0
for _ in 1 2 3 4 5; do [ -e "${DEVNODE}" ] && break; sleep 0.2; done
[ -c "${DEVNODE}" ] && ok "${DEVNODE} создан как символьное устройство" \
                    || no "нет ${DEVNODE} — device_create не отработал"

if [ -c "${DEVNODE}" ]; then
    FULL="$(timeout 5 cat "${DEVNODE}")"; RC=$?
    if [ "${RC}" -eq 0 ] && [ -n "${FULL}" ]
    then ok "cat дочитал устройство до конца ($(printf '%s' "${FULL}" | wc -l) строк)"
    else no "cat вернул ${RC}: без признака конца файла он зациклится"; fi

    printf '%s' "${FULL}" | grep -qE '^seq=[0-9]+ t=-?[0-9]+\.[0-9]{3}$' \
        && ok "формат строк соответствует shadow_format_line" \
        || no "неожиданный формат: $(printf '%s' "${FULL}" | head -1)"

    HEAD="$(timeout 5 head -c 8 "${DEVNODE}")"
    [ "${HEAD}" = "$(printf '%s' "${FULL}" | head -c 8)" ] \
        && ok "head -c 8 отдал ровно начало (частичное чтение верно)" \
        || no "частичное чтение отдало «${HEAD}» вместо начала"

    A="$(timeout 5 cat "${DEVNODE}")"
    [ "${A}" = "${FULL}" ] && ok "повторное чтение даёт то же самое" \
                           || no "второе чтение отличается — позиция не сбрасывается при open"
fi

dmesg | tail -30 | grep -qi 'shadow' && ok "модуль отчитался в журнале ядра" \
                                     || no "в dmesg нет сообщений модуля"

if rmmod "${MOD}"; then ok "модуль выгрузился"
else no "rmmod не прошёл — вероятно, ресурс остался занят"; fi
[ -e "${DEVNODE}" ] && no "${DEVNODE} остался после выгрузки" || ok "узел в /dev убран"

finish
