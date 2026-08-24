#!/usr/bin/env bash
#
# cleanup.sh — убрать найденное и доказать, что убрано (ЭТАЛОН).
#
#   cleanup.sh [--verify] <корень> <план>
#
# Без ключа — приводит систему к состоянию, описанному планом.
# С ключом --verify — только проверяет и ничего не меняет.
#
# Устройство, ради которого написана серия: каждая строка плана описывает
# СОСТОЯНИЕ, а не действие. Поэтому прогон на уже очищенной системе — это
# не ошибка и не повторное удаление, а подтверждение: состояние достигнуто.
#
# Вывод: по строке на пункт плана, отсортировано по порядку плана.
#   ITEM <состояние> <действие> <объект>   где состояние: FIXED | ALREADY | FAILED
#   SUMMARY fixed=<n> already=<n> failed=<n>
#
# Код возврата: 0 — состояние достигнуто, 1 — что-то не достигнуто,
#               2 — вход не разобран.

set -uo pipefail

VERIFY=no
if [ "${1:-}" = "--verify" ]; then VERIFY=yes; shift; fi
[ "$#" -eq 2 ] || { echo "usage: $(basename "$0") [--verify] <корень> <план>" >&2; exit 2; }
ROOT="${1%/}"; PLAN="$2"
[ -d "${ROOT}" ] || { echo "нет каталога: ${ROOT}" >&2; exit 2; }
[ -f "${PLAN}" ] || { echo "нет плана: ${PLAN}" >&2; exit 2; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
FIXED=0; ALREADY=0; FAILED=0

# Проверка состояния: выполнено ли уже то, что требует пункт.
clean_p() {
    case "$1" in
        remove-file) [ ! -e "${ROOT}/$2" ] ;;
        remove-line) [ ! -f "${ROOT}/$2" ] || ! grep -qF -- "$3" "${ROOT}/$2" ;;
        remove-user) [ ! -f "${ROOT}/$2" ] || ! grep -q "^$3:" "${ROOT}/$2" ;;
        *) return 1 ;;
    esac
}

# Приведение к состоянию. Правка файлов — через временную копию и
# переименование: файл либо старый, либо новый, промежуточного состояния
# не бывает даже при обрыве.
apply() {
    case "$1" in
        remove-file) rm -f "${ROOT}/$2" ;;
        remove-line)
            [ -f "${ROOT}/$2" ] || return 0
            grep -vF -- "$3" "${ROOT}/$2" > "${TMP}/w" && mv "${TMP}/w" "${ROOT}/$2" ;;
        remove-user)
            [ -f "${ROOT}/$2" ] || return 0
            grep -v "^$3:" "${ROOT}/$2" > "${TMP}/w" && mv "${TMP}/w" "${ROOT}/$2" ;;
        *) return 1 ;;
    esac
}

while read -r action target extra; do
    [ -n "${action:-}" ] || continue
    case "${action}" in \#*) continue ;; esac

    obj="${target}${extra:+ ${extra}}"

    if clean_p "${action}" "${target}" "${extra:-}"; then
        echo "ITEM ALREADY ${action} ${obj}"; ALREADY=$((ALREADY+1)); continue
    fi

    if [ "${VERIFY}" = yes ]; then
        echo "ITEM FAILED ${action} ${obj}"; FAILED=$((FAILED+1)); continue
    fi

    apply "${action}" "${target}" "${extra:-}"

    # Проверка после действия — отдельный шаг, а не предположение.
    # «Команда отработала» и «состояние достигнуто» — разные утверждения.
    if clean_p "${action}" "${target}" "${extra:-}"; then
        echo "ITEM FIXED ${action} ${obj}"; FIXED=$((FIXED+1))
    else
        echo "ITEM FAILED ${action} ${obj}"; FAILED=$((FAILED+1))
    fi
done < <(sed 's/#.*//' "${PLAN}")

echo "SUMMARY fixed=${FIXED} already=${ALREADY} failed=${FAILED}"
[ "${FAILED}" -eq 0 ] && exit 0 || exit 1
