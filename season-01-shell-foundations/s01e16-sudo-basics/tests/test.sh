#!/usr/bin/env bash
#
# s01e16 «Не своё имя» (финал Season 1) — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт access_answers.txt
# сверяется со снимком чужого сервера из data/. Эталон вычисляется здесь
# же — констант в тесте нет (§4.2, §4.3).
#
# Без root, без сети: разбирается копия вывода четырёх команд.
#
# Выбор отчёта: SUBJECT=... | artifacts/access_answers.txt | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/../data/moscow_server_access.txt"

if   [ -n "${SUBJECT:-}" ];                                 then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/access_answers.txt" ];   then REPORT="${SERIES_DIR}/artifacts/access_answers.txt"
elif [ -f "${SERIES_DIR}/access_answers.txt" ];             then REPORT="${SERIES_DIR}/access_answers.txt"
else REPORT="${SERIES_DIR}/solution/access_answers.txt"
     echo "ℹ️  Свой access_answers.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/access_answers.txt artifacts/access_answers.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e16 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ ! -f "${D}" ]; then echo "  FAIL: не найден объект разведки: ${D}" >&2; exit 1; fi
if [ -f "${REPORT}" ]; then
    ok "отчёт access_answers.txt найден"
else
    no "access_answers.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- эталон: вычисляется из снимка ------------------------------------------
sec() { awk -v s="$1" '$0=="=== "s" ===" {f=1; next} /^=== /{f=0} f' "${D}" \
          | grep -vE '^[[:space:]]*$'; }
ls_rows() { sec 'ls -l /srv/ops' | grep -E '^[-dl]'; }

# rwx-строка → восьмерично
to_octal() {
    awk -v p="$1" 'BEGIN {
        split("rwxrwxrwx", m, ""); v = 0
        for (i = 1; i <= 9; i++) {
            c = substr(p, i + 1, 1)
            bit = (i % 3 == 1) ? 4 : (i % 3 == 2) ? 2 : 1
            sh  = (i <= 3) ? 64 : (i <= 6) ? 8 : 1
            if (c == m[i] || c == "s" || c == "t") v += bit * sh
        }
        printf "%o", v }'
}
perm_of() { ls_rows | awk -v n="$1" '$NF == n {print $1; exit}'; }

exp_whoami=$(sec whoami | head -1 | tr -d ' ')
exp_uid=$(sec id | grep -oE 'uid=[0-9]+' | head -1 | tr -dc '0-9')
# все группы: то, что перечислено в groups=… (основная там уже есть)
exp_groups=$(sec id | sed -E 's/.*groups=//' | tr ',' '\n' | grep -c .)
naive_groups=$(( exp_groups + 1 ))
exp_opsgrp=$(sec id | grep -oE '\(ops-[a-z]+\)' | head -1 | tr -d '()')

# читается всеми: обычный файл с r в позиции «остальных»
exp_world_read=$(ls_rows | awk '$1 ~ /^-.{6}r/ {print $NF; exit}')
# читается через группу adm: r у группы, но не у остальных, и группа = adm
exp_group_read=$(ls_rows | awk '$1 ~ /^-...r..---/ && $4=="adm" {print $NF; exit}')
# не читается никак: ни группе, ни остальным, и владелец не max
exp_unread=$(ls_rows | awk -v me="${exp_whoami}" '$1 ~ /^-...------/ && $3 != me {print $NF; exit}')
# каталог, доступный всем на запись
exp_wdir=$(ls_rows | awk '$1 ~ /^d.{7}w/ {print $NF; exit}')

exp_collect=$(to_octal "$(perm_of collect.sh)")
exp_plan=$(to_octal "$(perm_of plan.txt)")
exp_suid=$(ls_rows | awk '$1 ~ /^-..s/ {print $NF; exit}')

exp_sudo_cnt=$(sec 'sudo -l' | awk '/may run the following/{f=1; next} f && /^[[:space:]]*\(/ {n++} END{print n+0}')
exp_runas=$(sec 'sudo -l' | grep -oE '^[[:space:]]*\([a-z]+\)' | head -1 | tr -d ' ()')
exp_used=$(sec 'журнал sudo за 8 октября' | grep -c "  ${exp_whoami} : TTY=.*COMMAND=")
exp_denied=$(sec 'журнал sudo за 8 октября' | grep 'NOT in sudoers' | sed -E 's/.*COMMAND=([^ ]+).*/\1/' | head -1)
naive_sudo_lines=$(sec 'журнал sudo за 8 октября' | grep -c "${exp_whoami}")

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

check whoami             "${exp_whoami}"     "кто я на этой машине"
check uid                "${exp_uid}"        "числовой идентификатор"
check groups_total       "${exp_groups}"     "групп всего"
check ops_group          "${exp_opsgrp}"     "группа операции"
check world_readable     "${exp_world_read}" "файл, читаемый всеми"
check readable_via_group "${exp_group_read}" "файл, читаемый через группу"
check unreadable         "${exp_unread}"     "файл, недоступный совсем"
check world_writable_dir "${exp_wdir}"       "каталог, доступный всем на запись"
check collect_octal      "${exp_collect}"    "права collect.sh"
check plan_octal         "${exp_plan}"       "права plan.txt"
check suid_file          "${exp_suid}"       "файл с битом SUID"
check sudo_allowed_count "${exp_sudo_cnt}"   "команд разрешено через sudo"
check sudo_runas         "${exp_runas}"      "от чьего имени выполняются"
check sudo_used          "${exp_used}"       "успешных вызовов sudo за день"
check sudo_denied        "${exp_denied}"     "команда, которую sudo запретил"

# ---- согласованность отчёта -------------------------------------------------
if [ "$(val readable_via_group)" != "$(val world_readable)" ] \
   && [ "$(val unreadable)" != "$(val world_readable)" ]; then
    ok "самопроверка отчёта: три уровня доступа различены"
else
    no "самопроверка отчёта: файлы разных уровней доступа совпали"
fi

if [ "$(val sudo_used)" -lt "$(val sudo_allowed_count)" ] 2>/dev/null; then
    ok "самопроверка отчёта: разрешено больше, чем использовано — это нормально"
else
    no "самопроверка отчёта: использовано не меньше, чем разрешено — пересчитайте"
fi

# ---- самопроверки: ловушки в данных на месте --------------------------------
if [ "${naive_groups}" -gt "${exp_groups}" ] \
   && sec id | grep -q "gid=${exp_uid}(${exp_whoami})"; then
    ok "самопроверка данных: основная группа перечислена и в groups= — наивный счёт даёт ${naive_groups}"
else
    no "самопроверка данных: ловушка с подсчётом групп исчезла"
fi

if [ "${naive_sudo_lines}" -gt "${exp_used}" ]; then
    ok "самопроверка данных: строк с моим именем в журнале ${naive_sudo_lines} против ${exp_used} успешных"
else
    no "самопроверка данных: строка об отказе пропала, различать нечего"
fi

if ls_rows | awk '$1 ~ /^-..s/' | grep -q .; then
    ok "самопроверка данных: SUID-файл в снимке присутствует"
else
    no "самопроверка данных: файл с битом s исчез"
fi

if [ "$(ls_rows | awk -v me="${exp_whoami}" '$3 == me' | wc -l | tr -d ' ')" -eq 1 ]; then
    ok "самопроверка данных: моя собственная строка в каталоге ровно одна"
else
    no "самопроверка данных: изменилось число моих файлов — сюжет про «здесь всё чужое» ослаб"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
