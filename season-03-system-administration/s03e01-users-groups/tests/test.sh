#!/usr/bin/env bash
#
# s03e01 «Кто есть на этой машине» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт users_report.txt сверяется
# со снимками /etc/passwd, /etc/group и /etc/shadow из data/. Эталон
# вычисляется здесь же командами — констант в тесте нет.
#
# Без root, без сети: разбираются копии файлов, лежащие в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/users_report.txt | <серия>/users_report.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
P="${DATA}/passwd_shadow-01.txt"
G="${DATA}/group_shadow-01.txt"
S="${DATA}/shadow_shadow-01.txt"

if   [ -n "${SUBJECT:-}" ];                            then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/users_report.txt" ];then REPORT="${SERIES_DIR}/artifacts/users_report.txt"
elif [ -f "${SERIES_DIR}/users_report.txt" ];          then REPORT="${SERIES_DIR}/users_report.txt"
else REPORT="${SERIES_DIR}/solution/users_report.txt"
     echo "ℹ️  Свой users_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/users_report.txt artifacts/users_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e01 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${P}" "${G}" "${S}"; do
    if [ ! -f "${f}" ]; then
        echo "  FAIL: не найден объект разведки: ${f}" >&2
        exit 1
    fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт users_report.txt найден"
else
    no "users_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из снимков -----------------------------------------
noc() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

exp_total=$(noc "${P}" | wc -l | tr -d ' ')
exp_system=$(noc "${P}" | awk -F: '$3 < 1000' | wc -l | tr -d ' ')
exp_human=$(noc "${P}" | awk -F: '$3 >= 1000 && $3 != 65534' | wc -l | tr -d ' ')
exp_uid0=$(noc "${P}" | awk -F: '$3 == 0 {print $1}' | sort | paste -sd, - | tr -d ' ')
exp_sudo=$(noc "${G}" | awk -F: '$1=="sudo" {print $4}' | tr -d ' ')
exp_nopass=$(noc "${S}" | awk -F: '$2 == "" {print $1}' | sort | paste -sd, - | tr -d ' ')
exp_locked=$(noc "${S}" | awk -F: '$2 ~ /^!/ {print $1}' | sort | paste -sd, - | tr -d ' ')
exp_svcshell=$(noc "${P}" | awk -F: '$3 < 1000 && $1 != "root" && $7 ~ /(bash|zsh|\/sh)$/ {print $1}' \
                 | sort | paste -sd, - | tr -d ' ')
exp_opslogs=$(noc "${G}" | awk -F: '$1=="ops-logs" {print $4}' | tr ',' '\n' | grep -c .)
# «Учётка, которой быть не должно» — единственный UID 0, кроме root.
exp_backdoor=$(noc "${P}" | awk -F: '$3 == 0 && $1 != "root" {print $1}' | head -1)

# ---- чтение отчёта студента --------------------------------------------------
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${REPORT}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- | tr -d ' \t\r'
}

check() {  # check <ключ> <эталон> <описание>
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

check accounts_total     "${exp_total}"    "всего учётных записей"
check system_accounts    "${exp_system}"   "системных (UID < 1000)"
check human_accounts     "${exp_human}"    "человеческих (UID >= 1000)"
check uid0_accounts      "${exp_uid0}"     "учётки с UID 0"
check sudo_members       "${exp_sudo}"     "состав группы sudo"
check passwordless       "${exp_nopass}"   "вход без пароля"
check locked_accounts    "${exp_locked}"   "заблокированные"
check service_with_shell "${exp_svcshell}" "служебные с интерактивной оболочкой"
check ops_logs_members   "${exp_opslogs}"  "человек в группе ops-logs"
check backdoor_account   "${exp_backdoor}" "учётка, которой быть не должно"

# ---- согласованность отчёта -------------------------------------------------
sum=$(( $(val system_accounts 2>/dev/null || echo 0) + $(val human_accounts 2>/dev/null || echo 0) ))
if [ "${sum}" -eq "$(( exp_total - 1 ))" ]; then
    ok "самопроверка отчёта: системные + человеческие + nobody = все ${exp_total}"
else
    no "самопроверка отчёта: сумма системных и человеческих не сходится с общим числом"
fi

if printf '%s' "$(val uid0_accounts)" | grep -q "$(val backdoor_account)"; then
    ok "самопроверка отчёта: подозрительная учётка входит в список UID 0"
else
    no "самопроверка отчёта: backdoor_account не согласован с uid0_accounts"
fi

# ---- самопроверки: в данных есть что искать ---------------------------------
n_uid0=$(noc "${P}" | awk -F: '$3 == 0' | wc -l | tr -d ' ')
if [ "${n_uid0}" -gt 1 ]; then
    ok "самопроверка данных: учётных записей с UID 0 больше одной (${n_uid0})"
else
    no "самопроверка данных: вторая учётка с UID 0 исчезла, задание вырождено"
fi

if [ -n "${exp_nopass}" ] && [ -n "${exp_svcshell}" ]; then
    ok "самопроверка данных: в снимке есть и вход без пароля, и служебная учётка с оболочкой"
else
    no "самопроверка данных: аномалии из снимка пропали, задание ослабло"
fi

# Ловушка: /bin/sync — не nologin, но и не вход в систему.
if noc "${P}" | awk -F: '$7 ~ /sync$/' | grep -q .; then
    ok "самопроверка данных: ловушка «не nologin ещё не значит вход» на месте (sync)"
else
    no "самопроверка данных: учётка с /bin/sync пропала, ловушка ослабла"
fi

# Ловушка: имя учётки ничего не решает — решает UID.
if noc "${P}" | awk -F: '$3 == 0 && $1 != "root"' | grep -q .; then
    ok "самопроверка данных: права даёт UID, а не имя — ловушка на месте"
else
    no "самопроверка данных: ловушка «root по имени» исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
