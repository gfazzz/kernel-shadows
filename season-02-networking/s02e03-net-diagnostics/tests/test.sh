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

# Мок ping. Три поведения, как в жизни:
#   up-server-01 → отвечает быстро (12.3 ms);
#   up-server-02 → отвечает медленно (403.7 ms) — RTT не должен быть захардкожен;
#   quiet-*      → отвечает УСПЕШНО, но БЕЗ поля time= (бывает на урезанных ping);
#   остальные    → недоступны (ненулевой код).
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/ping" <<'MOCK'
#!/usr/bin/env bash
host="${!#}"
case "${host}" in
  up-server-01)
    echo "PING ${host}: 56 data bytes"
    echo "64 bytes from ${host}: icmp_seq=0 ttl=57 time=12.3 ms"
    exit 0 ;;
  up-server-02)
    echo "PING ${host}: 56 data bytes"
    echo "64 bytes from ${host}: icmp_seq=0 ttl=53 time=403.7 ms"
    exit 0 ;;
  quiet-server-01)
    echo "PING ${host}: 56 data bytes"
    echo "64 bytes from ${host}: icmp_seq=0 ttl=57"
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
quiet-server-01 10.50.1.3
EOF

# Ожидания ВЫЧИСЛЯЮТСЯ прогоном мока по фикстуре, а не записаны константами.
EXP_UP=0; EXP_DOWN=0
while IFS= read -r l; do
    [ -z "${l}" ] && continue
    case "${l}" in \#*) continue ;; esac
    h="${l%% *}"
    if PATH="${FAKEBIN}:${PATH}" ping -c 1 -W 2 "${h}" >/dev/null 2>&1; then
        EXP_UP=$((EXP_UP + 1))
    else
        EXP_DOWN=$((EXP_DOWN + 1))
    fi
done < "${LIST}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "net_diag.sh найден" || no "net_diag.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" 2>/dev/null)" || true

# TEST 4: доступный хост помечен UP
printf '%s' "${OUT}" | grep -qE 'up-server-01.*UP' && ok "up-server-01 → UP" || no "up-server-01 не UP"

# TEST 5: RTT разобран из вывода ping
printf '%s' "${OUT}" | grep -qE 'up-server-01.*12\.3' && ok "разобран RTT 12.3 ms (sed по time=)" || no "не разобран RTT из вывода ping"

# TEST 6: RTT РАЗНЫЙ у разных хостов — значение не захардкожено
printf '%s' "${OUT}" | grep -qE 'up-server-02.*403\.7' \
    && ok "RTT берётся из ответа каждого хоста (403.7 у второго)" \
    || no "RTT второго хоста не 403.7 — значение захардкожено или разбирается один раз"

# TEST 7: ответ БЕЗ поля time= → всё равно UP, но RTT неизвестен (не ноль)
q_line="$(printf '%s\n' "${OUT}" | grep -m1 'quiet-server-01')"
if printf '%s' "${q_line}" | grep -q 'UP'; then
    if printf '%s' "${q_line}" | grep -qE '(^|[^0-9.])0([^0-9.]|$)'; then
        no "ответ без time= показан как RTT 0 — неизвестное должно быть явным (?)"
    else
        ok "ответ без time= → UP с неизвестным RTT"
    fi
else
    no "хост, ответивший без time=, ошибочно помечен DOWN"
fi

# TEST 8: недоступный хост помечен DOWN
printf '%s' "${OUT}" | grep -qE 'down-server-01.*DOWN' && ok "down-server-01 → DOWN" || no "down-server-01 не DOWN"

# TEST 9: итог совпадает с посчитанным по фикстуре
printf '%s' "${OUT}" | grep -qE "UP=${EXP_UP}([^0-9]|$)" && printf '%s' "${OUT}" | grep -qE "DOWN=${EXP_DOWN}([^0-9]|$)" \
    && ok "итог UP=${EXP_UP} DOWN=${EXP_DOWN}" || no "неверный итог (ожидалось UP=${EXP_UP} DOWN=${EXP_DOWN})"

# TEST 10: итог согласован со строками таблицы
n_up="$(printf '%s\n' "${OUT}" | grep -cE '^[^ ]+ +UP +')"
[ "${n_up}" -eq "${EXP_UP}" ] && ok "счётчик UP согласован со строками таблицы" \
    || no "строк UP ${n_up}, а в итоге ${EXP_UP}"

# TEST 11: комментарий и пустая строка не обработаны как хосты
printf '%s' "${OUT}" | grep -q "ЦОД Москва" && no "комментарий обработан как хост" || ok "комментарии/пустые пропущены"

# TEST 12: отсутствующий список → ненулевой код возврата
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
