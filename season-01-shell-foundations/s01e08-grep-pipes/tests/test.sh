#!/usr/bin/env bash
#
# s01e08 «Фильтрация логов атаки» — воспроизводимый unit-тест (без root, без сети).
# Работает над фикстурой-логом. Проверяет grep-фильтр (не-200) + подсчёт.
#
# Выбор артефакта: SUBJECT=... | <серия>/filter_attack.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                          then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/filter_attack.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/filter_attack.sh"
elif [ -f "${SERIES_DIR}/filter_attack.sh" ];        then SCRIPT="${SERIES_DIR}/filter_attack.sh"
else SCRIPT="${SERIES_DIR}/solution/filter_attack.sh"
     echo "ℹ️  Свой filter_attack.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/filter_attack.sh artifacts/filter_attack.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e08 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e08)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Фикстура: access.log (Apache Combined). 3 нормальных (200) + 4 атакующих (не-200).
LOG="${TEST_ROOT}/access.log"
cat > "${LOG}" <<'EOF'
10.0.0.5 - - [04/Oct/2025:03:40:01 +0000] "GET /index.html HTTP/1.1" 200 512 NORMAL-A
10.0.0.6 - - [04/Oct/2025:03:41:02 +0000] "GET /about HTTP/1.1" 200 634 NORMAL-B
66.66.66.66 - - [04/Oct/2025:03:47:23 +0000] "GET /admin HTTP/1.1" 403 0 ATTACK-A
66.66.66.66 - - [04/Oct/2025:03:47:24 +0000] "POST /login HTTP/1.1" 401 0 ATTACK-B
77.77.77.77 - - [04/Oct/2025:03:47:25 +0000] "GET /../../etc/passwd HTTP/1.1" 404 0 ATTACK-C
99.99.99.99 - - [04/Oct/2025:03:47:26 +0000] "GET /wp-admin HTTP/1.1" 500 0 ATTACK-D
10.0.0.7 - - [04/Oct/2025:03:50:00 +0000] "GET /home HTTP/1.1" 200 800 NORMAL-C
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "filter_attack.sh найден" || no "filter_attack.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${LOG}" 2>/dev/null)" || true

# TEST 4: атакующие строки попали в вывод
printf '%s' "${OUT}" | grep -q "ATTACK-A" && printf '%s' "${OUT}" | grep -q "ATTACK-D" \
    && ok "выделяет подозрительные (ATTACK-*)" || no "не выделяет подозрительные строки"
# TEST 5: нормальная 200-строка НЕ попала (значит, реально фильтрует)
printf '%s' "${OUT}" | grep -q "NORMAL-A" && no "нормальный 200-запрос просочился (фильтр не работает)" || ok "нормальные 200-запросы отфильтрованы"
# TEST 6: подсчёт = 4
printf '%s' "${OUT}" | grep -qE "Подозрительных запросов: 4" && ok "посчитал 4 подозрительных" || no "неверный счёт (ожидалось 4)"
# TEST 7: отсутствующий файл → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope.log" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
