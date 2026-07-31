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
3306 (v6)                  ALLOW       Anywhere (v6)
5432/tcp                   ALLOW       10.50.0.0/24
6379                       ALLOW       127.0.0.1
33060                      ALLOW       Anywhere
9200/tcp                   ALLOW       Anywhere
27017                      DENY        Anywhere
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "fw_audit.sh найден" || no "fw_audit.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${RULES}" 2>&1)" || true

WARN="$(printf '%s\n' "${OUT}" | grep -E 'чувствительный порт|⚠')"

# TEST 4: 3306 открытый наружу — помечен проблемой
printf '%s' "${WARN}" | grep -q '3306' && ok "3306 (MySQL, Anywhere) → флаг" || no "3306 не помечен опасным"

# TEST 5: 9200 (Elasticsearch) со слэшем в порту — тоже помечен
printf '%s' "${WARN}" | grep -q '9200' && ok "9200/tcp распознан со слэшем и помечен" || no "порт со слэшем (9200/tcp) не распознан"

# TEST 6: 6379 на петле — НЕ помечен
printf '%s' "${WARN}" | grep -q '6379' && no "6379 (127.0.0.1) ошибочно помечен" || ok "порт на localhost не флагуется"

# TEST 7: 5432 с конкретной подсетью — НЕ помечен
printf '%s' "${WARN}" | grep -q '5432' && no "5432 с источником 10.50.0.0/24 ошибочно помечен" || ok "порт, ограниченный подсетью, не флагуется"

# TEST 8: ЛОВУШКА — 33060 не должен считаться портом 3306
printf '%s' "${WARN}" | grep -qE '(^|[^0-9])33060([^0-9]|$)' \
    && no "33060 помечен как чувствительный — сравнение по вхождению" || ok "33060 не принят за 3306"

# TEST 9: DENY-строка не считается разрешением
printf '%s' "${WARN}" | grep -q '27017' && no "27017 с действием DENY принят за разрешение" || ok "строки DENY не считаются разрешениями"

# TEST 10: правило (v6) не удваивает счётчик по тому же порту
n_3306="$(printf '%s\n' "${WARN}" | grep -c '3306')"
[ "${n_3306}" -le 1 ] && ok "правило (v6) не удваивает проблему по 3306" || no "порт 3306 отмечен ${n_3306} раза — дубль из-за (v6)"

# TEST 11: счётчик согласован с числом предупреждений
n_warn="$(printf '%s\n' "${WARN}" | grep -c .)"
printf '%s' "${OUT}" | grep -qE "Проблем: ${n_warn}([^0-9]|$)" \
    && ok "счётчик проблем = ${n_warn} и согласован с выводом" || no "счётчик не совпадает с числом предупреждений (${n_warn})"

# TEST 12: нет файла → ненулевой exit
bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1; [ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
