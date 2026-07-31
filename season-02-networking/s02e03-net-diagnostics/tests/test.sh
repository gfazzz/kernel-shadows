#!/usr/bin/env bash
#
# s02e03 «Диагностика сети» (капстоун ep05) — воспроизводимый unit-тест (без root, БЕЗ сети).
# Мокает ping (up-* отвечают с time=..., остальные — недоступны). Проверяет
# разбор RTT, статусы и итог.
#
# Выбор артефакта: SUBJECT=... | <серия>/net_diag.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                     then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/net_diag.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/net_diag.sh"
elif [ -f "${SERIES_DIR}/net_diag.sh" ];        then SCRIPT="${SERIES_DIR}/net_diag.sh"
else SCRIPT="${SERIES_DIR}/solution/net_diag.sh"
     echo "ℹ️  Свой net_diag.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/net_diag.sh artifacts/net_diag.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e03 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e03)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# мок ping: up-* → успех с "time=12.3 ms"; остальные → недоступны
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/ping" <<'MOCK'
#!/usr/bin/env bash
host="${!#}"
case "${host}" in
  up-*)
    echo "PING ${host}: 56 data bytes"
    echo "64 bytes from ${host}: icmp_seq=0 ttl=57 time=12.3 ms"
    exit 0 ;;
  *) exit 1 ;;
esac
MOCK
chmod +x "${FAKEBIN}/ping"

LIST="${TEST_ROOT}/hosts.txt"
cat > "${LIST}" <<'EOF'
# сеть ЦОД Москва-1
up-server-01 10.50.1.1
down-server-01 10.50.1.9
up-server-02 10.50.1.2
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "net_diag.sh найден" || no "net_diag.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" 2>/dev/null)" || true

# TEST 4: up-хост помечен UP
printf '%s' "${OUT}" | grep -qE 'up-server-01.*UP' && ok "up-server-01 → UP" || no "up-server-01 не UP"
# TEST 5: RTT разобран из вывода ping (12.3)
printf '%s' "${OUT}" | grep -qE 'up-server-01.*12\.3' && ok "разобрал RTT 12.3 ms (sed по time=)" || no "не разобрал RTT из вывода ping"
# TEST 6: down-хост помечен DOWN
printf '%s' "${OUT}" | grep -qE 'down-server-01.*DOWN' && ok "down-server-01 → DOWN" || no "down-server-01 не DOWN"
# TEST 7: итог UP=2 DOWN=1
printf '%s' "${OUT}" | grep -qE 'UP=2' && printf '%s' "${OUT}" | grep -qE 'DOWN=1' && ok "итог UP=2 DOWN=1" || no "неверный итог"
# TEST 8: комментарий не обработан как хост
printf '%s' "${OUT}" | grep -q "ЦОД Москва" && no "комментарий обработан как хост" || ok "комментарии/пустые пропущены"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
