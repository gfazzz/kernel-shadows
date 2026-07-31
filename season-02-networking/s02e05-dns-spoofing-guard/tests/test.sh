#!/usr/bin/env bash
#
# s02e05 «Ловим подмену DNS» (капстоун ep06) — воспроизводимый unit-тест (без root, БЕЗ сети).
# Мокает dig: один домен (shadow-05) резолвится в IP Крылова вместо эталона (подмена).
#
# Выбор артефакта: SUBJECT=... | <серия>/dns_guard.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                     then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/dns_guard.sh" ];       then SCRIPT="${SERIES_DIR}/dns_guard.sh"
elif [ -f "${SERIES_DIR}/artifacts/dns_guard.sh" ];then SCRIPT="${SERIES_DIR}/artifacts/dns_guard.sh"
else SCRIPT="${SERIES_DIR}/solution/dns_guard.sh"
     echo "ℹ️  Свой dns_guard.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/dns_guard.sh ./dns_guard.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e05 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e05)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# мок dig: shadow-05 ОТРАВЛЕН (IP Крылова), остальные — правильные.
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/dig" <<'MOCK'
#!/usr/bin/env bash
domain=""
for a in "$@"; do case "$a" in +*|A|AAAA|MX|NS|CNAME|TXT|PTR) ;; *) domain="$a" ;; esac; done
case "${domain}" in
  shadow-01.ops.internal) echo "10.50.1.10" ;;
  shadow-05.ops.internal) echo "185.220.101.52" ;;   # IP Крылова — ПОДМЕНА!
  gateway.ops.internal)   echo "10.50.1.1" ;;
  *) ;;
esac
MOCK
chmod +x "${FAKEBIN}/dig"

# baseline: домен → правильный IP
BASE="${TEST_ROOT}/baseline.txt"
cat > "${BASE}" <<'EOF'
# эталонные адреса инфраструктуры
shadow-01.ops.internal 10.50.1.10
shadow-05.ops.internal 10.50.1.20
gateway.ops.internal 10.50.1.1
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "dns_guard.sh найден" || no "dns_guard.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${BASE}" 2>&1)" || true

# TEST 4: shadow-05 помечен как подмена (резолв 185.220.101.52 ≠ эталон 10.50.1.20)
printf '%s' "${OUT}" | grep -qE 'shadow-05.*ПОДМЕН|shadow-05.*185.220.101.52' && ok "shadow-05 → обнаружена подмена" || no "подмена shadow-05 не обнаружена"
# TEST 5: shadow-01 совпал (не флагуется)
printf '%s' "${OUT}" | grep -qE 'shadow-01.*совпад' && ok "shadow-01 → совпадает (не флаг)" || no "shadow-01 неверно"
# TEST 6: итог OK=2 SPOOFED=1
printf '%s' "${OUT}" | grep -qE 'OK=2' && printf '%s' "${OUT}" | grep -qE 'SPOOFED=1' && ok "итог OK=2 SPOOFED=1" || no "неверный итог"
# TEST 7: ALERT при подмене
printf '%s' "${OUT}" | grep -q "ALERT" && ok "выдан ALERT (есть подмена)" || no "нет ALERT при подмене"
# TEST 8: нет baseline → ненулевой exit
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет baseline → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
