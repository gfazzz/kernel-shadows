#!/usr/bin/env bash
#
# s02e01 «Твой адрес в сети» — воспроизводимый unit-тест (без root, без сети).
# Чистая проверка разбора IPv4 — детерминированно на любой машине.
#
# Выбор артефакта: SUBJECT=... | <серия>/ipinfo.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                   then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/ipinfo.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/ipinfo.sh"
elif [ -f "${SERIES_DIR}/ipinfo.sh" ];        then SCRIPT="${SERIES_DIR}/ipinfo.sh"
else SCRIPT="${SERIES_DIR}/solution/ipinfo.sh"
     echo "ℹ️  Свой ipinfo.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/ipinfo.sh artifacts/ipinfo.sh"; echo ""
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
# TEST 8: 172.31.255.255 — верхняя граница /12 ВКЛЮЧИТЕЛЬНО
printf '%s' "$(run 172.31.255.255)" | grep -qi "private" && ok "172.31.255.255 → private (верхняя граница /12)" || no "172.31.255.255 должен быть private"
# TEST 9: 172.32 — уже public (не 16-31)
printf '%s' "$(run 172.32.5.20)" | grep -qi "public" && ok "172.32.5.20 → public (вне 172.16/12)" || no "172.32.5.20 неверно (границы private)"
# TEST 10: 192.169 — уже public (private только 192.168)
printf '%s' "$(run 192.169.1.1)" | grep -qi "public" && ok "192.169.1.1 → public (private только 192.168)" || no "192.169.1.1 ошибочно считается private"
# TEST 11: loopback — весь /8, а не только 127.0.0.1
printf '%s' "$(run 127.0.0.1)" | grep -qi "loopback" && printf '%s' "$(run 127.10.20.30)" | grep -qi "loopback" \
    && ok "127.0.0.1 и 127.10.20.30 → loopback (весь /8)" || no "loopback распознан не по всему 127.0.0.0/8"
# TEST 12: broadcast
printf '%s' "$(run 255.255.255.255)" | grep -qi "broadcast" && ok "255.255.255.255 → broadcast" || no "255.255.255.255 не broadcast"
# TEST 13: класс B на границе 128
printf '%s' "$(run 128.0.0.1)" | grep -q "Класс: B" && ok "128.0.0.1 → класс B" || no "неверный класс для 128.0.0.1"
# TEST 14: невалидный октет > 255 → ненулевой exit (999 и 256 — граница)
run 999.1.1.1 >/dev/null 2>&1; rc1=$?
run 10.0.0.256 >/dev/null 2>&1; rc2=$?
[ "${rc1}" -ne 0 ] && [ "${rc2}" -ne 0 ] && ok "999.1.1.1 и 10.0.0.256 отвергнуты" || no "не отвергнут октет больше 255"
# TEST 15: невалидная форма — 3 октета, нецифровой октет, пустой октет, пустая строка
bad=0
for v in "1.2.3" "10.0.0.a" "10.0.0." "" "1.2.3.4.5"; do
    run "$v" >/dev/null 2>&1 && bad=1
done
[ "${bad}" -eq 0 ] && ok "невалидные формы отвергнуты (3 октета, буквы, пустой октет, пусто, 5 октетов)" \
    || no "какая-то невалидная форма принята за адрес"
# TEST 16: сообщение об ошибке уходит в stderr, а не в stdout
err="$(bash "${SCRIPT}" 999.1.1.1 2>&1 >/dev/null)"
[ -n "${err}" ] && ok "сообщение об ошибке идёт в stderr" || no "ошибка не выведена в stderr"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
