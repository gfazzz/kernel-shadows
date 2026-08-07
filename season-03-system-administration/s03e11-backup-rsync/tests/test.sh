#!/usr/bin/env bash
#
# s03e11 «Копия, которой не было» — тест скрипта (Type A).
#
# Проверяет backup.sh на настоящем дереве файлов во временном каталоге:
# создаётся ли снимок, обновляется ли latest, пишется ли манифест,
# передаются ли rsync нужные ключи, работает ли блокировка и ротация.
#
# rsync подменяется заглушкой (§5.3): она ЗАПИСЫВАЕТ полученные аргументы
# и при этом честно копирует дерево через cp -a. Так тест не зависит ни от
# наличия rsync, ни от его версии, но проверяет и аргументы, и результат.
#
# Без root, без сети.
#
# Выбор скрипта: SUBJECT=... | artifacts/backup.sh | <серия>/backup.sh | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                        then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/backup.sh" ];   then SCRIPT="${SERIES_DIR}/artifacts/backup.sh"
elif [ -f "${SERIES_DIR}/backup.sh" ];             then SCRIPT="${SERIES_DIR}/backup.sh"
else SCRIPT="${SERIES_DIR}/solution/backup.sh"
     echo "ℹ️  Свой backup.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/backup.sh artifacts/backup.sh"; echo ""
fi
SCRIPT="$(cd "$(dirname "${SCRIPT}")" && pwd)/$(basename "${SCRIPT}")"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e11 tests — скрипт: ${SCRIPT##*/s03e11-backup-rsync/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${SCRIPT}" ]; then
    ok "скрипт backup.sh найден"
else
    no "backup.sh не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
BIN="${TMP}/bin"; mkdir -p "${BIN}"
RLOG="${TMP}/rsync.args"; : > "${RLOG}"

# ---- заглушка rsync: пишет аргументы и копирует дерево ----------------------
cat > "${BIN}/rsync" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${RSYNC_ARGS_LOG}"
src=""; dst=""
for a in "$@"; do case "${a}" in -*) ;; *) src="${dst}"; dst="${a}" ;; esac; done
case " $* " in *" --dry-run "*|*" -n "*) exit 0 ;; esac
[ -n "${src}" ] && [ -n "${dst}" ] || exit 0
mkdir -p "${dst}"
( cd "${src}" 2>/dev/null && find . -mindepth 1 -print0 ) | \
  while IFS= read -r -d '' f; do
      if [ -d "${src}/${f}" ]; then mkdir -p "${dst}/${f}"
      else mkdir -p "$(dirname "${dst}/${f}")"; cp -p "${src}/${f}" "${dst}/${f}"; fi
  done
exit 0
STUB
chmod +x "${BIN}/rsync"
export RSYNC_ARGS_LOG="${RLOG}"

SRC="${TMP}/src"; DST="${TMP}/dst"
mkdir -p "${SRC}/sub" "${DST}"
printf 'alpha\n' > "${SRC}/a.txt"
printf 'beta\n'  > "${SRC}/sub/b.txt"
printf 'temp\n'  > "${SRC}/scratch.tmp"
printf '*.tmp\n' > "${TMP}/exclude.txt"

run() { PATH="${BIN}:${PATH}" bash "${SCRIPT}" "$@" >"${TMP}/out" 2>"${TMP}/err"; }

# ---- 1. дисциплина -----------------------------------------------------------
head -1 "${SCRIPT}" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash' \
  && ok "шебанг на месте" || no "нет строки #!/usr/bin/env bash"
grep -qE '^set -[euo]+' "${SCRIPT}" \
  && ok "set -e/-u включён" || no "нет set -euo pipefail"

# ---- 2. первый прогон --------------------------------------------------------
if run --source "${SRC}" --dest "${DST}" --name run1 --exclude-from "${TMP}/exclude.txt"; then
    ok "первый прогон завершился успешно"
else
    no "первый прогон упал: $(tail -1 "${TMP}/err")"
fi

[ -d "${DST}/run1" ] && ok "снимок run1 создан" || no "каталога ${DST}/run1 нет — имя из --name не использовано"
[ -f "${DST}/run1/a.txt" ] && [ -f "${DST}/run1/sub/b.txt" ] \
  && ok "файлы скопированы, вложенность сохранена" || no "в снимке нет файлов источника"

if [ -L "${DST}/latest" ] && [ "$(readlink "${DST}/latest")" = "run1" ]; then
    ok "latest указывает на run1"
else
    no "нет символьной ссылки latest → run1: восстанавливающий не узнает, какой снимок свежий"
fi

args1="$(cat "${RLOG}")"
printf '%s' "${args1}" | grep -qE '(^| )(-a|--archive)( |$)' \
  && ok "rsync получил --archive (права, владельцы, время, ссылки)" \
  || no "rsync без --archive: копия потеряет права и владельцев"
printf '%s' "${args1}" | grep -q -- '--exclude-from' \
  && ok "список исключений передан в rsync" || no "--exclude-from не передан"
printf '%s' "${args1}" | grep -q -- '--link-dest' \
  && no "на первом прогоне использован --link-dest, хотя предыдущего снимка нет" \
  || ok "на первом прогоне --link-dest не используется"

