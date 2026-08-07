#!/usr/bin/env bash
#
# lvm_plan.sh — план расширения логического тома (ЭТАЛОН)
#
# Читает снимок состояния LVM и снимок файловых систем, печатает
# последовательность команд для расширения тома. НИЧЕГО НЕ ВЫПОЛНЯЕТ:
# ни одна команда LVM отсюда не вызывается — они только печатаются.
#
# Использование:
#   ./lvm_plan.sh [--snapshot ФАЙЛ] [--fs-snapshot ФАЙЛ] [--target LV] [--add-disk УСТР]

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SNAPSHOT="${HERE}/../../data/lvm_shadow-01.txt"
FS_SNAPSHOT="${HERE}/../../data/disk_shadow-01.txt"
TARGET_LV="log"
ADD_DISK=""

while [ $# -gt 0 ]; do
    case "$1" in
        --snapshot)    SNAPSHOT="$2";    shift 2 ;;
        --fs-snapshot) FS_SNAPSHOT="$2"; shift 2 ;;
        --target)      TARGET_LV="$2";   shift 2 ;;
        --add-disk)    ADD_DISK="$2";    shift 2 ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

for f in "${SNAPSHOT}" "${FS_SNAPSHOT}"; do
    [ -r "${f}" ] || { echo "не читается снимок: ${f}" >&2; exit 1; }
done

# ---- разбор снимков ---------------------------------------------------------
section()    { awk -v s="$1" '$0=="=== "s" ===" {f=1; next} /^=== /{f=0} f' "${SNAPSHOT}" \
                 | grep -vE '^[[:space:]]*$'; }
fs_section() { awk -v s="$1" '$0=="=== "s" ===" {f=1; next} /^=== /{f=0} f' "${FS_SNAPSHOT}" \
                 | grep -vE '^[[:space:]]*$'; }

# группа томов и свободное место в ней
VG=$(section vgs   | awk 'NR>1 {print $1; exit}')
VFREE=$(section vgs | awk 'NR>1 {print $NF; exit}')
# размер целевого тома
LSIZE=$(section lvs | awk -v lv="${TARGET_LV}" 'NR>1 && $1==lv {print $4; exit}')
[ -n "${LSIZE}" ] || { echo "тома '${TARGET_LV}' нет в снимке" >&2; exit 1; }

# устройства, уже входящие в группу
in_vg() { section pvs | awk 'NR>1 {print $1}' | sed 's|^/dev/||'; }

# свободный диск: есть в lsblk, но не является PV
if [ -z "${ADD_DISK}" ]; then
    ADD_DISK=$(section 'lsblk -dn -o NAME,SIZE,TYPE' \
        | awk '$3=="disk" {print $1}' \
        | grep -vxF -f <(in_vg | sed 's/[0-9]*$//') \
        | head -1)
    [ -n "${ADD_DISK}" ] && ADD_DISK="/dev/${ADD_DISK}"
fi
ADD_SIZE=$(section 'lsblk -dn -o NAME,SIZE,TYPE' \
    | awk -v d="$(basename "${ADD_DISK:-нет}")" '$1==d {print $2; exit}')

# точка монтирования и тип ФС целевого тома — из снимка файловых систем
MOUNT=$(fs_section 'df -h' | awk -v lv="${VG//-/--}-${TARGET_LV}" \
          '$1 ~ ("/dev/mapper/" lv "$") {print $NF; exit}')
FSTYPE=$(fs_section 'lsblk -f' | awk -v lv="${VG//-/--}-${TARGET_LV}" '
          $0 ~ lv {for (i=1;i<=NF;i++) if ($i ~ /^(ext[234]|xfs|btrfs)$/) {print $i; exit}}')

# чем растягивать файловую систему — зависит от её типа
case "${FSTYPE}" in
    ext2|ext3|ext4) GROW="resize2fs /dev/${VG}/${TARGET_LV}" ;;
    xfs)            GROW="xfs_growfs ${MOUNT}" ;;
    btrfs)          GROW="btrfs filesystem resize max ${MOUNT}" ;;
    *)              GROW="# тип файловой системы не определён — растягивать вручную" ;;
esac

# ---- состояние --------------------------------------------------------------
echo "СОСТОЯНИЕ"
echo "  группа томов:      ${VG}"
echo "  свободно в группе: ${VFREE}"
echo "  целевой том:       ${VG}/${TARGET_LV}, ${LSIZE}"
echo "  смонтирован в:     ${MOUNT:-не смонтирован}"
echo "  файловая система:  ${FSTYPE:-неизвестна}"
echo "  свободный диск:    ${ADD_DISK:-нет} ${ADD_SIZE:-}"
echo ""

# ---- план -------------------------------------------------------------------
echo "ПЛАН"
if [ "${VFREE}" = "0" ] || [ "${VFREE}" = "0g" ]; then
    if [ -z "${ADD_DISK}" ]; then
        echo "  свободного места нет и свободных дисков нет — расширять нечем"
        exit 1
    fi
    echo "  1. pvcreate ${ADD_DISK}"
    echo "  2. vgextend ${VG} ${ADD_DISK}"
    echo "  3. lvextend -l +100%FREE /dev/${VG}/${TARGET_LV}"
    echo "  4. ${GROW}"
else
    echo "  1. lvextend -l +100%FREE /dev/${VG}/${TARGET_LV}"
    echo "  2. ${GROW}"
fi
echo ""

echo "ПРОВЕРКА ПОСЛЕ"
echo "  vgs ${VG}"
echo "  lvs ${VG}/${TARGET_LV}"
echo "  df -h ${MOUNT}"
echo ""
echo "  Размонтировать ничего не требуется: и lvextend, и рост ext4/xfs"
echo "  работают на смонтированном томе. Обратная операция (lvreduce)"
echo "  требует размонтирования и на xfs невозможна вовсе."
