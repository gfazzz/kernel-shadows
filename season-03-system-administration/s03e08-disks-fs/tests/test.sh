#!/usr/bin/env bash
#
# s03e08 «Место, которого нет» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт disk_report.txt сверяется
# со снимком дискового состояния из data/. Эталон вычисляется здесь же —
# констант в тесте нет (§4.2, §4.3).
#
# Без root, без сети: разбирается копия вывода df, lsblk, du и lsof.
#
# Выбор отчёта: SUBJECT=... | artifacts/disk_report.txt | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/../data/disk_shadow-01.txt"

if   [ -n "${SUBJECT:-}" ];                             then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/disk_report.txt" ];  then REPORT="${SERIES_DIR}/artifacts/disk_report.txt"
elif [ -f "${SERIES_DIR}/disk_report.txt" ];            then REPORT="${SERIES_DIR}/disk_report.txt"
else REPORT="${SERIES_DIR}/solution/disk_report.txt"
     echo "ℹ️  Свой disk_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/disk_report.txt artifacts/disk_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e08 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ ! -f "${D}" ]; then echo "  FAIL: не найден объект разведки: ${D}" >&2; exit 1; fi
if [ -f "${REPORT}" ]; then
    ok "отчёт disk_report.txt найден"
else
    no "disk_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- эталон: вычисляется из снимка ------------------------------------------
sec() { awk -v s="$1" '$0=="=== "s" ===" {f=1; next} /^=== /{f=0} f' "${D}" | grep -v '^[[:space:]]*$'; }
# «4.2G» → байты (для сравнений внутри теста, не для отчёта)
tobytes() { awk -v v="$1" 'BEGIN {
    n=v; u=substr(v,length(v),1); sub(/[KMGTP]$/,"",n)
    m = (u=="K")?1024 : (u=="M")?1048576 : (u=="G")?1073741824 : (u=="T")?1099511627776 : 1
    printf "%.0f", n*m }'; }

read -r exp_full exp_full_pct <<EOF
$(sec 'df -h' | awk 'NR>1 {p=$5; gsub(/%/,"",p); if (p+0 > m) {m=p+0; mp=$6}} END{print mp, m"%"}')
EOF

exp_inode_fs=$(sec 'df -i' | awk 'NR>1 && $5=="100%" {print $6; exit}')
exp_inode_free=$(sec 'df -h' | awk -v p="${exp_inode_fs}" '$6==p {print $4; exit}')

exp_df_used=$(sec 'df -h' | awk '$6=="/var/log" {print $3; exit}')
exp_du_total=$(sec 'du -h --max-depth=1 /var/log' | awk '$2=="/var/log" {print $1; exit}')

read -r exp_del_pid exp_del_cmd exp_del_bytes exp_del_file <<EOF
$(sec 'lsof +L1' | awk 'NR>1 {print $2, $1, $7, $NF}' | sort -k3 -nr | head -1)
EOF
# «(deleted)» — пометка lsof, а не часть пути
exp_del_file=$(sec 'lsof +L1' | awk -v p="${exp_del_pid}" '$2==p {print $(NF-1); exit}')

read -r exp_big_size exp_big_dir <<EOF
$(sec 'du -h --max-depth=1 /var/log' | awk '$2!="/var/log"' \
  | awk '{ v=$1; u=substr(v,length(v),1); sub(/[KMGTP]$/,"",v)
           m=(u=="K")?1024:(u=="M")?1048576:(u=="G")?1073741824:1
           b=v*m; if (b>best) {best=b; s=$1; d=$2} } END {print s, d}')
EOF
naive_big=$(sec 'du -h --max-depth=1 /var/log' | awk '$2!="/var/log"' | sort -rn | awk 'NR==1{print $2}')

exp_dev=$(sec 'df -h' | awk '$6=="/var/log" {print $1; exit}')
exp_fstype=$(sec 'lsblk -f' | awk '/ops--vg-log/ {for(i=1;i<=NF;i++) if ($i=="ext4"||$i=="xfs"||$i=="btrfs"||$i=="ext3") {print $i; exit}}')
exp_lv=$(sec 'lsblk -f' | grep -c 'ops--vg-')

# ---- чтение отчёта студента --------------------------------------------------
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${REPORT}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- | tr -d ' \t\r'
}
check() {
    local key="$1" want="$2" desc="$3" got
    got="$(val "${key}")"
    if [ -z "${got}" ];            then no "${desc}: значение не заполнено (${key}=)"
    elif [ "${got}" = "${want}" ]; then ok "${desc}: ${got}"
    else                                no "${desc}: указано '${got}', в снимке '${want}'"
    fi
}

check fullest_fs             "${exp_full}"       "самая заполненная файловая система"
check fullest_fs_use         "${exp_full_pct}"   "её занятость"
check inode_full_fs          "${exp_inode_fs}"   "файловая система с исчерпанными inode"
check inode_full_free        "${exp_inode_free}" "свободного места на ней"
check var_log_df_used        "${exp_df_used}"    "занято на /var/log по df"
check var_log_du_total       "${exp_du_total}"   "насчитал du по /var/log"
check deleted_file           "${exp_del_file}"   "удалённый файл, объясняющий разницу"
check deleted_holder_pid     "${exp_del_pid}"    "PID процесса, который его держит"
check deleted_holder_command "${exp_del_cmd}"    "имя процесса"
check deleted_file_bytes     "${exp_del_bytes}"  "размер удалённого файла в байтах"
check biggest_subdir         "${exp_big_dir}"    "самый крупный подкаталог /var/log"
check biggest_subdir_size    "${exp_big_size}"   "его размер"
check var_log_device         "${exp_dev}"        "устройство под /var/log"
check var_log_fstype         "${exp_fstype}"     "тип файловой системы"
check lvm_volumes            "${exp_lv}"         "логических томов LVM"

# ---- согласованность отчёта -------------------------------------------------
if [ "$(tobytes "$(val var_log_df_used)")" -gt "$(tobytes "$(val var_log_du_total)")" ] 2>/dev/null; then
    ok "самопроверка отчёта: df показывает больше, чем du — расхождение зафиксировано"
else
    no "самопроверка отчёта: df и du не расходятся, а вся серия про эту разницу"
fi

if [ "$(val inode_full_fs)" != "$(val fullest_fs)" ]; then
    ok "самопроверка отчёта: место кончилось не там, где кончились inode"
else
    no "самопроверка отчёта: исчерпание inode приписано самой заполненной ФС — в снимке это разные тома"
fi

# ---- самопроверки: ловушки в данных на месте --------------------------------
if [ "${naive_big}" != "${exp_big_dir}" ]; then
    ok "самопроверка данных: sort -n даёт ${naive_big} вместо ${exp_big_dir} — ловушка на месте"
else
    no "самопроверка данных: размеры перестали различаться по единицам, sort -h больше не нужен"
fi

if sec 'df -i' | awk 'NR>1 && $5=="100%" {f=1} END{exit !f}' \
   && sec 'df -h' | awk -v p="${exp_inode_fs}" '$6==p {gsub(/%/,"",$5); if ($5+0 < 50) f=1} END{exit !f}'; then
    ok "самопроверка данных: том с исчерпанными inode занят меньше чем наполовину"
else
    no "самопроверка данных: ловушка с inode исчезла"
fi

if [ "$(sec 'lsof +L1' | grep -c 'deleted')" -gt 1 ]; then
    ok "самопроверка данных: удалённых файлов больше одного — нужен именно крупнейший"
else
    no "самопроверка данных: остался единственный удалённый файл, выбирать не из чего"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
