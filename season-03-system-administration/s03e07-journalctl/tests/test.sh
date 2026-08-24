#!/usr/bin/env bash
#
# s03e07 «Вечер 14 октября» (капстоун Episode 10) — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а восстановленную студентом хронологию: отчёт
# journal_report.txt сверяется со снимком журнала из data/. Эталон
# вычисляется здесь же — констант в тесте нет.
#
# Без root, без сети: journalctl не запускается, разбирается копия вывода.
#
# Выбор отчёта: SUBJECT=... | artifacts/journal_report.txt | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
J="${DATA}/journal_shadow-01.txt"
E="${DATA}/journal_err_shadow-01.txt"

if   [ -n "${SUBJECT:-}" ];                                then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/journal_report.txt" ];  then REPORT="${SERIES_DIR}/artifacts/journal_report.txt"
elif [ -f "${SERIES_DIR}/journal_report.txt" ];            then REPORT="${SERIES_DIR}/journal_report.txt"
else REPORT="${SERIES_DIR}/solution/journal_report.txt"
     echo "ℹ️  Свой journal_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/journal_report.txt artifacts/journal_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e07 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${J}" "${E}"; do
    if [ ! -f "${f}" ]; then echo "  FAIL: не найден объект разведки: ${f}" >&2; exit 1; fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт journal_report.txt найден"
else
    no "journal_report.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- эталон: вычисляется из снимка ------------------------------------------
rows()  { grep -vE '^[[:space:]]*#|^[[:space:]]*$' "${J}"; }
erows() { grep -vE '^[[:space:]]*#|^[[:space:]]*$' "${E}"; }
stamp() { sed -E 's/^([0-9-]+T[0-9:]+).*/\1/'; }   # отбросить часовой пояс

exp_ip=$(rows | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' \
           | sort | uniq -c | sort -rn | awk 'NR==1{print $2}')
exp_failed=$(rows | grep -c 'Failed password')
naive_failed=$(rows | grep -ci 'invalid user')
exp_probed=$(rows | grep -oE 'Invalid user [A-Za-z0-9_-]+' | awk '{print $3}' \
               | sort -u | paste -sd, - | tr -d ' ')
exp_login=$(rows | grep 'Accepted ' | head -1 | stamp)
exp_account=$(rows | grep 'Accepted ' | head -1 | sed -E 's/.*Accepted [a-z]+ for ([^ ]+) .*/\1/')

exp_sudo=$(rows | grep -c 'COMMAND=')
naive_sudo=$(rows | grep -c 'sudo')
exp_useradd=$(rows | grep 'useradd\[' | head -1 | stamp)
exp_enabled=$(rows | grep 'Created symlink' | grep 'sshd-helper' | head -1 | stamp)
exp_started=$(rows | grep 'Started SSH connection helper' | head -1 | stamp)

# наибольший разрыв между записями ops-check
gap="$(rows | grep 'ops-check\[' | stamp | awk -F'[T:-]' '
    { m = $3*1440 + $4*60 + $5
      if (prev != "" && m - prev > best) { best = m - prev; a = prevline; b = $0 }
      prev = m; prevline = $0 }
    END { print a "\t" b "\t" best }')"
exp_gap_start=$(printf '%s' "${gap}" | cut -f1)
exp_gap_end=$(printf '%s' "${gap}" | cut -f2)
exp_gap_min=$(printf '%s' "${gap}" | cut -f3)
exp_jump=$(rows | grep 'clock jumped' | grep -oE '[0-9]+s\)' | tr -dc '0-9')
exp_err=$(erows | wc -l | tr -d ' ')

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
    else                                no "${desc}: указано '${got}', в журнале '${want}'"
    fi
}

check attack_source_ip     "${exp_ip}"        "адрес, с которого шли попытки"
check failed_attempts      "${exp_failed}"    "неудачных попыток аутентификации"
check probed_usernames     "${exp_probed}"    "перебранные несуществующие имена"
check first_success_login  "${exp_login}"     "первый успешный вход"
check compromised_account  "${exp_account}"   "учётная запись, под которой вошли"
check sudo_commands        "${exp_sudo}"      "команд через sudo"
check devops_created       "${exp_useradd}"   "создание учётной записи devops"
check helper_enabled       "${exp_enabled}"   "включение sshd-helper в автозагрузку"
check helper_started       "${exp_started}"   "запуск sshd-helper"
check gap_start            "${exp_gap_start}" "последняя запись перед провалом"
check gap_end              "${exp_gap_end}"   "первая запись после провала"
check gap_minutes          "${exp_gap_min}"   "длительность провала в минутах"
check clock_jump_seconds   "${exp_jump}"      "скачок системных часов, секунд"
check err_records          "${exp_err}"       "записей уровня err и выше"

# ---- согласованность отчёта -------------------------------------------------
if [ "$(val compromised_account)" != "devops" ]; then
    ok "самопроверка отчёта: вошли не под той учёткой, которую потом создали"
else
    no "самопроверка отчёта: devops создан в 22:01, а вход был в 21:58 — под ним войти не могли"
fi

if [ "$(val helper_enabled)" \< "$(val helper_started)" ]; then
    ok "самопроверка отчёта: включение раньше запуска"
else
    no "самопроверка отчёта: enable и start перепутаны местами"
fi

jump_min=$(( exp_jump / 60 ))
if [ "$(val gap_minutes)" -ge "${jump_min}" ] 2>/dev/null; then
    ok "самопроверка отчёта: провал (${jump_min}+ мин) сходится со скачком часов"
else
    no "самопроверка отчёта: длительность провала не сходится со скачком часов (${exp_jump} с)"
fi

# ---- самопроверки: ловушки в данных на месте --------------------------------
if [ "${naive_failed}" -gt "${exp_failed}" ]; then
    ok "самопроверка данных: 'invalid user' встречается ${naive_failed} раз против ${exp_failed} неудачных попыток — ловушка на месте"
else
    no "самопроверка данных: парные строки Invalid user исчезли, различать нечего"
fi

if [ "${naive_sudo}" -gt "${exp_sudo}" ]; then
    ok "самопроверка данных: строк со словом sudo ${naive_sudo} против ${exp_sudo} команд — ловушка на месте"
else
    no "самопроверка данных: строки pam_unix у sudo пропали, задание ослабло"
fi

if rows | grep -q 'Failed password for root'; then
    ok "самопроверка данных: среди попыток есть существующая учётка (root) — она не в списке перебора"
else
    no "самопроверка данных: попытка под существующим пользователем исчезла"
fi

if ! erows | grep -qE 'Failed password|COMMAND=|Accepted '; then
    ok "самопроверка данных: в выборке по приоритету нет ни одной записи об атаке"
else
    no "самопроверка данных: записи об атаке попали в -p err, хотя они уровня notice и info"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
