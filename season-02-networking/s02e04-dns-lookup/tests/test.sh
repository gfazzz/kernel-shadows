#!/usr/bin/env bash
#
# s02e04 «Телефонная книга интернета» — воспроизводимый unit-тест (без root, БЕЗ сети).
# Принцип mock-first (§5.3): dig подменяется мок-версией с фиксированными ответами.
#
# Выбор артефакта: SUBJECT=... | <серия>/dns_lookup.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                       then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/dns_lookup.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/dns_lookup.sh"
elif [ -f "${SERIES_DIR}/dns_lookup.sh" ];        then SCRIPT="${SERIES_DIR}/dns_lookup.sh"
else SCRIPT="${SERIES_DIR}/solution/dns_lookup.sh"
     echo "ℹ️  Свой dns_lookup.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/dns_lookup.sh artifacts/dns_lookup.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e04 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e04)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# мок dig: разбирает домен и тип из аргументов (+short игнор), фиксированные ответы.
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/dig" <<'MOCK'
#!/usr/bin/env bash
domain=""; type="A"
for a in "$@"; do
  case "$a" in
    +*) ;;
    A|AAAA|MX|NS|CNAME|TXT|PTR) type="$a" ;;
    *) domain="$a" ;;
  esac
done
case "${domain}:${type}" in
  google.com:A)  echo "142.250.185.46" ;;
  google.com:MX) echo "5 gmail-smtp-in.l.google.com." ; echo "10 alt1.gmail-smtp-in.l.google.com." ;;
  shadow.onion:A) echo "185.192.45.118" ;;
  nxdomain.test:*) ;;                 # пусто — домена нет
  *:A) echo "10.0.0.1" ;;
esac
MOCK
chmod +x "${FAKEBIN}/dig"

run(){ PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "$@" 2>/dev/null; }

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "dns_lookup.sh найден" || no "dns_lookup.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

# TEST 4: A-запись по умолчанию
printf '%s' "$(run google.com)" | grep -q "142.250.185.46" && ok "google.com → A 142.250.185.46 (по умолчанию)" || no "A-запись не разобрана"
# TEST 5: явный тип MX
printf '%s' "$(run google.com MX)" | grep -q "gmail-smtp-in" && ok "google.com MX → mail exchange" || no "MX-запись не разобрана"
# TEST 6: несколько значений MX → счётчик
printf '%s' "$(run google.com MX)" | grep -qE "Записей: 2" && ok "счётчик записей = 2 (MX)" || no "неверный счётчик записей"
# TEST 7: NXDOMAIN → ненулевой exit
run nxdomain.test >/dev/null 2>&1; [ $? -ne 0 ] && ok "nxdomain.test → ненулевой exit (нет записи)" || no "не обработан отсутствующий домен"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
