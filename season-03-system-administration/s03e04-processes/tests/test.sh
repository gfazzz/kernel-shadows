#!/usr/bin/env bash
#
# s03e04 «PID 6623» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт proc_report.txt сверяется
# со снимками ps и /proc из data/. Эталон вычисляется здесь же — констант
# в тесте нет (§4.2, §4.3). Номера сигналов берутся у самой системы
# (`kill -l`), а не вписаны числами.
#
# Без root, без сети: разбираются копии вывода команд.
#
# Выбор отчёта: SUBJECT=... | artifacts/proc_report.txt | <серия>/proc_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
PS="${DATA}/ps_shadow-01.txt"
PROC="${DATA}/proc_shadow-01.txt"

if   [ -n "${SUBJECT:-}" ];                             then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/proc_report.txt" ];  then REPORT="${SERIES_DIR}/artifacts/proc_report.txt"
elif [ -f "${SERIES_DIR}/proc_report.txt" ];            then REPORT="${SERIES_DIR}/proc_report.txt"
else REPORT="${SERIES_DIR}/solution/proc_report.txt"
     echo "ℹ️  Свой proc_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/proc_report.txt artifacts/proc_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e04 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${PS}" "${PROC}"; do
    if [ ! -f "${f}" ]; then
        echo "  FAIL: не найден объект разведки: ${f}" >&2; exit 1
    fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт proc_report.txt найден"
else
    no "proc_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- разбор снимков ---------------------------------------------------------
rows() { grep -vE '^[[:space:]]*#|^USER[[:space:]]|^[[:space:]]*$' "${PS}"; }

# «pid <TAB> ключ <TAB> значение» по каждому разделу /proc
FIELDS="$(awk '
  /^=== \/proc\/[0-9]+ ===$/ { p=$0; gsub(/[^0-9]/,"",p); next }
  !p { next }
  /^exe -> /   { print p "\texe\t"     substr($0,8) }
  /^cwd -> /   { print p "\tcwd\t"     substr($0,8) }
  /^cmdline: / { print p "\tcmdline\t" substr($0,10) }
  /^Name:/     { print p "\tname\t"    $2 }
  /^State:/    { print p "\tstate\t"   $2 }
  /^PPid:/     { print p "\tppid\t"    $2 }' "${PROC}")"

pv() { printf '%s\n' "${FIELDS}" | awk -F'\t' -v p="$1" -v k="$2" '$1==p && $2==k {print $3; exit}'; }
pids_where() { printf '%s\n' "${FIELDS}" | awk -F'\t' -v k="$1" -v v="$2" '$2==k && $3==v {print $1}'; }

exp_real=$(pids_where exe /usr/sbin/sshd | head -1)

