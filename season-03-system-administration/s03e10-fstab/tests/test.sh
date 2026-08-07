#!/usr/bin/env bash
#
# s03e10 «Машина, которая не поднялась» (капстоун Episode 11) —
# тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства таблицы монтирования: каждая запись
# сверяется со снимком blkid из data/ — существует ли устройство, тот ли
# тип файловой системы. Констант в тесте нет: UUID и типы берутся из
# снимка (§4.2, §4.3).
#
# Отдельно ловятся: имена вида /dev/vdX (порядок обнаружения, а не адрес),
# запись для несуществующего устройства (аварийный режим при загрузке),
# отсутствующие тома и неверный порядок fsck.
#
# Без root, без сети: mount не запускается.
#
# Выбор артефакта: SUBJECT=... | artifacts/fstab | <серия>/fstab | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
BLKID="${DATA}/blkid_shadow-01.txt"
DISK="${DATA}/disk_shadow-01.txt"
STARTER="${SERIES_DIR}/starter/fstab"

if   [ -n "${SUBJECT:-}" ];                    then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/fstab" ];   then CFG="${SERIES_DIR}/artifacts/fstab"
elif [ -f "${SERIES_DIR}/fstab" ];             then CFG="${SERIES_DIR}/fstab"
else CFG="${SERIES_DIR}/solution/fstab"
     echo "ℹ️  Свой fstab не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/fstab artifacts/fstab"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e10 tests — fstab: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${BLKID}" "${DISK}"; do
    if [ ! -f "${f}" ]; then echo "  FAIL: не найден снимок: ${f}" >&2; exit 1; fi
done
if [ -f "${CFG}" ]; then
    ok "таблица монтирования найдена"
else
    no "fstab не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- чтение ------------------------------------------------------------------
