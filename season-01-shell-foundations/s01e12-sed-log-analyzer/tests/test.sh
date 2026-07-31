#!/usr/bin/env bash
#
# s01e12 «Отчёт по атаке» (капстоун ep03) — воспроизводимый unit-тест (без root, без сети).
# Работает над фикстурой-логом + база угроз. Проверяет Type B-отчёт: статистика,
# TOP-IP, распределение статусов, sed-очистку таймстампа, сверку с базой угроз.
#
# Выбор артефакта: SUBJECT=... | <серия>/log_analyzer.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                          then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/log_analyzer.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/log_analyzer.sh"
elif [ -f "${SERIES_DIR}/log_analyzer.sh" ];         then SCRIPT="${SERIES_DIR}/log_analyzer.sh"
else SCRIPT="${SERIES_DIR}/solution/log_analyzer.sh"
     echo "ℹ️  Свой log_analyzer.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/log_analyzer.sh artifacts/log_analyzer.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e12 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e12)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Фикстура. Ловушки:
#   - 10.0.0.50 в журнале при 10.0.0.5 в базе угроз (совпадение по подстроке даст ложный FOUND);
#   - 1.2.3.4 в базе, но НЕ в журнале (отчёт не должен его упоминать);
#   - комментарий и пустая строка в базе.
LOG="${TEST_ROOT}/access.log"
cat > "${LOG}" <<'EOF'
10.0.0.50 - - [04/Oct/2025:03:40:01 +0000] "GET /index HTTP/1.1" 200 512
10.0.0.6 - - [04/Oct/2025:03:41:02 +0000] "GET /about HTTP/1.1" 200 634
66.66.66.66 - - [04/Oct/2025:03:47:23 +0000] "GET /admin HTTP/1.1" 403 0
66.66.66.66 - - [04/Oct/2025:03:47:24 +0000] "POST /login HTTP/1.1" 401 0
66.66.66.66 - - [04/Oct/2025:03:47:25 +0000] "GET /wp-admin HTTP/1.1" 404 0
66.66.66.66 - - [04/Oct/2025:03:47:26 +0000] "GET /shell HTTP/1.1" 500 0
45.155.205.67 - - [04/Oct/2025:03:47:30 +0000] "GET /../etc/passwd HTTP/1.1" 404 0
45.155.205.67 - - [04/Oct/2025:03:48:00 +0000] "GET /admin HTTP/1.1" 403 0
10.0.0.7 - - [04/Oct/2025:03:50:00 +0000] "GET /home HTTP/1.1" 200 800
10.0.0.8 - - [04/Oct/2025:03:59:59 +0000] "GET /contact HTTP/1.1" 200 400
EOF

THREATS="${TEST_ROOT}/suspicious_ips.txt"
cat > "${THREATS}" <<'EOF'
# известные угрозы

66.66.66.66
45.155.205.67
10.0.0.5
1.2.3.4
EOF

REPORT="${TEST_ROOT}/report.txt"

# Ожидания ВЫЧИСЛЯЮТСЯ по фикстуре, а не записаны константами.
EXP_TOTAL="$(wc -l < "${LOG}" | tr -d ' ')"
EXP_UNIQ="$(awk '{print $1}' "${LOG}" | sort -u | wc -l | tr -d ' ')"
EXP_TOP="$(awk '{print $1}' "${LOG}" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
EXP_TOP_N="$(awk '{print $1}' "${LOG}" | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')"
EXP_FIRST_TS="$(awk '{print $4}' "${LOG}" | head -1 | tr -d '[]')"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "log_analyzer.sh найден" || no "log_analyzer.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${LOG}" "${THREATS}" "${REPORT}" 2>/dev/null)" || true
RC="$(cat "${REPORT}" 2>/dev/null || true)"

# TEST 4: отчёт создан
[ -f "${REPORT}" ] && ok "отчёт создан" || no "отчёт не создан"

# TEST 5: всего запросов
printf '%s' "${RC}" | grep -qE "Всего запросов:[[:space:]]*${EXP_TOTAL}([^0-9]|$)" \
    && ok "всего запросов = ${EXP_TOTAL}" || no "неверное «всего запросов» (ожидалось ${EXP_TOTAL})"

# TEST 6: уникальных адресов
printf '%s' "${RC}" | grep -qE "Уникальных IP:[[:space:]]*${EXP_UNIQ}([^0-9]|$)" \
    && ok "уникальных IP = ${EXP_UNIQ}" || no "неверное число уникальных IP (ожидалось ${EXP_UNIQ})"

# TEST 7: топ адресов
printf '%s' "${RC}" | grep -qE "(^|[[:space:]])${EXP_TOP_N}[[:space:]]+${EXP_TOP//./\\.}([^0-9]|$)" \
    && ok "TOP: ${EXP_TOP} = ${EXP_TOP_N}" || no "неверный TOP-IP или счёт (ожидалось ${EXP_TOP_N} ${EXP_TOP})"

# TEST 8: распределение статусов
printf '%s' "${RC}" | grep -qE '[0-9]+ +200' && ok "есть распределение HTTP-статусов" || no "нет распределения статусов"

# TEST 9: sed очистил скобки у времени первой записи
ts_line="$(printf '%s\n' "${RC}" | grep -m1 'Первый запрос')"
if printf '%s' "${ts_line}" | grep -q '[][]'; then
    no "время не очищено sed (остались скобки)"
elif printf '%s' "${ts_line}" | grep -qF "${EXP_FIRST_TS}"; then
    ok "sed очистил скобки, время первой записи верное"
else
    no "время первой записи не совпадает с журналом (ожидалось ${EXP_FIRST_TS})"
fi

# TEST 10: найденные угрозы помечены FOUND
printf '%s' "${RC}" | grep -q "FOUND: 66.66.66.66" && printf '%s' "${RC}" | grep -q "FOUND: 45.155.205.67" \
    && ok "найденные угрозы помечены FOUND" || no "не отмечены угрозы, реально присутствующие в журнале"

# TEST 11: угроза, которой нет в журнале, в отчёт не попадает
printf '%s' "${RC}" | grep -q '1\.2\.3\.4' \
    && no "в отчёт попал адрес 1.2.3.4, которого нет в журнале" \
    || ok "отсутствующие в журнале угрозы пропущены"

# TEST 12: ловушка-префикс — 10.0.0.5 из базы не должен «найтись» внутри 10.0.0.50
printf '%s' "${RC}" | grep -qE 'FOUND:[[:space:]]*10\.0\.0\.5([^0-9]|$)' \
    && no "ложный FOUND: 10.0.0.5 совпал по подстроке с 10.0.0.50 (нужен grep -w)" \
    || ok "совпадение по подстроке не принято за адрес"

# TEST 13: комментарии и пустые строки базы не считаются адресами
printf '%s' "${RC}" | grep -qE 'FOUND:[[:space:]]*(#|$)' \
    && no "комментарий или пустая строка базы обработаны как адрес" \
    || ok "комментарии и пустые строки базы пропущены"

# TEST 14: отсутствующий журнал → ненулевой код возврата
bash "${SCRIPT}" "${TEST_ROOT}/nope.log" "${THREATS}" "${TEST_ROOT}/r2.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет журнала → ненулевой exit" || no "не обработан отсутствующий журнал"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
