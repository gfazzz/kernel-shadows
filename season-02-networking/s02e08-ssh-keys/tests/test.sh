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

# Фикстура ~/.ssh:
#   id_ed25519         600 — эталон;
#   id_ed25519_backup  400 — строже, тоже допустимо;
#   id_rsa             644 — небезопасно;
#   id_dsa             600 — права ок, но тип устарел;
#   *.pub              публичные — проверять как приватные нельзя;
#   config/known_hosts посторонние файлы — не ключи.
SSHDIR="${TEST_ROOT}/.ssh"; mkdir -p "${SSHDIR}"
echo "priv" > "${SSHDIR}/id_ed25519";         chmod 600 "${SSHDIR}/id_ed25519"
echo "pub"  > "${SSHDIR}/id_ed25519.pub";     chmod 644 "${SSHDIR}/id_ed25519.pub"
echo "priv" > "${SSHDIR}/id_ed25519_backup";  chmod 400 "${SSHDIR}/id_ed25519_backup"
echo "priv" > "${SSHDIR}/id_rsa";             chmod 644 "${SSHDIR}/id_rsa"
echo "pub"  > "${SSHDIR}/id_rsa.pub";         chmod 644 "${SSHDIR}/id_rsa.pub"
echo "priv" > "${SSHDIR}/id_dsa";             chmod 600 "${SSHDIR}/id_dsa"
echo "Host x" > "${SSHDIR}/config";           chmod 600 "${SSHDIR}/config"
echo "host key" > "${SSHDIR}/known_hosts";    chmod 644 "${SSHDIR}/known_hosts"

# Ожидания ВЫЧИСЛЯЮТСЯ по фикстуре, а не записаны константами.
EXP_KEYS=0
for f in "${SSHDIR}"/id_*; do
    case "${f}" in *.pub) continue ;; esac
    [ -f "${f}" ] && EXP_KEYS=$((EXP_KEYS + 1))
done

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "ssh_key_check.sh найден" || no "ssh_key_check.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${SSHDIR}" 2>&1)" || true

WARN="$(printf '%s\n' "${OUT}" | grep -E 'НЕБЕЗОПАСНО|устарел|⚠')"

# TEST 4: ключ с правами 600 признан корректным
printf '%s' "${OUT}" | grep -qE 'id_ed25519 — права 600' && ok "id_ed25519 (600) → ок" || no "ключ с правами 600 не признан корректным"

# TEST 5: ЛОВУШКА — 400 строже 600 и тоже допустим
printf '%s' "${WARN}" | grep -q 'id_ed25519_backup' \
    && no "ключ с правами 400 помечен проблемой (400 строже 600 и допустим)" \
    || ok "права 400 признаны корректными"

# TEST 6: id_rsa (644) — небезопасные права
printf '%s' "${WARN}" | grep -q 'id_rsa' && ok "id_rsa (644) → флаг небезопасных прав" || no "id_rsa не помечен"

# TEST 7: id_dsa — устаревший тип (права при этом верные)
printf '%s' "${WARN}" | grep -q 'id_dsa' && ok "id_dsa → устаревший тип (флаг)" || no "id_dsa не помечен устаревшим"

# TEST 8: публичные ключи не проверяются как приватные
printf '%s' "${WARN}" | grep -q '\.pub' && no ".pub проверен как приватный ключ" || ok "публичные ключи (.pub) пропущены"

# TEST 9: посторонние файлы каталога ключами не считаются
printf '%s' "${OUT}" | grep -qE '(^|[^a-z])(config|known_hosts)' \
    && no "config/known_hosts обработаны как ключи" || ok "посторонние файлы не считаются ключами"

# TEST 10: счётчик ключей совпадает с посчитанным по фикстуре
printf '%s' "${OUT}" | grep -qE "Ключей проверено: ${EXP_KEYS}([^0-9]|$)" \
    && ok "проверено ${EXP_KEYS} приватных ключа" || no "неверный счётчик ключей (ожидалось ${EXP_KEYS})"

# TEST 11: счётчик проблем согласован с числом предупреждений
n_warn="$(printf '%s\n' "${WARN}" | grep -c .)"
printf '%s' "${OUT}" | grep -qE "Проблем: ${n_warn}([^0-9]|$)" \
    && ok "счётчик проблем = ${n_warn} и согласован с выводом" || no "счётчик проблем не совпадает с числом предупреждений (${n_warn})"

# TEST 12: права читаются реально, а не подставляются (кроссплатформенный stat)
printf '%s' "${OUT}" | grep -qE 'права 6?4?0?0' && printf '%s' "${OUT}" | grep -q '644' \
    && ok "права прочитаны из файловой системы" || no "права не прочитаны (stat не сработал?)"

# TEST 13: несуществующий каталог → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope" >/dev/null 2>&1; [ $? -ne 0 ] && ok "нет каталога → ненулевой exit" || no "не обработан отсутствующий каталог"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
