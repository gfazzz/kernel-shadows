#!/usr/bin/env bash
#
# s03e05 «Служба, которая вернётся» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства unit-файла, который написал студент:
# читает artifacts/ops-monitor.service так, как это делает systemd
# (секции значимы, побеждает ПОСЛЕДНЕЕ присваивание, пустое значение
# сбрасывает настройку, комментарии не в счёт) и сверяет эффективные
# значения с требованиями к службе.
#
# Отдельно ловятся: конвейер в ExecStart (оболочки нет), After без Wants,
# Restart=always и настройка, сброшенная пустым присваиванием ниже.
#
# Без root, без сети: systemd не запускается, systemd-analyze не требуется.
#
# Выбор артефакта: SUBJECT=... | artifacts/ops-monitor.service | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
UNIT_NAME="ops-monitor.service"
STARTER="${SERIES_DIR}/starter/${UNIT_NAME}"

if   [ -n "${SUBJECT:-}" ];                                 then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/${UNIT_NAME}" ];         then CFG="${SERIES_DIR}/artifacts/${UNIT_NAME}"
elif [ -f "${SERIES_DIR}/${UNIT_NAME}" ];                   then CFG="${SERIES_DIR}/${UNIT_NAME}"
else CFG="${SERIES_DIR}/solution/${UNIT_NAME}"
     echo "ℹ️  Свой ${UNIT_NAME} не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/${UNIT_NAME} artifacts/${UNIT_NAME}"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e05 tests — unit: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${CFG}" ]; then
    ok "unit-файл ${UNIT_NAME} найден"
else
    no "${UNIT_NAME} не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- чтение unit-файла так, как это делает systemd --------------------------
# «секция <TAB> ключ <TAB> значение», в порядке следования, с учётом переносов.
ENTRIES="$(sed -e 's/\r$//' "${CFG}" \
  | awk '{ line=$0; sub(/[[:space:]]+$/,"",line)
           buf = (cont ? buf line : line)
           if (buf ~ /\\$/) { sub(/\\$/," ",buf); cont=1; next }
           cont=0; print buf }' \
  | awk '
      /^[[:space:]]*[#;]/ { next }
      /^[[:space:]]*$/    { next }
      /^[[:space:]]*\[.*\][[:space:]]*$/ {
          s=$0; gsub(/^[[:space:]]*\[|\][[:space:]]*$/,"",s); sec=s; next }
      /=/ {
          k=$0; sub(/=.*$/,"",k); gsub(/^[[:space:]]+|[[:space:]]+$/,"",k)
          v=$0; sub(/^[^=]*=/,"",v); gsub(/^[[:space:]]+|[[:space:]]+$/,"",v)
          print sec "\t" k "\t" v; next }
      { print sec "\t!BAD!\t" $0 }')"

# последнее присваивание в секции
eff() { printf '%s\n' "${ENTRIES}" | awk -F'\t' -v s="$1" -v k="$2" \
          'tolower($1)==tolower(s) && tolower($2)==tolower(k) {v=$3} END{print v}'; }
# сколько раз ключ присвоен (для разговора про сброс пустым значением)
cnt() { printf '%s\n' "${ENTRIES}" | awk -F'\t' -v s="$1" -v k="$2" \
          'tolower($1)==tolower(s) && tolower($2)==tolower(k) {n++} END{print n+0}'; }
has_section() { printf '%s\n' "${ENTRIES}" | awk -F'\t' -v s="$1" 'tolower($1)==tolower(s){f=1} END{exit !f}'; }
all_of() { printf '%s\n' "${ENTRIES}" | awk -F'\t' -v s="$1" -v k="$2" \
          'tolower($1)==tolower(s) && tolower($2)==tolower(k) {print $3}'; }

want() {  # want <секция> <ключ> <регулярка допустимых> <зачем>
    local sec="$1" key="$2" re="$3" why="$4" got
    got="$(eff "${sec}" "${key}")"
    if [ "$(cnt "${sec}" "${key}")" -eq 0 ]; then
        no "${key}: не задан (${why})"
    elif [ -z "${got}" ]; then
        no "${key}: пустое присваивание сбрасывает настройку (${why})"
    elif printf '%s' "${got}" | grep -qiE "${re}"; then
        ok "${key} = ${got}"
    else
        no "${key} = ${got} — не годится (${why})"
    fi
}

# ---- 1. структура -----------------------------------------------------------
bad="$(printf '%s\n' "${ENTRIES}" | awk -F'\t' '$2=="!BAD!"{print $3}')"
if [ -z "${bad}" ]; then
    ok "синтаксис: все активные строки — секции или «ключ=значение»"
else
    no "systemd не разобрал бы строку: $(printf '%s' "${bad}" | head -1)"
fi

for s in Unit Service Install; do
    if has_section "${s}"; then ok "секция [${s}] на месте"
    else no "нет секции [${s}]$( [ "${s}" = Install ] && printf '%s' " — systemctl enable сообщит, что включать нечего" )"
    fi
done

# ---- 2. [Unit] --------------------------------------------------------------
desc="$(eff Unit Description)"
if [ "${#desc}" -ge 15 ]; then
    ok "Description осмыслен: «${desc}»"
else
    no "Description «${desc}» ничего не сообщает — его читают в systemctl status и в журнале"
fi

after="$(all_of Unit After | tr ' ' '\n')"
wants="$(all_of Unit Wants; all_of Unit Requires)"
if printf '%s\n' "${after}" | grep -qx 'network-online.target'; then
    if printf '%s' "${wants}" | grep -q 'network-online.target'; then
        ok "After=network-online.target подкреплён Wants= — цель действительно будет запущена"
    else
        no "After=network-online.target без Wants=: After задаёт только порядок, цель сама не запустится"
    fi
elif printf '%s\n' "${after}" | grep -qx 'network.target'; then
    no "After=network.target означает лишь «сеть настраивается», адреса ещё нет — нужен network-online.target"
else
    no "порядок запуска не задан: служба стартует до появления сети"
fi

# ---- 3. [Service]: что и как запускается ------------------------------------
exec_start="$(eff Service ExecStart)"
if [ -z "${exec_start}" ]; then
    no "ExecStart не задан — запускать нечего"
elif ! printf '%s' "${exec_start}" | grep -qE '^[-@+!]*/'; then
    no "ExecStart должен начинаться с абсолютного пути: '${exec_start}'"
elif printf '%s' "${exec_start}" | grep -qE '[|;&><]' \
     && ! printf '%s' "${exec_start}" | grep -qE '/(ba)?sh +-c'; then
    no "в ExecStart есть символ оболочки, а оболочки нет: systemd разберёт строку на аргументы и передаст его скрипту как есть"
else
    ok "ExecStart = ${exec_start}"
fi

want Service Type '^(simple|exec|notify|forking|oneshot|idle|dbus)$' "тип службы должен быть указан явно"

restart="$(eff Service Restart)"
case "$(printf '%s' "${restart}" | tr 'A-Z' 'a-z')" in
  on-failure|on-abnormal) ok "Restart = ${restart}" ;;
  always) no "Restart=always перезапускает службу и после штатного выхода с кодом 0 — для мониторинга нужен on-failure" ;;
  "")     no "Restart не задан: служба не вернётся после падения" ;;
  *)      no "Restart = ${restart} — не годится для службы, которая должна пережить сбой" ;;
