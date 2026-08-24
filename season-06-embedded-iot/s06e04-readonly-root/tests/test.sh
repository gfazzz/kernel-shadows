#!/usr/bin/env bash
#
# s06e04 «Устройство без диска» — тест fstab (Type B).
#
# Ни одного зашитого пути: что монтировать и каким способом, тест берёт
# из data/write_paths.txt (колонка «режим»), идентификаторы разделов —
# из data/partitions.txt и data/board_facts.txt, предел суммарного tmpfs —
# из ram_mb. Подмени режим у пути — тест будет ждать другой тип монтирования.
#
# Без root, без сети, без платы: fstab проверяется как текст.
#
# Выбор файла: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WP="${SERIES_DIR}/data/write_paths.txt"
PT="${SERIES_DIR}/data/partitions.txt"
BF="${SERIES_DIR}/data/board_facts.txt"

if   [ -n "${SUBJECT:-}" ];                     then F="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/fstab" ];    then F="${SERIES_DIR}/artifacts/fstab"
elif [ -f "${SERIES_DIR}/fstab" ];              then F="${SERIES_DIR}/fstab"
else F="${SERIES_DIR}/solution/fstab"
     echo "ℹ️  Своего fstab не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/fstab artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e04 tests — fstab: ${F#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${WP}" "${PT}" "${BF}"; do [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }; done
if [ -f "${F}" ]; then ok "fstab найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

fact() { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/[[:space:]]/,""); print; exit}' "${BF}"; }
RAM="$(fact ram_mb)"
ROOT_UUID="$(fact root_partuuid)"; BOOT_UUID="$(fact boot_partuuid)"; DATA_UUID="$(fact data_partuuid)"

# ── разбор fstab ─────────────────────────────────────────────────────
ROWS="$(awk '{sub(/#.*$/,"")} NF>=4 {print}' "${F}")"
dev_of()  { awk -v m="$1" '$2==m {print $1; exit}' <<<"${ROWS}"; }
type_of() { awk -v m="$1" '$2==m {print $3; exit}' <<<"${ROWS}"; }
opts_of() { awk -v m="$1" '$2==m {print $4; exit}' <<<"${ROWS}"; }
pass_of() { awk -v m="$1" '$2==m {print $6; exit}' <<<"${ROWS}"; }
has_mp()  { awk -v m="$1" '$2==m {f=1} END{exit !f}' <<<"${ROWS}"; }
has_opt() { printf '%s' ",$(opts_of "$1")," | grep -q ",$2,"; }
has_optp(){ printf '%s' "$(opts_of "$1")" | tr ',' '\n' | grep -q "^$2"; }

paths_of_mode() { awk -v m="$1" '/^[[:space:]]*#/{next} NF>=3 && $3==m {print $1}' "${WP}"; }

TMPFS_PATHS="$(paths_of_mode tmpfs)"
OVL_PATHS="$(paths_of_mode overlay)"
PERS_PATHS="$(paths_of_mode persist)"

echo ""
echo "── Исходные данные ──"
if [ -n "${TMPFS_PATHS}" ] && [ -n "${OVL_PATHS}" ] && [ -n "${PERS_PATHS}" ]
then ok "режимы разобраны: tmpfs $(echo ${TMPFS_PATHS}|wc -w), overlay $(echo ${OVL_PATHS}|wc -w), persist $(echo ${PERS_PATHS}|wc -w)"
else no "в write_paths.txt нет всех трёх режимов — проверка вырождена"; fi
if [ -n "${RAM}" ] && [ -n "${ROOT_UUID}" ] && [ -n "${DATA_UUID}" ]
then ok "факты платы: ОЗУ ${RAM} МБ, root ${ROOT_UUID}, data ${DATA_UUID}"
else no "не разобрался data/board_facts.txt"; fi

echo ""
echo "── Носитель только для чтения ──"
if has_mp /; then
    if has_opt / ro; then ok "корень смонтирован ro"
    else no "корень монтируется на запись (опции: $(opts_of /)) — сбой питания застанет его в середине записи"; fi
    if [ "$(dev_of /)" = "PARTUUID=${ROOT_UUID}" ]; then ok "корень по PARTUUID=${ROOT_UUID}"
    else no "корень как «$(dev_of /)» — имена устройств зависят от порядка обнаружения"; fi
    if has_opt / noatime; then ok "noatime на корне"
    else no "нет noatime на корне: каждое чтение файла порождает запись времени доступа"; fi
else no "нет строки для /"; fi

if has_mp /boot; then
    if has_opt /boot ro; then ok "/boot смонтирован ro"
    else no "/boot на запись — после настройки он не меняется"; fi
    if [ "$(dev_of /boot)" = "PARTUUID=${BOOT_UUID}" ]; then ok "/boot по PARTUUID=${BOOT_UUID}"
    else no "/boot как «$(dev_of /boot)»"; fi
else no "нет строки для /boot"; fi

