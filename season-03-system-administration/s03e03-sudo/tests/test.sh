#!/usr/bin/env bash
#
# s03e03 «Заряженный пистолет» (капстоун Episode 09) — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства политики sudo, которую написал студент:
# читает artifacts/ops-team так, как это делает sudo (алиасы раскрываются,
# теги и runas-скобки отбрасываются, комментарии не в счёт), и сверяет
# получившиеся права с ролями команды.
#
# Кого достаёт правило на группу — вычисляется из снимка /etc/group в data/,
# а не задано константой. Поэтому «%sudo» разоблачается
# поимённо: тест сам называет, кто в этой группе состоит.
#
# Без root, без сети: sudo не запускается, visudo не требуется.
#
# Выбор артефакта: SUBJECT=... | artifacts/ops-team | <серия>/ops-team | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"
GRP="${DATA}/group_shadow-01.txt"
PWD_FILE="${DATA}/passwd_shadow-01.txt"
STARTER="${SERIES_DIR}/starter/ops-team"

if   [ -n "${SUBJECT:-}" ];                       then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/ops-team" ];   then CFG="${SERIES_DIR}/artifacts/ops-team"
elif [ -f "${SERIES_DIR}/ops-team" ];             then CFG="${SERIES_DIR}/ops-team"
else CFG="${SERIES_DIR}/solution/ops-team"
     echo "ℹ️  Своя политика не найдена — проверяю ЭТАЛОН (solution/)."
     echo "   Начни свою:  cp starter/ops-team artifacts/ops-team"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e03 tests — политика: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${GRP}" "${PWD_FILE}"; do
    if [ ! -f "${f}" ]; then
        echo "  FAIL: не найден снимок: ${f}" >&2; exit 1
    fi
done
if [ -f "${CFG}" ]; then
    ok "политика ops-team найдена"
else
    no "ops-team не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- чтение политики так, как это делает sudo -------------------------------
# Склеиваем перенос строки «\», убираем комментарии и пустые строки.
norm() {
    sed -e 's/\r$//' "${CFG}" \
    | awk '{ line=$0; sub(/[[:space:]]+$/,"",line)
             buf = (cont ? buf " " line : line)
             if (buf ~ /\\$/) { sub(/\\$/,"",buf); cont=1; next }
             cont=0; print buf }' \
    | sed -e 's/^[[:space:]]*#.*$//' -e 's/[[:space:]]#.*$//' \
          -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
    | grep -v '^$'
}

# «кто → какая команда → был ли NOPASSWD», с раскрытыми Cmnd_Alias.
pairs() {
    norm | awk '
      /^Cmnd_Alias[[:space:]]/ {
          s=$0; sub(/^Cmnd_Alias[[:space:]]+/,"",s)
          n=s;  sub(/[[:space:]]*=.*$/,"",n)
          v=s;  sub(/^[^=]*=[[:space:]]*/,"",v)
          A[n]=v; next }
      /^(User|Host|Runas)_Alias[[:space:]]/ { next }
      /^Defaults/ { next }
      !/=/ { next }
      {
          left=$0;  sub(/=.*$/,"",left)
          right=$0; sub(/^[^=]*=/,"",right)
          split(left, L, /[[:space:]]+/); p=L[1]
          tag = (right ~ /NOPASSWD:/) ? "NOPASSWD" : "PASSWD"
          gsub(/\([^)]*\)/, " ", right)
          gsub(/(NOPASSWD|PASSWD|NOEXEC|EXEC|SETENV|NOSETENV|LOG_INPUT|NOLOG_INPUT|LOG_OUTPUT|NOLOG_OUTPUT|FOLLOW|NOFOLLOW|INTERCEPT|NOINTERCEPT):/, " ", right)
          n=split(right, C, /[[:space:]]*,[[:space:]]*/)
          for (i=1; i<=n; i++) {
              c=C[i]; gsub(/^[[:space:]]+|[[:space:]]+$/,"",c); if (c=="") continue
              if (c in A) {
                  m=split(A[c], D, /[[:space:]]*,[[:space:]]*/)
                  for (j=1; j<=m; j++) { d=D[j]; gsub(/^[[:space:]]+|[[:space:]]+$/,"",d)
                                         if (d!="") print p "\t" d "\t" tag }
              } else print p "\t" c "\t" tag
          }
      }'
}

PAIRS="$(pairs)"
cmds_of()    { printf '%s\n' "${PAIRS}" | awk -F'\t' -v p="$1" '$1==p{print $2}'; }
principals() { printf '%s\n' "${PAIRS}" | awk -F'\t' 'NF{print $1}' | sort -u; }
has_basename() {  # has_basename <принципал> <имя команды>
    cmds_of "$1" | awk -v b="$2" '{ split($1, w, /[[:space:]]+/); n=split(w[1], q, "/")
                                    if (q[n]==b) { found=1 } } END { exit !found }'
}