# ---- 3. манифест -------------------------------------------------------------
MAN="$(find "${DST}/run1" -maxdepth 1 -name '.manifest*' -o -maxdepth 1 -name 'manifest*' | head -1)"
if [ -n "${MAN}" ] && [ -s "${MAN}" ]; then
    ok "манифест создан: $(basename "${MAN}")"
    if grep -qE '^[0-9a-f]{64} ' "${MAN}"; then
        ok "в манифесте контрольные суммы sha256"
    else
        no "в манифесте нет sha256 — проверить целостность копии будет нечем"
    fi
    if grep -q ' /' "${MAN}" || grep -qE "${TMP}" "${MAN}"; then
        no "в манифесте абсолютные пути — сверить его с восстановленной копией не получится"
    else
        ok "пути в манифесте относительные"
    fi
    n=$(grep -cE '^[0-9a-f]{64} ' "${MAN}")
    if [ "${n}" -ge 2 ]; then
        ok "в манифесте ${n} файла — перечислены и вложенные"
    else
        no "в манифесте ${n} записей, а файлов в снимке больше"
    fi
else
    no "манифеста с контрольными суммами нет"
    no "нет sha256 — проверить целостность копии будет нечем"
    no "нет манифеста — сверять восстановленную копию не с чем"
    no "нет перечня файлов снимка"
fi

# ---- 4. инкремент ------------------------------------------------------------
: > "${RLOG}"
printf 'gamma\n' > "${SRC}/c.txt"
run --source "${SRC}" --dest "${DST}" --name run2 --exclude-from "${TMP}/exclude.txt" \
  && ok "второй прогон завершился успешно" || no "второй прогон упал: $(tail -1 "${TMP}/err")"

args2="$(cat "${RLOG}")"
if printf '%s' "${args2}" | grep -q -- '--link-dest'; then
    ok "второй прогон использует --link-dest — место занимает только разница"
else
    no "нет --link-dest: каждый снимок будет занимать полный объём"
fi
if printf '%s' "${args2}" | grep -qE -- '--link-dest[= ][^ ]*(run1|latest)'; then
    ok "--link-dest указывает на предыдущий снимок"
else
    no "--link-dest указывает не на предыдущий снимок"
fi
[ "$(readlink "${DST}/latest" 2>/dev/null)" = "run2" ] \
  && ok "latest переставлен на run2" || no "latest не обновлён после второго прогона"

# ---- 5. холостой прогон ------------------------------------------------------
: > "${RLOG}"
if run --source "${SRC}" --dest "${DST}" --name dryrun --dry-run; then
    ok "--dry-run завершился успешно"
else
    no "--dry-run упал: $(tail -1 "${TMP}/err")"
fi
if [ -e "${DST}/dryrun" ] && [ -n "$(ls -A "${DST}/dryrun" 2>/dev/null)" ]; then
    no "--dry-run создал непустой снимок — холостой прогон не должен менять ничего"
else
    ok "--dry-run ничего не создал"
fi
printf '%s' "$(cat "${RLOG}")" | grep -qE -- '--dry-run|(^| )-n( |$)' \
  && ok "холостой режим передан и самому rsync" || no "rsync не получил --dry-run"

# ---- 6. блокировка -----------------------------------------------------------
before=$(find "${DST}" -maxdepth 1 -mindepth 1 | wc -l)
mkdir -p "${DST}/.backup.lock"
if run --source "${SRC}" --dest "${DST}" --name locked; then
    no "при существующей блокировке запуск прошёл — два бэкапа могут пойти одновременно"
else
    ok "при существующей блокировке запуск отклонён с ненулевым кодом"
fi
rmdir "${DST}/.backup.lock" 2>/dev/null || rm -rf "${DST}/.backup.lock"

# ---- 7. ошибки ---------------------------------------------------------------
run --source "${TMP}/нет-такого" --dest "${DST}" --name x \
  && no "несуществующий источник принят молча" \
  || ok "несуществующий источник отвергнут с ненулевым кодом"
[ -s "${TMP}/err" ] && ok "сообщение об ошибке уходит в stderr" \
  || no "об ошибке не сказано в stderr — в журнале службы её не будет"

# ---- 8. ротация --------------------------------------------------------------
run --source "${SRC}" --dest "${DST}" --name run3 --keep 2 >/dev/null 2>&1
snaps=$(find "${DST}" -maxdepth 1 -mindepth 1 -type d ! -name '.backup.lock' | wc -l | tr -d ' ')
if [ "${snaps}" -eq 2 ]; then
    ok "--keep 2 оставил ровно два снимка"
else
    no "--keep 2 оставил ${snaps} снимков"
fi
[ -d "${DST}/run1" ] && no "удалён не самый старый снимок: run1 на месте" \
                     || ok "удалён самый старый снимок"

# ---- 9. воспроизводимость ----------------------------------------------------
D2="${TMP}/dst2"; D3="${TMP}/dst3"; mkdir -p "${D2}" "${D3}"
run --source "${SRC}" --dest "${D2}" --name same >/dev/null 2>&1
LC_ALL=C TZ=Pacific/Auckland run --source "${SRC}" --dest "${D3}" --name same >/dev/null 2>&1
m2="$(find "${D2}/same" -name '.manifest*' -o -name 'manifest*' | head -1)"
m3="$(find "${D3}/same" -name '.manifest*' -o -name 'manifest*' | head -1)"
if [ -n "${m2}" ] && [ -n "${m3}" ] && diff -q "${m2}" "${m3}" >/dev/null; then
    ok "манифест не зависит от локали и часового пояса"
else
    no "манифест отличается между прогонами — в нём есть дата, порядок или локальные числа"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
