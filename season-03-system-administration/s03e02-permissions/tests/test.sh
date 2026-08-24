#!/usr/bin/env bash
#
# s03e02 «Кто что может» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт perms_report.txt сверяется
# со снимками прав и SUID-файлов из data/. Эталон вычисляется здесь же —
# констант в тесте нет.
#
# Без root, без сети: разбираются копии вывода ls -l и find.
#
# Выбор отчёта: SUBJECT=... | artifacts/perms_report.txt | <серия>/perms_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
A="${DATA}/perm_audit_shadow-01.txt"
S="${DATA}/suid_scan_shadow-01.txt"

if   [ -n "${SUBJECT:-}" ];                            then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/perms_report.txt" ];then REPORT="${SERIES_DIR}/artifacts/perms_report.txt"
elif [ -f "${SERIES_DIR}/perms_report.txt" ];          then REPORT="${SERIES_DIR}/perms_report.txt"
else REPORT="${SERIES_DIR}/solution/perms_report.txt"
     echo "ℹ️  Свой perms_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/perms_report.txt artifacts/perms_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e02 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${A}" "${S}"; do
    if [ ! -f "${f}" ]; then
        echo "  FAIL: не найден объект разведки: ${f}" >&2
        exit 1
    fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт perms_report.txt найден"
else
    no "perms_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из снимков -----------------------------------------
rows() { grep -E '^[-dl]' "$1"; }

# rwx-строка → восьмеричное представление (с учётом специальных битов)
to_octal() {
    awk -v p="$1" 'BEGIN {
        split("rwxrwxrwx", m, "");
        v = 0; sp = 0;
        for (i = 1; i <= 9; i++) {
            c = substr(p, i + 1, 1);
            bit = (i % 3 == 1) ? 4 : (i % 3 == 2) ? 2 : 1;
            shift = (i <= 3) ? 64 : (i <= 6) ? 8 : 1;
            if (c == m[i] || c == "s" || c == "t") v += bit * shift;
        }
        if (substr(p,4,1) ~ /[sS]/) sp += 4;
        if (substr(p,7,1) ~ /[sS]/) sp += 2;
        if (substr(p,10,1) ~ /[tT]/) sp += 1;
        o = "";
        n = v;
        printf "%s%o%o%o", (sp ? sp "" : ""), int(n/64), int((n%64)/8), n%8;
    }'
}

perm_of() { rows "${A}" | awk -v path="$1" '$NF == path {print $1; exit}'; }

exp_shadow=$(to_octal "$(perm_of /etc/shadow)")
exp_sudoers=$(to_octal "$(perm_of /etc/sudoers)")
exp_dmitry=$(to_octal "$(perm_of /home/dmitry)")

exp_ww_files=$(rows "${A}" | awk '$1 ~ /^-.{7}w/ {print $NF}' | sort | paste -sd, - | tr -d ' ')
exp_ww_dirs=$(rows "${A}" | awk '$1 ~ /^d.{7}w/ {print $NF}' | sort | paste -sd, - | tr -d ' ')
exp_unsafe=$(rows "${A}" | awk '$1 ~ /^d.{7}w/ && substr($1,10,1) !~ /[tT]/ {print $NF}' \
               | sort | paste -sd, - | tr -d ' ')
exp_keys=$(rows "${A}" | awk '$NF ~ /id_ed25519$/ && $1 !~ /^-rw-------/ {print $NF}' \
             | sort | paste -sd, - | tr -d ' ')

exp_suid=$(rows "${S}" | awk '$1 ~ /^-..s/' | wc -l | tr -d ' ')
exp_sgid=$(rows "${S}" | awk '$1 ~ /^-.....s/' | wc -l | tr -d ' ')
exp_outside=$(rows "${S}" | awk '$1 ~ /^-..s/ && $NF !~ /^\/usr\// {print $NF}' \
                | sort | paste -sd, - | tr -d ' ')
exp_planted=$(rows "${S}" | awk '$1 ~ /^-..s/ && $3 == "root" && $NF ~ /^\/home\// {print $NF}' | head -1)

# ---- чтение отчёта студента --------------------------------------------------
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${REPORT}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- | tr -d ' \t\r'
}

check() {
    local key="$1" want="$2" desc="$3" got
    got="$(val "${key}")"
    if [ -z "${got}" ]; then
        no "${desc}: значение не заполнено (${key}=)"
    elif [ "${got}" = "${want}" ]; then
        ok "${desc}: ${got}"
    else
        no "${desc}: указано '${got}', в снимке '${want}'"
    fi
}

check shadow_octal         "${exp_shadow}"   "права /etc/shadow"
check sudoers_octal        "${exp_sudoers}"  "права /etc/sudoers"
check dmitry_home_octal    "${exp_dmitry}"   "права домашнего каталога dmitry"
check world_writable_files "${exp_ww_files}" "файлы, доступные всем на запись"
check world_writable_dirs  "${exp_ww_dirs}"  "каталоги, доступные всем на запись"
check unsafe_shared_dirs   "${exp_unsafe}"   "общие каталоги без sticky"
check exposed_private_keys "${exp_keys}"     "приватные ключи с широкими правами"
check suid_total           "${exp_suid}"     "файлов с SUID"
check sgid_total           "${exp_sgid}"     "файлов с SGID"
check suid_outside_usr     "${exp_outside}"  "SUID за пределами /usr"
check planted_suid         "${exp_planted}"  "подсаженный SUID в домашнем каталоге"

# ---- согласованность отчёта -------------------------------------------------
if printf '%s' "$(val world_writable_dirs)" | grep -q "$(val unsafe_shared_dirs | cut -d, -f1)"; then
    ok "самопроверка отчёта: небезопасные каталоги — подмножество доступных на запись"
else
    no "самопроверка отчёта: unsafe_shared_dirs не согласован с world_writable_dirs"
fi

if printf '%s' "$(val suid_outside_usr)" | grep -q "$(val planted_suid)"; then
    ok "самопроверка отчёта: подсаженный SUID входит в список вне /usr"
else
    no "самопроверка отчёта: planted_suid не согласован с suid_outside_usr"
fi

# ---- самопроверки: ловушки в данных на месте --------------------------------
n_dirs=$(printf '%s' "${exp_ww_dirs}" | tr ',' '\n' | grep -c .)
n_unsafe=$(printf '%s' "${exp_unsafe}" | tr ',' '\n' | grep -c .)
if [ "${n_dirs}" -gt "${n_unsafe}" ]; then
    ok "самопроверка данных: есть каталог 777 СО sticky (${n_dirs} против ${n_unsafe}) — ловушка на месте"
else
    no "самопроверка данных: разница между 777 и 1777 исчезла, задание ослабло"
fi

if [ "$(printf '%s' "${exp_outside}" | tr ',' '\n' | grep -c .)" -gt 1 ]; then
    ok "самопроверка данных: SUID вне /usr больше одного — не всякий из них атака"
else
    no "самопроверка данных: остался единственный SUID вне /usr, различать нечего"
fi

if rows "${S}" | awk '$1 ~ /^-.....s/' | grep -q .; then
    ok "самопроверка данных: SGID-файлы в снимке присутствуют"
else
    no "самопроверка данных: SGID-файлы пропали, половина задания исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