# ---- члены групп из снимка (без констант) ----------------------------------
members_of() {  # прямые члены + те, у кого это основная группа
    local g="$1" gid
    gid="$(awk -F: -v g="${g}" '$1==g{print $3}' "${GRP}")"
    { awk -F: -v g="${g}" '$1==g{gsub(/,/,"\n",$4); print $4}' "${GRP}"
      [ -n "${gid}" ] && awk -F: -v gid="${gid}" '$4==gid{print $1}' "${PWD_FILE}"
    } | grep -v '^$' | sort -u
}
join_c() { paste -sd, - | sed 's/,/, /g'; }

# ---- 1. синтаксис -----------------------------------------------------------
bad_syntax="$(norm | grep -vE '^(Defaults|Cmnd_Alias[[:space:]]|User_Alias[[:space:]]|Host_Alias[[:space:]]|Runas_Alias[[:space:]])' \
                   | grep -vE '^[^[:space:]]+[[:space:]]+[^[:space:]]+=' || true)"
if [ -z "${bad_syntax}" ]; then
    ok "синтаксис: все активные строки — Defaults, алиас или правило «кто где=(от кого) что»"
else
    no "синтаксис: visudo не принял бы строку: $(printf '%s' "${bad_syntax}" | head -1)"
fi

if norm | grep -qE '^[@#]include'; then
    no "в политике есть include — файл в sudoers.d должен быть самодостаточным"
else
    ok "посторонних include в политике нет"
fi

# ---- 2. абсолютные пути -----------------------------------------------------
rel="$(printf '%s\n' "${PAIRS}" | awk -F'\t' 'NF && $2!="ALL" && $2 !~ /^\// {print $1": "$2}')"
if [ -z "${rel}" ]; then
    ok "все команды заданы абсолютным путём"
else
    no "команда без абсолютного пути не совпадёт никогда: $(printf '%s' "${rel}" | head -1)"
fi

# ---- 3. кого достают правила на группы --------------------------------------
sudo_reach=""
for p in $(principals); do
    case "${p}" in
      %sudo|%admin|%wheel|%root) sudo_reach="${sudo_reach} ${p}" ;;
    esac
done
if [ -z "${sudo_reach}" ]; then
    ok "правил на административные группы (%sudo, %wheel, %admin) нет"
else
    no "правило на${sudo_reach}: в снимке это $(members_of sudo | join_c) — среди них подсадки из s03e01"
fi

# ---- 4. группы должны существовать ------------------------------------------
dead=""
for p in $(principals); do
    case "${p}" in
      %*) g="${p#%}"
          awk -F: -v g="${g}" '$1==g{f=1} END{exit !f}' "${GRP}" || dead="${dead} ${g}" ;;
    esac
done
if [ -z "${dead}" ]; then
    ok "все группы из политики существуют в снимке /etc/group"
else
    no "правило на несуществующую группу — мёртвая строка:${dead}"
fi

# ---- 5. viktor -------------------------------------------------------------
if principals | grep -qx 'viktor'; then
    no "у viktor есть правило sudo — координатору операции root не нужен ни разу"
else
    ok "правила для viktor нет: отсутствие доступа — тоже решение"
fi

# ---- 6. кто может ALL -------------------------------------------------------
all_holders="$(printf '%s\n' "${PAIRS}" | awk -F'\t' '$2=="ALL"{print $1}' | sort -u)"
case "$(printf '%s' "${all_holders}" | tr '\n' ' ' | sed 's/ *$//')" in
  "max") ok "полный доступ есть ровно у одного названного человека: max" ;;
  "")    no "полного доступа нет ни у кого — восстанавливать систему будет некому" ;;
  *)     no "полный доступ (ALL) выдан нескольким: $(printf '%s' "${all_holders}" | join_c)" ;;
esac

nopass_all="$(printf '%s\n' "${PAIRS}" | awk -F'\t' '$2=="ALL" && $3=="NOPASSWD"{print $1}' | sort -u)"
if [ -z "${nopass_all}" ]; then
    ok "NOPASSWD: ALL не выдан никому"
else
    no "NOPASSWD: ALL у $(printf '%s' "${nopass_all}" | join_c) — root одной командой, без паузы и без пароля"
fi

# ---- 7. команды, из которых выходят в оболочку -------------------------------
ESCAPES="bash sh zsh dash ksh vi vim nano emacs less more man find awk gawk python python3 perl ruby env ed tar mount cp dd"
esc_found=""
for p in $(principals); do
    for b in ${ESCAPES}; do
        has_basename "${p}" "${b}" && esc_found="${esc_found} ${p}:${b}"
    done
