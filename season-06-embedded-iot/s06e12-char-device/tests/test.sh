#!/usr/bin/env bash
#
# s06e12 «Символьное устройство» — тест (Type D, финал сезона).
#
# Та же двухуровневая схема, что в s06e11:
#   1. shadow_view.c и shadow_ring.c собираются обычным gcc вместе с
#      tests/unit_view.c — проверяется то, из-за чего драйверы ведут себя
#      странно: частичное чтение, позиция, признак конца файла;
#   2. shadow_dev.c разбирается структурно: требования из
#      data/dev_rules.txt, запреты из data/forbidden.txt, а симметрия
#      «взял — отдал» — из data/pairs.txt.
#
# Сборка .ko, загрузка и чтение /dev/shadow0 — в tests/integration.sh
# (make test-integration).
#
# Выбор каталога: SUBJECT_DIR=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"

if   [ -n "${SUBJECT_DIR:-}" ];                       then SD="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/shadow_view.c" ];  then SD="${SERIES_DIR}/artifacts"
elif [ -f "${SERIES_DIR}/shadow_view.c" ];            then SD="${SERIES_DIR}"
else SD="${SERIES_DIR}/solution"
     echo "ℹ️  Своего shadow_view.c не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/* artifacts/"; echo ""
fi
VIEW="${SD}/shadow_view.c"; DEV="${SD}/shadow_dev.c"; RING="${SD}/shadow_ring.c"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e12 tests — устройство: ${SD#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${D}/dev_rules.txt" "${D}/forbidden.txt" "${D}/pairs.txt" "${SERIES_DIR}/tests/unit_view.c"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done

CC="${CC:-$(command -v gcc || command -v cc || true)}"
if [ -z "${CC}" ]; then
    echo "  FAIL: не найден компилятор C (gcc или cc)"
    echo " Итог: 0 passed, 1 failed"; exit 1
fi
ok "компилятор C найден (${CC##*/})"

for f in "${VIEW}" "${DEV}" "${RING}"; do
    [ -f "${f}" ] && ok "$(basename "${f}") найден" || no "нет $(basename "${f}")"
done
[ -f "${VIEW}" ] && [ -f "${DEV}" ] && [ -f "${RING}" ] || { echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── 1. Логика собирается без ядра ────────────────────────────────────
echo ""
echo "── 1. Сборка логики обычным компилятором ──"
if grep -qE '#include[[:space:]]*<linux/' "${VIEW}"; then
    no "shadow_view.c подключает заголовки ядра — его нельзя проверить без ядра"
else ok "shadow_view.c не зависит от заголовков ядра"; fi

if "${CC}" -std=c99 -Wall -Wextra -Werror -O1 -I"${SD}" -I"${SERIES_DIR}/tests" \
       -o "${TMP}/unit_view" "${RING}" "${VIEW}" "${SERIES_DIR}/tests/unit_view.c" \
       >"${TMP}/build.log" 2>&1
then ok "собралось без предупреждений (-Wall -Wextra -Werror)"
else no "не собралось:"; sed 's/^/        /' "${TMP}/build.log" | head -20
     echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

# ── 2. Юнит-тесты ────────────────────────────────────────────────────
echo ""
UNIT_OUT="$("${TMP}/unit_view" 2>&1)"; URC=$?
while IFS= read -r line; do
    case "${line}" in
        "  PASS: "*) ok "${line#  PASS: }" ;;
        "  FAIL: "*) no "${line#  FAIL: }" ;;
        *) echo "${line}" ;;
    esac
done <<< "${UNIT_OUT}"

# ── 3. Драйвер: структура ────────────────────────────────────────────
echo ""
echo "── 3. Драйвер ──"
# убираем строки-комментарии, но НЕ строки вида «*ppos += n»:
# продолжение блочного комментария — это «*» и пробел или «*/»
DEVSRC="$(grep -vE '^[[:space:]]*\*([[:space:]]|/|$)' "${DEV}" | grep -v '^[[:space:]]*//' | grep -v '^[[:space:]]*/\*')"

while IFS=$'\t' read -r id re why; do
    case "${id}" in ''|\#*) continue ;; esac
    if grep -qE "${re}" <<<"${DEVSRC}"; then ok "${id}: ${why}"
    else no "${id}: не найдено — ${why}"; fi
done < "${D}/dev_rules.txt"

echo ""
echo "── 4. Чего быть не должно ──"
while IFS=$'\t' read -r id re why; do
    case "${id}" in ''|\#*) continue ;; esac
    if grep -qE "${re}" <<<"${DEVSRC}"; then no "${id}: найдено — ${why}"
    else ok "${id}: отсутствует (${why})"; fi
