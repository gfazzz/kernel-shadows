#!/usr/bin/env bash
#
# s01e03 «Дойти и прочитать» — воспроизводимый unit-тест (fixture/TEST_ROOT, без root).
# Проверяет, что артефакт студента переходит в директорию (cd) и читает (cat)
# файл из поддиректории и два скрытых файла. Живой хост не затрагивается.
#
# Выбор артефакта: SUBJECT=... | <серия>/read_briefing.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                             then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/read_briefing.sh" ];           then SCRIPT="${SERIES_DIR}/read_briefing.sh"
elif [ -f "${SERIES_DIR}/artifacts/read_briefing.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/read_briefing.sh"
else SCRIPT="${SERIES_DIR}/solution/read_briefing.sh"
     echo "ℹ️  Свой read_briefing.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/read_briefing.sh ./read_briefing.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e03 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# Фикстура: "сервер" с поддиректорией и скрытыми файлами, уникальные маркеры.
TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e03)"
trap 'rm -rf "${TEST_ROOT}"' EXIT
SRV="${TEST_ROOT}/server"
mkdir -p "${SRV}/documents"
echo "BRIEFING-MARKER-8842 Viktor Petrov" > "${SRV}/documents/briefing.txt"
echo "SECRET-GUM-14:00"                   > "${SRV}/.secret_location"
echo "NEXT-185.192.47.203:2222"           > "${SRV}/.next_server"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "read_briefing.sh найден" || no "read_briefing.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

# Прогон: запускаем из ПОСТОРОННЕЙ директории, передав путь к серверу.
# Так проверяем, что скрипт реально навигирует, а не полагается на CWD теста.
OUT="$(cd "${TEST_ROOT}" && bash "${SCRIPT}" "${SRV}" 2>/dev/null)" || true

# TEST 4: прочитал briefing из ПОДдиректории (значит, дошёл и прочитал)
printf '%s' "${OUT}" | grep -qF "BRIEFING-MARKER-8842" && ok "прочитал documents/briefing.txt" || no "не прочитал documents/briefing.txt"
# TEST 5-6: прочитал оба скрытых файла
printf '%s' "${OUT}" | grep -qF "SECRET-GUM-14:00"     && ok "прочитал .secret_location" || no "не прочитал .secret_location"
printf '%s' "${OUT}" | grep -qF "NEXT-185.192.47.203"  && ok "прочитал .next_server"     || no "не прочитал .next_server"

# TEST 7: сообщил, где находится (использовал pwd после навигации)
printf '%s' "${OUT}" | grep -qF "${SRV}" && ok "печатает текущий путь после cd" || no "не печатает путь (использована ли навигация?)"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
