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
elif [ -f "${SERIES_DIR}/artifacts/${NAME}" ]; then SCRIPT="${SERIES_DIR}/artifacts/${NAME}"
elif [ -f "${SERIES_DIR}/${NAME}" ];           then SCRIPT="${SERIES_DIR}/${NAME}"
else SCRIPT="${SERIES_DIR}/solution/${NAME}"
     echo "ℹ️  Свой ${NAME} не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/${NAME} artifacts/${NAME}"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e09 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e09)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Фикстура 1: НЕзакалённый конфиг.
#   закомментированная «правильная» строка ПОСЛЕ активной небезопасной —
#   ловушка для разбора без якоря и без фильтра комментариев;
#   PermitEmptyPasswords не задан вовсе (действует умолчание).
WEAK="${TEST_ROOT}/sshd_weak.conf"
cat > "${WEAK}" <<'EOF'
# sshd_config (небезопасный пример)
Port 22
PermitRootLogin yes
#PermitRootLogin no
PasswordAuthentication yes
X11Forwarding no
EOF

# Фикстура 2: полностью закалённый конфиг — аудит обязан молчать.
HARD="${TEST_ROOT}/sshd_hard.conf"
cat > "${HARD}" <<'EOF'
Port 22
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
EOF

# Фикстура 3: то же закалённое, но с отступами и другим регистром директив.
CASE="${TEST_ROOT}/sshd_case.conf"
cat > "${CASE}" <<'EOF'
Port 22
   permitrootlogin no
	PasswordAuthentication NO
PERMITEMPTYPASSWORDS no
   x11forwarding no
EOF

# Фикстура 4: PermitRootLogin prohibit-password — не «yes», но и не «no».
PROHIB="${TEST_ROOT}/sshd_prohibit.conf"
cat > "${PROHIB}" <<'EOF'
Port 22
PermitRootLogin prohibit-password
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
COUT="$(bash "${SCRIPT}" "${CASE}" 2>&1)" || true
POUT="$(bash "${SCRIPT}" "${PROHIB}" 2>&1)" || true

WWARN="$(printf '%s\n' "${WOUT}" | grep -E '⚠')"

# TEST 4: PermitRootLogin yes — помечен проблемой
printf '%s' "${WWARN}" | grep -qi 'PermitRootLogin' && ok "PermitRootLogin yes → флаг" || no "PermitRootLogin не помечен"

# TEST 5: PasswordAuthentication yes — помечен
printf '%s' "${WWARN}" | grep -qi 'PasswordAuthentication' && ok "PasswordAuthentication yes → флаг" || no "PasswordAuthentication не помечен"

# TEST 6: не заданная директива — тоже проблема
printf '%s' "${WWARN}" | grep -qi 'PermitEmptyPasswords' && ok "PermitEmptyPasswords (не задано) → флаг" || no "не заданная директива не помечена"

# TEST 7: корректное значение не флагуется даже в слабом конфиге
printf '%s' "${WWARN}" | grep -qi 'X11Forwarding' && no "корректный X11Forwarding no помечен проблемой" || ok "верные значения не флагуются"

# TEST 8: ЛОВУШКА — закомментированная строка не считается активным значением
printf '%s' "${WOUT}" | grep -qiE 'PermitRootLogin = no \(ок\)' \
    && no "закомментированная строка засчитана как активная" || ok "комментарии игнорируются"

# TEST 9: счётчик слабого конфига согласован с числом предупреждений
n_w="$(printf '%s\n' "${WWARN}" | grep -c .)"
printf '%s' "${WOUT}" | grep -qE "Проблем: ${n_w}([^0-9]|$)" \
    && ok "слабый конфиг: проблем ${n_w}, счётчик согласован" || no "счётчик не совпадает с числом предупреждений (${n_w})"

# TEST 10: слабый конфиг даёт не меньше трёх проблем
[ "${n_w}" -ge 3 ] && ok "слабый конфиг → проблем >= 3" || no "недооценены проблемы слабого конфига (${n_w})"

# TEST 11: закалённый конфиг → 0 проблем
printf '%s' "${HOUT}" | grep -qE 'Проблем: 0([^0-9]|$)' && ok "закалённый конфиг → 0 проблем" || no "ложные срабатывания на закалённом конфиге"

# TEST 12: ЛОВУШКА — отступы и другой регистр директив
printf '%s' "${COUT}" | grep -qE 'Проблем: 0([^0-9]|$)' \
    && ok "отступы и регистр директив не мешают разбору" \
    || no "директивы с отступом или в другом регистре не распознаны"

# TEST 13: ЛОВУШКА — prohibit-password не равен no
printf '%s' "${POUT}" | grep -E '⚠' | grep -qi 'PermitRootLogin' \
    && ok "prohibit-password не принят за no" \
    || no "PermitRootLogin prohibit-password засчитан как безопасный (проверка «не yes»?)"

# TEST 14: ALERT при проблемах идёт в stderr; нет файла → ненулевой код
ERR="$(bash "${SCRIPT}" "${WEAK}" 2>&1 >/dev/null)"
bash "${SCRIPT}" "${TEST_ROOT}/nope.conf" >/dev/null 2>&1; rc=$?
if printf '%s' "${ERR}" | grep -q "ALERT" && [ "${rc}" -ne 0 ]; then
    ok "ALERT в stderr, отсутствующий файл → ненулевой exit"
else
    no "нет ALERT в stderr либо не обработан отсутствующий файл"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
