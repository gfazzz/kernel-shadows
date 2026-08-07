#!/usr/bin/env bash
#
# backup.sh — инкрементальный снимок каталога (ЭТАЛОН)
#
# Каждый запуск создаёт ПОЛНЫЙ по виду снимок, но неизменившиеся файлы
# в нём — жёсткие ссылки на предыдущий (rsync --link-dest). Место занимает
# только разница, а восстанавливать можно из любого снимка целиком:
# ходить по цепочке инкрементов не нужно.
#
# Использование:
#   ./backup.sh --source /var/log/ops --dest /srv/backup [--name ИМЯ]
#               [--exclude-from ФАЙЛ] [--keep N] [--dry-run]

set -euo pipefail

SOURCE=""
DEST=""
NAME=""
EXCLUDE_FROM=""
KEEP=7
DRY_RUN=0

while [ $# -gt 0 ]; do
    case "$1" in
        --source)       SOURCE="$2";       shift 2 ;;
        --dest)         DEST="$2";         shift 2 ;;
        --name)         NAME="$2";         shift 2 ;;
        --exclude-from) EXCLUDE_FROM="$2"; shift 2 ;;
        --keep)         KEEP="$2";         shift 2 ;;
        --dry-run)      DRY_RUN=1;         shift   ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

log() { printf '%s  %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"; }
die() { printf '%s  ОШИБКА: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >&2; exit 1; }

[ -n "${SOURCE}" ] || die "не задан --source"
[ -n "${DEST}"   ] || die "не задан --dest"
[ -d "${SOURCE}" ] || die "источник не существует: ${SOURCE}"
[ -d "${DEST}"   ] || die "каталог назначения не существует: ${DEST}"
[ -n "${EXCLUDE_FROM}" ] && [ ! -r "${EXCLUDE_FROM}" ] && die "не читается список исключений: ${EXCLUDE_FROM}"

# контрольные суммы: sha256sum в GNU, shasum -a 256 в macOS
if command -v sha256sum >/dev/null 2>&1; then SHA() { sha256sum "$@"; }
elif command -v shasum  >/dev/null 2>&1; then SHA() { shasum -a 256 "$@"; }
else die "нет ни sha256sum, ни shasum — проверять целостность нечем"
fi

# ---- блокировка: два бэкапа одного каталога одновременно не нужны -----------
LOCK="${DEST}/.backup.lock"
if ! mkdir "${LOCK}" 2>/dev/null; then
    die "каталог заблокирован другим запуском (${LOCK}); если процесса нет, убрать вручную"
fi
cleanup() { rmdir "${LOCK}" 2>/dev/null || true; }
trap cleanup EXIT

[ -n "${NAME}" ] || NAME="$(date -u '+%Y-%m-%dT%H%M%SZ')"
SNAP="${DEST}/${NAME}"
LATEST="${DEST}/latest"

log "источник:  ${SOURCE}"
log "снимок:    ${SNAP}"

# ---- сборка команды ----------------------------------------------------------
args=(--archive --hard-links --delete --numeric-ids)
[ -n "${EXCLUDE_FROM}" ] && args+=(--exclude-from="${EXCLUDE_FROM}")
if [ -d "${LATEST}" ] || [ -L "${LATEST}" ]; then
    args+=(--link-dest="$(cd "${DEST}" && pwd)/latest")
    log "инкремент от: $(readlink "${LATEST}" 2>/dev/null || echo latest)"
else
    log "предыдущего снимка нет — первый проход будет полным"
fi
[ "${DRY_RUN}" -eq 1 ] && args+=(--dry-run)

if [ "${DRY_RUN}" -eq 1 ]; then
    log "холостой прогон: ничего не создаётся"
    rsync "${args[@]}" "${SOURCE}/" "${SNAP}/" >/dev/null
    log "готово (холостой прогон)"
    exit 0
fi

mkdir -p "${SNAP}"
rsync "${args[@]}" "${SOURCE}/" "${SNAP}/" >/dev/null \
    || die "rsync завершился с кодом $? — снимок неполный"

# ---- манифест: относительные пути + контрольные суммы ------------------------
MANIFEST="${SNAP}/.manifest.sha256"
(
  cd "${SNAP}"
  find . -type f ! -name '.manifest.sha256' | LC_ALL=C sort | while IFS= read -r f; do
      SHA "${f}"
  done
) > "${MANIFEST}"
FILES=$(grep -c . "${MANIFEST}" || true)
log "файлов в снимке: ${FILES}"
log "манифест: ${MANIFEST#"${DEST}"/}"

# ---- latest -----------------------------------------------------------------
rm -f "${LATEST}"
( cd "${DEST}" && ln -s "${NAME}" latest )
log "latest → ${NAME}"

# ---- ротация снимков ---------------------------------------------------------
if [ "${KEEP}" -gt 0 ]; then
    snaps=$(cd "${DEST}" && find . -maxdepth 1 -mindepth 1 -type d \
              ! -name '.backup.lock' | sed 's|^\./||' | LC_ALL=C sort)
    total=$(printf '%s\n' "${snaps}" | grep -c . || true)
    if [ "${total}" -gt "${KEEP}" ]; then
        printf '%s\n' "${snaps}" | head -n "$(( total - KEEP ))" | while IFS= read -r old; do
            [ -n "${old}" ] || continue
            log "удаляю старый снимок: ${old}"
            rm -rf "${DEST:?}/${old}"
        done
    fi
fi

log "готово"
