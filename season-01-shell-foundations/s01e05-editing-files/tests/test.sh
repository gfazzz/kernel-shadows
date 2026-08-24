#!/usr/bin/env bash
#
# s01e05 «Правка на месте» — тест конфигурации (Type B).
#
# Проверяет СВОЙСТВА конфига, а не то, каким редактором его правили: значения,
# раскомментированную директиву, выключённый отладочный лог. Часть значений
# сверяется с файлом доступа на «сервере» — так проверяется кумулятивность
# (данные из s01e03 реально использованы, а не выдуманы).
#
# Без root, без сети. Источник истины лежит в репозитории.
#
# Выбор конфига: SUBJECT=... | artifacts/agent.conf (основное место) | <серия>/agent.conf | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${SERIES_DIR}/../data/test_environment/.next_server"

if   [ -n "${SUBJECT:-}" ];                       then CONF="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/agent.conf" ]; then CONF="${SERIES_DIR}/artifacts/agent.conf"
elif [ -f "${SERIES_DIR}/agent.conf" ];           then CONF="${SERIES_DIR}/agent.conf"
else CONF="${SERIES_DIR}/solution/agent.conf"
     echo "ℹ️  Свой agent.conf не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/agent.conf artifacts/agent.conf"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s01e05 tests — конфиг: ${CONF#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${SRC}" ] || { echo "  FAIL: не найден источник доступа: ${SRC}" >&2; exit 1; }
if [ -f "${CONF}" ]; then
    ok "конфиг agent.conf найден"
else
    no "agent.conf не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- эталонные значения берутся из файла доступа ---------------------------
want_ip=$(grep -E '^IP Address:' "${SRC}" | awk '{print $3}')
want_port=$(grep -E '^Port:' "${SRC}" | awk '{print $2}')
want_user=$(grep -E '^Username:' "${SRC}" | awk '{print $2}')

# значение активной (незакомментированной) директивы
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${CONF}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- | tr -d ' \t\r'
}

check() {  # check <директива> <ожидание> <описание>
    local key="$1" want="$2" desc="$3" got
    got="$(val "${key}")"
    if [ -z "${got}" ]; then
        no "${desc}: директива ${key} отсутствует или закомментирована"
    elif [ "${got}" = "${want}" ]; then
        ok "${desc}: ${got}"
    else
        no "${desc}: указано '${got}', ожидалось '${want}'"
    fi
}

# ---- 1. значения подставлены из разведданных (кумулятивность) --------------
check server     "${want_ip}"   "адрес узла (из .next_server)"
check port       "${want_port}" "порт SSH"
check user       "${want_user}" "имя пользователя"

# ---- 2. плейсхолдеры не остались -------------------------------------------
if grep -q 'CHANGE_ME' "${CONF}"; then
    no "в конфиге остались плейсхолдеры CHANGE_ME"
else
    ok "плейсхолдеров не осталось"
fi

# ---- 3. шифрование включено (строка раскомментирована) ---------------------
check encryption "on" "шифрование канала"

# ---- 4. отладочный лог выключен --------------------------------------------
check debug_log  "false" "отладочный лог"

# ---- 5. чужое не тронуто ---------------------------------------------------
check timeout    "30" "таймаут (менять не требовалось)"

# ---- 6. файл остался конфигом, а не превратился в кашу ---------------------
if grep -qE '^[[:space:]]*[a-z_]+[[:space:]]*=' "${CONF}" && [ "$(grep -c '=' "${CONF}")" -ge 5 ]; then
    ok "структура файла сохранена (директивы вида ключ = значение)"
else
    no "структура конфига нарушена"
fi

# ---- 7. комментарии-пояснения не удалены -----------------------------------
if [ "$(grep -c '^#' "${CONF}")" -ge 3 ]; then
    ok "комментарии сохранены (конфиг остался читаемым)"
else
    no "комментарии вычищены — конфиг потерял пояснения"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