done
if [ -z "${esc_found}" ]; then
    ok "команд с выходом в оболочку никому не выдано"
else
    no "из этих команд выходят в root-оболочку:${esc_found}"
fi

# ---- 8. journalctl и пейджер ------------------------------------------------
jrn="$(printf '%s\n' "${PAIRS}" | awk -F'\t' '$2 ~ /journalctl/{print $2}')"
if [ -z "${jrn}" ]; then
    no "чтение журналов никому не выдано — Анна не сможет работать"
elif printf '%s\n' "${jrn}" | grep -qv -- '--no-pager'; then
    no "journalctl без --no-pager: он сам запустит less, а из less выходят в оболочку"
else
    ok "journalctl выдан только с --no-pager"
fi

# ---- 9. systemctl с аргументами ---------------------------------------------
svc="$(printf '%s\n' "${PAIRS}" | awk -F'\t' '$2 ~ /systemctl/{print $1"\t"$2}')"
if [ -z "${svc}" ]; then
    no "управление службами никому не выдано — Дмитрий не сможет работать"
elif printf '%s\n' "${svc}" | awk -F'\t' '$2 !~ /systemctl[[:space:]]+[^[:space:]]/ {bad=1} END{exit !bad}'; then
    no "systemctl выдан без аргументов: это и 'systemctl edit' (редактор от root), и mask чего угодно"
else
    ok "systemctl ограничен конкретными подкомандами и юнитами"
fi

# ---- 10. роли получили своё --------------------------------------------------
role_check() {  # role_check <принципал> <команда> <кому это нужно>
    local p="$1" b="$2" who="$3"
    if ! principals | grep -qx -- "${p}"; then
        no "правила для ${p} нет — ${who} останется без нужного доступа"
    elif has_basename "${p}" "${b}"; then
        ok "${p} → ${b} ($(members_of "${p#%}" | join_c))"
    else
        no "${p} не получает ${b}, а ${who} без этого не работает"
    fi
}
role_check "%ops-net"      "ip"         "Алекс, сетевая диагностика"
role_check "%ops-net"      "ss"         "Алекс, сокеты и порты"
role_check "%ops-logs"     "journalctl" "Анна, чтение журналов"
role_check "%ops-services" "systemctl"  "Дмитрий, службы операции"

# ---- 11. Defaults -----------------------------------------------------------
if norm | grep -qE '^Defaults[^[:space:]]*[[:space:]]+!authenticate'; then
    no "Defaults !authenticate: пароль не спрашивается ни у кого"
else
    ok "!authenticate в политике нет"
fi

if norm | grep -qE '^Defaults[^[:space:]]*[[:space:]]+(!env_reset|env_keep.*LD_)'; then
    no "окружение передаётся внутрь: LD_PRELOAD в env_keep — это root для любого, у кого есть хоть одно правило"
else
    ok "окружение сбрасывается (env_reset не отключён, LD_* не сохраняются)"
fi

if norm | grep -qE '^Defaults[^[:space:]]*[[:space:]]+.*(logfile=|log_input|log_output)'; then
    ok "журналирование sudo включено"
else
    no "нет ни logfile=, ни log_input/log_output — разбирать инцидент будет нечем"
fi

if norm | grep -E '^Defaults:[^[:space:]]*max' | grep -q 'log_input' \
   && norm | grep -E '^Defaults:[^[:space:]]*max' | grep -q 'log_output'; then
    ok "сессии полного доступа пишутся целиком (log_input, log_output для max)"
else
    no "у обладателя полного доступа нет log_input/log_output — что именно делали от root, останется неизвестным"
fi

# ---- 12. самопроверки: задание не выродилось --------------------------------
if [ -f "${STARTER}" ] && grep -qE 'NOPASSWD:[[:space:]]*ALL' "${STARTER}"; then
    ok "самопроверка: в стартере ловушка на месте (NOPASSWD: ALL)"
else
    no "самопроверка: стартер больше не содержит исходного нарушения — чинить нечего"
fi

strangers="$(comm -23 <(members_of sudo) \
                      <(for g in $(awk -F: '$1 ~ /^ops-/{print $1}' "${GRP}"); do members_of "${g}"; done | sort -u))"
if [ "$(printf '%s' "${strangers}" | grep -c .)" -gt 1 ]; then
    ok "самопроверка данных: в группе sudo есть лишние — $(printf '%s' "${strangers}" | join_c)"
else
    no "самопроверка данных: группа sudo больше не содержит посторонних, разоблачать нечего"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
