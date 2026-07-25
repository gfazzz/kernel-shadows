#!/usr/bin/env bash
#
# s02e02 «Что слушает на сервере» — воспроизводимый unit-тест (без root, БЕЗ сети).
# Принцип mock-first (§5.3): ss подменяется мок-версией с фиксированным выводом
# LISTEN-сокетов. Так тест зелёный на любой машине.
#
# Выбор артефакта: SUBJECT=... | <серия>/check_ports.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                       then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/check_ports.sh" ];       then SCRIPT="${SERIES_DIR}/check_ports.sh"
elif [ -f "${SERIES_DIR}/artifacts/check_ports.sh" ];then SCRIPT="${SERIES_DIR}/artifacts/check_ports.sh"
else SCRIPT="${SERIES_DIR}/solution/check_ports.sh"
     echo "ℹ️  Свой check_ports.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/check_ports.sh ./check_ports.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e02 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e02)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# мок ss: фиксированный вывод -tln. Порт 4444 — «бэкдор» (не в allowlist).
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/ss" <<'MOCK'
#!/usr/bin/env bash
cat <<'OUT'
State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
LISTEN 0      128    0.0.0.0:22          0.0.0.0:*
LISTEN 0      128    0.0.0.0:80          0.0.0.0:*
LISTEN 0      128    127.0.0.1:443       0.0.0.0:*
LISTEN 0      128    0.0.0.0:4444        0.0.0.0:*
OUT
MOCK
chmod +x "${FAKEBIN}/ss"

ALLOW="${TEST_ROOT}/allow.txt"
printf '22\n80\n443\n' > "${ALLOW}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "check_ports.sh найден" || no "check_ports.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${ALLOW}" 2>/dev/null)" || true

# TEST 4: показал слушающие порты (22, 80, 443, 4444)
for p in 22 80 443 4444; do :; done
printf '%s' "${OUT}" | grep -q ":22" && printf '%s' "${OUT}" | grep -q ":4444" && ok "показал слушающие порты (вкл. 4444)" || no "не показал слушающие порты"
# TEST 5: 22 отмечен разрешённым
printf '%s' "${OUT}" | grep -qE '22.*разрешён' && ok "22 → разрешён (в allowlist)" || no "22 не отмечен разрешённым"
# TEST 6: 4444 отмечен неожиданным
printf '%s' "${OUT}" | grep -qE '4444.*НЕ в allowlist|4444.*неожид' && ok "4444 → неожиданный (не в allowlist)" || no "4444 не помечен неожиданным"
# TEST 7: счётчик неожиданных = 1
printf '%s' "${OUT}" | grep -qE 'Неожиданных портов: 1' && ok "счётчик неожиданных = 1" || no "неверный счётчик неожиданных"
# TEST 8: разрешённый порт НЕ помечен как неожиданный
printf '%s' "${OUT}" | grep -qE '80.*НЕ в allowlist' && no "разрешённый 80 ошибочно помечен неожиданным" || ok "разрешённые порты не флагуются"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
