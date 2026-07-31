#!/usr/bin/env bash
#
# s01e11 «Отчёт по атаке» (капстоун ep03) — воспроизводимый unit-тест (без root, без сети).
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
echo " s01e11 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e11)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Фикстура: 10 строк. 66.66.66.66 ×4 (в т.ч. атака), 45.155.205.67 ×2, прочие.
LOG="${TEST_ROOT}/access.log"
cat > "${LOG}" <<'EOF'
10.0.0.5 - - [04/Oct/2025:03:40:01 +0000] "GET /index HTTP/1.1" 200 512
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
1.2.3.4
EOF

REPORT="${TEST_ROOT}/report.txt"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "log_analyzer.sh найден" || no "log_analyzer.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${LOG}" "${THREATS}" "${REPORT}" 2>/dev/null)" || true
RC="$(cat "${REPORT}" 2>/dev/null || true)"

# TEST 4: отчёт создан
[ -f "${REPORT}" ] && ok "отчёт создан" || no "отчёт не создан"
# TEST 5: всего запросов = 10
printf '%s' "${RC}" | grep -qE "Всего запросов:[[:space:]]*10" && ok "посчитал всего запросов = 10" || no "неверное 'всего запросов'"
# TEST 6: уникальных IP = 6 (10.0.0.5/6/7/8, 66.66.66.66, 45.155.205.67)
printf '%s' "${RC}" | grep -qE "Уникальных IP:[[:space:]]*6" && ok "уникальных IP = 6" || no "неверное число уникальных IP"
# TEST 7: TOP-IP — 66.66.66.66 c 4 запросами
printf '%s' "${RC}" | grep -qE '(^| )4 +66\.66\.66\.66' && ok "TOP: 66.66.66.66 = 4" || no "неверный TOP-IP/счёт"
# TEST 8: распределение статусов содержит 200
printf '%s' "${RC}" | grep -qE '[0-9]+ +200' && ok "есть распределение HTTP-статусов" || no "нет распределения статусов"
# TEST 9: sed очистил скобки таймстампа (нет '[' в строке 'Первый запрос')
ts_line="$(printf '%s\n' "${RC}" | grep 'Первый запрос')"
printf '%s' "${ts_line}" | grep -q '\[' && no "таймстамп не очищен sed (остались скобки)" || ok "sed очистил скобки таймстампа"
# TEST 10: сверка с базой угроз — FOUND 66.66.66.66, но НЕ 1.2.3.4 (его нет в логе)
printf '%s' "${RC}" | grep -q "FOUND: 66.66.66.66" && ! printf '%s' "${RC}" | grep -q "1.2.3.4" \
    && ok "сверка с базой угроз (FOUND найденные, отсутствующие пропущены)" || no "неверная сверка с базой угроз"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
