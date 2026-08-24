#!/usr/bin/env bash
#
# s08e11 «Руткит» — тест разбора (Type C).
#
# Каждое расхождение пересчитывается сравнением двух снимков. Констант нет.
#
# Отдельно проверяется, что данные не выродились: во всех четырёх парах
# независимый взгляд видит больше системного (иначе прятать было бы нечего)
# и что скрытый модуль присутствует — именно он объясняет остальное.
#
# Без root, без сети.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"

if   [ -n "${SUBJECT:-}" ];                               then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/rootkit_report.txt" ]; then REP="${SERIES_DIR}/artifacts/rootkit_report.txt"
elif [ -f "${SERIES_DIR}/rootkit_report.txt" ];           then REP="${SERIES_DIR}/rootkit_report.txt"
else REP="${SERIES_DIR}/solution/rootkit_report.txt"
     echo "ℹ️  Своего rootkit_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/rootkit_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e11 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in ps proc_pids netstat proc_net_tcp ls_etc_systemd getdents_etc_systemd \
         lsmod proc_modules; do
    [ -f "${D}/${f}.txt" ] || { echo "  FAIL: нет ${D}/${f}.txt"; exit 1; }
done
[ -f "${REP}" ] || { echo "  FAIL: нет ${REP}"; echo " Итог: 0 passed, 1 failed"; exit 1; }

val() { awk -F= -v k="$1" '{sub(/#.*/,"")} $1==k {gsub(/^[ \t]+|[ \t\r]+$/,"",$2); print $2; exit}' "${REP}"; }
check() { got="$(val "$1")"; [ "${got}" = "$2" ] && ok "$1=$2${3:+ — $3}" \
          || no "$1=${got:-пусто}, ожидается $2${3:+ — $3}"; }

# Первая колонка (после комментариев) каждого снимка — ключ сравнения.
col1() { local c="${2:-1}"; awk -v c="$c" '{sub(/#.*/,"")} NF>=c && $c!="" {print $c}' "$1" | LC_ALL=C sort; }
count() { col1 "$1" "${2:-1}" | grep -c . || true; }
# Что во втором файле есть, а в первом нет.
only_in_2() { comm -13 <(col1 "$1" "${3:-1}") <(col1 "$2" "${3:-1}"); }

echo ""
echo "── 0. Данные не выродились ──"
for pair in "ps proc_pids 1" "netstat proc_net_tcp 2" "ls_etc_systemd getdents_etc_systemd 1" "lsmod proc_modules 1"; do
    set -- $pair
    a=$(count "${D}/$1.txt" "$3"); b=$(count "${D}/$2.txt" "$3")
    [ "$b" -gt "$a" ] && ok "независимый взгляд ($2: $b) видит больше системного ($1: $a)" \
        || no "данные вырождены: $2=$b не больше $1=$a"
done

echo ""
echo "── 1. Процессы ──"
check ps_count       "$(count "${D}/ps.txt")"
check proc_count     "$(count "${D}/proc_pids.txt")"
H="$(only_in_2 "${D}/ps.txt" "${D}/proc_pids.txt")"
check hidden_pids    "$(printf '%s' "${H}" | grep -c . || true)"
check hidden_pid_list "$(printf '%s' "${H}" | paste -sd, -)"

echo ""
echo "── 2. Порты ──"
check netstat_ports   "$(count "${D}/netstat.txt" 2)"
check proc_net_ports  "$(count "${D}/proc_net_tcp.txt" 2)"
HP="$(only_in_2 "${D}/netstat.txt" "${D}/proc_net_tcp.txt" 2)"
check hidden_ports    "$(printf '%s' "${HP}" | grep -c . || true)"
check hidden_port_list "$(printf '%s' "${HP}" | paste -sd, -)"

echo ""
echo "── 3. Файлы ──"
check ls_count        "$(count "${D}/ls_etc_systemd.txt")"
check getdents_count  "$(count "${D}/getdents_etc_systemd.txt")"
HF="$(only_in_2 "${D}/ls_etc_systemd.txt" "${D}/getdents_etc_systemd.txt")"
check hidden_files    "$(printf '%s' "${HF}" | grep -c . || true)"
check hidden_file_list "$(printf '%s' "${HF}" | paste -sd, -)"

echo ""
echo "── 4. Модули ──"
check lsmod_count       "$(count "${D}/lsmod.txt")"
check proc_modules_count "$(count "${D}/proc_modules.txt")"
HM="$(only_in_2 "${D}/lsmod.txt" "${D}/proc_modules.txt")"
check hidden_modules    "$(printf '%s' "${HM}" | grep -c . || true)"
check hidden_module_list "$(printf '%s' "${HM}" | paste -sd, -)"

echo ""
echo "── 5. Вывод ──"
# Сколько пар разошлись — считаем сами.
DIV=0
for pair in "ps proc_pids 1" "netstat proc_net_tcp 2" "ls_etc_systemd getdents_etc_systemd 1" "lsmod proc_modules 1"; do
    set -- $pair
    [ -n "$(only_in_2 "${D}/$1.txt" "${D}/$2.txt" "$3")" ] && DIV=$((DIV+1))
done
check views_diverged "${DIV}"
check consistent_story yes
check verdict        rootkit-suspected
check trust          outside "система изнутри врёт согласованно"
check next_step      investigate-offline "руткит в ядре переживёт перезагрузку и патч"

echo ""
echo "── 6. Форма ──"
grep -q '^#' "${REP}" && ok "комментарии сохранены" || no "комментарии удалены"
grep -qE '^[a-z0-9_]+= *$' "${REP}" && no "есть незаполненные ключи" || ok "незаполненных ключей нет"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
