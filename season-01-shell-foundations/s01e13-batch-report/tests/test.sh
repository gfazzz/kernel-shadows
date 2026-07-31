#!/usr/bin/env bash
#
# s01e13 «Отчёт о готовности» (капстоун Season 1) — воспроизводимый unit-тест.
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
echo " s01e13 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e13)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# мок dpkg: -l <pkg> → "ii ... версия ..."; --print-architecture → amd64
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/dpkg" <<'MOCK'
#!/usr/bin/env bash
case "${1:-}" in
  --print-architecture) echo "amd64" ;;
  -l)
     case "$2" in
       git)  echo "ii  git  2.34.1-1  amd64  fast VCS" ;;
       curl) echo "ii  curl 7.81.0-1  amd64  http client" ;;
       jq)   echo "ii  jq   1.6-2      amd64  json" ;;
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
htop           # НЕ установлен
ufw            # НЕ установлен
EOF
REPORT="${TEST_ROOT}/install_report.txt"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "${NAME} найден" || no "${NAME} не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" "${REPORT}" 2>/dev/null)" || true
RC="$(cat "${REPORT}" 2>/dev/null || true)"

# TEST 4: отчёт создан
[ -f "${REPORT}" ] && ok "отчёт создан" || no "отчёт не создан"
# TEST 5: установленный пакет с версией
printf '%s' "${RC}" | grep -qE 'git.*2\.34\.1' && ok "git показан установленным с версией" || no "нет git с версией"
# TEST 6: отсутствующий помечен
printf '%s' "${RC}" | grep -qE 'htop.*НЕ установ' && ok "htop помечен отсутствующим" || no "htop не помечен отсутствующим"
# TEST 7: статистика 3/5
printf '%s' "${RC}" | grep -qE 'Установлено из списка: 3 / 5' && ok "статистика 3 / 5" || no "неверная статистика (ожидалось 3 / 5)"
# TEST 8: batch one-liner с xargs
printf '%s' "${RC}" | grep -q 'xargs' && printf '%s' "${RC}" | grep -q 'apt install' && ok "есть batch one-liner (xargs | apt install)" || no "нет batch one-liner"
# TEST 9: комментарий не обработан как пакет (уникальный маркер только в комментарии)
printf '%s' "${RC}" | grep -q "базовый тулкит" && no "строка-комментарий обработана как пакет" || ok "комментарии/пустые пропущены"
# TEST 10: нет файла → ненулевой exit
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
