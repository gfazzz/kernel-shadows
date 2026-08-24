#!/usr/bin/env bash
#
# s01e01 «Terminal Awakening» — воспроизводимый unit-тест.
#
# Философия теста:
#   - Работает над ФИКСТУРАМИ во временном TEST_ROOT, а не над живым хостом.
#   - Зелёный БЕЗ root, без systemd/Docker/сети. Идёт на Linux/macOS/WSL.
#   - Проверяет ПОВЕДЕНИЕ артефакта студента (исполняет его), а не grep по
#     поставляемым файлам курса.
#
# Что проверяется: артефакт студента whereami.sh корректно сообщает,
# где он находится (использует pwd) и печатает $HOME.
#
# Выбор проверяемого файла (в порядке приоритета):
#   1. переменная окружения SUBJECT=/path/to/whereami.sh
#   2. <корень серии>/whereami.sh          (твоё решение)
#   3. <корень серии>/artifacts/whereami.sh
#   4. <корень серии>/solution/whereami.sh (эталон — фолбэк, чтобы харнесс
#      был зелёным «из коробки»; тогда печатается подсказка создать своё)

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# ---- выбор артефакта -------------------------------------------------------
if [ -n "${SUBJECT:-}" ]; then
    SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/whereami.sh" ]; then
    SCRIPT="${SERIES_DIR}/artifacts/whereami.sh"
elif [ -f "${SERIES_DIR}/whereami.sh" ]; then
    SCRIPT="${SERIES_DIR}/whereami.sh"
else
    SCRIPT="${SERIES_DIR}/solution/whereami.sh"
    echo "ℹ️  Свой whereami.sh не найден — проверяю ЭТАЛОН (solution/)."
    echo "   Создай своё решение:  cp starter/whereami.sh artifacts/whereami.sh"
    echo ""
fi

# ---- мини-харнесс ----------------------------------------------------------
PASS=0
FAIL=0
ok()   { echo "  PASS: $1"; PASS=$((PASS+1)); }
no()   { echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e01 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- фикстура: изолированный TEST_ROOT -------------------------------------
TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e01)"
trap 'rm -rf "${TEST_ROOT}"' EXIT
KNOWN="${TEST_ROOT}/home/max/ops/deep/place"
FAKE_HOME="${TEST_ROOT}/home/max"
mkdir -p "${KNOWN}"

# ---- TEST 1: артефакт существует ------------------------------------------
if [ -f "${SCRIPT}" ]; then ok "whereami.sh найден"; else no "whereami.sh не найден"; fi

# ---- TEST 2: валидный синтаксис bash --------------------------------------
if bash -n "${SCRIPT}" 2>/dev/null; then ok "синтаксис bash корректен"; else no "ошибка синтаксиса (bash -n)"; fi

# ---- TEST 3: shebang -------------------------------------------------------
if head -1 "${SCRIPT}" | grep -q '^#!.*sh'; then ok "есть shebang"; else no "нет shebang (#!/usr/bin/env bash)"; fi

# ---- прогон в фикстуре: запускаем из KNOWN с поддельным HOME ---------------
OUT="$(cd "${KNOWN}" && HOME="${FAKE_HOME}" bash "${SCRIPT}" 2>/dev/null)" || true

# ---- TEST 4: печатает текущий путь (значит, реально использует pwd) --------
if printf '%s' "${OUT}" | grep -qF "${KNOWN}"; then
    ok "выводит текущий путь (использует pwd)"
else
    no "в выводе нет текущего пути ${KNOWN} (скрипт должен печатать pwd)"
fi

# ---- TEST 5: печатает домашнюю директорию ---------------------------------
if printf '%s' "${OUT}" | grep -qF "${FAKE_HOME}"; then
    ok "выводит домашнюю директорию (\$HOME)"
else
    no "в выводе нет \$HOME (${FAKE_HOME})"
fi

# ---- TEST 6: не «хардкодит» путь — из другого места печатает другое --------
OTHER="${TEST_ROOT}/var/tmp/here"
mkdir -p "${OTHER}"
OUT2="$(cd "${OTHER}" && HOME="${FAKE_HOME}" bash "${SCRIPT}" 2>/dev/null)" || true
if printf '%s' "${OUT2}" | grep -qF "${OTHER}" && ! printf '%s' "${OUT2}" | grep -qF "${KNOWN}"; then
    ok "путь не захардкожен (из другого места — другой вывод)"
else
    no "похоже, путь захардкожен: вывод не меняется при смене директории"
fi

# ---- итог ------------------------------------------------------------------
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
