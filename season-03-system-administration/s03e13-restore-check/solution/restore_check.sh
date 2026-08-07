#!/usr/bin/env bash
#
# restore_check.sh — восстановление из снимка и проверка целостности (ЭТАЛОН)
#
# Отвечает на третий вопрос Лийзы: «когда вы в последний раз восстанавливались».
# Восстанавливает снимок во временный каталог и сверяет каждый файл с
# манифестом: испорченные, пропавшие и лишние перечисляются поимённо.
#
# Сам бэкап при этом НЕ ИЗМЕНЯЕТСЯ: он открывается только на чтение.
#
# Использование:
#   ./restore_check.sh --backup /srv/backup/latest --into /tmp/restore-test
#                      [--report ФАЙЛ] [--quick] [--force]
#
# Коды возврата: 0 — копия цела, 1 — расхождения, 2 — ошибка вызова.

set -euo pipefail

BACKUP=""
INTO=""
REPORT=""
QUICK=0
FORCE=0

while [ $# -gt 0 ]; do
    case "$1" in
        --backup) BACKUP="$2"; shift 2 ;;
        --into)   INTO="$2";   shift 2 ;;
        --report) REPORT="$2"; shift 2 ;;
        --quick)  QUICK=1;     shift   ;;
        --force)  FORCE=1;     shift   ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

log()  { printf '%s  %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"; }
die()  { printf '%s  ОШИБКА: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >&2; exit 2; }

[ -n "${BACKUP}" ] || die "не задан --backup"
[ -d "${BACKUP}" ] || die "снимок не найден: ${BACKUP}"
MANIFEST="${BACKUP}/.manifest.sha256"
[ -r "${MANIFEST}" ] || die "в снимке нет манифеста (${MANIFEST}) — проверять не с чем"

if command -v sha256sum >/dev/null 2>&1; then SHA() { sha256sum "$@"; }
elif command -v shasum  >/dev/null 2>&1; then SHA() { shasum -a 256 "$@"; }
else die "нет ни sha256sum, ни shasum"
fi

# ---- куда восстанавливать ----------------------------------------------------
if [ "${QUICK}" -eq 1 ]; then
    TARGET="${BACKUP}"
    log "быстрая проверка: сверяю на месте, не восстанавливая"
else
    [ -n "${INTO}" ] || die "не задан --into (или используйте --quick)"
    if [ -e "${INTO}" ] && [ -n "$(ls -A "${INTO}" 2>/dev/null)" ] && [ "${FORCE}" -eq 0 ]; then
        die "каталог ${INTO} не пуст; проверьте его и повторите с --force"
    fi
    mkdir -p "${INTO}"
    log "восстанавливаю ${BACKUP} → ${INTO}"
    ( cd "${BACKUP}" && find . -type d -print ) | while IFS= read -r d; do
        mkdir -p "${INTO}/${d}"
    done
    ( cd "${BACKUP}" && find . -type f -print ) | while IFS= read -r f; do
        cp -p "${BACKUP}/${f}" "${INTO}/${f}"
    done
    TARGET="${INTO}"
fi

# ---- сверка ------------------------------------------------------------------
CHECKED=0; BAD=0; MISSING=0; EXTRA=0
bad_list=""; missing_list=""; extra_list=""

while IFS= read -r line; do
    [ -n "${line}" ] || continue
    want="${line%% *}"
    path="${line#* }"
    path="${path# }"            # sha256sum ставит два пробела
    CHECKED=$(( CHECKED + 1 ))
    if [ ! -f "${TARGET}/${path}" ]; then
        MISSING=$(( MISSING + 1 )); missing_list="${missing_list}${path}"$'\n'; continue
    fi
    got="$(SHA "${TARGET}/${path}" | awk '{print $1}')"
    if [ "${got}" != "${want}" ]; then
        BAD=$(( BAD + 1 )); bad_list="${bad_list}${path}"$'\n'
    fi
done < "${MANIFEST}"

# лишние файлы: есть в дереве, нет в манифесте
listed="$(awk '{ sub(/^[0-9a-f]+ +/,""); print }' "${MANIFEST}" | LC_ALL=C sort)"
present="$(cd "${TARGET}" && find . -type f ! -name '.manifest.sha256' | LC_ALL=C sort)"
extra_list="$(comm -13 <(printf '%s\n' "${listed}") <(printf '%s\n' "${present}") || true)"
EXTRA=$(printf '%s' "${extra_list}" | grep -c . || true)

# ---- отчёт -------------------------------------------------------------------
log "проверено файлов: ${CHECKED}"
[ "${BAD}"     -gt 0 ] && { log "ИСПОРЧЕНЫ (${BAD}):";  printf '%s' "${bad_list}"     | sed 's/^/    /'; }
[ "${MISSING}" -gt 0 ] && { log "ПРОПАЛИ (${MISSING}):"; printf '%s' "${missing_list}" | sed 's/^/    /'; }
[ "${EXTRA}"   -gt 0 ] && { log "ЛИШНИЕ (${EXTRA}):";   printf '%s' "${extra_list}"   | sed 's/^/    /'; }

if [ -n "${REPORT}" ]; then
    {
        echo "backup=${BACKUP}"
        echo "checked=${CHECKED}"
        echo "corrupted=${BAD}"
        echo "missing=${MISSING}"
        echo "extra=${EXTRA}"
        echo "result=$( [ $(( BAD + MISSING + EXTRA )) -eq 0 ] && echo OK || echo FAILED )"
    } > "${REPORT}"
    log "отчёт: ${REPORT}"
fi

if [ $(( BAD + MISSING + EXTRA )) -eq 0 ]; then
    log "копия цела: восстановление проверено"
    exit 0
fi
log "копия НЕ цела — восстанавливаться из неё нельзя"
exit 1