esac
want Service RestartSec '^[0-9]+(s|sec|min)?$' "без паузы падающая служба крутится в цикле"

# ---- 4. [Service]: от кого и с какими правами -------------------------------
user="$(eff Service User)"
if [ -z "${user}" ]; then
    no "User не задан — служба пойдёт от root, хотя ей нужно только читать состояние"
elif [ "${user}" = "root" ]; then
    no "User=root: мониторингу root не нужен ни для одной из его задач"
else
    ok "User = ${user}"
fi

want Service NoNewPrivileges '^(yes|true|1)$' "иначе потомки службы смогут получить права через SUID"
want Service ProtectSystem   '^(strict|full)$' "true оставляет /etc доступным на запись"
want Service ProtectHome     '^(yes|true|read-only|tmpfs)$' "домашние каталоги службе не нужны"
want Service PrivateTmp      '^(yes|true|1)$' "общий /tmp — то место, откуда запускалась закладка из s03e04"

if printf '%s' "$(eff Service ProtectSystem)" | grep -qi '^strict$'; then
    if [ "$(cnt Service ReadWritePaths)" -gt 0 ] || [ "$(cnt Service StateDirectory)" -gt 0 ]; then
        ok "при ProtectSystem=strict указано, куда службе можно писать"
    else
        no "ProtectSystem=strict без ReadWritePaths= или StateDirectory=: служба не сможет писать никуда, включая свой каталог"
    fi
fi

# ---- 5. [Service]: ресурсы --------------------------------------------------
want Service MemoryMax '^[0-9]+(K|M|G|%)$' "служба сбора состояния не должна уметь съесть память сервера"
want Service CPUQuota  '^[0-9]+%$'         "то же для процессора"
want Service TasksMax  '^[0-9]+$'          "ограничение числа процессов — заодно защита от форк-бомбы"

# ---- 6. вывод и автозагрузка -------------------------------------------------
sout="$(eff Service StandardOutput)"
if [ -z "${sout}" ] && [ "$(cnt Service StandardOutput)" -eq 0 ]; then
    ok "StandardOutput не задан — действует умолчание journal"
elif printf '%s' "${sout}" | grep -qiE '^(journal|journal\+console|inherit)$'; then
    ok "StandardOutput = ${sout}"
else
    no "StandardOutput = ${sout}: вывод уходит мимо журнала, и разбирать инцидент будет нечем"
fi

want Install WantedBy '^(multi-user|graphical|default)\.target$' "без этого systemctl enable нечего включать"

# ---- 7. самопроверки ---------------------------------------------------------
reset_keys=""
for k in ProtectSystem ProtectHome PrivateTmp NoNewPrivileges MemoryMax User; do
    [ "$(cnt Service "${k}")" -gt 0 ] && [ -z "$(eff Service "${k}")" ] && reset_keys="${reset_keys} ${k}"
done
if [ -z "${reset_keys}" ]; then
    ok "самопроверка: важные настройки не сброшены пустым присваиванием ниже по файлу"
else
    no "пустое присваивание внизу файла отменяет настройку выше:${reset_keys}"
fi

if [ -f "${STARTER}" ] && grep -qE '^ExecStart=.*\|' "${STARTER}" && grep -qE '^Restart=always' "${STARTER}"; then
    ok "самопроверка: в стартере ловушки на месте (конвейер в ExecStart, Restart=always)"
else
    no "самопроверка: стартер больше не содержит исходных ошибок — чинить нечего"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
