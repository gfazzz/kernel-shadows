#!/usr/bin/env bash
#
# s01e05 «Детектив и автоматизация» — воспроизводимый unit-тест (fixture/TEST_ROOT, без root).
# Проверяет, что артефакт студента РЕКУРСИВНО находит три файла (find),
# читает их (cat) и сохраняет отчёт (report.txt). Живой хост не затрагивается.
#
# Выбор артефакта: SUBJECT=... | <серия>/find_files.sh | artifacts/ | solution/ (фолбэк).

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                          then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/find_files.sh" ]; then SCRIPT="${SERIES_DIR}/artifacts/find_files.sh"
elif [ -f "${SERIES_DIR}/find_files.sh" ];           then SCRIPT="${SERIES_DIR}/find_files.sh"
else SCRIPT="${SERIES_DIR}/solution/find_files.sh"
     echo "ℹ️  Свой find_files.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Создай своё:  cp starter/find_files.sh artifacts/find_files.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e05 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# Фикстура: файлы на РАЗНОЙ глубине — проверяем рекурсию find.
TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e05)"
trap 'rm -rf "${TEST_ROOT}"' EXIT
SRV="${TEST_ROOT}/server"
mkdir -p "${SRV}/documents" "${SRV}/a/b/c/deep"
echo "BRIEF-MARK-8842"      > "${SRV}/documents/briefing.txt"
echo "SECRET-GUM-MARK-7731" > "${SRV}/.secret_location"
echo "NEXT-IP-MARK-4420"    > "${SRV}/a/b/c/deep/.next_server"   # глубоко!
REPORT="${TEST_ROOT}/report.txt"

# TEST 1-3
[ -f "${SCRIPT}" ] && ok "find_files.sh найден" || no "find_files.sh не найден"
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

# Прогон из посторонней директории: BASE=SRV, REPORT в TEST_ROOT.
OUT="$(cd "${TEST_ROOT}" && bash "${SCRIPT}" "${SRV}" "${REPORT}" 2>/dev/null)" || true

# TEST 4: отчёт создан
[ -f "${REPORT}" ] && ok "создан файл отчёта (report.txt)" || no "отчёт не создан"

# TEST 5-7: отчёт содержит все три файла (значит, find нашёл рекурсивно, cat прочитал)
RC="$(cat "${REPORT}" 2>/dev/null || true)"
printf '%s' "${RC}" | grep -qF "BRIEF-MARK-8842"      && ok "нашёл и прочитал briefing.txt (в поддиректории)" || no "нет содержимого briefing.txt"
printf '%s' "${RC}" | grep -qF "SECRET-GUM-MARK-7731" && ok "нашёл .secret_location (скрытый)"                || no "нет .secret_location"
printf '%s' "${RC}" | grep -qF "NEXT-IP-MARK-4420"    && ok "нашёл .next_server (глубоко вложенный — рекурсия)" || no "нет .next_server (рекурсия find?)"

# TEST 8: негатив — «плоский» ls/cat без find не найдёт глубоко вложенный файл.
NAIVE="${TEST_ROOT}/naive.sh"
printf '#!/usr/bin/env bash\ncat "%s"/* 2>/dev/null\n' "${SRV}" > "${NAIVE}"
NOUT="$(bash "${NAIVE}" 2>/dev/null)" || true
if printf '%s' "${NOUT}" | grep -qF "NEXT-IP-MARK-4420"; then
    no "самопроверка: без find глубокий файл не должен находиться"
else
    ok "самопроверка: без рекурсивного find глубокий файл не найти (тест дискриминирует)"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
