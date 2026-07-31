#!/usr/bin/env bash
#
# s02e01 «Твой адрес в сети» — воспроизводимый unit-тест (без root, без сети).
# Чистая проверка разбора IPv4 — детерминированно на любой машине.
#
# Выбор артефакта: SUBJECT=... | <серия>/ipinfo.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                   then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/ipinfo.sh" ];        then SCRIPT="${SERIES_DIR}/ipinfo.sh"
elif [ -f "${SERIES_DIR}/artifacts/ipinfo.sh" ];then SCRIPT="${SERIES_DIR}/artifacts/ipinfo.sh"
else SCRIPT="${SERIES_DIR}/solution/ipinfo.sh"
     echo "ℹ️  Свой ipinfo.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/ipinfo.sh ./ipinfo.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e01 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "ipinfo.sh найден" || no "ipinfo.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

run(){ bash "${SCRIPT}" "$1" 2>/dev/null; }

# TEST 4: public + класс A (8.8.8.8)
o="$(run 8.8.8.8)"
printf '%s' "$o" | grep -qi "public" && printf '%s' "$o" | grep -q "Класс: A" && ok "8.8.8.8 → public, класс A" || no "8.8.8.8 разобран неверно"
# TEST 5: private 192.168 (класс C)
o="$(run 192.168.1.100)"
printf '%s' "$o" | grep -qi "private" && printf '%s' "$o" | grep -q "Класс: C" && ok "192.168.1.100 → private, класс C" || no "192.168.1.100 неверно"
# TEST 6: private 10/8
printf '%s' "$(run 10.50.1.100)" | grep -qi "private" && ok "10.50.1.100 → private" || no "10.50.1.100 не private"
# TEST 7: private 172.16-31
printf '%s' "$(run 172.16.5.20)" | grep -qi "private" && ok "172.16.5.20 → private" || no "172.16.5.20 не private"
# TEST 8: 172.32 — уже public (не 16-31)
printf '%s' "$(run 172.32.5.20)" | grep -qi "public" && ok "172.32.5.20 → public (вне 172.16/12)" || no "172.32.5.20 неверно (границы private)"
# TEST 9: loopback
printf '%s' "$(run 127.0.0.1)" | grep -qi "loopback" && ok "127.0.0.1 → loopback" || no "127.0.0.1 не loopback"
# TEST 10: невалидный октет > 255 → ненулевой exit
run 999.1.1.1 >/dev/null 2>&1; [ $? -ne 0 ] && ok "999.1.1.1 → невалидный (ненулевой exit)" || no "не отверг 999.1.1.1"
# TEST 11: невалидная форма (3 октета)
run 1.2.3 >/dev/null 2>&1; [ $? -ne 0 ] && ok "1.2.3 → невалидный (не 4 октета)" || no "не отверг 1.2.3"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
