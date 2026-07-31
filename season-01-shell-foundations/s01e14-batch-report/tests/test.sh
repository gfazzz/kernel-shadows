#!/usr/bin/env bash
#
# s01e14 «Отчёт о готовности» (капстоун Season 1) — воспроизводимый unit-тест.
# Без root, БЕЗ apt/dpkg на хосте: dpkg подменяется мок-версией (mock-first §5.3).
#
# Выбор артефакта: SUBJECT=... | <серия>/install_report_generator.sh | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NAME="install_report_generator.sh"

if   [ -n "${SUBJECT:-}" ];                    then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/${NAME}" ]; then SCRIPT="${SERIES_DIR}/artifacts/${NAME}"
elif [ -f "${SERIES_DIR}/${NAME}" ];           then SCRIPT="${SERIES_DIR}/${NAME}"
else SCRIPT="${SERIES_DIR}/solution/${NAME}"
     echo "ℹ️  Свой ${NAME} не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/${NAME} artifacts/${NAME}"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e14 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e14)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# Мок dpkg. Состояния как в жизни: ii (установлен), rc (удалён, конфиги остались),
# неизвестен (ненулевой код). Плюс --print-architecture для шапки отчёта.
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/dpkg" <<'MOCK'
#!/usr/bin/env bash
case "${1:-}" in
  --print-architecture) echo "amd64" ;;
  -l)
     case "$2" in
       git)  echo "ii  git  2.34.1-1  amd64  fast VCS" ;;
       curl) echo "ii  curl 7.81.0-1  amd64  http client" ;;
       jq)   echo "ii  jq   1.6-2     amd64  json" ;;
       htop) echo "rc  htop 3.0.5-7   amd64  removed, config files remain" ;;
       *) exit 1 ;;
     esac ;;
  *) exit 0 ;;
esac
MOCK
chmod +x "${FAKEBIN}/dpkg"

LIST="${TEST_ROOT}/required_tools.txt"
cat > "${LIST}" <<'EOF'
# OPERATION KERNEL SHADOWS — базовый тулкит

git            # version control
curl           # http client
jq             # json
htop           # в моке состояние rc — удалён, остались конфиги
ufw            # в моке отсутствует вовсе
EOF
REPORT="${TEST_ROOT}/install_report.txt"

# Ожидания ВЫЧИСЛЯЮТСЯ прогоном мока по манифесту, а не записаны константами.
EXP_INST=0; EXP_REQ=0
while IFS= read -r l; do
    [ -z "${l}" ] && continue
    case "${l}" in \#*) continue ;; esac
    EXP_REQ=$((EXP_REQ + 1))
    p="${l%% *}"
    PATH="${FAKEBIN}:${PATH}" dpkg -l "${p}" 2>/dev/null | grep -q '^ii' && EXP_INST=$((EXP_INST + 1))
done < "${LIST}"
EXP_GIT_VER="$(PATH="${FAKEBIN}:${PATH}" dpkg -l git | awk '/^ii/{print $3; exit}')"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "${NAME} найден" || no "${NAME} не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" "${REPORT}" 2>/dev/null)" || true
RC="$(cat "${REPORT}" 2>/dev/null || true)"

# TEST 4: отчёт создан
[ -f "${REPORT}" ] && ok "отчёт создан" || no "отчёт не создан"
# TEST 5: установленный пакет показан с ТОЧНОЙ версией из dpkg
printf '%s' "${RC}" | grep -qF "${EXP_GIT_VER}" \
    && ok "git показан с версией ${EXP_GIT_VER}" || no "нет git с версией ${EXP_GIT_VER}"

# TEST 6: версия — одна, а не склейка нескольких (awk без exit печатает всё подряд)
git_line="$(printf '%s\n' "${RC}" | grep -m1 'git')"
[ "$(printf '%s' "${git_line}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | wc -l | tr -d ' ')" -le 1 ] \
    && ok "в строке пакета одна версия" || no "в строку попало несколько версий (нужен exit в awk)"

# TEST 7: полностью отсутствующий пакет помечен
printf '%s' "${RC}" | grep -qE 'ufw.*НЕ установ' && ok "ufw помечен отсутствующим" || no "ufw не помечен отсутствующим"

# TEST 8: ЛОВУШКА — пакет в состоянии rc не считается установленным
printf '%s' "${RC}" | grep -qE 'htop.*НЕ установ' \
    && ok "пакет в состоянии rc не принят за установленный" \
    || no "htop (rc — удалён, остались конфиги) принят за установленный: проверять надо '^ii'"

# TEST 9: статистика совпадает с посчитанной по моку
printf '%s' "${RC}" | grep -qE "Установлено из списка: ${EXP_INST} / ${EXP_REQ}([^0-9]|$)" \
    && ok "статистика ${EXP_INST} / ${EXP_REQ}" \
    || no "неверная статистика (ожидалось ${EXP_INST} / ${EXP_REQ})"

# TEST 10: итог согласован с самими строками отчёта (а не взят из длины списка)
marks="$(printf '%s\n' "${RC}" | grep -c '✓')"
[ "${marks}" -eq "${EXP_INST}" ] && ok "итог согласован со строками отчёта" \
    || no "строк «✓» ${marks}, а в итоге ${EXP_INST} — счётчик считает не то"

# TEST 11: краткая сводка на экране совпадает с отчётом.
# Ловит сборку отчёта в ПОДОБОЛОЧКЕ ( … ): внутри счётчики верные, снаружи — нули.
printf '%s' "${OUT}" | grep -qE "${EXP_INST} / ${EXP_REQ}([^0-9]|$)" \
    && ok "сводка на экране совпадает с отчётом" \
    || no "сводка на экране расходится с отчётом — отчёт собран в подоболочке ( … ) вместо { … }"

# TEST 12: batch one-liner с xargs
printf '%s' "${RC}" | grep -q 'xargs' && printf '%s' "${RC}" | grep -q 'apt install' \
    && ok "есть batch one-liner (xargs | apt install)" || no "нет batch one-liner"

# TEST 13: шапка отчёта содержит архитектуру (dpkg --print-architecture)
printf '%s' "${RC}" | grep -q 'amd64' && ok "в шапке есть архитектура" || no "нет архитектуры в шапке"

# TEST 14: комментарий не обработан как пакет
printf '%s' "${RC}" | grep -q "базовый тулкит" && no "строка-комментарий обработана как пакет" || ok "комментарии/пустые пропущены"

# TEST 15: нет файла → ненулевой exit
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
