#!/usr/bin/env bash
#
# hunt_persistence.sh — что на этом узле запускается само (ЭТАЛОН).
#
#   hunt_persistence.sh <корень-снимка> <эталонный-перечень>
#
# Две независимые проверки, и обе нужны:
#
#   1. Расхождение с эталоном. Файл появился там, где его не было, или
#      изменился там, где был. Ловит закрепление любого вида, но только
#      если эталон снят раньше проникновения.
#   2. Признаки, не зависящие от эталона. Учётная запись с нулевым uid
#      кроме root, ld.so.preload, NOPASSWD: ALL. Ловит и то, что попало
#      в эталон, — то есть проникновение до его снятия.
#
# Вывод: по строке на находку, отсортировано; в конце итог.
#   PERSIST <категория> <путь> <почему>
#   TOTAL <n>
#
# Код возврата: 0 — чисто, 1 — есть находки, 2 — вход не разобран.
#
# Ничего не меняет: только читает.

set -uo pipefail

usage() { echo "usage: $(basename "$0") <корень-снимка> <эталонный-перечень>" >&2; return 2; }
[ "$#" -eq 2 ] || { usage; exit 2; }
ROOT="${1%/}"; MANIFEST="$2"
[ -d "${ROOT}" ]     || { echo "нет каталога: ${ROOT}" >&2; exit 2; }
[ -f "${MANIFEST}" ] || { echo "нет перечня: ${MANIFEST}" >&2; exit 2; }

# Контрольная сумма тем, что нашлось в системе: на разных платформах это
# разные программы, и полагаться на одну нельзя.
if   command -v sha256sum >/dev/null 2>&1; then hash_of() { sha256sum "$1" | cut -d' ' -f1; }
elif command -v shasum    >/dev/null 2>&1; then hash_of() { shasum -a 256 "$1" | cut -d' ' -f1; }
elif command -v openssl   >/dev/null 2>&1; then hash_of() { openssl dgst -sha256 "$1" | awk '{print $NF}'; }
else echo "нечем считать контрольные суммы: нужен sha256sum, shasum или openssl" >&2; exit 2; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
OUT="${TMP}/findings"; : > "${OUT}"

report() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "${OUT}"; }

# Каталоги, в которых система хранит то, что запускается само. Всё, что
# вне этого списка, интересно тоже, но не в первую очередь.
watched() {
    case "$1" in
        etc/crontab|etc/cron.d/*|var/spool/cron/crontabs/*) echo cron ;;
        etc/systemd/system/*)                              echo systemd ;;
        etc/profile.d/*|root/.bashrc|home/*/.bashrc)       echo shell-profile ;;
        */.ssh/authorized_keys)                            echo ssh-key ;;
        etc/sudoers.d/*)                                   echo sudoers ;;
        etc/ld.so.preload)                                 echo preload ;;
        etc/rc.local)                                      echo rc-local ;;
        etc/passwd)                                        echo account ;;
        *)                                                 echo "" ;;
    esac
}

# ── 1. расхождение с эталоном ────────────────────────────────────────
awk '{sub(/#.*/,"")} NF==2 {print $1"\t"$2}' "${MANIFEST}" | LC_ALL=C sort > "${TMP}/base"

(cd "${ROOT}" && find . -type f 2>/dev/null | sed 's|^\./||' | LC_ALL=C sort) > "${TMP}/now"

while IFS= read -r rel; do
    [ -n "${rel}" ] || continue
    cat="$(watched "${rel}")"
    [ -n "${cat}" ] || continue
    base_sum="$(awk -F'\t' -v p="${rel}" '$1==p {print $2; exit}' "${TMP}/base")"
    now_sum="$(hash_of "${ROOT}/${rel}")"
    if [ -z "${base_sum}" ]; then
        report "${cat}" "${rel}" "файла не было в эталоне"
    elif [ "${base_sum}" != "${now_sum}" ]; then
        report "${cat}" "${rel}" "содержимое изменилось после эталона"
    fi
done < "${TMP}/now"

# ── 2. признаки, не зависящие от эталона ─────────────────────────────
# Учётная запись с нулевым uid кроме root: второй root по факту, каким бы
# именем он ни назывался.
if [ -f "${ROOT}/etc/passwd" ]; then
    while IFS=: read -r name _ uid _; do
        [ "${uid:-}" = 0 ] && [ "${name}" != root ] && \
            report account "etc/passwd:${name}" "uid 0 у учётной записи, которая не root"
    done < "${ROOT}/etc/passwd"
fi

# Библиотека, подгружаемая в каждый процесс. Сам факт существования файла
# на обычном узле — уже повод.
[ -s "${ROOT}/etc/ld.so.preload" ] && \
    report preload "etc/ld.so.preload" "подгрузка библиотеки во все процессы: $(tr "\n" " " < "${ROOT}/etc/ld.so.preload" | sed "s/ *$//")"

# Повышение прав без пароля для всего.
if [ -d "${ROOT}/etc/sudoers.d" ]; then
    grep -rlE 'NOPASSWD:[[:space:]]*ALL' "${ROOT}/etc/sudoers.d" 2>/dev/null | while IFS= read -r f; do
        report sudoers "${f#"${ROOT}/"}" "NOPASSWD: ALL — повышение прав без пароля"
    done
fi

# ── итог ─────────────────────────────────────────────────────────────
# Дубликаты возможны: файл может попасть и в расхождение, и в признаки.
# Сортировка фиксирована — вывод не должен зависеть от порядка обхода.
LC_ALL=C sort -u "${OUT}" | awk -F'\t' '{printf "PERSIST %s %s %s\n", $1, $2, $3}'
N="$(LC_ALL=C sort -u "${OUT}" | grep -c . || true)"
echo "TOTAL ${N}"
[ "${N}" -eq 0 ] && exit 0 || exit 1
