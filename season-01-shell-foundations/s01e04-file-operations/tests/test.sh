#!/usr/bin/env bash
#
# s01e04 «Рабочее место» — тест состояния файловой системы (Type B).
#
# Артефакт этой серии — не файл с текстом, а СТРУКТУРА, созданная командами.
# Тест проверяет свойства результата: каталоги, копии добытых файлов, пустой
# журнал, отсутствие черновика и — главное — что оригиналы на «сервере» целы
# (копировать надо cp, а не mv).
#
# Без root, без сети. Ничего вне серии не изменяется.
#
# Запуск: bash tests/test.sh  (из корня серии; путь к рабочему пространству
# можно переопределить: WORKSPACE=... bash tests/test.sh)

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRV="${SERIES_DIR}/../data/test_environment"
WS="${WORKSPACE:-${SERIES_DIR}/artifacts/workspace}"

# Фолбэк, как в остальных сериях: пока своего пространства нет, проверяется ЭТАЛОН,
# собранный во временном каталоге. Так тест зелёный «из коробки», а раннер курса
# отличает реальную поломку от «студент ещё не начал».
TMP_WS=""
if [ ! -d "${WS}" ] && [ -z "${WORKSPACE:-}" ]; then
    echo "ℹ️  Своё рабочее пространство не найдено — проверяю ЭТАЛОН (solution/)."
    echo "   Начни своё:  mkdir -p artifacts/workspace"
    echo ""
    TMP_WS="$(mktemp -d 2>/dev/null || mktemp -d -t s01e04)"
    trap 'rm -rf "${TMP_WS}"' EXIT
    ( cd "${SERIES_DIR}" && WS_OVERRIDE="${TMP_WS}" bash solution/build_workspace.sh >/dev/null 2>&1 )
    WS="${TMP_WS}"
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e04 tests — рабочее пространство: ${WS#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ ! -d "${SRV}" ]; then
    echo "  FAIL: не найден «сервер»: ${SRV}" >&2
    exit 1
fi

if [ -d "${WS}" ]; then
    ok "рабочее пространство создано"
else
    no "каталог artifacts/workspace не создан"
    echo "  Подсказка: mkdir -p artifacts/workspace"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- 1. каркас каталогов ---------------------------------------------------
for d in intel tools logs; do
    if [ -d "${WS}/${d}" ]; then
        ok "каталог ${d}/ на месте"
    else
        no "нет каталога ${d}/ (mkdir -p ${d})"
    fi
done

# ---- 2. копии добытых файлов (содержимое сверяется с источником) -----------
same() {  # same <файл-копия> <файл-источник> <описание>
    local copy="$1" src="$2" desc="$3"
    if [ ! -f "${copy}" ]; then
        no "${desc}: файл отсутствует"
    elif cmp -s "${copy}" "${src}"; then
        ok "${desc}: копия совпадает с оригиналом"
    else
        no "${desc}: содержимое не совпадает с источником"
    fi
}

same "${WS}/intel/briefing.txt" "${SRV}/documents/briefing.txt"     "briefing.txt"
same "${WS}/intel/meeting.txt"  "${SRV}/documents/.secret_location" "meeting.txt (копия .secret_location)"
same "${WS}/intel/access.txt"   "${SRV}/.next_server"               "access.txt (копия .next_server)"

# ---- 3. журнал создан и пуст ----------------------------------------------
if [ -f "${WS}/logs/operation.log" ]; then
    if [ ! -s "${WS}/logs/operation.log" ]; then
        ok "журнал logs/operation.log создан и пуст (touch)"
    else
        ok "журнал logs/operation.log существует"
    fi
else
    no "нет файла logs/operation.log (touch создаёт пустой файл)"
fi

# ---- 4. черновик удалён ----------------------------------------------------
if [ -e "${WS}/tmp_draft.txt" ]; then
    no "черновик tmp_draft.txt не удалён (rm)"
else
    ok "черновик удалён"
fi

# ---- 5. ГЛАВНОЕ: оригиналы на «сервере» целы -------------------------------
intact=1
for f in "${SRV}/documents/briefing.txt" "${SRV}/documents/.secret_location" "${SRV}/.next_server"; do
    [ -f "${f}" ] || intact=0
done
if [ "${intact}" -eq 1 ]; then
    ok "оригиналы на «сервере» не тронуты (копировали cp, а не mv)"
else
    no "на «сервере» пропали файлы — использован mv вместо cp; восстанови: git checkout -- ../data/"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
