#!/usr/bin/env bash
#
# s02e08 «Ключи вместо паролей» — воспроизводимый unit-тест (без root, без сети).
# Создаёт фикстуру-каталог с ключами разных прав/типов во временном TEST_ROOT.
#
# Выбор артефакта: SUBJECT=... | <серия>/ssh_key_check.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                        then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/ssh_key_check.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/ssh_key_check.sh"
elif [ -f "${SERIES_DIR}/ssh_key_check.sh" ];      then SCRIPT="${SERIES_DIR}/ssh_key_check.sh"
else SCRIPT="${SERIES_DIR}/solution/ssh_key_check.sh"
     echo "ℹ️  Свой ssh_key_check.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/ssh_key_check.sh artifacts/ssh_key_check.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e08 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e08)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# фикстура ~/.ssh: ed25519 (600, ок), rsa (644, небезопасно), dsa (600, устарел)
SSHDIR="${TEST_ROOT}/.ssh"; mkdir -p "${SSHDIR}"
echo "priv" > "${SSHDIR}/id_ed25519";     chmod 600 "${SSHDIR}/id_ed25519"
echo "pub"  > "${SSHDIR}/id_ed25519.pub"; chmod 644 "${SSHDIR}/id_ed25519.pub"
echo "priv" > "${SSHDIR}/id_rsa";         chmod 644 "${SSHDIR}/id_rsa"
echo "priv" > "${SSHDIR}/id_dsa";         chmod 600 "${SSHDIR}/id_dsa"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "ssh_key_check.sh найден" || no "ssh_key_check.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${SSHDIR}" 2>&1)" || true

# TEST 4: ed25519 (600) — ок, без предупреждения о правах
printf '%s' "${OUT}" | grep -qE 'id_ed25519 — права 600' && ok "id_ed25519 (600) → ок" || no "id_ed25519 неверно"
# TEST 5: id_rsa (644) — небезопасные права
printf '%s' "${OUT}" | grep -qE 'id_rsa.*НЕБЕЗОПАСНО|id_rsa.*644' && ok "id_rsa (644) → флаг небезопасных прав" || no "id_rsa не помечен"
# TEST 6: id_dsa — устарел
printf '%s' "${OUT}" | grep -qE 'id_dsa.*устарел|dsa.*замен' && ok "id_dsa → устаревший тип (флаг)" || no "id_dsa не помечен устаревшим"
# TEST 7: публичный ключ (.pub) не проверялся как приватный
printf '%s' "${OUT}" | grep -qE 'id_ed25519.pub.*НЕБЕЗОПАСНО' && no ".pub ошибочно проверен как приватный" || ok "публичные ключи (.pub) пропущены"
# TEST 8: проверено 3 приватных ключа
printf '%s' "${OUT}" | grep -qE 'Ключей проверено: 3' && ok "проверено 3 приватных ключа" || no "неверный счётчик ключей"
# TEST 9: несуществующий каталог → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope" >/dev/null 2>&1; [ $? -ne 0 ] && ok "нет каталога → ненулевой exit" || no "не обработан отсутствующий каталог"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
