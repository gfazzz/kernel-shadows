#!/usr/bin/env bash
#
# s01e15 «Девять букв» — тест скрипта (Type A).
#
# Проверяет setup_workspace.sh на настоящем дереве во временном каталоге:
# создаются ли каталоги, те ли у них права, приводятся ли к нужным правам
# файлы внутри, и — главное — ЧИНИТ ли скрипт то, что уже испорчено.
# Скрипт, который только создаёт, пройдёт первую половину и упадёт на второй.
#
# `sudo` подменяется заглушкой-регистратором (§5.3): своему каталогу root
# не нужен, и любой вызов sudo означает провал.
#
# Без root, без сети.
#
# Выбор скрипта: SUBJECT=... | artifacts/setup_workspace.sh | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                                then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/setup_workspace.sh" ];  then SCRIPT="${SERIES_DIR}/artifacts/setup_workspace.sh"
elif [ -f "${SERIES_DIR}/setup_workspace.sh" ];            then SCRIPT="${SERIES_DIR}/setup_workspace.sh"
else SCRIPT="${SERIES_DIR}/solution/setup_workspace.sh"
     echo "ℹ️  Свой setup_workspace.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/setup_workspace.sh artifacts/setup_workspace.sh"; echo ""
fi
SCRIPT="$(cd "$(dirname "${SCRIPT}")" && pwd)/$(basename "${SCRIPT}")"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e15 tests — скрипт: ${SCRIPT##*/s01e15-permissions-basics/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${SCRIPT}" ]; then
    ok "скрипт setup_workspace.sh найден"
else
    no "setup_workspace.sh не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
BIN="${TMP}/bin"; mkdir -p "${BIN}"
SUDOLOG="${TMP}/sudo.log"; : > "${SUDOLOG}"
cat > "${BIN}/sudo" <<'STUB'
#!/usr/bin/env bash
printf 'sudo %s\n' "$*" >> "${SUDO_CALL_LOG}"
exit 0
STUB
chmod +x "${BIN}/sudo"
export SUDO_CALL_LOG="${SUDOLOG}"

mode_of() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null; }
oct()     { printf '%s' "$(( 8#$1 ))"; }
run()     { PATH="${BIN}:${PATH}" bash "${SCRIPT}" "$@" >"${TMP}/out" 2>"${TMP}/err"; }

want_mode() {  # want_mode <путь> <режим> <зачем>
    local p="$1" want="$2" why="$3" have
    if [ ! -e "${p}" ]; then no "нет ${p##*/tmp.*/} — каталог не создан"; return; fi
    have="$(mode_of "${p}")"
    if [ "$(oct "${have}")" = "$(oct "${want}")" ]; then
        ok "${p#${TMP}/}: ${want} (${why})"
    else
        no "${p#${TMP}/}: ${have}, нужно ${want} — ${why}"
    fi
}

# ---- 1. дисциплина -----------------------------------------------------------
head -1 "${SCRIPT}" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash' \
  && ok "шебанг на месте" || no "нет строки #!/usr/bin/env bash"
grep -qE '^set -[euo]+' "${SCRIPT}" \
  && ok "set -e/-u включён" || no "нет set -euo pipefail"
if grep -qE 'chmod +(-R +)?777' "${SCRIPT}"; then
    no "в скрипте есть chmod 777 — это не «починить права», а выключить вопрос"
else
    ok "chmod 777 в скрипте нет"
fi

# ---- 2. чистый запуск --------------------------------------------------------
W="${TMP}/ops"
if run --root "${W}"; then ok "скрипт отработал на пустом месте"
else no "скрипт упал: $(tail -1 "${TMP}/err")"; fi

want_mode "${W}/scripts" 700 "свои инструменты — только владельцу"
want_mode "${W}/secrets" 700 "посторонним нечего даже перечислять"
want_mode "${W}/reports" 755 "отчёты отдают другим, значит их читают"
want_mode "${W}/logs"    750 "журналы читает группа, посторонние нет"

if [ -s "${SUDOLOG}" ]; then
    no "скрипт вызвал sudo: $(head -1 "${SUDOLOG}") — своему каталогу root не нужен"
else
    ok "sudo не вызывался: права на свои файлы ставит владелец"
fi

# ---- 3. файлы внутри ---------------------------------------------------------
printf 'ключ\n'      > "${W}/secrets/.env"
printf 'echo hi\n'   > "${W}/scripts/collect.sh"
printf 'отчёт\n'     > "${W}/reports/day1.txt"
chmod 644 "${W}/secrets/.env" "${W}/scripts/collect.sh"
chmod 600 "${W}/reports/day1.txt"

if run --root "${W}"; then ok "повторный запуск отработал (идемпотентность)"
else no "повторный запуск упал: $(tail -1 "${TMP}/err")"; fi

want_mode "${W}/secrets/.env"      600 "секрет читает только владелец"
want_mode "${W}/scripts/collect.sh" 700 "скрипт исполняем и только для владельца"
want_mode "${W}/reports/day1.txt"  644 "отчёт должны прочитать"

# ---- 4. главное: чинит ли испорченное ---------------------------------------
chmod 777 "${W}/secrets"
chmod 666 "${W}/secrets/.env"
chmod 700 "${W}/reports"
if run --root "${W}"; then ok "запуск на испорченном каталоге отработал"
else no "на испорченном каталоге скрипт упал: $(tail -1 "${TMP}/err")"; fi

want_mode "${W}/secrets"      700 "каталог 777 приведён обратно"
want_mode "${W}/secrets/.env" 600 "файл 666 приведён обратно"
want_mode "${W}/reports"      755 "слишком узкие права тоже исправляются"

# ---- 5. ничего лишнего -------------------------------------------------------
OUT="${TMP}/outside"; mkdir -p "${OUT}"; printf 'чужое\n' > "${OUT}/чужой.txt"
chmod 644 "${OUT}/чужой.txt"
run --root "${W}"
if [ "$(oct "$(mode_of "${OUT}/чужой.txt")")" = "$(oct 644)" ]; then
    ok "файлы за пределами --root не тронуты"
else
    no "скрипт изменил права вне своего каталога"
fi

# ---- 6. ошибки вызова --------------------------------------------------------
printf 'файл\n' > "${TMP}/не-каталог"
if run --root "${TMP}/не-каталог"; then
    no "путь к обычному файлу принят как каталог"
else
    ok "путь к обычному файлу отвергнут с ненулевым кодом"
fi
if run; then
    no "запуск без --root прошёл молча"
else
    ok "запуск без --root отвергнут"
fi

# ---- 7. воспроизводимость ----------------------------------------------------
A="${TMP}/a"; B="${TMP}/b"
run --root "${A}"
LC_ALL=C TZ=Pacific/Auckland run --root "${B}"
ma="$(for d in scripts secrets reports logs; do oct "$(mode_of "${A}/${d}")"; done | tr '\n' ' ')"
mb="$(for d in scripts secrets reports logs; do oct "$(mode_of "${B}/${d}")"; done | tr '\n' ' ')"
if [ "${ma}" = "${mb}" ]; then
    ok "результат не зависит от локали и часового пояса"
else
    no "права различаются между прогонами: ${ma} против ${mb}"
fi

# ---- 8. самопроверка теста ---------------------------------------------------
umask_now="$(umask)"
if [ "$(oct "$(mode_of "${A}/scripts")")" -ne "$(oct 755)" ]; then
    ok "самопроверка: 700 у scripts выставлено скриптом, а не umask (${umask_now})"
else
    no "самопроверка: права совпали с umask по умолчанию — скрипт мог их не ставить"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
