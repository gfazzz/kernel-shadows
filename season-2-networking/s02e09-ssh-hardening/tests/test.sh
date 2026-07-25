#!/usr/bin/env bash
#
# s02e09 «Закалённый вход» (капстоун Season 2) — воспроизводимый unit-тест (без root, без сети).
# Работает над фикстурой-sshd_config — реальный sshd не нужен.
#
# Выбор артефакта: SUBJECT=... | <серия>/sshd_harden_check.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NAME="sshd_harden_check.sh"

if   [ -n "${SUBJECT:-}" ];                    then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/${NAME}" ];           then SCRIPT="${SERIES_DIR}/${NAME}"
elif [ -f "${SERIES_DIR}/artifacts/${NAME}" ]; then SCRIPT="${SERIES_DIR}/artifacts/${NAME}"
else SCRIPT="${SERIES_DIR}/solution/${NAME}"
     echo "ℹ️  Свой ${NAME} не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/${NAME} ./${NAME}"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e09 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e09)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# фикстура 1: НЕзакалённый конфиг (root разрешён, пароли включены, empty не задано)
WEAK="${TEST_ROOT}/sshd_weak.conf"
cat > "${WEAK}" <<'EOF'
# sshd_config (небезопасный пример)
Port 22
#PermitRootLogin no
PermitRootLogin yes
PasswordAuthentication yes
X11Forwarding no
EOF

# фикстура 2: закалённый конфиг
HARD="${TEST_ROOT}/sshd_hard.conf"
cat > "${HARD}" <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "${NAME} найден" || no "${NAME} не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

WOUT="$(bash "${SCRIPT}" "${WEAK}" 2>&1)" || true
HOUT="$(bash "${SCRIPT}" "${HARD}" 2>&1)" || true

# TEST 4: PermitRootLogin yes — помечен проблемой (и активное значение, а не закомментированное)
printf '%s' "${WOUT}" | grep -qE 'PermitRootLogin.*yes' && ok "PermitRootLogin yes → флаг" || no "PermitRootLogin не помечен"
# TEST 5: PasswordAuthentication yes — помечен
printf '%s' "${WOUT}" | grep -qiE 'PasswordAuthentication.*(yes|парол)' && ok "PasswordAuthentication yes → флаг" || no "PasswordAuthentication не помечен"
# TEST 6: PermitEmptyPasswords не задано — помечен (<не задано>)
printf '%s' "${WOUT}" | grep -qE 'PermitEmptyPasswords' && ok "PermitEmptyPasswords (не задано) → флаг" || no "PermitEmptyPasswords не проверен"
# TEST 7: слабый конфиг → проблем >= 3
printf '%s' "${WOUT}" | grep -qE 'Проблем: [3-9]' && ok "слабый конфиг → проблем >= 3" || no "недооценил проблемы слабого конфига"
# TEST 8: закалённый конфиг → 0 проблем
printf '%s' "${HOUT}" | grep -qE 'Проблем: 0' && ok "закалённый конфиг → 0 проблем" || no "ложные срабатывания на закалённом конфиге"
# TEST 9: закомментированный PermitRootLogin no НЕ засчитан как ок в слабом конфиге
printf '%s' "${WOUT}" | grep -qE 'PermitRootLogin = no \(ок\)' && no "закомментированная строка засчитана как активная" || ok "комментарии игнорируются (берётся активное значение)"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