done < "${D}/forbidden.txt"

# ── 5. Симметрия «взял — отдал» ──────────────────────────────────────
echo ""
echo "── 5. Что взял — отдай ──"
PAIRS_SEEN=0
while IFS=$'\t' read -r take give what; do
    case "${take}" in ''|\#*) continue ;; esac
    if grep -qE "\b${take}[[:space:]]*\(" <<<"${DEVSRC}"; then
        PAIRS_SEEN=$((PAIRS_SEEN+1))
        if grep -qE "\b${give}[[:space:]]*\(" <<<"${DEVSRC}"
        then ok "${take} -> ${give} (${what})"
        else no "${take}() без ${give}(): ${what} останется занят до перезагрузки"; fi
    fi
done < "${D}/pairs.txt"
[ "${PAIRS_SEEN}" -ge 4 ] && ok "устройство действительно регистрируется (${PAIRS_SEEN} пар ресурсов)" \
    || no "найдено всего ${PAIRS_SEEN} пар — символьное устройство не зарегистрировано"

# каждая метка отката должна освобождать что-то
NLABELS="$(grep -cE '^err_[a-z_]+:' <<<"${DEVSRC}")"
NGOTO="$(grep -cE 'goto[[:space:]]+err_' <<<"${DEVSRC}")"
if [ "${NLABELS}" -ge 3 ] && [ "${NGOTO}" -ge 3 ]
then ok "лестница отката: ${NLABELS} меток, ${NGOTO} переходов"
else no "лестницы отката нет (${NLABELS} меток, ${NGOTO} переходов) — частичная инициализация не откатывается"; fi

# блокировка снимается на всех путях выхода из чтения
READ_BODY="$(awk '/shadow_read[[:space:]]*\(/,/^}/' <<<"${DEVSRC}")"
# считаем только возвраты ПОСЛЕ взятия блокировки: до неё снимать нечего
AFTER_LOCK="$(awk '/(mutex_lock|spin_lock)/{f=1} f' <<<"${READ_BODY}")"
# возврат по неудачному взятию блокировки не считаем: держать нечего
NRET="$(grep -E '^[[:space:]]*return' <<<"${AFTER_LOCK}" | grep -cv 'ERESTARTSYS')"
NUNLOCK="$(grep -cE '(mutex_unlock|spin_unlock)' <<<"${AFTER_LOCK}")"
if [ "${NRET}" -gt 0 ] && [ "${NUNLOCK}" -ge "${NRET}" ]
then ok "блокировка снимается на каждом выходе из чтения (${NUNLOCK} на ${NRET} возвратов)"
else no "выходов из shadow_read ${NRET}, снятий блокировки ${NUNLOCK} — где-то она останется взятой"; fi

# арифметика не продублирована в драйвере
if grep -qE 'len[[:space:]]*-[[:space:]]*\*?ppos|count[[:space:]]*>[[:space:]]*len' <<<"${DEVSRC}"
then no "подсчёт отдаваемых байт продублирован в драйвере — он должен жить в shadow_copy_slice"
else ok "подсчёт отдаваемых байт не продублирован"; fi

# ── 6. Сборка ────────────────────────────────────────────────────────
echo ""
echo "── 6. Сборка ──"
MK="${SD}/Makefile"
if [ -f "${MK}" ]; then
    ok "Makefile на месте"
    grep -qE '^obj-m' "${MK}" && ok "цель kbuild объявлена" || no "нет obj-m"
    grep -qE 'shadow_view\.o' "${MK}" && ok "представление входит в модуль" || no "shadow_view.o не включён"
    grep -qE 'shadow_ring\.o' "${MK}" && ok "кольцо входит в модуль" || no "shadow_ring.o не включён"
else no "нет Makefile"; fi
[ -f "${SERIES_DIR}/tests/integration.sh" ] \
    && ok "интеграционный тест объявлен (make test-integration)" \
    || no "нет tests/integration.sh"

echo ""
echo "── 7. Повторяемость ──"
A="$("${TMP}/unit_view" 2>&1 | tail -1)"
B="$(LC_ALL=C TZ=Asia/Tokyo "${TMP}/unit_view" 2>&1 | tail -1)"
[ "${A}" = "${B}" ] && ok "результат не зависит от локали и часового пояса" \
                    || no "при LC_ALL=C / чужом TZ результат другой"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ] && [ "${URC}" -eq 0 ]
