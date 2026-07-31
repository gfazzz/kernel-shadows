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

# Заглушка ufw: НЕ блокирует, а фиксирует факт вызова.
# Скрипт, применяющий правила вместо генерации, будет пойман.
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
UFW_CALLS="${TEST_ROOT}/ufw_calls.log"
cat > "${FAKEBIN}/ufw" <<MOCK
#!/usr/bin/env bash
echo "\$*" >> "${UFW_CALLS}"
exit 0
MOCK
chmod +x "${FAKEBIN}/ufw"

# Фикстура: комментарии, пустые строки, комментарий сбоку, строка-мусор.
LIST="${TEST_ROOT}/botnet_ips.txt"
cat > "${LIST}" <<'EOF'
# Botnet IPs (Anna, forensics)
185.220.101.47     # Tor exit node (DE)
91.219.237.244     # Tor exit node (NL)

195.123.246.151    # Tor exit node (RO)
не знаю чей это адрес
EOF
OUT="${TEST_ROOT}/block_rules.sh"

# Ожидания ВЫЧИСЛЯЮТСЯ по фикстуре, а не записаны константами.
EXP_N=0
while IFS= read -r l; do
    [ -z "${l}" ] && continue
    case "${l}" in \#*) continue ;; esac
    i="${l%% *}"
    case "${i}" in *.*.*.*) EXP_N=$((EXP_N + 1)) ;; esac
done < "${LIST}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "block_botnet.sh найден" || no "block_botnet.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

REPORT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" "${OUT}" 2>/dev/null)" || true

# TEST 4: файл правил создан
[ -f "${OUT}" ] && ok "файл правил создан" || no "файл правил не создан"
# TEST 5: правило для каждого валидного адреса
if grep -q "ufw deny from 185.220.101.47" "${OUT}" 2>/dev/null \
   && grep -q "ufw deny from 91.219.237.244" "${OUT}" 2>/dev/null \
   && grep -q "ufw deny from 195.123.246.151" "${OUT}" 2>/dev/null; then
    ok "правила сгенерированы для всех валидных адресов"
else
    no "правила сгенерированы не для всех адресов"
fi

# TEST 6: число правил совпадает с посчитанным по фикстуре
n="$(grep -c 'ufw deny from' "${OUT}" 2>/dev/null || echo 0)"
[ "${n}" -eq "${EXP_N}" ] && ok "ровно ${EXP_N} правила (комментарии и пустые пропущены)" \
    || no "неверное число правил (${n}, по фикстуре ожидалось ${EXP_N})"

# TEST 7: сгенерированный файл — валидный bash
bash -n "${OUT}" 2>/dev/null && ok "сгенерированный файл — валидный bash" || no "сгенерированный файл невалиден"

# TEST 8: комментарий-строка не превратилась в правило
grep -qE 'ufw deny from #' "${OUT}" 2>/dev/null && no "комментарий попал в правило" || ok "комментарии не стали правилами"

# TEST 9: комментарий СБОКУ от адреса отрезан
grep -qE 'ufw deny from [0-9.]+ +[^ ]' "${OUT}" 2>/dev/null \
    && no "в правило попал комментарий сбоку от адреса" || ok "комментарий сбоку отрезан"

# TEST 10: ЛОВУШКА — строка-мусор не стала правилом
grep -qE 'ufw deny from [^0-9]' "${OUT}" 2>/dev/null \
    && no "строка-мусор превратилась в правило (нет проверки формата)" || ok "мусор отсеян проверкой формата"

# TEST 11: в файле есть shebang и пометка об источнике
head -1 "${OUT}" | grep -q '^#!' && grep -qiE '(источник|generated|сгенерир)' "${OUT}" \
    && ok "в файле есть shebang и пометка об источнике" || no "нет shebang или пометки об источнике"

# TEST 12: ЛОВУШКА — скрипт НЕ должен применять правила сам
if [ -s "${UFW_CALLS}" ]; then
    no "скрипт вызывал ufw во время генерации: $(head -1 "${UFW_CALLS}")"
else
    ok "правила только сгенерированы, ufw не вызывался"
fi

# TEST 13: сводка согласована с содержимым файла
printf '%s' "${REPORT}" | grep -qE "сгенерировано: ${n}([^0-9]|$)" && ok "сводка совпадает с файлом (${n})" || no "сводка не совпадает с числом правил в файле"

# TEST 14: пустой список валидных адресов → ненулевой код
EMPTY="${TEST_ROOT}/empty.txt"; printf '# только комментарии\n\n' > "${EMPTY}"
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${EMPTY}" "${TEST_ROOT}/empty_rules.sh" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет валидных адресов → ненулевой exit" || no "пустой результат принят за успех"

# TEST 15: отсутствующий список → ненулевой код
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" "${TEST_ROOT}/x.sh" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
