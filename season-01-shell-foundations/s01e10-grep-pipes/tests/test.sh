#!/usr/bin/env bash
#
# s01e10 «Фильтрация логов атаки» — воспроизводимый unit-тест (без root, без сети).
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
echo " s01e10 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e10)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Фикстура: access.log (Apache Combined). Нормальные (200) + атакующие (не-200)
# + ЛОВУШКИ: размер ответа 1200 и адрес 10.0.200.5 — их нельзя принять за статус 200.
LOG="${TEST_ROOT}/access.log"
cat > "${LOG}" <<'EOF'
10.0.0.5 - - [05/Oct/2025:03:40:01 +0000] "GET /index.html HTTP/1.1" 200 512 NORMAL-A
10.0.0.6 - - [05/Oct/2025:03:41:02 +0000] "GET /about HTTP/1.1" 200 634 NORMAL-B
66.66.66.66 - - [05/Oct/2025:03:47:23 +0000] "GET /admin HTTP/1.1" 403 0 ATTACK-A
66.66.66.66 - - [05/Oct/2025:03:47:24 +0000] "POST /login HTTP/1.1" 401 0 ATTACK-B
77.77.77.77 - - [05/Oct/2025:03:47:25 +0000] "GET /../../etc/passwd HTTP/1.1" 404 0 ATTACK-C
99.99.99.99 - - [05/Oct/2025:03:47:26 +0000] "GET /wp-admin HTTP/1.1" 500 0 ATTACK-D
88.88.88.88 - - [05/Oct/2025:03:47:27 +0000] "GET /backup.zip HTTP/1.1" 403 1200 ATTACK-E
10.0.200.5 - - [05/Oct/2025:03:47:28 +0000] "GET /phpmyadmin HTTP/1.1" 404 0 ATTACK-F
10.0.0.7 - - [05/Oct/2025:03:50:00 +0000] "GET /home HTTP/1.1" 200 800 NORMAL-C
EOF

# Ожидания ВЫЧИСЛЯЮТСЯ по фикстуре: правка фикстуры не разъезжается с тестом.
EXP_BAD="$(grep -c 'ATTACK-' "${LOG}")"

# Пустой журнал (только нормальные запросы) — для проверки «ноль тоже результат».
CLEAN="${TEST_ROOT}/clean.log"
grep 'NORMAL-' "${LOG}" > "${CLEAN}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "filter_attack.sh найден" || no "filter_attack.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${LOG}" 2>/dev/null)" || true

# TEST 4: все атакующие строки попали в вывод
missing=""
for m in $(grep -oE 'ATTACK-[A-Z]' "${LOG}"); do
    printf '%s' "${OUT}" | grep -q "${m}" || missing="${missing} ${m}"
done
[ -z "${missing}" ] && ok "выделены все подозрительные строки" \
    || no "не выделены подозрительные:${missing}"

# TEST 5: нормальные 200-строки НЕ попали (значит, фильтр действительно фильтрует)
printf '%s' "${OUT}" | grep -q "NORMAL-" \
    && no "нормальный 200-запрос просочился (фильтр не работает)" \
    || ok "нормальные 200-запросы отфильтрованы"

# TEST 6: ловушки — «200» внутри размера 1200 и внутри адреса 10.0.200.5
if printf '%s' "${OUT}" | grep -q "ATTACK-E" && printf '%s' "${OUT}" | grep -q "ATTACK-F"; then
    ok "шаблон не путает 200 в размере/адресе со статусом"
else
    no "потеряны строки с '1200' или '10.0.200.5' — шаблон без пробелов вокруг 200"
fi

# TEST 7: подсчёт совпадает с числом атакующих строк в фикстуре
printf '%s' "${OUT}" | grep -qE "Подозрительных запросов: ${EXP_BAD}([^0-9]|$)" \
    && ok "посчитал ${EXP_BAD} подозрительных" \
    || no "неверный счёт (по фикстуре ожидалось ${EXP_BAD})"

# TEST 8: журнал без атак → ноль, а не молчание, и код возврата 0
CLEAN_OUT="$(bash "${SCRIPT}" "${CLEAN}" 2>/dev/null)"; clean_rc=$?
if [ "${clean_rc}" -eq 0 ] && printf '%s' "${CLEAN_OUT}" | grep -qE "Подозрительных запросов: 0([^0-9]|$)"; then
    ok "чистый журнал → 0 и код 0"
else
    no "чистый журнал: ожидались «Подозрительных запросов: 0» и код 0 (получен ${clean_rc})"
fi

# TEST 9: чистый журнал не должен показывать нормальные запросы как подозрительные
printf '%s' "${CLEAN_OUT}" | grep -q "NORMAL-" \
    && no "на чистом журнале выведены нормальные запросы" \
    || ok "на чистом журнале подозрительных строк нет"

# TEST 10: отсутствующий файл → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope.log" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
