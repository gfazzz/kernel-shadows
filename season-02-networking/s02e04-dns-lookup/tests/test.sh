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
  google.com:TXT) echo '"v=spf1 include:_spf.google.com ~all"' ;;
  google.com:*)  ;;                   # существующий домен, но записи такого типа нет
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

# Эталонные ответы берутся из САМОГО мока, а не записаны константами.
EXP_A="$(PATH="${FAKEBIN}:${PATH}" dig google.com A +short)"
EXP_MX_N="$(PATH="${FAKEBIN}:${PATH}" dig google.com MX +short | grep -c .)"

# TEST 4: A-запись по умолчанию (без второго аргумента)
printf '%s' "$(run google.com)" | grep -qF "${EXP_A}" && ok "google.com → A ${EXP_A} (тип по умолчанию)" || no "A-запись не разобрана"

# TEST 5: явный тип MX передан в dig
printf '%s' "$(run google.com MX)" | grep -q "gmail-smtp-in" && ok "google.com MX → mail exchange" || no "MX-запись не разобрана"

# TEST 6: выведены ВСЕ значения многозначного ответа, а не только первое
mx_out="$(run google.com MX)"
if printf '%s' "${mx_out}" | grep -q "5 gmail-smtp-in" && printf '%s' "${mx_out}" | grep -q "10 alt1"; then
    ok "выведены все ${EXP_MX_N} записи MX"
else
    no "выведена только часть ответа (взят head -1?)"
fi

# TEST 7: счётчик совпадает с числом записей из мока
printf '%s' "${mx_out}" | grep -qE "Записей: ${EXP_MX_N}([^0-9]|$)" && ok "счётчик записей = ${EXP_MX_N}" || no "неверный счётчик (ожидалось ${EXP_MX_N})"

# TEST 8: счётчик согласован с числом напечатанных значений
printed="$(printf '%s\n' "${mx_out}" | grep -cE '^[0-9]+ ')"
[ "${printed}" -eq "${EXP_MX_N}" ] && ok "счётчик согласован с выводом" || no "напечатано ${printed} записей, а счётчик другой"

# TEST 9: другой тип (TXT) тоже проходит
printf '%s' "$(run google.com TXT)" | grep -q "v=spf1" && ok "google.com TXT → SPF-запись" || no "TXT-запись не разобрана"

# TEST 10: несуществующий домен → ненулевой код
run nxdomain.test >/dev/null 2>&1; [ $? -ne 0 ] && ok "nxdomain.test → ненулевой exit" || no "не обработан отсутствующий домен"

# TEST 11: существующий домен, но записи такого типа нет → тоже ненулевой код и без «Записей: 1»
empty_out="$(run google.com AAAA 2>&1)"; empty_rc=$?
if [ "${empty_rc}" -ne 0 ] && ! printf '%s' "${empty_out}" | grep -qE 'Записей: [1-9]'; then
    ok "пустой ответ у существующего домена → ошибка, счётчик не печатается"
else
    no "пустой ответ обработан как успех (dig возвращает 0 и при отсутствии записи)"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
