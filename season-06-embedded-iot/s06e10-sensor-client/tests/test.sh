#!/usr/bin/env bash
#
# s06e10 «Клиент-датчик» — тест программы (Type D).
#
# Первая серия курса, где проверяется ПОВЕДЕНИЕ кода. Обёртка запускает
# юнит-тесты (tests/unit_sensor.py): они импортируют sensor.py как модуль
# и вызывают функции напрямую — без датчика, без сети, без ожидания.
#
# Время и случайность программа принимает снаружи; поэтому тест
# детерминирован и проходит одинаково при любом TZ и любой локали.
#
# Выбор файла: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e10 tests — клиент-датчик"
echo "════════════════════════════════════════════════════════════"

PY="$(command -v python3 || true)"
if [ -z "${PY}" ]; then
    echo "  FAIL: не найден python3 — серия Type D требует Python 3.8+"
    echo "        macOS: xcode-select --install | Debian: apt install python3"
    echo " Итог: 0 passed, 1 failed"
    exit 1
fi
ok "python3 найден ($("${PY}" -c 'import sys; print(".".join(map(str,sys.version_info[:3])))'))"

if   [ -n "${SUBJECT:-}" ];                        then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/sensor.py" ];   then S="${SERIES_DIR}/artifacts/sensor.py"
elif [ -f "${SERIES_DIR}/sensor.py" ];             then S="${SERIES_DIR}/sensor.py"
else S="${SERIES_DIR}/solution/sensor.py"
     echo "ℹ️  Своего sensor.py не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/sensor.py artifacts/"; echo ""
fi
export SUBJECT="${S}"

if [ -f "${S}" ]; then ok "sensor.py найден: ${S#"$SERIES_DIR"/}"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

if "${PY}" -m py_compile "${S}" 2>/dev/null; then ok "синтаксис Python корректен"
else no "синтаксическая ошибка:"; "${PY}" -m py_compile "${S}"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi
rm -rf "${SERIES_DIR}/__pycache__" "$(dirname "${S}")/__pycache__" 2>/dev/null

echo ""
echo "── Юнит-тесты ──"
OUT="$(cd "${SERIES_DIR}" && "${PY}" -B tests/unit_sensor.py -v 2>&1)"
RC=$?

# unittest печатает по строке на тест: «имя (класс) ... ok|FAIL|ERROR»
while IFS= read -r line; do
    case "${line}" in
        *"... ok")      ok "${line% ... ok}" ;;
        *"... FAIL"*)   no "${line%% ...*}" ;;
        *"... ERROR"*)  no "${line%% ...*} (исключение)" ;;
    esac
done <<< "${OUT}"

if [ "${RC}" -ne 0 ]; then
    echo ""
    echo "── Подробности ──"
    printf '%s\n' "${OUT}" | sed -n '/^=\{20,\}/,$p' | head -60 | sed 's/^/    /'
fi

echo ""
echo "── Повторяемость ──"
A="$(cd "${SERIES_DIR}" && "${PY}" -B tests/unit_sensor.py 2>&1 | tail -1)"
B="$(cd "${SERIES_DIR}" && LC_ALL=C TZ=Asia/Tokyo "${PY}" -B tests/unit_sensor.py 2>&1 | tail -1)"
[ "${A}" = "${B}" ] && ok "результат не зависит от локали и часового пояса" \
                    || no "при LC_ALL=C / чужом TZ результат другой: ${A} против ${B}"

rm -rf "${SERIES_DIR}/tests/__pycache__" 2>/dev/null

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
