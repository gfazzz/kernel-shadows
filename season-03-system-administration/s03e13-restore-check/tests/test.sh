#!/usr/bin/env bash
#
# s03e13 «03:47» (финал Season 3) — тест скрипта (Type A).
#
# Строит настоящий бэкап с манифестом во временном каталоге и портит его
# тремя разными способами: испорченный файл, пропавший файл, лишний файл.
# Скрипт обязан найти каждый и назвать поимённо, вернуть ненулевой код —
# и не изменить при этом сам бэкап.
#
# Без root, без сети, без внешних утилит.
#
# Выбор скрипта: SUBJECT=... | artifacts/restore_check.sh | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                              then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/restore_check.sh" ];  then SCRIPT="${SERIES_DIR}/artifacts/restore_check.sh"
elif [ -f "${SERIES_DIR}/restore_check.sh" ];            then SCRIPT="${SERIES_DIR}/restore_check.sh"
else SCRIPT="${SERIES_DIR}/solution/restore_check.sh"
     echo "ℹ️  Свой restore_check.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/restore_check.sh artifacts/restore_check.sh"; echo ""
fi
SCRIPT="$(cd "$(dirname "${SCRIPT}")" && pwd)/$(basename "${SCRIPT}")"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e13 tests — скрипт: ${SCRIPT##*/s03e13-restore-check/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${SCRIPT}" ]; then
    ok "скрипт restore_check.sh найден"
else
    no "restore_check.sh не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then SHA() { sha256sum "$@"; }
elif command -v shasum  >/dev/null 2>&1; then SHA() { shasum -a 256 "$@"; }
else echo "  FAIL: нет ни sha256sum, ни shasum — тест выполнить нечем" >&2; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ---- эталонный бэкап с манифестом -------------------------------------------
make_backup() {   # make_backup <каталог>
    local b="$1"
    rm -rf "${b}"; mkdir -p "${b}/sub" "${b}/deep/er"
    printf 'alpha\n'   > "${b}/a.txt"
    printf 'beta\n'    > "${b}/sub/b.txt"
    printf 'gamma\n'   > "${b}/deep/er/c.txt"
    ( cd "${b}" && find . -type f ! -name '.manifest.sha256' | LC_ALL=C sort \
        | while IFS= read -r f; do SHA "${f}"; done > .manifest.sha256 )
}

run() { bash "${SCRIPT}" "$@" >"${TMP}/out" 2>"${TMP}/err"; }
out() { cat "${TMP}/out" "${TMP}/err" 2>/dev/null; }

# ---- 1. дисциплина -----------------------------------------------------------
head -1 "${SCRIPT}" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash' \
  && ok "шебанг на месте" || no "нет строки #!/usr/bin/env bash"
grep -qE '^set -[euo]+' "${SCRIPT}" \
  && ok "set -e/-u включён" || no "нет set -euo pipefail"

# ---- 2. целая копия ----------------------------------------------------------
BK="${TMP}/bk"; make_backup "${BK}"
if run --backup "${BK}" --into "${TMP}/r1" --report "${TMP}/rep1"; then
    ok "целая копия принята (код 0)"
else
    no "целая копия отвергнута: $(out | tail -1)"
fi

restored=$(find "${TMP}/r1" -type f ! -name '.manifest.sha256' 2>/dev/null | wc -l | tr -d ' ')
if [ "${restored}" -eq 3 ]; then
    ok "восстановлены все три файла, включая вложенные"
else
    no "в каталоге восстановления ${restored} файлов вместо 3"
fi
if [ -f "${TMP}/r1/deep/er/c.txt" ] && [ "$(cat "${TMP}/r1/deep/er/c.txt")" = "gamma" ]; then
    ok "содержимое и вложенность восстановлены верно"
else
    no "глубоко вложенный файл восстановлен неверно"
fi

if [ -s "${TMP}/rep1" ] && grep -qiE 'checked|проверен' "${TMP}/rep1" \
   && grep -qiE 'OK|result' "${TMP}/rep1"; then
    ok "отчёт записан и содержит итог"
else
    no "отчёт по --report не записан или в нём нет итога"
fi

# бэкап не тронут
sig_before="$(cd "${BK}" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do SHA "${f}"; done | SHA | awk '{print $1}')"

# ---- 3. испорченный файл -----------------------------------------------------
BK2="${TMP}/bk2"; make_backup "${BK2}"
printf 'ПОДМЕНА\n' > "${BK2}/sub/b.txt"
if run --backup "${BK2}" --into "${TMP}/r2"; then
    no "испорченный файл не обнаружен — код возврата 0"
else
    ok "испорченный файл: ненулевой код возврата"
fi
out | grep -q 'b.txt' \
  && ok "испорченный файл назван поимённо (b.txt)" \
  || no "в выводе нет имени испорченного файла — искать придётся вручную"

# ---- 4. пропавший файл -------------------------------------------------------
BK3="${TMP}/bk3"; make_backup "${BK3}"
rm -f "${BK3}/a.txt"
if run --backup "${BK3}" --into "${TMP}/r3"; then
    no "пропавший файл не обнаружен — код возврата 0"
else
    ok "пропавший файл: ненулевой код возврата"
fi
out | grep -q 'a.txt' \
  && ok "пропавший файл назван поимённо (a.txt)" \
  || no "в выводе нет имени пропавшего файла"

# ---- 5. лишний файл ----------------------------------------------------------
BK4="${TMP}/bk4"; make_backup "${BK4}"
printf 'чужое\n' > "${BK4}/sub/подсадка.txt"
if run --backup "${BK4}" --into "${TMP}/r4"; then
    no "лишний файл не обнаружен: в копию можно дописать что угодно незаметно"
else
    ok "лишний файл: ненулевой код возврата"
fi
out | grep -q 'подсадка' \
  && ok "лишний файл назван поимённо" \
  || no "в выводе нет имени лишнего файла"

# ---- 6. бэкап не изменён -----------------------------------------------------
sig_after="$(cd "${BK}" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do SHA "${f}"; done | SHA | awk '{print $1}')"
if [ "${sig_before}" = "${sig_after}" ]; then
    ok "сам бэкап не изменён проверкой"
else
    no "проверка изменила бэкап — единственную копию трогать нельзя"
fi

# ---- 7. отсутствие манифеста -------------------------------------------------
BK5="${TMP}/bk5"; make_backup "${BK5}"; rm -f "${BK5}/.manifest.sha256"
if run --backup "${BK5}" --into "${TMP}/r5"; then
    no "снимок без манифеста принят как целый — проверять было нечем"
else
    ok "снимок без манифеста отвергнут"
fi
out | grep -qiE 'манифест|manifest' \
  && ok "причина названа: нет манифеста" || no "непонятно, почему отказ"

# ---- 8. защита каталога восстановления ---------------------------------------
mkdir -p "${TMP}/busy"; printf 'важное\n' > "${TMP}/busy/чужой.txt"
run --backup "${BK}" --into "${TMP}/busy"
if [ -f "${TMP}/busy/чужой.txt" ]; then
    ok "непустой каталог восстановления не затёрт молча"
else
    no "чужие файлы в каталоге восстановления удалены без предупреждения"
fi

# ---- 9. быстрая проверка на месте --------------------------------------------
if run --backup "${BK}" --quick; then
    ok "--quick проверяет снимок на месте, без восстановления"
else
    no "--quick не работает: $(out | tail -1)"
fi
if run --backup "${BK2}" --quick; then
    no "--quick не заметил испорченный файл"
else
    ok "--quick находит порчу так же, как полная проверка"
fi

# ---- 10. ошибки вызова -------------------------------------------------------
run --backup "${TMP}/нет-такого" --into "${TMP}/r9" \
  && no "несуществующий снимок принят молча" \
  || ok "несуществующий снимок отвергнут"
[ -s "${TMP}/err" ] && ok "сообщение об ошибке уходит в stderr" \
                    || no "ошибка не попала в stderr — в журнале службы её не будет"

# ---- 11. воспроизводимость ---------------------------------------------------
run --backup "${BK}" --into "${TMP}/rA" --report "${TMP}/repA"
LC_ALL=C TZ=Pacific/Auckland run --backup "${BK}" --into "${TMP}/rB" --report "${TMP}/repB"
if [ -s "${TMP}/repA" ] && [ -s "${TMP}/repB" ] \
   && diff <(grep -v '^backup=' "${TMP}/repA") <(grep -v '^backup=' "${TMP}/repB") >/dev/null; then
    ok "отчёт не зависит от локали и часового пояса"
else
    no "отчёт различается между прогонами"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
