#!/usr/bin/env bash
#
# s06e11 «Модуль ядра» — тест (Type D).
#
# Двухуровневая проверка, ради которой логика и вынесена из ядра:
#   1. shadow_ring.c собирается обычным gcc вместе с tests/unit_ring.c
#      и проверяется настоящими юнит-тестами — без ядра, без root,
#      на любой системе;
#   2. shadow_mod.c проверяется структурно: требования и запреты
#      берутся из data/module_rules.txt и data/forbidden.txt.
#
# Сборка настоящего .ko и его загрузка — отдельная цель:
#   make test-integration        (tests/integration.sh)
# Она требует Linux с заголовками ядра и прав root; основной прогон
# остаётся зелёным везде.
#
# Выбор каталога: SUBJECT_DIR=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"

if   [ -n "${SUBJECT_DIR:-}" ];                        then SD="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/shadow_ring.c" ];   then SD="${SERIES_DIR}/artifacts"
elif [ -f "${SERIES_DIR}/shadow_ring.c" ];             then SD="${SERIES_DIR}"
else SD="${SERIES_DIR}/solution"
     echo "ℹ️  Своего shadow_ring.c не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/* artifacts/"; echo ""
fi
RING="${SD}/shadow_ring.c"; MOD="${SD}/shadow_mod.c"; HDR="${SD}/shadow_ring.h"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e11 tests — модуль: ${SD#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${D}/module_rules.txt" "${D}/forbidden.txt" "${SERIES_DIR}/tests/unit_ring.c"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done

CC="${CC:-$(command -v gcc || command -v cc || true)}"
if [ -z "${CC}" ]; then
    echo "  FAIL: не найден компилятор C (gcc или cc)"
    echo "        macOS: xcode-select --install | Debian: apt install build-essential"
    echo " Итог: 0 passed, 1 failed"; exit 1
fi
ok "компилятор C найден (${CC##*/})"

[ -f "${RING}" ] && ok "shadow_ring.c найден" || no "нет shadow_ring.c"
[ -f "${MOD}" ]  && ok "shadow_mod.c найден"  || no "нет shadow_mod.c"
[ -f "${HDR}" ]  && ok "shadow_ring.h на месте" || no "нет shadow_ring.h"
[ -f "${RING}" ] && [ -f "${MOD}" ] && [ -f "${HDR}" ] || { echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── 1. Логика собирается без ядра ────────────────────────────────────
echo ""
echo "── 1. Сборка логики обычным компилятором ──"
if grep -qE '#include[[:space:]]*<linux/' "${RING}"; then
    no "shadow_ring.c подключает заголовки ядра — тогда его нельзя проверить без ядра"
else
    ok "shadow_ring.c не зависит от заголовков ядра"
fi

BUILD_LOG="${TMP}/build.log"
if "${CC}" -std=c99 -Wall -Wextra -Werror -O1 -I"${SD}" -I"${SERIES_DIR}/tests" \
       -o "${TMP}/unit_ring" "${RING}" "${SERIES_DIR}/tests/unit_ring.c" >"${BUILD_LOG}" 2>&1
then ok "собралось без предупреждений (-Wall -Wextra -Werror)"
else no "не собралось:"; sed 's/^/        /' "${BUILD_LOG}" | head -20
     echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

# ── 2. Юнит-тесты логики ─────────────────────────────────────────────
echo ""
UNIT_OUT="$("${TMP}/unit_ring" 2>&1)"; URC=$?
while IFS= read -r line; do
    case "${line}" in
        "  PASS: "*) ok "${line#  PASS: }" ;;
        "  FAIL: "*) no "${line#  FAIL: }" ;;
        *) echo "${line}" ;;
    esac
done <<< "${UNIT_OUT}"

# ── 3. Структура модуля ──────────────────────────────────────────────
echo ""
echo "── 3. Обвязка модуля ──"
MODSRC="$(grep -v '^[[:space:]]*\*' "${MOD}" | grep -v '^[[:space:]]*//' | grep -v '^[[:space:]]*/\*')"

while IFS=$'\t' read -r id re why; do
    case "${id}" in ''|\#*) continue ;; esac
    if grep -qE "${re}" <<<"${MODSRC}"; then ok "${id}: ${why}"
    else no "${id}: не найдено — ${why}"; fi
done < "${D}/module_rules.txt"

echo ""
echo "── 4. Чего в ядре быть не должно ──"
while IFS=$'\t' read -r id re why; do
    case "${id}" in ''|\#*) continue ;; esac
    if grep -qE "${re}" <<<"${MODSRC}"; then no "${id}: найдено в исходнике — ${why}"
    else ok "${id}: отсутствует (${why})"; fi
done < "${D}/forbidden.txt"

echo ""
echo "── 5. Ресурсы и логика ──"
if grep -qE '\b(kmalloc|kzalloc|kcalloc)\b' <<<"${MODSRC}"; then
    grep -qE '\bkfree\b' <<<"${MODSRC}" \
        && ok "выделенная память освобождается (kfree)" \
        || no "есть kzalloc/kmalloc без kfree — в ядре нет сборщика мусора"
    if grep -qE 'return[[:space:]]+-ENOMEM' <<<"${MODSRC}"; then
        ok "неудача выделения обработана (-ENOMEM)"
    else
        no "нет обработки неудачного выделения: kzalloc может вернуть NULL"
    fi
else
    no "модуль ничего не выделяет — буфер должен жить в памяти ядра"
fi

grep -qE '\bshadow_param_clamp[[:space:]]*\(' <<<"${MODSRC}" \
    && ok "параметр загоняется в границы перед использованием" \
    || no "depth используется без shadow_param_clamp — значение приходит извне"
grep -qE '\bshadow_ring_init[[:space:]]*\(' <<<"${MODSRC}" \
    && ok "буфер инициализируется" || no "shadow_ring_init не вызывается"

# логика не продублирована в модуле
if grep -qE '%[[:space:]]*capacity|head[[:space:]]*\+[[:space:]]*1[[:space:]]*\)[[:space:]]*%' <<<"${MODSRC}"
then no "арифметика кольца продублирована в shadow_mod.c — она должна жить в проверяемом файле"
else ok "арифметика кольца не продублирована в обвязке"; fi

# ── 6. Сборка модуля описана ─────────────────────────────────────────
echo ""
echo "── 6. Сборка ──"
MK="${SD}/Makefile"
if [ -f "${MK}" ]; then
    ok "Makefile на месте"
    grep -qE '^obj-m' "${MK}" && ok "объявлена цель kbuild (obj-m)" || no "нет obj-m — kbuild не соберёт модуль"
    grep -qE 'shadow_ring\.o' "${MK}" && ok "логика входит в модуль отдельным объектом" \
        || no "shadow_ring.o не включён в модуль"
else no "нет Makefile"; fi

[ -f "${SERIES_DIR}/tests/integration.sh" ] \
    && ok "интеграционный тест объявлен (make test-integration)" \
    || no "нет tests/integration.sh: сборку .ko надо где-то проверять"

echo ""
echo "── 7. Повторяемость ──"
A="$("${TMP}/unit_ring" 2>&1 | tail -1)"
B="$(LC_ALL=C TZ=Asia/Tokyo "${TMP}/unit_ring" 2>&1 | tail -1)"
[ "${A}" = "${B}" ] && ok "результат не зависит от локали и часового пояса" \
                    || no "при LC_ALL=C / чужом TZ результат другой"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ] && [ "${URC}" -eq 0 ]
