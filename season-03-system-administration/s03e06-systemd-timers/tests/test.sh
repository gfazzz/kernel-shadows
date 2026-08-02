#!/usr/bin/env bash
#
# s03e06 «Пять минут по расписанию» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства пары юнитов, которую написал студент:
# ops-check.timer и ops-check.service читаются по правилам systemd
# (секции значимы, побеждает последнее присваивание, пустое значение
# сбрасывает) и сверяются с требованиями к расписанию.
#
# Отдельно ловятся: cron-синтаксис в OnCalendar, WantedBy=multi-user.target
# у таймера, Restart у Type=oneshot и секция [Install] в службе, которую
# включать не нужно.
#
# Без root, без сети: systemd не запускается.
#
# Выбор артефактов: SUBJECT_DIR=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT_DIR:-}" ];                              then DIR="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/ops-check.timer" ];       then DIR="${SERIES_DIR}/artifacts"
elif [ -f "${SERIES_DIR}/ops-check.timer" ];                 then DIR="${SERIES_DIR}"
else DIR="${SERIES_DIR}/solution"
     echo "ℹ️  Своей пары юнитов не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/ops-check.* artifacts/"; echo ""
fi

TIMER="${DIR}/ops-check.timer"
SERVICE="${DIR}/ops-check.service"
STARTER="${SERIES_DIR}/starter/ops-check.timer"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e06 tests — юниты: ${DIR#"$SERIES_DIR"/}/"
echo "════════════════════════════════════════════════════════════"

miss=0
for f in "${TIMER}" "${SERVICE}"; do
    if [ -f "${f}" ]; then ok "$(basename "${f}") найден"; else no "$(basename "${f}") не найден"; miss=1; fi
done
if [ "${miss}" -ne 0 ]; then
    echo "  Таймер без службы не работает, служба без таймера не запускается."
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- чтение юнита по правилам systemd ---------------------------------------
entries() {
    sed -e 's/\r$//' "$1" \
    | awk '{ line=$0; sub(/[[:space:]]+$/,"",line)
             buf = (cont ? buf line : line)
             if (buf ~ /\\$/) { sub(/\\$/," ",buf); cont=1; next }
             cont=0; print buf }' \
    | awk '
        /^[[:space:]]*[#;]/ { next }
        /^[[:space:]]*$/    { next }
        /^[[:space:]]*\[.*\][[:space:]]*$/ {
            s=$0; gsub(/^[[:space:]]*\[|\][[:space:]]*$/,"",s); sec=s; next }
        /=/ { k=$0; sub(/=.*$/,"",k); gsub(/^[[:space:]]+|[[:space:]]+$/,"",k)
              v=$0; sub(/^[^=]*=/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v)
              print sec "\t" k "\t" v; next }
        { print sec "\t!BAD!\t" $0 }'
}
T_ENT="$(entries "${TIMER}")"
S_ENT="$(entries "${SERVICE}")"

eff() { printf '%s\n' "$1" | awk -F'\t' -v s="$2" -v k="$3" \
          'tolower($1)==tolower(s) && tolower($2)==tolower(k) {v=$3} END{print v}'; }
cnt() { printf '%s\n' "$1" | awk -F'\t' -v s="$2" -v k="$3" \
          'tolower($1)==tolower(s) && tolower($2)==tolower(k) {n++} END{print n+0}'; }
has_section() { printf '%s\n' "$1" | awk -F'\t' -v s="$2" 'tolower($1)==tolower(s){f=1} END{exit !f}'; }

want() {  # want <набор> <секция> <ключ> <регулярка> <зачем>
    local ent="$1" sec="$2" key="$3" re="$4" why="$5" got
    got="$(eff "${ent}" "${sec}" "${key}")"
    if [ "$(cnt "${ent}" "${sec}" "${key}")" -eq 0 ]; then
        no "${key}: не задан (${why})"
    elif [ -z "${got}" ]; then
        no "${key}: пустое присваивание сбрасывает настройку (${why})"
    elif printf '%s' "${got}" | grep -qiE "${re}"; then
        ok "${key} = ${got}"
    else
        no "${key} = ${got} — не годится (${why})"
    fi
}

# ---- 1. синтаксис -----------------------------------------------------------
for pair in "timer:${T_ENT}" "service:${S_ENT}"; do
    n="${pair%%:*}"; e="${pair#*:}"
    b="$(printf '%s\n' "${e}" | awk -F'\t' '$2=="!BAD!"{print $3}')"
    if [ -z "${b}" ]; then ok "синтаксис ${n}: все строки — секции или «ключ=значение»"
    else no "systemd не разобрал бы строку в ${n}: $(printf '%s' "${b}" | head -1)"; fi
done

has_section "${T_ENT}" Timer && ok "секция [Timer] на месте" || no "нет секции [Timer] — это не таймер"

# ---- 2. расписание -----------------------------------------------------------
cal="$(eff "${T_ENT}" Timer OnCalendar)"
if [ "$(cnt "${T_ENT}" Timer OnCalendar)" -eq 0 ]; then
    no "OnCalendar не задан — таймер не знает, когда срабатывать"
elif printf '%s' "${cal}" | grep -qE '^[-0-9*/,]+ +[-0-9*/,]+ +[-0-9*/,]+ +[-0-9*/,]+ +[-0-9*/,]+$'; then
    no "OnCalendar='${cal}' — это синтаксис crontab; systemd разберёт его как дату и откажется загружать юнит"
elif ! printf '%s' "${cal}" | grep -qE '(:|minutely|hourly|daily|weekly|monthly)'; then
    no "OnCalendar='${cal}' не похож на календарное выражение systemd (проверь: systemd-analyze calendar '...')"
elif ! printf '%s' "${cal}" | grep -qE '/5|minutely'; then
    no "OnCalendar='${cal}' не даёт интервала в пять минут"
else
    ok "OnCalendar = ${cal}"
fi

want "${T_ENT}" Timer Persistent '^(true|yes|1|on)$' "без него пропущенный за время простоя запуск не догоняется"
want "${T_ENT}" Timer RandomizedDelaySec '^[0-9]+(s|sec|m|min)?$' "разброс убирает всплеск нагрузки ровно в :00 и :05 на всех серверах разом"
want "${T_ENT}" Timer AccuracySec '^[0-9]+(us|ms|s|sec)$' "по умолчанию systemd вправе отложить запуск на минуту — 20 % интервала"

unit_ref="$(eff "${T_ENT}" Timer Unit)"
if [ -z "${unit_ref}" ]; then
    ok "Unit= не задан — таймер запустит службу с тем же именем (ops-check.service)"
elif [ "${unit_ref}" = "ops-check.service" ]; then
    ok "Unit = ${unit_ref}"
else
    no "Unit = ${unit_ref}: таймер запустит не ту службу, которая лежит рядом"
fi

want "${T_ENT}" Install WantedBy '^timers\.target$' "с multi-user.target юнит включится, но в systemctl list-timers не появится"

# ---- 3. служба под таймером --------------------------------------------------
want "${S_ENT}" Service Type '^oneshot$' "simple считается запущенной сразу и не даёт таймеру узнать результат"

restart="$(eff "${S_ENT}" Service Restart)"
if [ "$(cnt "${S_ENT}" Service Restart)" -eq 0 ] \
   || printf '%s' "${restart}" | grep -qiE '^(no|none)$'; then
    ok "Restart у разовой задачи не задан — повторные запуски обеспечивает таймер"
else
    no "Restart=${restart} при Type=oneshot: systemd откажется загружать юнит, а по смыслу это вечный цикл"
fi

want "${S_ENT}" Service TimeoutStartSec '^[0-9]+(s|sec|min|m)?$' "зависшая разовая задача блокирует все следующие запуски таймера"

if has_section "${S_ENT}" Install; then
    no "в службе есть [Install]: systemctl enable включит и её, и она стартанёт при загрузке помимо таймера"
else
    ok "в службе нет [Install] — включается таймер, а не она"
fi

exec_start="$(eff "${S_ENT}" Service ExecStart)"
if [ -z "${exec_start}" ]; then
    no "ExecStart не задан — запускать нечего"
elif ! printf '%s' "${exec_start}" | grep -qE '^[-@+!]*/'; then
    no "ExecStart должен начинаться с абсолютного пути: '${exec_start}'"
else
    ok "ExecStart = ${exec_start}"
fi

user="$(eff "${S_ENT}" Service User)"
if [ -z "${user}" ];        then no "User не задан — задача пойдёт от root"
elif [ "${user}" = root ];  then no "User=root: проверке состояния root не нужен"
else                             ok "User = ${user}"
fi

want "${S_ENT}" Service NoNewPrivileges '^(yes|true|1)$' "разовость задачи не делает её безопаснее — код тот же"
want "${S_ENT}" Service ProtectSystem   '^(strict|full)$' "то же ограничение, что и у постоянной службы"
want "${S_ENT}" Service PrivateTmp      '^(yes|true|1)$' "свой /tmp"

for pair in "timer:${T_ENT}" "service:${S_ENT}"; do
    n="${pair%%:*}"; e="${pair#*:}"
    d="$(eff "${e}" Unit Description)"
    if [ "${#d}" -ge 15 ]; then ok "Description ${n}: «${d}»"
    else no "Description ${n} «${d}» ничего не сообщает — его видно в systemctl list-timers"; fi
done

# ---- 4. самопроверки ---------------------------------------------------------
if [ -f "${STARTER}" ] && grep -qE '^OnCalendar=[-0-9*/,]+ +[-0-9*/,]+ ' "${STARTER}"; then
    ok "самопроверка: в стартере ловушка на месте (строка из crontab)"
else
    no "самопроверка: стартер больше не содержит cron-синтаксиса — чинить нечего"
fi

if [ -f "${STARTER}" ] && grep -qE '^WantedBy=multi-user\.target' "${STARTER}"; then
    ok "самопроверка: в стартере таймер включается не в ту цель"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
