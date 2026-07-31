#!/usr/bin/env bash
#
# s01e11 «Кто атакует чаще всех» — воспроизводимый unit-тест (без root, без сети).
# Работает над фикстурой-логом. Проверяет awk-извлечение + sort|uniq -c|sort -rn.
#
# Выбор артефакта: SUBJECT=... | <серия>/top_attackers.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                           then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/top_attackers.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/top_attackers.sh"
elif [ -f "${SERIES_DIR}/top_attackers.sh" ];         then SCRIPT="${SERIES_DIR}/top_attackers.sh"
else SCRIPT="${SERIES_DIR}/solution/top_attackers.sh"
     echo "ℹ️  Свой top_attackers.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/top_attackers.sh artifacts/top_attackers.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e11 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e11)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Фикстура: строки намеренно ПЕРЕМЕШАНЫ — без `sort` перед `uniq -c`
# счёт распадётся на несколько групп на один адрес.
# Счётчики: 66.* ×10, 77.* ×9, 10.0.0.5 ×3, 10.0.0.6 ×1.
LOG="${TEST_ROOT}/access.log"
{
  for i in $(seq 1 10); do
    echo "66.66.66.66 - - [t] \"GET /admin HTTP/1.1\" 403 0"
    [ "$i" -le 9 ] && echo "77.77.77.77 - - [t] \"GET /login HTTP/1.1\" 401 0"
    [ "$i" -le 3 ] && echo "10.0.0.5 - - [t] \"GET /index HTTP/1.1\" 200 512"
  done
  echo '10.0.0.6 - - [t] "GET /about HTTP/1.1" 200 634'
} > "${LOG}"

# Ожидания ВЫЧИСЛЯЮТСЯ по фикстуре, а не записаны константами.
EXP_TOP="$(awk '{print $1}' "${LOG}" | sort | uniq -c | sort -rn | head -1 | awk '{print $2}')"
EXP_TOP_N="$(awk '{print $1}' "${LOG}" | sort | uniq -c | sort -rn | head -1 | awk '{print $1}')"
EXP_2ND="$(awk '{print $1}' "${LOG}" | sort | uniq -c | sort -rn | sed -n 2p | awk '{print $2}')"
EXP_2ND_N="$(awk '{print $1}' "${LOG}" | sort | uniq -c | sort -rn | sed -n 2p | awk '{print $1}')"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "top_attackers.sh найден" || no "top_attackers.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${LOG}" 3 2>/dev/null)" || true

# Только строки данных вида «<число> <IP>»
DATA="$(printf '%s\n' "${OUT}" | grep -E '^[[:space:]]*[0-9]+[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+[[:space:]]*$')"

# TEST 4: лидер посчитан верно
printf '%s\n' "${DATA}" | grep -qE "^[[:space:]]*${EXP_TOP_N}[[:space:]]+${EXP_TOP//./\\.}[[:space:]]*$" \
    && ok "${EXP_TOP} посчитан ${EXP_TOP_N} раз" || no "неверный счёт для ${EXP_TOP} (ожидалось ${EXP_TOP_N})"

# TEST 5: второй посчитан верно
printf '%s\n' "${DATA}" | grep -qE "^[[:space:]]*${EXP_2ND_N}[[:space:]]+${EXP_2ND//./\\.}[[:space:]]*$" \
    && ok "${EXP_2ND} посчитан ${EXP_2ND_N} раз" || no "неверный счёт для ${EXP_2ND} (ожидалось ${EXP_2ND_N})"

# TEST 6: каждый адрес встречается в рейтинге РОВНО один раз (есть sort перед uniq)
dupes="$(printf '%s\n' "${DATA}" | awk '{print $2}' | sort | uniq -d)"
[ -z "${dupes}" ] && ok "каждый адрес в рейтинге один раз (sort перед uniq)" \
    || no "адрес повторяется в рейтинге — нет sort перед uniq -c: ${dupes}"

# TEST 7: топ-1 — действительно самый активный
first="$(printf '%s\n' "${DATA}" | head -1 | awk '{print $2}')"
[ "${first}" = "${EXP_TOP}" ] && ok "топ-1 = самый активный адрес" \
    || no "топ-1 = ${first}, ожидался ${EXP_TOP}"

# TEST 8: порядок строго по убыванию числа запросов
if printf '%s\n' "${DATA}" | awk '{if (NR>1 && $1 > prev) exit 1; prev=$1}'; then
    ok "рейтинг упорядочен по убыванию"
else
    no "рейтинг не по убыванию — нужен sort -rn после uniq -c"
fi

# TEST 9: head ограничивает вывод запрошенным N
lines="$(printf '%s\n' "${DATA}" | grep -c .)"
[ "${lines}" -le 3 ] && ok "head -n ограничивает топ (<=3 строк)" || no "не ограничен топ (head?), строк: ${lines}"

# TEST 10: отсутствующий файл → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope.log" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
