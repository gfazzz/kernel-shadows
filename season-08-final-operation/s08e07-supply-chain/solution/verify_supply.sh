#!/usr/bin/env bash
#
# verify_supply.sh — откуда приехало то, что запущено (ЭТАЛОН).
#
#   verify_supply.sh <инвентарь> <перечень-издателя> <разрешённые-реестры>
#
# Четыре разных вопроса, и путать их нельзя:
#
#   MISMATCH  отпечаток не совпал с опубликованным — содержимое другое
#   UNPINNED  образ подтянут по метке: что именно скачано, не записано
#   UNKNOWN   такого образа издатель не публиковал вовсе
#   MIRROR    реестр не входит в список разрешённых
#
# Вывод отсортирован; в конце итог.
#   FINDING <категория> <образ> <подробность>
#   TOTAL <n>
#
# Код возврата: 0 — чисто, 1 — есть находки, 2 — вход не разобран.

set -uo pipefail

[ "$#" -eq 3 ] || { echo "usage: $(basename "$0") <инвентарь> <перечень> <реестры>" >&2; exit 2; }
DEP="$1"; OFF="$2"; REG="$3"
for f in "${DEP}" "${OFF}" "${REG}"; do
    [ -f "${f}" ] || { echo "нет файла: ${f}" >&2; exit 2; }
done

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
OUT="${TMP}/findings"; : > "${OUT}"

# Перечень издателя: образ -> отпечаток.
awk '{sub(/#.*/,"")} NF==2 {print $1"\t"$2}' "${OFF}" | LC_ALL=C sort > "${TMP}/official"
awk '{sub(/#.*/,"")} NF==1 {print $1}'       "${REG}" | LC_ALL=C sort > "${TMP}/registries"

[ -s "${TMP}/official" ]   || { echo "перечень издателя пуст" >&2; exit 2; }
[ -s "${TMP}/registries" ] || { echo "список реестров пуст" >&2; exit 2; }

# Инвентарь: один и тот же образ встречается на многих узлах — интересует
# сам образ, а не сколько раз он запущен.
awk '{sub(/#.*/,"")} NF==3 {print $2"\t"$3}' "${DEP}" | LC_ALL=C sort -u > "${TMP}/deployed"
[ -s "${TMP}/deployed" ] || { echo "инвентарь пуст" >&2; exit 2; }

report() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "${OUT}"; }

while IFS=$'\t' read -r ref dig; do
    [ -n "${ref}" ] || continue

    # Реестр — всё до первой косой черты.
    registry="${ref%%/*}"
    grep -qxF "${registry}" "${TMP}/registries" \
        || report MIRROR "${ref}" "реестр ${registry} не в списке разрешённых"

    off_dig="$(awk -F'\t' -v r="${ref}" '$1==r {print $2; exit}' "${TMP}/official")"

    if [ -z "${off_dig}" ]; then
        report UNKNOWN "${ref}" "издатель такого образа не публиковал"
    elif [ "${dig}" = "-" ]; then
        # Отпечатка нет вовсе: образ подтянут по метке. Совпадать нечему,
        # и это отдельная беда, а не отсутствие беды.
        report UNPINNED "${ref}" "подтянут по метке, отпечаток не зафиксирован"
    elif [ "${dig}" != "${off_dig}" ]; then
        report MISMATCH "${ref}" "запущено ${dig}, опубликовано ${off_dig}"
    fi
done < "${TMP}/deployed"

LC_ALL=C sort -u "${OUT}" | awk -F'\t' '{printf "FINDING %s %s %s\n", $1, $2, $3}'
N="$(LC_ALL=C sort -u "${OUT}" | grep -c . || true)"
echo "TOTAL ${N}"
[ "${N}" -eq 0 ] && exit 0 || exit 1