rows()  { sed -e 's/\r$//' -e 's/#.*$//' "${CFG}" | grep -vE '^[[:space:]]*$'; }
bl()    { grep -vE '^[[:space:]]*#|^[[:space:]]*$' "${BLKID}"; }
# UUID → устройство и UUID → тип, по снимку blkid
uuid_dev()  { bl | awk -v u="$1" -F'"' '{for(i=1;i<NF;i++) if ($i==u) {split($0,a,":"); print a[1]; exit}}'; }
uuid_type() { bl | awk -v u="$1" '$0 ~ ("UUID=\"" u "\"") {
                  if (match($0, /TYPE="[^"]+"/)) { t=substr($0, RSTART+6, RLENGTH-7); print t; exit } }'; }

# ---- 1. формат ---------------------------------------------------------------
bad=$(rows | awk 'NF!=6 {print NR": "$0}')
if [ -z "${bad}" ]; then
    ok "формат: в каждой записи ровно шесть полей"
else
    no "запись не из шести полей: $(printf '%s' "${bad}" | head -1)"
fi

if rows | grep -q .; then ok "таблица не пуста"; else no "в таблице нет ни одной записи"; fi

# ---- 2. устойчивые адреса ----------------------------------------------------
unstable=$(rows | awk '$1 ~ /^\/dev\/(sd|vd|hd|nvme)/ {print $1" → "$2}')
if [ -z "${unstable}" ]; then
    ok "имена вида /dev/vdX не используются — адресация устойчивая"
else
    no "адрес зависит от порядка обнаружения дисков: $(printf '%s' "${unstable}" | head -1)"
fi

# ---- 3. каждый UUID существует в снимке --------------------------------------
ghost=""; typemis=""
dev_type() { bl | awk -v d="$1" 'index($0, d": ")==1 {
                 if (match($0, /TYPE="[^"]+"/)) { print substr($0, RSTART+6, RLENGTH-7); exit } }'; }
while read -r dev mp fs opts dump pass; do
    case "${dev}" in
      UUID=*) u="${dev#UUID=}"
              d="$(uuid_dev "${u}")"
              [ -z "${d}" ] && { ghost="${ghost} ${mp}(${u})"; continue; }
              t="$(uuid_type "${u}")" ;;
      /dev/*) bl | grep -q "^${dev}:" || { ghost="${ghost} ${mp}(${dev})"; continue; }
              t="$(dev_type "${dev}")" ;;
      *)      continue ;;
    esac
    [ -n "${t}" ] && [ "${t}" != "${fs}" ] && typemis="${typemis} ${mp}:${fs}≠${t}"
done <<EOF
$(rows)
EOF

if [ -z "${ghost}" ]; then
    ok "все UUID из таблицы есть в снимке blkid"
else
    no "запись для несуществующего устройства — загрузка уйдёт в аварийный режим:${ghost}"
fi
if [ -z "${typemis}" ]; then
    ok "типы файловых систем совпадают со снимком"
else
    no "тип ФС не совпадает с blkid:${typemis}"
fi

# ---- 4. все тома на месте ----------------------------------------------------
exp_mounts=$(awk '$0=="=== df -h ===" {f=1; next} /^=== /{f=0} f' "${DISK}" \
             | awk 'NR>1 && $1 ~ /^\/dev\// {print $NF}' | sort -u)
missing=""
for m in ${exp_mounts}; do
    rows | awk -v m="${m}" '$2==m {f=1} END{exit !f}' || missing="${missing} ${m}"
done
if [ -z "${missing}" ]; then
    ok "смонтированы все тома из снимка: $(printf '%s' "${exp_mounts}" | tr '\n' ' ')"
else
    no "в таблице нет записи для:${missing} — после перезагрузки том не вернётся"
fi

if rows | awk '$3=="swap" {f=1} END{exit !f}'; then
    ok "подкачка описана"
else
    no "нет записи для swap — после перезагрузки подкачки не будет"
fi

dups=$(rows | awk '$2!="none" && $2!="swap" {print $2}' | sort | uniq -d)
if [ -z "${dups}" ]; then
    ok "точки монтирования не дублируются"
else
    no "точка монтирования описана дважды: ${dups}"
fi

# ---- 5. порядок проверки fsck ------------------------------------------------
root_pass=$(rows | awk '$2=="/" {print $6; exit}')
if [ "${root_pass}" = "1" ]; then
    ok "корень проверяется первым (pass=1)"
else
    no "у корня pass=${root_pass:-не задан}, должен быть 1"
fi

bad_pass=$(rows | awk '$2!="/" && $3 ~ /^(ext[234]|xfs)$/ && $6!="2" {print $2"="$6}')
if [ -z "${bad_pass}" ]; then
    ok "прочие файловые системы проверяются вторыми (pass=2)"
else
    no "неверный порядок проверки: ${bad_pass}"
fi

bad_swap=$(rows | awk '($3=="swap" || $3=="tmpfs") && ($6!="0" || $5!="0") {print $2}')
if [ -z "${bad_swap}" ]; then
    ok "у swap и tmpfs dump и pass равны нулю"
else
    no "swap/tmpfs помечены для проверки fsck: ${bad_swap}"
fi

bad_dump=$(rows | awk '$5!="0" {print $2"="$5}')
if [ -z "${bad_dump}" ]; then
    ok "поле dump везде 0"
else
    no "поле dump не ноль: ${bad_dump} — утилиты dump давно нет"
fi

# ---- 6. опции монтирования ---------------------------------------------------
opts_of() { rows | awk -v m="$1" '$2==m {print $4; exit}'; }
has_opt() { printf '%s' "$1" | tr ',' '\n' | grep -qx "$2"; }

for m in /var/log /var/spool; do
    o="$(opts_of "${m}")"
    if [ -z "${o}" ]; then
        no "нет записи для ${m} — опции проверять не на чем"
        continue
    fi
    miss=""
    for opt in nodev nosuid noexec; do has_opt "${o}" "${opt}" || miss="${miss} ${opt}"; done
    if [ -z "${miss}" ]; then
        ok "${m}: nodev, nosuid, noexec — SUID-копия оболочки здесь бесполезна"
    else
        no "${m}: не хватает опций:${miss} (см. закладку из s03e02)"
    fi
done

if has_opt "$(opts_of /var/log)" noatime; then
    ok "/var/log смонтирован с noatime — чтение не порождает запись"
else
    no "/var/log без noatime: ядро будет писать время доступа при каждом чтении журнала"
fi

# ---- 7. самопроверки ---------------------------------------------------------
if [ -f "${STARTER}" ] && grep -qE '^/dev/(vd|sd)' "${STARTER}"; then
    ok "самопроверка: в стартере ловушка на месте (имя устройства вместо UUID)"
else
    no "самопроверка: стартер больше не содержит неустойчивых имён — чинить нечего"
fi

if [ -f "${STARTER}" ] \
   && [ -n "$(awk '$1 ~ /^\/dev\// {print $1}' "${STARTER}" | while read -r d; do
                 grep -q "^${d}:" "${BLKID}" || echo "${d}"; done)" ]; then
    ok "самопроверка: в стартере есть запись для устройства, которого нет в blkid"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
