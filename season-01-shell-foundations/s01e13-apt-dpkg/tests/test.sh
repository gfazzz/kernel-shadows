#!/usr/bin/env bash
#
# s01e13 «Что уже стоит?» — воспроизводимый unit-тест (без root, БЕЗ apt/dpkg на хосте).
#
# Принцип mock-first (§5.3): реальный dpkg трогает систему и требует Ubuntu.
# Подменяем dpkg мок-версией в PATH: "установленные" пакеты (git/curl/jq) → строка "ii",
# остальные → пусто/exit 1. Так тест зелёный на любой машине (Linux/macOS/WSL) без root.
#
# Выбор артефакта: SUBJECT=... | <серия>/pkg_check.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                       then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/pkg_check.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/pkg_check.sh"
elif [ -f "${SERIES_DIR}/pkg_check.sh" ];         then SCRIPT="${SERIES_DIR}/pkg_check.sh"
else SCRIPT="${SERIES_DIR}/solution/pkg_check.sh"
     echo "ℹ️  Свой pkg_check.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/pkg_check.sh artifacts/pkg_check.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e13 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e13)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Мок dpkg. Три состояния, как в жизни:
#   ii — установлен нормально;
#   rc — УДАЛЁН, остались только конфиги (строка есть, пакета нет — ловушка);
#   отсутствует вовсе — ненулевой код возврата.
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/dpkg" <<'MOCK'
#!/usr/bin/env bash
if [ "$1" = "-l" ]; then
    case "$2" in
        git|curl|jq) echo "ii  $2  1.2.3-1  amd64  mock package" ;;
        htop)        echo "rc  htop  3.0.5-7  amd64  removed, config files remain" ;;
        *) exit 1 ;;
    esac
    exit 0
fi
exit 0
MOCK
chmod +x "${FAKEBIN}/dpkg"

# фикстура-манифест (без docker-ce — T3: тяжёлые тулы ставятся, когда изучаются)
LIST="${TEST_ROOT}/required_tools.txt"
cat > "${LIST}" <<'EOF'
# OPERATION KERNEL SHADOWS — базовый инструментарий

git            # version control
curl           # http client
jq             # json processor
htop           # в моке состояние rc — УДАЛЁН, остались конфиги
tree           # в моке отсутствует вовсе
EOF

# Ожидания ВЫЧИСЛЯЮТСЯ прогоном мока по манифесту, а не записаны константами.
EXP_INST=0; EXP_MISS=0
while IFS= read -r l; do
    [ -z "${l}" ] && continue
    case "${l}" in \#*) continue ;; esac
    p="${l%% *}"
    if PATH="${FAKEBIN}:${PATH}" dpkg -l "${p}" 2>/dev/null | grep -q '^ii'; then
        EXP_INST=$((EXP_INST + 1))
    else
        EXP_MISS=$((EXP_MISS + 1))
    fi
done < "${LIST}"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "pkg_check.sh найден" || no "pkg_check.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" 2>/dev/null)" || true

# TEST 4: установленные распознаны (git)
printf '%s' "${OUT}" | grep -qE 'git.*[^Е]установл' && ok "git помечен установленным" || no "git не распознан как установленный"

# TEST 5: полностью отсутствующий пакет распознан (tree)
printf '%s' "${OUT}" | grep -qE 'tree.*НЕ установл' && ok "tree помечен отсутствующим" || no "tree не распознан как отсутствующий"

# TEST 6: ЛОВУШКА — htop в состоянии rc не должен считаться установленным
printf '%s' "${OUT}" | grep -qE 'htop.*НЕ установл' \
    && ok "пакет в состоянии rc не принят за установленный" \
    || no "htop (rc — удалён, остались конфиги) принят за установленный: проверять надо '^ii'"

# TEST 7: итог — установлено
printf '%s' "${OUT}" | grep -qE "Установлено: ${EXP_INST}([^0-9]|$)" \
    && ok "итог: установлено ${EXP_INST}" || no "неверный счёт установленных (ожидалось ${EXP_INST})"

# TEST 8: итог — отсутствует
printf '%s' "${OUT}" | grep -qE "Отсутствует: ${EXP_MISS}([^0-9]|$)" \
    && ok "итог: отсутствует ${EXP_MISS}" || no "неверный счёт отсутствующих (ожидалось ${EXP_MISS})"

# TEST 9: сумма сходится с числом пакетов в манифесте
[ "$((EXP_INST + EXP_MISS))" -eq 5 ] && ok "манифест разобран целиком (5 пакетов)" \
    || no "разобрано $((EXP_INST + EXP_MISS)) пакетов вместо 5"

# TEST 10: комментарий-строка не обработана как пакет
printf '%s' "${OUT}" | grep -q "OPERATION" && no "строка-комментарий обработана как пакет" || ok "комментарии/пустые пропущены"

# TEST 11: inline-комментарий не попал в имя пакета
printf '%s' "${OUT}" | grep -q "version control" && no "комментарий после имени попал в имя пакета" || ok "inline-комментарии отрезаны"

# TEST 12: нет файла → ненулевой exit
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
