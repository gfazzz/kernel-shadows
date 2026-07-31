#!/usr/bin/env bash
#
# s02e05 «Ловим подмену DNS» (капстоун ep06) — воспроизводимый unit-тест (без root, БЕЗ сети).
# Мокает dig: один домен (shadow-05) резолвится в IP Крылова вместо эталона (подмена).
#
# Выбор артефакта: SUBJECT=... | <серия>/dns_guard.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                     then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/dns_guard.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/dns_guard.sh"
elif [ -f "${SERIES_DIR}/dns_guard.sh" ];       then SCRIPT="${SERIES_DIR}/dns_guard.sh"
else SCRIPT="${SERIES_DIR}/solution/dns_guard.sh"
     echo "ℹ️  Свой dns_guard.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/dns_guard.sh artifacts/dns_guard.sh"; echo ""
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
  multi.ops.internal)     echo "10.50.1.30"; echo "10.50.1.31" ;;  # несколько A-записей
  gone.ops.internal)      ;;                          # НЕТ ответа вовсе
  broken.ops.internal)    echo "10.50.1.99" ;;        # эталон в baseline не указан
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
multi.ops.internal 10.50.1.30
gone.ops.internal 10.50.1.77
broken.ops.internal
EOF

# Ожидания ВЫЧИСЛЯЮТСЯ прогоном мока по baseline, а не записаны константами.
EXP_OK=0; EXP_SPOOF=0
while IFS= read -r l; do
    [ -z "${l}" ] && continue
    case "${l}" in \#*) continue ;; esac
    d="${l%% *}"; e="${l##* }"
    a="$(PATH="${FAKEBIN}:${PATH}" dig "${d}" A +short 2>/dev/null | head -1)"
    if [ -n "${a}" ] && [ -n "${e}" ] && [ "${d}" != "${e}" ] && [ "${a}" = "${e}" ]; then
        EXP_OK=$((EXP_OK + 1))
    else
        EXP_SPOOF=$((EXP_SPOOF + 1))
    fi
done < "${BASE}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "dns_guard.sh найден" || no "dns_guard.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${BASE}" 2>&1)" || true

FLAG_RE='ПОДМЕН|⚠'

# TEST 4: отравленный домен обнаружен
printf '%s\n' "${OUT}" | grep -E "${FLAG_RE}" | grep -q 'shadow-05' && ok "shadow-05 → обнаружена подмена" || no "подмена shadow-05 не обнаружена"

# TEST 5: в сообщении видны ОБА адреса — полученный и ожидаемый
sp_line="$(printf '%s\n' "${OUT}" | grep -m1 'shadow-05')"
if printf '%s' "${sp_line}" | grep -q '185\.220\.101\.52' && printf '%s' "${sp_line}" | grep -q '10\.50\.1\.20'; then
    ok "в сообщении есть и полученный, и ожидаемый адрес"
else
    no "в сообщении о подмене не хватает одного из адресов"
fi

# TEST 6: совпавший домен не флагуется
printf '%s\n' "${OUT}" | grep -E "${FLAG_RE}" | grep -q 'shadow-01' \
    && no "совпавший shadow-01 помечен как подмена" || ok "shadow-01 → совпадает, не флагуется"

# TEST 7: несколько A-записей — первая совпадает с эталоном, домен не флагуется
printf '%s\n' "${OUT}" | grep -E "${FLAG_RE}" | grep -q 'multi' \
    && no "домен с несколькими A-записями ошибочно помечен подменой" || ok "несколько A-записей: первая сверена с эталоном"

# TEST 8: ЛОВУШКА — домен без ответа не должен считаться совпавшим
printf '%s\n' "${OUT}" | grep -E "${FLAG_RE}" | grep -q 'gone' \
    && ok "домен без ответа → расхождение, а не совпадение" \
    || no "домен без ответа принят за совпавший (пустое сравнено с пустым)"

# TEST 9: ЛОВУШКА — строка эталона без адреса не даёт тихое «ОК»
printf '%s\n' "${OUT}" | grep -E "${FLAG_RE}" | grep -q 'broken' \
    && ok "строка эталона без адреса не принята за совпадение" \
    || no "строка без эталонного адреса обработана как совпавшая"

# TEST 10: итог совпадает с посчитанным по моку и baseline
printf '%s' "${OUT}" | grep -qE "OK=${EXP_OK}([^0-9]|$)" && printf '%s' "${OUT}" | grep -qE "SPOOFED=${EXP_SPOOF}([^0-9]|$)" \
    && ok "итог OK=${EXP_OK} SPOOFED=${EXP_SPOOF}" || no "неверный итог (ожидалось OK=${EXP_OK} SPOOFED=${EXP_SPOOF})"

# TEST 11: ALERT при подмене И он идёт в stderr
ERR="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${BASE}" 2>&1 >/dev/null)"
printf '%s' "${ERR}" | grep -q "ALERT" && ok "ALERT выдан в stderr" || no "ALERT отсутствует в stderr"

# TEST 12: нет baseline → ненулевой exit
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет baseline → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
