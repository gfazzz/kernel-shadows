#!/usr/bin/env bash
#
# s07e11 «Отказ, которого нет в журнале» — тест находок (Type C).
#
# Каждое значение отчёта пересчитывается из снимков в data/: строки AVC,
# вывод semanage и getsebool, контексты процессов и файлов. Констант нет.
#
# Ключевая самопроверка данных — что снимок с выключенным dontaudit
# содержит отказы, которых нет в обычном. Без этого серия свелась бы к
# пересчёту строк одного файла.
#
# Без root, без сети, без SELinux на машине студента.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
SES="${D}/sestatus.txt"; PSZ="${D}/ps_z.txt"; LSZ="${D}/ls_z.txt"
AVC="${D}/audit_avc.txt"; AVC2="${D}/audit_avc_dontaudit_off.txt"
FCX="${D}/semanage_fcontext.txt"; PORT="${D}/semanage_port.txt"; BOOL="${D}/getsebool.txt"

if   [ -n "${SUBJECT:-}" ];                                 then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/selinux_report.txt" ];   then REP="${SERIES_DIR}/artifacts/selinux_report.txt"
elif [ -f "${SERIES_DIR}/selinux_report.txt" ];             then REP="${SERIES_DIR}/selinux_report.txt"
else REP="${SERIES_DIR}/solution/selinux_report.txt"
     echo "ℹ️  Своего selinux_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/selinux_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e11 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${SES}" "${PSZ}" "${LSZ}" "${AVC}" "${AVC2}" "${FCX}" "${PORT}" "${BOOL}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${REP}" ]; then ok "selinux_report.txt найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

got()   { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "${REP}"; }
check() { local k="$1" want="$2" why="$3" have; have="$(got "${k}")"
    if [ -z "${have}" ]; then no "${k}: не заполнено (${why})"
    elif [ "${have}" = "${want}" ]; then ok "${k}=${have}"
    else no "${k}=${have}, из снимков следует «${want}» — ${why}"; fi; }

# ── разбор AVC: «scontext_type tcontext_type tclass perm» ────────────
avc() {  # $1 — файл
    awk '/avc:[[:space:]]+denied/ {
        perm = $0; sub(/.*denied[[:space:]]+\{[[:space:]]*/, "", perm); sub(/[[:space:]]*\}.*/, "", perm)
        s = $0; sub(/.*scontext=/, "", s); sub(/[[:space:]].*/, "", s)
        t = $0; sub(/.*tcontext=/, "", t); sub(/[[:space:]].*/, "", t)
        c = $0; sub(/.*tclass=/, "", c); sub(/[[:space:]].*/, "", c)
        split(s, sp, ":"); split(t, tp, ":")
        print sp[3], tp[3], c, perm
    }' "$1"
}
E_TOTAL=$(avc "${AVC}" | grep -c . || true)
E_DISTINCT=$(avc "${AVC}" | sort -u | grep -c . || true)
E_TOTAL2=$(avc "${AVC2}" | grep -c . || true)
E_HIDDEN=$(( E_TOTAL2 - E_TOTAL ))

E_MODE=$(awk '/^Current mode:/ {print $3; exit}' "${SES}")
E_POLICY=$(awk '/^Loaded policy name:/ {print $4; exit}' "${SES}")

