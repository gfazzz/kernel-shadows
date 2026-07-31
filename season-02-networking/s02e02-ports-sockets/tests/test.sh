#!/usr/bin/env bash
#
# s02e02 «Что слушает на сервере» — воспроизводимый unit-тест (без root, БЕЗ сети).
# Принцип mock-first (§5.3): ss подменяется мок-версией с фиксированным выводом
# LISTEN-сокетов. Так тест зелёный на любой машине.
#
# Выбор артефакта: SUBJECT=... | <серия>/check_ports.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                       then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/check_ports.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/check_ports.sh"
elif [ -f "${SERIES_DIR}/check_ports.sh" ];       then SCRIPT="${SERIES_DIR}/check_ports.sh"
else SCRIPT="${SERIES_DIR}/solution/check_ports.sh"
     echo "ℹ️  Свой check_ports.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/check_ports.sh artifacts/check_ports.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e02 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s02e02)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Мок ss: реалистичный вывод -tln.
#   [::]:80        — IPv6-сокет: ломает разбор по ПЕРВОМУ двоеточию;
#   22 дважды      — дубликат на разных адресах: проверяет sort -u;
#   44 при 443 в allowlist — ловушка для сверки по подстроке (grep без -x/-F);
#   9200 и 4444    — неожиданные: забытый Elasticsearch и чужой сервис.
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/ss" <<'MOCK'
#!/usr/bin/env bash
cat <<'OUT'
State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
LISTEN 0      128    0.0.0.0:22          0.0.0.0:*
LISTEN 0      128    10.50.1.100:22      0.0.0.0:*
LISTEN 0      128    [::]:80             [::]:*
LISTEN 0      128    127.0.0.1:443       0.0.0.0:*
LISTEN 0      128    0.0.0.0:44          0.0.0.0:*
LISTEN 0      128    0.0.0.0:9200        0.0.0.0:*
LISTEN 0      128    0.0.0.0:4444        0.0.0.0:*
OUT
MOCK
chmod +x "${FAKEBIN}/ss"

ALLOW="${TEST_ROOT}/allow.txt"
printf '22\n80\n443\n' > "${ALLOW}"

# Ожидания ВЫЧИСЛЯЮТСЯ по выводу мока, а не записаны константами.
EXP_PORTS="$(PATH="${FAKEBIN}:${PATH}" ss -tln | awk 'NR>1{print $4}' | sed 's/.*://' | grep -E '^[0-9]+$' | sort -un)"
EXP_FLAGGED=0
for p in ${EXP_PORTS}; do grep -qxF "${p}" "${ALLOW}" || EXP_FLAGGED=$((EXP_FLAGGED + 1)); done

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "check_ports.sh найден" || no "check_ports.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${ALLOW}" 2>/dev/null)" || true

CHECK="$(printf '%s\n' "${OUT}" | sed -n '/--- Проверка/,$p')"
FLAGGED_LINES="$(printf '%s\n' "${CHECK}" | grep -E 'НЕ в allowlist|неожид' | grep -vi 'Неожиданных портов')"

# TEST 4: показаны слушающие сокеты
printf '%s' "${OUT}" | grep -q ":22" && printf '%s' "${OUT}" | grep -q ":4444" \
    && ok "показаны слушающие сокеты (вкл. 4444)" || no "не показаны слушающие сокеты"

# TEST 5: разрешённый порт отмечен разрешённым
printf '%s' "${CHECK}" | grep -qE '22.*разрешён' && ok "22 → разрешён (в allowlist)" || no "22 не отмечен разрешённым"

# TEST 6: ЛОВУШКА IPv6 — порт 80 должен попасть В ПРОВЕРКУ, а не только в сырой список
printf '%s' "${CHECK}" | grep -qE '(^|[^0-9])80([^0-9]|$)' \
    && ok "порт 80 извлечён из IPv6-сокета [::]:80" \
    || no "порт из [::]:80 не извлечён — разбор идёт по первому двоеточию"

# TEST 7: неожиданные помечены — оба (9200 и 4444)
if printf '%s' "${FLAGGED_LINES}" | grep -q '4444' && printf '%s' "${FLAGGED_LINES}" | grep -q '9200'; then
    ok "неожиданные порты помечены (9200 и 4444)"
else
    no "не помечены все неожиданные порты"
fi

# TEST 8: счётчик совпадает с посчитанным по моку и allowlist
printf '%s' "${OUT}" | grep -qE "Неожиданных портов: ${EXP_FLAGGED}([^0-9]|$)" \
    && ok "счётчик неожиданных = ${EXP_FLAGGED}" || no "неверный счётчик (ожидалось ${EXP_FLAGGED})"

# TEST 9: счётчик согласован с числом помеченных строк
n_lines="$(printf '%s\n' "${FLAGGED_LINES}" | grep -c .)"
[ "${n_lines}" -eq "${EXP_FLAGGED}" ] && ok "счётчик согласован со строками отчёта" \
    || no "помеченных строк ${n_lines}, а в счётчике ${EXP_FLAGGED}"

# TEST 10: разрешённые порты не флагуются
printf '%s' "${FLAGGED_LINES}" | grep -qE '(^|[^0-9])(22|80|443)([^0-9]|$)' \
    && no "разрешённый порт ошибочно помечен неожиданным" || ok "разрешённые порты не флагуются"

# TEST 11: ЛОВУШКА подстроки — порт 44 не в allowlist, но «44» есть внутри строки «443»
printf '%s' "${FLAGGED_LINES}" | grep -qE '(^|[^0-9])44([^0-9]|$)' \
    && ok "сверка со списком идёт по целой строке" \
    || no "порт 44 принят за разрешённый — совпадение с подстрокой «443» (нужен grep -qxF)"

# TEST 12: дубликат 22 на двух адресах не удвоился в проверке
dups="$(printf '%s\n' "${CHECK}" | grep -cE '(^|[^0-9])22 — разрешён')"
[ "${dups}" -le 1 ] && ok "дубликаты портов не удваиваются (sort -u)" || no "порт 22 проверен дважды — нет sort -u"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
