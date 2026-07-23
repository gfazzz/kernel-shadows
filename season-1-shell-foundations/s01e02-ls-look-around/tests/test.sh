#!/usr/bin/env bash
#
# s01e02 «Осмотреться» — воспроизводимый unit-тест (fixture/TEST_ROOT, без root).
# Проверяет, что артефакт студента показывает СКРЫТЫЕ файлы (использует ls -a/-la),
# а не обычный ls. Не трогает живой хост.
#
# Выбор артефакта: SUBJECT=... | <серия>/look_around.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                         then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/look_around.sh" ];         then SCRIPT="${SERIES_DIR}/look_around.sh"
elif [ -f "${SERIES_DIR}/artifacts/look_around.sh" ];then SCRIPT="${SERIES_DIR}/artifacts/look_around.sh"
else SCRIPT="${SERIES_DIR}/solution/look_around.sh"
     echo "ℹ️  Свой look_around.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/look_around.sh ./look_around.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e02 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# Фикстура: директория с видимыми и скрытыми объектами.
TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e02)"
trap 'rm -rf "${TEST_ROOT}"' EXIT
SANDBOX="${TEST_ROOT}/server"
mkdir -p "${SANDBOX}/documents"
echo "brief" > "${SANDBOX}/briefing.txt"
echo "59.9386,30.3141" > "${SANDBOX}/.secret_location"
echo "10.0.0.42" > "${SANDBOX}/.next_server"

# TEST 1-3: файл, синтаксис, shebang
[ -f "${SCRIPT}" ] && ok "look_around.sh найден" || no "look_around.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

# Прогон на фикстуре
OUT="$(bash "${SCRIPT}" "${SANDBOX}" 2>/dev/null)" || true

# TEST 4-5: видит СКРЫТЫЕ файлы (значит, использует ls -a/-la, а не обычный ls)
printf '%s' "${OUT}" | grep -qF ".secret_location" && ok "показывает .secret_location (использует ls -a)" || no "не видит .secret_location (нужен ls -a/-la)"
printf '%s' "${OUT}" | grep -qF ".next_server"     && ok "показывает .next_server"                    || no "не видит .next_server"

# TEST 6: видит и обычный файл
printf '%s' "${OUT}" | grep -qF "briefing.txt" && ok "показывает обычные файлы (briefing.txt)" || no "не показывает обычные файлы"

# TEST 7: негатив — обычный ls (без -a) НЕ должен проходить.
#         Собираем «наивный» скрипт и убеждаемся, что тест его отвергает.
NAIVE="${TEST_ROOT}/naive.sh"
printf '#!/usr/bin/env bash\nls "%s"\n' "${SANDBOX}" > "${NAIVE}"
NAIVE_OUT="$(bash "${NAIVE}" 2>/dev/null)" || true
if printf '%s' "${NAIVE_OUT}" | grep -qF ".secret_location"; then
    no "самопроверка теста: обычный ls не должен показывать скрытое"
else
    ok "самопроверка: обычный ls скрытое не показывает (тест дискриминирует)"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