# Отказ по файлам: класс file или dir.
read -r L_S L_T _ _ <<<"$(avc "${AVC}" | awk '$3=="file" || $3=="dir" {print; exit}')"
# Путь, по которому нашлось нарушение меток, ищем в ls -Z по типу tcontext.
# Заголовок раздела в ls -Z — «/srv/aurora/:»; убираем двоеточие и косую.
E_PATH=$(awk -v t="${L_T}" '/^\// && /:$/ {p=$0; sub(/:$/,"",p); sub(/\/$/,"",p)}
                            $0 ~ (":" t ":") && p!="" {print p; exit}' "${LSZ}")
E_EXPECT=$(awk -v p="${E_PATH}" '/^[[:space:]]*#/{next} NF>=2 {
              base=$1; sub(/\(.*/,"",base); if (base==p) {print $2; exit} }' "${FCX}")

# Отказ по порту: name_bind.
read -r P_S P_T _ _ <<<"$(avc "${AVC}" | awk '$4=="name_bind" {print; exit}')"
E_PORT=$(awk '/name_bind/ {p=$0; sub(/.*src=/,"",p); sub(/[[:space:]].*/,"",p); print p; exit}' "${AVC}")
# Тип, предназначенный для веб-портов: у него имя начинается на http.
E_PORT_EXPECT=$(awk '/^[[:space:]]*#/{next} $1 ~ /^http_port_t/ {print $1; exit}' "${PORT}")

# Отказ по соединению: name_connect.
read -r C_S C_T _ _ <<<"$(avc "${AVC}" | awk '$4=="name_connect" {print; exit}')"
E_DEST=$(awk '/name_connect/ {p=$0; sub(/.*dest=/,"",p); sub(/[[:space:]].*/,"",p); print p; exit}' "${AVC}")
E_BOOL=$(awk '/^[[:space:]]*#/{next} /_db[[:space:]]*-->/ {print $1; exit}' "${BOOL}")
E_BOOL_VAL=$(awk -v b="${E_BOOL}" '$1==b {print $3; exit}' "${BOOL}")
E_BOOL_OFF=$(awk '/^[[:space:]]*#/{next} /^httpd/ && $3=="off"' "${BOOL}" | grep -c . || true)

E_UNCONF=$(awk '/^[[:space:]]*#/{next} $1 ~ /unconfined_service_t/ {print $NF; exit}' "${PSZ}")

echo ""
echo "── Исходные данные ──"
if [ "${E_HIDDEN}" -gt 0 ]
then ok "с выключенным dontaudit видно на ${E_HIDDEN} отказа больше — ловушка на месте"
else no "данные вырождены: dontaudit ничего не скрывает"; fi
if [ "${E_DISTINCT}" -lt "${E_TOTAL}" ]
then ok "из ${E_TOTAL} строк разных отказов ${E_DISTINCT} — повторы есть"
else no "данные вырождены: каждая строка уникальна, считать нечего"; fi
if [ -n "${E_UNCONF}" ]
then ok "в снимке есть служба в неограниченном домене (${E_UNCONF})"
else no "данные вырождены: неограниченного домена нет"; fi
if [ "${E_MODE}" = enforcing ]
then ok "режим enforcing — отказы действительно отказы, а не запись в журнал"
else no "данные вырождены: режим ${E_MODE}"; fi

echo ""
echo "── 1. Состояние подсистемы ──"
check mode   "${E_MODE}"   "строка Current mode"
check policy "${E_POLICY}" "строка Loaded policy name"

echo ""
echo "── 2. Сколько отказов ──"
check denials_total    "${E_TOTAL}"    "строк avc: denied"
check denials_distinct "${E_DISTINCT}" "разных четвёрок «кто, к чему, класс, действие»"
check hidden_denials   "${E_HIDDEN}"   "разница между снимками с dontaudit и без"

echo ""
echo "── 3. Метки файлов ──"
check case_label_scontext      "${L_S}"        "домен процесса из scontext"
check case_label_tcontext      "${L_T}"        "тип объекта из tcontext"
check case_label_expected_type "${E_EXPECT}"   "что политика ожидает по пути ${E_PATH}"
check case_label_fix           "restorecon"    "правило в политике есть, метки не проставлены"

echo ""
echo "── 4. Порт ──"
check case_port_number        "${E_PORT}"        "src в отказе name_bind"
check case_port_current_type  "${P_T}"           "tcontext того же отказа"
check case_port_expected_type "${E_PORT_EXPECT}" "тип, которому назначены веб-порты"
check case_port_fix           "semanage-port"    "порт добавляется к типу"

echo ""
echo "── 5. Соединение с базой ──"
check case_db_dest_port       "${E_DEST}"     "dest в отказе name_connect"
check case_db_tcontext        "${C_T}"        "tcontext того же отказа"
check case_db_boolean         "${E_BOOL}"     "переключатель про соединение с базой"
check case_db_boolean_current "${E_BOOL_VAL}" "его состояние в getsebool"
check case_db_fix             "setsebool"     "развилка заготовлена политикой"

echo ""
echo "── 6. Чего не видно ──"
check unconfined_service "${E_UNCONF}"   "процесс в unconfined_service_t"
check booleans_off       "${E_BOOL_OFF}" "переключатели httpd в состоянии off"

echo ""
echo "── Выводы ──"
if [ "$(got case_label_fix)" != "policy-module" ] && [ "$(got case_port_fix)" != "policy-module" ] \
   && [ "$(got case_db_fix)" != "policy-module" ]
then ok "ни один отказ не потребовал своего модуля политики"
else no "предложен свой модуль там, где хватает штатных средств"; fi
if [ "$(got case_label_fix)" != "$(got case_port_fix)" ] \
   && [ "$(got case_port_fix)" != "$(got case_db_fix)" ]
then ok "три отказа чинятся тремя разными способами"
else no "разным отказам назначено одно лечение — «поставить permissive» не считается"; fi
grep -qE '^[[:space:]]*#' "${REP}" && ok "пояснения в файле остались" \
    || no "все комментарии вырезаны — отчёт должен объяснять, откуда значения"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