# самозванец: тот же Name и та же строка запуска, но exe ведёт в другой файл
exp_impostor=$(printf '%s\n' "${FIELDS}" | awk -F'\t' -v real="$(pv "${exp_real}" cmdline)" '
    $2=="cmdline" && $3==real {c[$1]=1}
    $2=="exe"     {e[$1]=$3}
    END { for (p in c) if (e[p] != "/usr/sbin/sshd" && e[p] !~ /deleted/) print p }' | head -1)
exp_impostor_exe=$(pv "${exp_impostor}" exe)

exp_masq=$(printf '%s\n' "${FIELDS}" | awk -F'\t' '$2=="exe" && $3 ~ /\(deleted\)$/ {print $1; exit}')
exp_masq_exe=$(pv "${exp_masq}" exe | sed 's/ *(deleted)$//')
exp_masq_cwd=$(pv "${exp_masq}" cwd)

exp_child=$(rows | awk -v p="${exp_masq}" '$3==p {print $2; exit}')
exp_beacon=$(rows | awk -v p="${exp_child}" '$2==p' \
              | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)

exp_zombie=$(rows | awk '$6 ~ /^Z/ {print $2; exit}')
exp_zparent=$(rows | awk -v p="${exp_zombie}" '$2==p {print $3; exit}')

exp_kthreads=$(rows | awk '$2==2 || $3==2' | wc -l | tr -d ' ')
naive_kthreads=$(rows | awk '{ $1=$1; sub(/^([^ ]+ ){7}/,""); if ($0 ~ /^\[/) n++ } END {print n+0}')

exp_topcpu=$(rows | sort -k4 -nr | awk '{print $2; exit}')
exp_monitoring=$(rows | awk '$1 ~ /^monitor/' | wc -l | tr -d ' ')

# номера сигналов спрашиваем у самой системы, а не вписываем числами
signo() { kill -l "$1" 2>/dev/null | tr -dc '0-9'; }
exp_term=$(signo TERM)
exp_kill=$(signo KILL)
exp_hup=$(signo HUP)

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

check real_sshd_pid       "${exp_real}"        "PID настоящего sshd"
check impostor_sshd_pid   "${exp_impostor}"    "PID второго sshd, запущенного не из /usr/sbin"
check impostor_sshd_exe   "${exp_impostor_exe}" "путь, из которого он запущен"
check masquerade_pid      "${exp_masq}"        "PID процесса с удалённым образом"
check masquerade_exe      "${exp_masq_exe}"    "удалённый исполняемый файл"
check masquerade_cwd      "${exp_masq_cwd}"    "рабочий каталог закладки"
check masquerade_child_pid "${exp_child}"      "PID дочернего процесса закладки"
check beacon_ip           "${exp_beacon}"      "адрес, на который он ходит"
check zombie_pid          "${exp_zombie}"      "PID зомби"
check zombie_parent_pid   "${exp_zparent}"     "PID родителя зомби"
check kernel_threads      "${exp_kthreads}"    "потоков ядра"
check top_cpu_pid         "${exp_topcpu}"      "процесс с наибольшей долей CPU"
check monitoring_procs    "${exp_monitoring}"  "процессов у учётной записи monitoring"
check signal_graceful     "${exp_term}"        "сигнал корректного завершения"
check signal_uncatchable  "${exp_kill}"        "неперехватываемый сигнал"
check signal_reload       "${exp_hup}"         "сигнал перечитать конфигурацию"

# ---- согласованность отчёта -------------------------------------------------
if [ "$(val top_cpu_pid)" != "$(val masquerade_pid)" ]; then
    ok "самопроверка отчёта: самый прожорливый процесс и закладка — разные PID"
else
    no "самопроверка отчёта: закладка названа и самой прожорливой — в снимке это не так"
fi

if [ "$(val real_sshd_pid)" != "$(val impostor_sshd_pid)" ] \
   && [ "$(val real_sshd_pid)" != "$(val masquerade_pid)" ]; then
    ok "самопроверка отчёта: три sshd в снимке различены"
else
    no "самопроверка отчёта: настоящий sshd совпал с одним из подделок"
fi

# ---- самопроверки: ловушки в данных на месте --------------------------------
if [ "${naive_kthreads}" -gt "${exp_kthreads}" ]; then
    ok "самопроверка данных: подсчёт по квадратной скобке даёт ${naive_kthreads} против ${exp_kthreads} — ловушка на месте"
else
    no "самопроверка данных: зомби в квадратных скобках исчез, различать нечего"
fi

if [ "$(printf '%s\n' "${FIELDS}" | awk -F'\t' -v c="$(pv "${exp_real}" cmdline)" '$2=="cmdline" && $3==c' | wc -l | tr -d ' ')" -gt 1 ]; then
    ok "самопроверка данных: две одинаковые строки запуска sshd при разных exe"
else
    no "самопроверка данных: второй sshd больше не маскируется под первый"
fi

if rows | awk '$1 ~ /\+$/' | grep -q .; then
    ok "самопроверка данных: обрезанные имена пользователей в ps сохранены (monitor+)"
else
    no "самопроверка данных: имена в ps перестали обрезаться, ловушка исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
