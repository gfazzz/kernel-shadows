#!/usr/bin/env bash
#
# lvm_plan.sh — план расширения логического тома (СТАРТЕР)
#
# Скрипт НИЧЕГО НЕ ВЫПОЛНЯЕТ. Он читает снимок состояния LVM и печатает
# последовательность команд, которую потом выполняет человек, глядя на неё.
# Это не осторожность ради осторожности: lvreduce на смонтированном томе
# уничтожает файловую систему, и единственная защита — прочитать план глазами.
#
# Задача: заставить его читать снимок, а не повторять то, что было верно
# вчера. Проверка:  bash tests/test.sh
#
# Использование (менять не нужно):
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

# Вырезать раздел снимка по заголовку «=== команда ===»
section() {
    awk -v s="$1" '$0=="=== "s" ===" {f=1; next} /^=== /{f=0} f' "${SNAPSHOT}" \
        | grep -vE '^[[:space:]]*$'
}

echo "СОСТОЯНИЕ"
echo "  группа томов: ops-vg"
echo "  свободно в группе: 0"
echo "  целевой том: ops-vg/log, 20.00g"
echo ""

# TODO: всё, что ниже, вписано руками и уже неверно.
#       Свободного места в группе нет, а /dev/vdb давно в неё входит.
echo "ПЛАН"
echo "  lvextend -l +100%FREE /dev/ops-vg/log"
echo "  xfs_growfs /var/log"
