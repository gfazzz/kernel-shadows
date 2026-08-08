#!/usr/bin/env bash
#
# s04e02 «Перед тем как нажать» — тест скрипта (Type A).
#
# Тест сам создаёт репозитории во временном каталоге: чистый и пять
# испорченных, по одному нарушению в каждом. Скрипт обязан промолчать на
# чистом, отказать на каждом испорченном и назвать коммит и файл.
#
# Отдельно проверяется, что скрипт НИЧЕГО не меняет в репозитории:
# хеш HEAD и список файлов до и после совпадают.
#
# Без root, без сети. Нужен `git`.
#
# Выбор скрипта: SUBJECT=... | artifacts/prepush_check.sh | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                              then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/prepush_check.sh" ];  then SCRIPT="${SERIES_DIR}/artifacts/prepush_check.sh"
elif [ -f "${SERIES_DIR}/prepush_check.sh" ];            then SCRIPT="${SERIES_DIR}/prepush_check.sh"
else SCRIPT="${SERIES_DIR}/solution/prepush_check.sh"
     echo "ℹ️  Свой prepush_check.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/prepush_check.sh artifacts/prepush_check.sh"; echo ""
fi
SCRIPT="$(cd "$(dirname "${SCRIPT}")" && pwd)/$(basename "${SCRIPT}")"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e02 tests — скрипт: ${SCRIPT##*/s04e02-branches-prepush/}"
echo "════════════════════════════════════════════════════════════"

command -v git >/dev/null 2>&1 || { echo "  SKIP: git не установлен"; exit 0; }
if [ -f "${SCRIPT}" ]; then ok "скрипт prepush_check.sh найден"
else no "prepush_check.sh не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# mkrepo <имя> — репозиторий с main и веткой work, три чистых коммита
mkrepo() {
    local r="${TMP}/$1"
    mkdir -p "${r}"; cd "${r}"
    git init -q; git symbolic-ref HEAD refs/heads/main
    git config user.name t; git config user.email t@t
    git config commit.gpgsign false
    printf 'ops\n' > README.md; git add README.md
    GIT_AUTHOR_DATE='2025-10-25T09:00:00+0000' GIT_COMMITTER_DATE='2025-10-25T09:00:00+0000' \
      git commit -q -m base
    git switch -q -c work
    printf 'echo hi\n' > run.sh; git add run.sh
    GIT_AUTHOR_DATE='2025-10-25T10:00:00+0000' GIT_COMMITTER_DATE='2025-10-25T10:00:00+0000' \
      git commit -q -m "скрипт"
    cd - >/dev/null
    printf '%s' "${r}"
}
add_commit() {  # add_commit <репо> <файл> <сообщение>
    ( cd "$1" && git add -A && \
      GIT_AUTHOR_DATE='2025-10-25T11:00:00+0000' GIT_COMMITTER_DATE='2025-10-25T11:00:00+0000' \
      git commit -q -m "$3" )
}
run() { bash "${SCRIPT}" --repo "$1" "${@:2}" >"${TMP}/out" 2>"${TMP}/err"; }
out() { cat "${TMP}/out" "${TMP}/err" 2>/dev/null; }

# ---- 1. дисциплина -----------------------------------------------------------
head -1 "${SCRIPT}" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash' \
  && ok "шебанг на месте" || no "нет строки #!/usr/bin/env bash"
grep -qE '^set -[euo]+' "${SCRIPT}" && ok "set -e/-u включён" || no "нет set -euo pipefail"

# ---- 2. чистый репозиторий ---------------------------------------------------
CLEAN="$(mkrepo clean)"
if run "${CLEAN}"; then ok "чистый репозиторий пропущен (код 0)"
else no "чистый репозиторий отвергнут: $(out | tail -1)"; fi

# ---- 3. на основной ветке ----------------------------------------------------
ONMAIN="$(mkrepo onmain)"; ( cd "${ONMAIN}" && git switch -q main )
if run "${ONMAIN}"; then
    no "отправка прямо из основной ветки разрешена"
else
    ok "отправка из основной ветки отклонена"
fi
out | grep -qiE 'main|основн|ветк' && ok "причина названа: основная ветка" \
                                   || no "непонятно, почему отказ на main"

# ---- 4. секрет в коммите -----------------------------------------------------
SEC="$(mkrepo secret)"
printf 'DB_PASSWORD=Sh4dow-Pr0d-2025!\n' > "${SEC}/config.ini"
add_commit "${SEC}" config.ini "конфигурация"
if run "${SEC}"; then no "секрет в коммите пропущен"; else ok "секрет в коммите отклонён"; fi
out | grep -q 'config.ini' && ok "назван файл с секретом" || no "файл с секретом не назван"
out | grep -qE '[0-9a-f]{7}' && ok "назван коммит с секретом" || no "коммит не назван"

# ---- 5. приватный ключ по имени файла ----------------------------------------
KEY="$(mkrepo key)"
printf 'not-a-real-key\n' > "${KEY}/deploy.pem"
add_commit "${KEY}" deploy.pem "ключ выката"
if run "${KEY}"; then no "файл .pem пропущен"; else ok "файл .pem отклонён по имени"; fi
out | grep -q 'deploy.pem' && ok "назван запрещённый файл" || no "запрещённый файл не назван"

# ---- 6. слишком большой файл -------------------------------------------------
BIG="$(mkrepo big)"
head -c 200000 /dev/zero | tr '\0' 'x' > "${BIG}/dump.txt"
add_commit "${BIG}" dump.txt "выгрузка"
if run "${BIG}" --max-size 100; then no "файл 200 КБ пропущен при пределе 100"; else ok "слишком большой файл отклонён"; fi
if run "${BIG}" --max-size 500; then ok "--max-size 500 пропускает тот же файл"; else no "--max-size не влияет на решение"; fi

# ---- 7. конфликтные маркеры --------------------------------------------------
CONF="$(mkrepo conflict)"
printf 'a\n<<<<<<< HEAD\nb\n=======\nc\n>>>>>>> other\n' > "${CONF}/app.conf"
add_commit "${CONF}" app.conf "правка"
if run "${CONF}"; then no "конфликтные маркеры пропущены"; else ok "конфликтные маркеры отклонены"; fi
out | grep -q 'app.conf' && ok "назван файл с маркерами" || no "файл с маркерами не назван"

# ---- 8. смотрит только на то, что уйдёт --------------------------------------
# секрет лежит в САМОМ ПЕРВОМ коммите, то есть в базовой ветке и в предках work.
# Диапазон base..HEAD его не содержит; проверка всей истории — содержит.
RANGE="${TMP}/range"; mkdir -p "${RANGE}"; ( cd "${RANGE}"
    git init -q; git symbolic-ref HEAD refs/heads/main
    git config user.name t; git config user.email t@t; git config commit.gpgsign false
    printf 'DB_PASSWORD=Sh4dow-Pr0d-2025!\n' > old.ini
    printf 'ops\n' > README.md
    git add -A
    GIT_AUTHOR_DATE='2025-10-25T09:00:00+0000' GIT_COMMITTER_DATE='2025-10-25T09:00:00+0000' \
      git commit -q -m "старое, уже отправленное"
    git switch -q -c work
    printf 'echo hi\n' > run.sh; git add run.sh
    GIT_AUTHOR_DATE='2025-10-25T10:00:00+0000' GIT_COMMITTER_DATE='2025-10-25T10:00:00+0000' \
      git commit -q -m "чистый коммит" )
if run "${RANGE}"; then
    ok "проверяются только коммиты, которых нет в базовой ветке"
else
    no "скрипт ругается на то, что уже есть в базовой ветке: $(out | tail -1)"
fi

# ---- 9. репозиторий не изменён ------------------------------------------------
SIG_BEFORE="$(cd "${SEC}" && git rev-parse HEAD; git -C "${SEC}" status --porcelain)"
run "${SEC}" || true
SIG_AFTER="$(cd "${SEC}" && git rev-parse HEAD; git -C "${SEC}" status --porcelain)"
if [ "${SIG_BEFORE}" = "${SIG_AFTER}" ]; then
    ok "репозиторий не изменён проверкой"
else
    no "скрипт изменил репозиторий — проверка должна только читать"
fi

# ---- 10. ошибки вызова -------------------------------------------------------
if run "${TMP}/не-репозиторий"; then
    no "каталог без репозитория принят молча"
else
    ok "каталог без репозитория отвергнут"
fi
[ -s "${TMP}/err" ] && ok "сообщения об ошибках уходят в stderr" \
                    || no "об ошибке не сказано в stderr"

# ---- 11. воспроизводимость ---------------------------------------------------
A="$(run "${SEC}" >/dev/null 2>&1; echo $?)"
B="$(LC_ALL=C TZ=Pacific/Auckland bash "${SCRIPT}" --repo "${SEC}" >/dev/null 2>&1; echo $?)"
if [ "${A}" = "${B}" ]; then
    ok "решение не зависит от локали и часового пояса"
else
    no "код возврата меняется от локали: ${A} против ${B}"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
