#!/usr/bin/env bash
#
# s02e06 «Читаем стену» — воспроизводимый unit-тест (без root, без сети).
# Работает над фикстурой-выводом `ufw status` — реальный ufw/ядро не нужны.
#
# Выбор артефакта: SUBJECT=... | <серия>/fw_audit.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                   then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/fw_audit.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/fw_audit.sh"
elif [ -f "${SERIES_DIR}/fw_audit.sh" ];      then SCRIPT="${SERIES_DIR}/fw_audit.sh"
else SCRIPT="${SERIES_DIR}/solution/fw_audit.sh"
     echo "ℹ️  Свой fw_audit.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/fw_audit.sh artifacts/fw_audit.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e06 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e06)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# фикстура: вывод `ufw status`. 3306 (MySQL) открыт наружу — проблема;
# 6379 (Redis) только с 127.0.0.1 — ок.
RULES="${TEST_ROOT}/ufw_status.txt"
cat > "${RULES}" <<'EOF'
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
3306                       ALLOW       Anywhere
6379                       ALLOW       127.0.0.1
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "fw_audit.sh найден" || no "fw_audit.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${RULES}" 2>&1)" || true

# TEST 4: 3306 открытый наружу — помечен проблемой
printf '%s' "${OUT}" | grep -qE '3306.*Anywhere|чувствительный порт 3306' && ok "3306 (MySQL, Anywhere) → флаг" || no "3306 не помечен опасным"
# TEST 5: 6379 с 127.0.0.1 — НЕ помечен
printf '%s' "${OUT}" | grep -qE 'чувствительный порт 6379' && no "6379 (127.0.0.1) ошибочно помечен" || ok "6379 на localhost не флагуется"
# TEST 6: счётчик проблем = 1
printf '%s' "${OUT}" | grep -qE 'Проблем: 1' && ok "счётчик проблем = 1" || no "неверный счётчик проблем"
# TEST 7: обычные порты (22/80/443) показаны как ALLOW
printf '%s' "${OUT}" | grep -q "22/tcp" && printf '%s' "${OUT}" | grep -q "443/tcp" && ok "показал ALLOW-правила (22/443)" || no "не показал ALLOW-правила"
# TEST 8: нет файла → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1; [ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
