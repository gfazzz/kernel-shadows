#!/usr/bin/env bash
#
# s01e08 «Проверить все серверы» — воспроизводимый unit-тест (без root, БЕЗ живой сети).
# Мокает ping (up-* достижимы). Проверяет цикл по файлу + условия + подсчёт.
#
# Выбор артефакта: SUBJECT=... | <серия>/check_all.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                       then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/check_all.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/check_all.sh"
elif [ -f "${SERIES_DIR}/check_all.sh" ];         then SCRIPT="${SERIES_DIR}/check_all.sh"
else SCRIPT="${SERIES_DIR}/solution/check_all.sh"
     echo "ℹ️  Свой check_all.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/check_all.sh artifacts/check_all.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e08 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e08)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# мок ping
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/ping" <<'MOCK'
#!/usr/bin/env bash
host="${!#}"
case "${host}" in up-*) exit 0 ;; *) exit 1 ;; esac
MOCK
chmod +x "${FAKEBIN}/ping"

# фикстура: список из 3 up + 2 down, плюс комментарий и пустая строка
LIST="${TEST_ROOT}/servers.txt"
cat > "${LIST}" <<EOF
# список серверов операции
up-server-01 10.0.0.1
up-server-02 10.0.0.2

down-server-01 10.0.0.9
up-server-03 10.0.0.3
down-server-02 10.0.0.8
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "check_all.sh найден" || no "check_all.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" 2>/dev/null)" || true

# TEST 4: итог UP=3
printf '%s' "${OUT}" | grep -qE "UP=3" && ok "посчитал UP=3" || no "неверный счёт UP (ожидалось 3)"
# TEST 5: итог DOWN=2
printf '%s' "${OUT}" | grep -qE "DOWN=2" && ok "посчитал DOWN=2" || no "неверный счёт DOWN (ожидалось 2)"
# TEST 6: конкретный up-хост помечен UP
printf '%s' "${OUT}" | grep -qE "UP.*up-server-02|up-server-02.*UP" && ok "up-server-02 → UP" || no "up-server-02 не UP"
# TEST 7: конкретный down-хост помечен DOWN
printf '%s' "${OUT}" | grep -qE "DOWN.*down-server-01|down-server-01.*DOWN" && ok "down-server-01 → DOWN" || no "down-server-01 не DOWN"
# TEST 8: комментарий не попал в обработку как хост
printf '%s' "${OUT}" | grep -q "список серверов" && no "строка-комментарий обработана как хост" || ok "комментарии/пустые строки пропущены"
# TEST 9: несуществующий файл → ненулевой выход
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "несуществующий файл → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
