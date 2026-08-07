#!/usr/bin/env bash
#
# s03e12 «Строка, которой не было» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства конфигурации logrotate: разбирает файл
# на блоки «путь { директивы }» и сверяет каждый блок с требованиями.
#
# Ключевая проверка — та, что закрывает находку s03e08: у блока должен быть
# способ сообщить пишущей службе о повороте (postrotate с сигналом или
# copytruncate). Без неё повторяется история с десятью гигабайтами,
# занятыми файлом без имени.
#
# Без root, без сети: logrotate не запускается.
#
# Выбор артефакта: SUBJECT=... | artifacts/ops | <серия>/ops | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STARTER="${SERIES_DIR}/starter/ops"

if   [ -n "${SUBJECT:-}" ];                  then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/ops" ];   then CFG="${SERIES_DIR}/artifacts/ops"
elif [ -f "${SERIES_DIR}/ops" ];             then CFG="${SERIES_DIR}/ops"
else CFG="${SERIES_DIR}/solution/ops"
     echo "ℹ️  Своей конфигурации не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/ops artifacts/ops"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e12 tests — конфигурация: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${CFG}" ]; then
    ok "конфигурация logrotate найдена"
else
    no "файл ops не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

# ---- разбор на блоки ---------------------------------------------------------
# «путь<TAB>директивы через ;» по каждому блоку
BLOCKS="$(sed -e 's/\r$//' -e 's/^[[:space:]]*#.*$//' "${CFG}" | awk '
    /\{[[:space:]]*$/ && !inb { p=$0; sub(/[[:space:]]*\{[[:space:]]*$/,"",p)
                                gsub(/^[[:space:]]+|[[:space:]]+$/,"",p)
                                inb=1; body=""; next }
    inb && /^[[:space:]]*\}[[:space:]]*$/ { print p "\t" body; inb=0; next }
    inb { l=$0; gsub(/^[[:space:]]+|[[:space:]]+$/,"",l)
          if (l != "") body = body ";" l }
')"

paths()   { printf '%s\n' "${BLOCKS}" | awk -F'\t' 'NF{print $1}'; }
body_of() { printf '%s\n' "${BLOCKS}" | awk -F'\t' -v p="$1" '$1==p{print $2}'; }
has()     { printf '%s' "$1" | tr ';' '\n' | grep -qE "^$2( |$)"; }
value()   { printf '%s' "$1" | tr ';' '\n' | grep -E "^$2 " | tail -1 | awk '{print $2}'; }

nblocks=$(paths | grep -c . || true)
if [ "${nblocks}" -ge 1 ]; then
    ok "разобрано блоков: ${nblocks}"
else
    no "ни одного блока «путь { … }» не найдено — проверять нечего"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

opens=$(grep -c '{[[:space:]]*$' "${CFG}" || true)
closes=$(grep -c '^[[:space:]]*}[[:space:]]*$' "${CFG}" || true)
if [ "${opens}" -eq "${closes}" ]; then
    ok "фигурные скобки сбалансированы (${opens})"
else
    no "скобки не сбалансированы: ${opens} открывающих, ${closes} закрывающих — logrotate откажется читать файл"
fi

# ---- обе службы описаны ------------------------------------------------------
for want in /var/log/ops /var/log/nginx; do
    if paths | grep -q "^${want}"; then
        ok "описан журнал ${want}"
    else
        no "нет блока для ${want} — его журналы не поворачиваются вовсе"
    fi
done

# ---- проверки по каждому блоку ----------------------------------------------
while IFS= read -r p; do
    [ -n "${p}" ] || continue
    b="$(body_of "${p}")"
    short="${p##*/log/}"

    # 1. сигнал пишущей службе — то, чего не было 14 октября
    if printf '%s' "${b}" | grep -qE 'postrotate' \
       && printf '%s' "${b}" | grep -qE 'HUP|USR1|rsyslog-rotate|reload|kill'; then
        ok "${short}: служба узнаёт о повороте (postrotate с сигналом)"
    elif has "${b}" copytruncate; then
        ok "${short}: используется copytruncate — дескриптор не ломается"
    else
        no "${short}: нет ни postrotate с сигналом, ни copytruncate — повторится история s03e08"
    fi

    # 2. copytruncate и create несовместимы
    if has "${b}" copytruncate && has "${b}" create; then
        no "${short}: copytruncate вместе с create — файл не пересоздаётся, create бессмыслен"
    else
        ok "${short}: copytruncate и create не смешаны"
    fi

    # 3. sharedscripts при шаблоне в пути
    case "${p}" in
      *\**)
        if printf '%s' "${b}" | grep -q 'postrotate'; then
            if has "${b}" sharedscripts; then
                ok "${short}: sharedscripts — служба получит сигнал один раз, а не по разу на файл"
            else
                no "${short}: путь с шаблоном и postrotate без sharedscripts — сигнал уйдёт по разу на каждый журнал"
            fi
        fi ;;
    esac

    # 4. глубина хранения
    r="$(value "${b}" rotate)"
    if [ -z "${r}" ]; then
        no "${short}: не задан rotate — сколько поколений хранить, неизвестно"
    elif printf '%s' "${r}" | grep -qE '^[0-9]+$' && [ "${r}" -ge 7 ]; then
        ok "${short}: rotate ${r} — разбор недельной давности ещё возможен"
    else
        no "${short}: rotate ${r} — меньше недели; события инцидента уйдут раньше, чем его заметят"
    fi

    # 5. периодичность
    if has "${b}" daily || has "${b}" weekly || has "${b}" monthly || has "${b}" hourly \
       || printf '%s' "${b}" | grep -q '^size\|;size'; then
        ok "${short}: периодичность поворота задана"
    else
        no "${short}: не задано, когда поворачивать (daily/weekly/size)"
    fi

    # 6. сжатие
    if has "${b}" compress; then
        if has "${b}" delaycompress; then
            ok "${short}: compress с delaycompress — свежий файл не сжимается, пока в него ещё пишут"
        else
            no "${short}: compress без delaycompress — файл сожмут раньше, чем служба перечитает дескриптор"
        fi
    else
        no "${short}: нет compress — журналы займут том, расширенный в s03e09"
    fi

    # 7. права нового файла
    if has "${b}" create; then
        mode="$(value "${b}" create)"
        if printf '%s' "${mode}" | grep -qE '^0?[0-7]{3}$' \
           && [ "$(printf '%s' "${mode}" | tail -c 2 | head -c 1)" -le 4 ] \
           && [ "$(printf '%s' "${mode}" | tail -c 1)" -eq 0 ]; then
            ok "${short}: create ${mode} — посторонние журнал не прочитают"
        else
            no "${short}: create ${mode} — права шире 0640, журнал доступен посторонним"
        fi
    elif has "${b}" copytruncate; then
        ok "${short}: create не нужен — файл не пересоздаётся"
    else
        no "${short}: нет create — новый журнал появится со случайными правами"
    fi

    # 8. шум
    miss=""
    has "${b}" missingok || miss="${miss} missingok"
    has "${b}" notifempty || miss="${miss} notifempty"
    if [ -z "${miss}" ]; then
        ok "${short}: missingok и notifempty — logrotate не шумит на пустом и отсутствующем"
    else
        no "${short}: не хватает:${miss} — на каждый запуск будет ошибка, и её перестанут читать"
    fi
done <<EOF
$(paths)
EOF

# ---- самопроверки ------------------------------------------------------------
if [ -f "${STARTER}" ] && ! grep -q 'postrotate\|copytruncate' "${STARTER}"; then
    ok "самопроверка: в стартере ловушка на месте (поворот без уведомления службы)"
else
    no "самопроверка: стартер больше не содержит исходной ошибки — чинить нечего"
fi

if [ -f "${STARTER}" ] && [ "$(grep -cE '^[[:space:]]*/var/log' "${STARTER}")" -lt 2 ]; then
    ok "самопроверка: в стартере описана только одна служба из двух"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
