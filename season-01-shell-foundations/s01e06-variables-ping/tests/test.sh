#!/usr/bin/env bash
#
# s01e06 «Первый умный скрипт» — воспроизводимый unit-тест (без root, БЕЗ живой сети).
#
# Принцип mock-first (§5.3): вместо реального ping в PATH подставляется мок-ping,
# который детерминированно возвращает 0 для "up-*" хостов и 1 для остальных.
# Так тест зелёный на любой машине без сети и не зависит от реальных серверов.
#
# Выбор артефакта: SUBJECT=... | <серия>/check_host.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                        then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/check_host.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/check_host.sh"
elif [ -f "${SERIES_DIR}/check_host.sh" ];         then SCRIPT="${SERIES_DIR}/check_host.sh"
else SCRIPT="${SERIES_DIR}/solution/check_host.sh"
     echo "ℹ️  Свой check_host.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/check_host.sh artifacts/check_host.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e06 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# Фикстура: мок-ping в отдельном bin, который кладём в начало PATH.
TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e06)"
trap 'rm -rf "${TEST_ROOT}"' EXIT
FAKEBIN="${TEST_ROOT}/bin"
mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/ping" <<'MOCK'
#!/usr/bin/env bash
# мок ping: последний аргумент — хост. "up-*" и 10.0.0.1 достижимы (0), иначе 1.
host="${!#}"
case "${host}" in
  up-*|10.0.0.1) exit 0 ;;
  *)            exit 1 ;;
esac
MOCK
chmod +x "${FAKEBIN}/ping"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "check_host.sh найден" || no "check_host.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

# Прогон с мок-ping в PATH.
OUT_UP="$(PATH="${FAKEBIN}:${PATH}"   bash "${SCRIPT}" up-server-01 2>/dev/null)" || true
OUT_DOWN="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" dead-server  2>/dev/null)" || true

# TEST 4: достижимый хост → UP
printf '%s' "${OUT_UP}" | grep -q "UP" && ! printf '%s' "${OUT_UP}" | grep -q "DOWN" \
    && ok "достижимый хост → STATUS UP" || no "достижимый хост не даёт UP"
# TEST 5: достижимый хост → exit code 0 в выводе
printf '%s' "${OUT_UP}" | grep -q "EXIT_CODE: 0" && ok "печатает EXIT_CODE 0 (использует \$?)" || no "нет EXIT_CODE 0"
# TEST 6: недостижимый → DOWN
printf '%s' "${OUT_DOWN}" | grep -q "DOWN" && ok "недостижимый хост → STATUS DOWN" || no "недостижимый хост не даёт DOWN"
# TEST 7: печатает имя хоста (использует переменную-аргумент)
printf '%s' "${OUT_UP}" | grep -qF "up-server-01" && ok "печатает имя хоста (аргумент \$1)" || no "не печатает имя хоста"

# TEST 8: дискриминатор — «всегда UP» не пройдёт (проверяем на нашем же тесте косвенно):
#         если DOWN-хост тоже даёт UP, скрипт не смотрит exit code.
if printf '%s' "${OUT_DOWN}" | grep -q "UP" && ! printf '%s' "${OUT_DOWN}" | grep -q "DOWN"; then
    no "скрипт всегда возвращает UP (не смотрит на exit code ping)"
else
    ok "статус зависит от результата ping (не захардкожен)"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
