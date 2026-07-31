#!/usr/bin/env bash
#
# s01e02 «Осмотреться» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт recon.txt сверяется с реальным
# содержимым объекта разведки. Эталон вычисляется здесь же командами — в тесте
# нет ни одного захардкоженного числа, поэтому при изменении учебных данных
# тест не разъезжается с реальностью (план §4.2, §4.3).
#
# Без root, без сети. Объект разведки лежит в репозитории.
#
# Выбор отчёта: SUBJECT=... | artifacts/recon.txt (основное место) | <серия>/recon.txt | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${SERIES_DIR}/../data/test_environment"

if   [ -n "${SUBJECT:-}" ];                     then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/recon.txt" ];then REPORT="${SERIES_DIR}/artifacts/recon.txt"
elif [ -f "${SERIES_DIR}/recon.txt" ];          then REPORT="${SERIES_DIR}/recon.txt"
else REPORT="${SERIES_DIR}/solution/recon.txt"
     echo "ℹ️  Свой recon.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/recon.txt artifacts/recon.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e02 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- предусловия -----------------------------------------------------------
if [ ! -d "${TARGET}" ]; then
    echo "  FAIL: объект разведки не найден: ${TARGET}" >&2
    echo "  (ожидается season-01-shell-foundations/data/test_environment)" >&2
    exit 1
fi
if [ -f "${REPORT}" ]; then
    ok "отчёт recon.txt найден"
else
    no "recon.txt не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталон: вычисляется из реальных данных --------------------------------
exp_total=$(ls -A "${TARGET}" | wc -l | tr -d ' ')
exp_hidden=$(ls -A "${TARGET}" | grep -c '^\.' || true)
exp_dirs=$(find "${TARGET}" -maxdepth 1 -mindepth 1 -type d | wc -l | tr -d ' ')
exp_hnames=$(ls -A "${TARGET}" | grep '^\.' | sort | paste -sd, - | tr -d ' ')
exp_docs=$(ls -A "${TARGET}/documents" 2>/dev/null | wc -l | tr -d ' ')
exp_dochidden=$(ls -A "${TARGET}/documents" 2>/dev/null | grep '^\.' | head -1)

# ---- чтение отчёта студента ------------------------------------------------
val() {  # val <ключ> — значение из recon.txt, без пробелов и комментариев
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
        no "${desc}: указано '${got}', в системе '${want}'"
    fi
}

check total_entries         "${exp_total}"     "объектов в корне сервера"
check hidden_entries        "${exp_hidden}"    "из них скрытых"
check dirs                  "${exp_dirs}"      "каталогов в корне"
check hidden_names          "${exp_hnames}"    "имена скрытых объектов"
check documents_entries     "${exp_docs}"      "объектов в documents/"
check documents_hidden_name "${exp_dochidden}" "скрытый файл в documents/"

# ---- дискриминатор: обычный ls не увидел бы скрытое ------------------------
visible_only=$(ls "${TARGET}" | wc -l | tr -d ' ')
if [ "${exp_total}" -gt "${visible_only}" ]; then
    ok "самопроверка: обычный ls показывает ${visible_only} из ${exp_total} — скрытое требует -a"
else
    no "самопроверка: в объекте нет скрытых объектов, задание вырождено"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
