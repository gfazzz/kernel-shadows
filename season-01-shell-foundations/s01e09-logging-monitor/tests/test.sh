#!/usr/bin/env bash
#
# s01e09 «Production-мониторинг» — воспроизводимый unit-тест (без root, БЕЗ живой сети).
# Мокает ping. Проверяет: цикл+условия, ЛОГ с таймстампами, SUMMARY, ALERT, append.
#
# Выбор артефакта: SUBJECT=... | <серия>/server_monitor.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                             then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/server_monitor.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/server_monitor.sh"
elif [ -f "${SERIES_DIR}/server_monitor.sh" ];          then SCRIPT="${SERIES_DIR}/server_monitor.sh"
else SCRIPT="${SERIES_DIR}/solution/server_monitor.sh"
     echo "ℹ️  Свой server_monitor.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/server_monitor.sh artifacts/server_monitor.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e09 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e09)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/ping" <<'MOCK'
#!/usr/bin/env bash
host="${!#}"
case "${host}" in up-*) exit 0 ;; *) exit 1 ;; esac
MOCK
chmod +x "${FAKEBIN}/ping"

LIST="${TEST_ROOT}/servers.txt"
cat > "${LIST}" <<EOF
# список узлов операции
up-server-01 10.0.0.1

down-server-01 10.0.0.9
up-server-02 10.0.0.2
EOF
LOG="${TEST_ROOT}/monitor.log"

# Ожидаемые значения ВЫЧИСЛЯЮТСЯ из фикстуры (мок отвечает только на up-*),
# а не записаны константами: правка фикстуры не разъезжается с тестом.
EXP_UP=0; EXP_DOWN=0
while IFS= read -r l; do
    [ -z "${l}" ] && continue
    case "${l}" in \#*) continue ;; esac
    case "${l%% *}" in up-*) EXP_UP=$((EXP_UP+1)) ;; *) EXP_DOWN=$((EXP_DOWN+1)) ;; esac
done < "${LIST}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "server_monitor.sh найден" || no "server_monitor.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" "${LOG}" 2>&1)" || true

# TEST 4: лог-файл создан
[ -f "${LOG}" ] && ok "создан лог-файл" || no "лог-файл не создан"

# TEST 5: в логе есть таймстамп формата YYYY-MM-DD HH:MM:SS
grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}' "${LOG}" 2>/dev/null \
    && ok "лог содержит таймстампы (date)" || no "нет таймстампов в логе"

# TEST 6: SUMMARY совпадает с посчитанным по фикстуре
printf '%s' "${OUT}" | grep -qE "UP=${EXP_UP}([^0-9]|$)" \
  && printf '%s' "${OUT}" | grep -qE "DOWN=${EXP_DOWN}([^0-9]|$)" \
    && ok "SUMMARY UP=${EXP_UP} DOWN=${EXP_DOWN}" \
    || no "неверный SUMMARY (по фикстуре ожидалось UP=${EXP_UP} DOWN=${EXP_DOWN})"

# TEST 7: ALERT при наличии DOWN — и он должен попасть В ЛОГ, а не только на экран
if printf '%s' "${OUT}" | grep -q "ALERT" && grep -q "ALERT" "${LOG}" 2>/dev/null; then
    ok "ALERT выдан и записан в лог"
else
    no "ALERT отсутствует на экране или в логе (тревога без записи не переживёт терминал)"
fi

# TEST 8: конкретные статусы записаны в лог
grep -q "up-server-01" "${LOG}" && grep -q "down-server-01" "${LOG}" \
    && ok "хосты записаны в лог" || no "хосты не в логе"

# TEST 9: мусор фикстуры (комментарий, пустая строка) не попал в лог как хост
grep -qE '\[(UP|DOWN)\][[:space:]]*(#|$)' "${LOG}" 2>/dev/null \
    && no "в лог попали комментарий/пустая строка" \
    || ok "комментарии и пустые строки пропущены"

# TEST 10: append — повторный запуск дописывает, а не затирает
before="$(wc -l < "${LOG}")"
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" "${LOG}" >/dev/null 2>&1 || true
after="$(wc -l < "${LOG}")"
[ "${after}" -gt "${before}" ] && ok "лог дополняется (>>), а не затирается" || no "повторный запуск затёр лог"

# TEST 11: первая запись первого прогона на месте после второго (история не потеряна)
head -1 "${LOG}" | grep -qE '[0-9]{4}-[0-9]{2}-[0-9]{2}' \
    && ok "начало журнала сохранилось" || no "начало журнала утрачено"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