echo ""
echo "── Пути в памяти (tmpfs) ──"
TOTAL=0
for p in ${TMPFS_PATHS}; do
    if ! has_mp "${p}"; then no "${p}: нет строки, а по замерам туда идёт запись"; continue; fi
    t="$(type_of "${p}")"
    if [ "${t}" != "tmpfs" ]; then no "${p}: тип «${t}», по write_paths.txt должен быть tmpfs"; continue; fi
    sz="$(printf '%s' "$(opts_of "${p}")" | tr ',' '\n' | awk -F= '$1=="size"{print $2; exit}')"
    if [ -z "${sz}" ]; then no "${p}: tmpfs без size= — вырастет и съест всю память"; continue; fi
    n="$(printf '%s' "${sz}" | tr -dc '0-9')"
    case "${sz}" in *[Gg]) n=$((n*1024)) ;; esac
    need="$(awk -v p="${p}" '/^[[:space:]]*#/{next} $1==p {print $2; exit}' "${WP}")"
    if [ "${n}" -ge "${need}" ] 2>/dev/null; then
        TOTAL=$((TOTAL+n)); ok "${p}: tmpfs size=${sz} (замер ${need} МБ/сутки)"
    else
        TOTAL=$((TOTAL+n)); no "${p}: size=${sz} меньше суточной записи ${need} МБ — переполнится за сутки"
    fi
    if has_opt "${p}" nosuid && has_opt "${p}" nodev; then ok "${p}: nosuid,nodev"
    else no "${p}: нет nosuid/nodev на записываемой ФС"; fi
done
LIMIT=$((RAM/2))
if [ "${TOTAL}" -le "${LIMIT}" ]; then ok "суммарный tmpfs ${TOTAL} МБ ≤ половины ОЗУ (${LIMIT} МБ)"
else no "суммарный tmpfs ${TOTAL} МБ > половины ОЗУ (${LIMIT} МБ) — свопа на узле нет, придёт OOM"; fi

echo ""
echo "── Слой поверх (overlay) ──"
for p in ${OVL_PATHS}; do
    if ! has_mp "${p}"; then no "${p}: нет строки, а режим — overlay"; continue; fi
    if [ "$(type_of "${p}")" = "overlay" ]; then ok "${p}: тип overlay"
    else no "${p}: тип «$(type_of "${p}")», по write_paths.txt — overlay"; fi
    miss=""
    for o in lowerdir upperdir workdir; do has_optp "${p}" "${o}=" || miss="${miss} ${o}"; done
    if [ -z "${miss}" ]; then ok "${p}: заданы lowerdir, upperdir, workdir"
    else no "${p}: не заданы:${miss} — overlay без них не смонтируется"; fi
    low="$(printf '%s' "$(opts_of "${p}")" | tr ',' '\n' | awk -F= '$1=="lowerdir"{print $2; exit}')"
    if [ "${low}" = "${p}" ]; then ok "${p}: нижний слой — исходное содержимое"
    else no "${p}: lowerdir=«${low}», а исходное содержимое лежит в ${p}"; fi
    up="$(printf '%s' "$(opts_of "${p}")" | tr ',' '\n' | awk -F= '$1=="upperdir"{print $2; exit}')"
    case "${up}" in /run/*|/dev/shm/*|/tmp/*) ok "${p}: верхний слой в памяти (${up})" ;;
        *) no "${p}: upperdir=«${up}» — верхний слой должен быть в памяти, иначе запись идёт на карту" ;; esac
done

echo ""
echo "── Что переживает перезагрузку (отдельный раздел) ──"
for p in ${PERS_PATHS}; do
    if ! has_mp "${p}"; then no "${p}: нет строки, а данные обязаны пережить перезагрузку"; continue; fi
    t="$(type_of "${p}")"
    if [ "${t}" = "tmpfs" ] || [ "${t}" = "overlay" ]
    then no "${p}: смонтирован как ${t} — при перезагрузке данные исчезнут, а они обязаны остаться"
    else ok "${p}: настоящая ФС (${t}), а не память"; fi
    if [ "$(dev_of "${p}")" = "PARTUUID=${DATA_UUID}" ]; then ok "${p}: по PARTUUID=${DATA_UUID}"
    else no "${p}: устройство «$(dev_of "${p}")», ждали PARTUUID=${DATA_UUID}"; fi
    if has_opt "${p}" nofail; then ok "${p}: nofail — узел поднимется и с побитым разделом"
    else no "${p}: нет nofail: побитый раздел данных оставит удалённый узел незагруженным"; fi
    if has_opt "${p}" noatime; then ok "${p}: noatime"
    else no "${p}: нет noatime — лишняя запись на каждое чтение"; fi
done

echo ""
echo "── Общая целостность ──"
DUP="$(awk '{print $2}' <<<"${ROWS}" | sort | uniq -d | grep -c .)"
[ "${DUP}" -eq 0 ] && ok "нет повторяющихся точек монтирования" \
                   || no "${DUP} точек монтирования заданы дважды — сработает последняя"
if awk '$2!="/" && $2!="/boot" && $4 !~ /(^|,)ro(,|$)/ && $4 !~ /(^|,)nosuid(,|$)/ {f=1} END{exit !f}' <<<"${ROWS}"
then no "есть записываемая точка без nosuid"; else ok "все записываемые точки с nosuid"; fi
if awk '$3=="tmpfs" && $6!="0" {f=1} END{exit !f}' <<<"${ROWS}"
then no "у tmpfs ненулевое поле pass — проверять fsck нечего"; else ok "у tmpfs поле pass = 0"; fi
BAD="$(awk '$1 ~ /^\/dev\// {print $1}' <<<"${ROWS}" | grep -c . )"
[ "${BAD}" -eq 0 ] && ok "ни одного /dev/… — только PARTUUID и виртуальные ФС" \
                   || no "${BAD} строк ссылаются на /dev/… — имена зависят от порядка обнаружения"

# сколько записи осталось на карту
SAVED="$(awk '/^[[:space:]]*#/{next} NF>=3 && $3!="persist" {s+=$2} END{print s+0}' "${WP}")"
KEPT="$(awk  '/^[[:space:]]*#/{next} NF>=3 && $3=="persist" {s+=$2} END{print s+0}' "${WP}")"
ok "на карту уходит ${KEPT} МБ/сутки вместо $((SAVED+KEPT)) — снято ${SAVED}"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
