#!/usr/bin/env bash
#
# s02e07 «Стена против ботнета» (капстоун ep07) — воспроизводимый unit-тест (без root, без сети).
# Генерируем правила блокировки из списка IP и проверяем результат (текст).
#
# Выбор артефакта: SUBJECT=... | <серия>/block_botnet.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                       then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/block_botnet.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/block_botnet.sh"
elif [ -f "${SERIES_DIR}/block_botnet.sh" ];      then SCRIPT="${SERIES_DIR}/block_botnet.sh"
else SCRIPT="${SERIES_DIR}/solution/block_botnet.sh"
     echo "ℹ️  Свой block_botnet.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/block_botnet.sh artifacts/block_botnet.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e07 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e07)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# фикстура: список ботнета (3 IP + комментарии + inline-комментарий)
LIST="${TEST_ROOT}/botnet_ips.txt"
cat > "${LIST}" <<'EOF'
# Botnet IPs (Anna, forensics)
185.220.101.47     # Tor exit node (DE)
91.219.237.244     # Tor exit node (NL)

195.123.246.151    # Tor exit node (RO)
EOF
OUT="${TEST_ROOT}/block_rules.sh"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "block_botnet.sh найден" || no "block_botnet.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

REPORT="$(bash "${SCRIPT}" "${LIST}" "${OUT}" 2>/dev/null)" || true

# TEST 4: файл правил создан
[ -f "${OUT}" ] && ok "файл правил создан" || no "файл правил не создан"
# TEST 5: правило для каждого IP
grep -q "ufw deny from 185.220.101.47" "${OUT}" 2>/dev/null && grep -q "ufw deny from 195.123.246.151" "${OUT}" 2>/dev/null && ok "правила для всех 3 IP" || no "не для всех IP правила"
# TEST 6: ровно 3 правила deny (комментарии/пустые пропущены)
n="$(grep -c 'ufw deny from' "${OUT}" 2>/dev/null || echo 0)"
[ "${n}" -eq 3 ] && ok "ровно 3 правила deny (пропущены # и пустые)" || no "неверное число правил (${n}, ожидалось 3)"
# TEST 7: сгенерированный файл — валидный bash
bash -n "${OUT}" 2>/dev/null && ok "сгенерированный файл — валидный bash" || no "сгенерированный файл невалиден"
# TEST 8: комментарий-строка не превратилась в IP-правило
grep -q "ufw deny from #" "${OUT}" 2>/dev/null && no "комментарий попал в правило" || ok "комментарии не стали правилами"
# TEST 9: сводка о числе правил
printf '%s' "${REPORT}" | grep -qE 'сгенерировано: 3' && ok "сводка: сгенерировано 3" || no "неверная сводка"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
