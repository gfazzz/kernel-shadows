#!/usr/bin/env bash
#
# s01e11 «Что уже стоит?» — воспроизводимый unit-тест (без root, БЕЗ apt/dpkg на хосте).
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
echo " s01e11 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e11)"
trap 'rm -rf "${TEST_ROOT}"' EXIT

# мок dpkg: -l <pkg> → "ii ..." для установленных, иначе exit 1
FAKEBIN="${TEST_ROOT}/bin"; mkdir -p "${FAKEBIN}"
cat > "${FAKEBIN}/dpkg" <<'MOCK'
#!/usr/bin/env bash
if [ "$1" = "-l" ]; then
    case "$2" in
        git|curl|jq) echo "ii  $2  1.2.3-1  amd64  mock package" ;;
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
htop           # НЕ установлен в фикстуре
tree           # НЕ установлен в фикстуре
EOF

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "pkg_check.sh найден" || no "pkg_check.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${LIST}" 2>/dev/null)" || true

# TEST 4: установленные распознаны (git)
printf '%s' "${OUT}" | grep -qE 'git.*установл' && ok "git помечен установленным" || no "git не распознан как установленный"
# TEST 5: отсутствующие распознаны (htop)
printf '%s' "${OUT}" | grep -qE 'htop.*НЕ установл' && ok "htop помечен отсутствующим" || no "htop не распознан как отсутствующий"
# TEST 6: итог — установлено 3
printf '%s' "${OUT}" | grep -qE 'Установлено: 3' && ok "итог: установлено 3 (git/curl/jq)" || no "неверный счёт установленных"
# TEST 7: итог — отсутствует 2
printf '%s' "${OUT}" | grep -qE 'Отсутствует: 2' && ok "итог: отсутствует 2 (htop/tree)" || no "неверный счёт отсутствующих"
# TEST 8: комментарий-строка не обработана как пакет
printf '%s' "${OUT}" | grep -q "OPERATION" && no "строка-комментарий обработана как пакет" || ok "комментарии/пустые пропущены"
# TEST 9: нет файла → ненулевой exit
PATH="${FAKEBIN}:${PATH}" bash "${SCRIPT}" "${TEST_ROOT}/nope.txt" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет файла → ненулевой exit" || no "не обработан отсутствующий файл"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
