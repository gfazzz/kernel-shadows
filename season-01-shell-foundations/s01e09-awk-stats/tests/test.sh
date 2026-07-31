#!/usr/bin/env bash
#
# s01e09 «Кто атакует чаще всех» — воспроизводимый unit-тест (без root, без сети).
# Работает над фикстурой-логом. Проверяет awk-извлечение + sort|uniq -c|sort -rn.
#
# Выбор артефакта: SUBJECT=... | <серия>/top_attackers.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                           then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/top_attackers.sh" ];         then SCRIPT="${SERIES_DIR}/top_attackers.sh"
elif [ -f "${SERIES_DIR}/artifacts/top_attackers.sh" ];then SCRIPT="${SERIES_DIR}/artifacts/top_attackers.sh"
else SCRIPT="${SERIES_DIR}/solution/top_attackers.sh"
     echo "ℹ️  Свой top_attackers.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/top_attackers.sh ./top_attackers.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e09 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e09)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Фикстура: 66.66.66.66 ×5 (главный атакующий), 77.77.77.77 ×3, 10.0.0.5 ×1, 10.0.0.6 ×1.
LOG="${TEST_ROOT}/access.log"
{
  for i in 1 2 3 4 5; do echo "66.66.66.66 - - [t] \"GET /admin HTTP/1.1\" 403 0"; done
  for i in 1 2 3;     do echo "77.77.77.77 - - [t] \"GET /login HTTP/1.1\" 401 0"; done
  echo '10.0.0.5 - - [t] "GET /index HTTP/1.1" 200 512'
  echo '10.0.0.6 - - [t] "GET /about HTTP/1.1" 200 634'
} > "${LOG}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "top_attackers.sh найден" || no "top_attackers.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${LOG}" 3 2>/dev/null)" || true

# TEST 4: главный атакующий с верным счётом (5 66.66.66.66)
printf '%s' "${OUT}" | grep -qE '(^| )5 +66\.66\.66\.66' && ok "66.66.66.66 посчитан 5 раз" || no "неверный счёт для 66.66.66.66"
# TEST 5: 77.77.77.77 посчитан 3 раза
printf '%s' "${OUT}" | grep -qE '(^| )3 +77\.77\.77\.77' && ok "77.77.77.77 посчитан 3 раза" || no "неверный счёт для 77.77.77.77"
# TEST 6: ранжирование — первая строка данных = самый активный (66.66.66.66)
first_data="$(printf '%s\n' "${OUT}" | grep -E '[0-9]+ +[0-9.]+' | head -1)"
printf '%s' "${first_data}" | grep -q '66\.66\.66\.66' && ok "топ-1 = самый активный IP (sort -rn)" || no "рейтинг не по убыванию (нет sort -rn?)"
# TEST 7: head ограничивает вывод N=3 строками данных
lines="$(printf '%s\n' "${OUT}" | grep -cE '[0-9]+ +[0-9.]+')"
[ "${lines}" -le 3 ] && ok "head -n ограничивает топ (<=3 строк)" || no "не ограничен топ (head?)"
# TEST 8: отсутствующий файл → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope.log" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
