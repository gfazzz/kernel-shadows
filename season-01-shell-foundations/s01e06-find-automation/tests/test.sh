#!/usr/bin/env bash
#
# s01e06 «Инвентаризация дампа» — тест инструмента (Type A).
#
# Запускает скрипт студента на фикстуре-дереве с известным составом и сверяет
# четыре факта. Эталонные числа НЕ захардкожены: они пересчитываются из той же
# фикстуры независимыми командами.
#
# Без root, без сети. Фикстура во временном TEST_ROOT, удаляется автоматически.
#
# Выбор артефакта: SUBJECT=... | artifacts/audit_tree.sh | <серия>/audit_tree.sh | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NAME="audit_tree.sh"

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
echo " s01e06 tests — subject: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- фикстура: дамп с сервера, файлы на разной глубине ---------------------
TEST_ROOT="$(mktemp -d 2>/dev/null || mktemp -d -t s01e06)"
trap 'rm -rf "${TEST_ROOT}"' EXIT
DUMP="${TEST_ROOT}/dump"
mkdir -p "${DUMP}/etc/nginx" "${DUMP}/var/log/app" "${DUMP}/home/ops/.ssh" "${DUMP}/srv/a/b/c"

printf 'server{}\n'    > "${DUMP}/etc/nginx/nginx.conf"
printf 'listen=80\n'   > "${DUMP}/etc/app.conf"
printf 'deep config\n' > "${DUMP}/srv/a/b/c/deep.conf"        # глубоко — нужна рекурсия
printf 'PRIVATE KEY\n' > "${DUMP}/home/ops/.ssh/.id_backup"   # скрытый
printf 'secret=1\n'    > "${DUMP}/home/ops/.env"              # скрытый
printf 'note\n'        > "${DUMP}/home/ops/readme.txt"
head -c 40000 /dev/zero | tr '\0' 'x' > "${DUMP}/var/log/app/big.log"  # самый большой
printf 'tiny\n'        > "${DUMP}/var/log/app/small.log"

# ---- эталон: пересчитывается из фикстуры независимо ------------------------
exp_files=$(find "${DUMP}" -type f | wc -l | tr -d ' ')
exp_conf=$(find "${DUMP}" -type f -name '*.conf' | wc -l | tr -d ' ')
exp_hidden=$(find "${DUMP}" -type f -name '.*' | wc -l | tr -d ' ')
exp_largest=$(find "${DUMP}" -type f -exec du -k {} + 2>/dev/null | sort -rn | head -1 | cut -f2- | xargs basename)

# ---- TEST 1-3: базовая пригодность ----------------------------------------
if [ -f "${SCRIPT}" ]; then
    ok "${NAME} найден"
else
    no "${NAME} не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi
bash -n "${SCRIPT}" 2>/dev/null && ok "синтаксис bash корректен" || no "ошибка синтаксиса"
head -1 "${SCRIPT}" | grep -q '^#!.*sh' && ok "есть shebang" || no "нет shebang"

OUT="$(bash "${SCRIPT}" "${DUMP}" 2>/dev/null)" || true

val(){ printf '%s\n' "${OUT}" | grep -E "^$1=" | tail -1 | cut -d= -f2- | tr -d ' \r'; }

check(){  # check <ключ> <эталон> <описание>
    local got; got="$(val "$1")"
    if [ -z "${got}" ]; then no "$3: значение не выведено ($1=)"
    elif [ "${got}" = "$2" ]; then ok "$3: ${got}"
    else no "$3: получено '${got}', в дереве '$2'"; fi
}

check files    "${exp_files}"   "всего файлов (рекурсивно)"
check configs  "${exp_conf}"    "конфигов *.conf"
check hidden   "${exp_hidden}"  "скрытых файлов"
check largest  "${exp_largest}" "самый большой файл"

# ---- TEST 8: инструмент работает на ЛЮБОМ дереве --------------------------
OTHER="${TEST_ROOT}/other"
mkdir -p "${OTHER}/x"
printf 'a\n' > "${OTHER}/x/one.conf"; printf 'b\n' > "${OTHER}/x/.two"
OUT2="$(bash "${SCRIPT}" "${OTHER}" 2>/dev/null)" || true
if [ "$(printf '%s\n' "${OUT2}" | grep -E '^files=' | cut -d= -f2 | tr -d ' \r')" = "2" ]; then
    ok "инструмент переносим: на другом дереве считает заново"
else
    no "на другом дереве результат неверен (числа привязаны к конкретной фикстуре?)"
fi

# ---- TEST 9: дискриминатор — без рекурсии верхний уровень почти пуст -------
flat_files=$(find "${DUMP}" -maxdepth 1 -type f | wc -l | tr -d ' ')
if [ "${exp_files}" -gt "${flat_files}" ]; then
    ok "самопроверка: на верхнем уровне ${flat_files} файлов из ${exp_files} — без рекурсии не сосчитать"
else
    no "самопроверка: фикстура вырождена, рекурсия не требуется"
fi

# ---- TEST 10: несуществующий каталог → ненулевой выход --------------------
bash "${SCRIPT}" "${TEST_ROOT}/nope" >/dev/null 2>&1
[ $? -ne 0 ] && ok "нет каталога → ненулевой exit" || no "не обработан отсутствующий каталог"

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
