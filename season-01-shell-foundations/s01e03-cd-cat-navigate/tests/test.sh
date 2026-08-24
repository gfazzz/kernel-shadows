#!/usr/bin/env bash
#
# s01e03 «Дойти и прочитать» — тест разведданных (Type C).
#
# Проверяет не скрипт, а извлечённые факты: intel.txt сверяется с содержимым трёх
# файлов «сервера». Эталон вычисляется здесь же из самих источников — ни одного
# захардкоженного значения, поэтому правка учебных данных не ломает
# задание, а автоматически меняет ожидаемый ответ.
#
# Без root, без сети. Источники лежат в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/intel.txt (основное место) | <серия>/intel.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRV="${SERIES_DIR}/../data/test_environment"

if   [ -n "${SUBJECT:-}" ];                     then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/intel.txt" ];then REPORT="${SERIES_DIR}/artifacts/intel.txt"
elif [ -f "${SERIES_DIR}/intel.txt" ];          then REPORT="${SERIES_DIR}/intel.txt"
else REPORT="${SERIES_DIR}/solution/intel.txt"
     echo "ℹ️  Свой intel.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/intel.txt artifacts/intel.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e03 tests — разведданные: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- предусловия -----------------------------------------------------------
for f in "${SRV}/documents/briefing.txt" "${SRV}/documents/.secret_location" "${SRV}/.next_server"; do
    if [ ! -f "${f}" ]; then
        echo "  FAIL: источник не найден: ${f}" >&2
        exit 1
    fi
done
if [ -f "${REPORT}" ]; then
    ok "отчёт intel.txt найден"
else
    no "intel.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: извлекается из самих источников -------------------------------
exp_clearance=$(grep -E '^CLEARANCE:' "${SRV}/documents/briefing.txt" | grep -oE 'Level [0-9]+' | grep -oE '[0-9]+')
exp_lat=$(grep -E '^Latitude:' "${SRV}/documents/.secret_location" | awk '{print $2}')
exp_lon=$(grep -E '^Longitude:' "${SRV}/documents/.secret_location" | awk '{print $2}')
exp_time=$(grep -E '^Time:' "${SRV}/documents/.secret_location" | grep -oE '[0-9]{2}:[0-9]{2}')
exp_ip=$(grep -E '^IP Address:' "${SRV}/.next_server" | awk '{print $3}')
exp_port=$(grep -E '^Port:' "${SRV}/.next_server" | awk '{print $2}')
exp_user=$(grep -E '^Username:' "${SRV}/.next_server" | awk '{print $2}')

# ---- чтение отчёта студента ------------------------------------------------
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${REPORT}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- | tr -d ' \t\r'
}

check() {  # check <ключ> <эталон> <описание>
    local key="$1" want="$2" desc="$3" got
    got="$(val "${key}")"
    if [ -z "${got}" ]; then
        no "${desc}: не заполнено (${key}=)"
    elif [ "${got}" = "${want}" ]; then
        ok "${desc}: ${got}"
    else
        no "${desc}: указано '${got}', в источнике '${want}'"
    fi
}

check clearance_level "${exp_clearance}" "уровень допуска (briefing.txt)"
check latitude        "${exp_lat}"       "широта (.secret_location)"
check longitude       "${exp_lon}"       "долгота (.secret_location)"
check meeting_time    "${exp_time}"      "время встречи"
check next_ip         "${exp_ip}"        "IP следующего узла (.next_server)"
check next_port       "${exp_port}"      "порт SSH"
check next_user       "${exp_user}"      "имя пользователя"

# ---- дискриминатор: данные лежат на разной глубине и в скрытых файлах -------
if [ -f "${SRV}/.next_server" ] && [ -f "${SRV}/documents/.secret_location" ]; then
    ok "самопроверка: источники на разных уровнях, два из трёх скрыты — нужен обход дерева"
else
    no "самопроверка: структура источников нарушена"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
