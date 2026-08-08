#!/usr/bin/env bash
#
# s04e06 «Одной командой» (капстоун Episode 14) — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства compose.yaml. Файл разбирается по отступам:
# верхний уровень — колонка 0, службы — 2 пробела, их ключи — 4. Этого
# достаточно, чтобы отвечать на вопросы «что у какой службы задано»,
# и не требует ни docker, ни внешнего разборщика YAML.
#
# Без root, без сети, **без docker**.
#
# Выбор артефакта: SUBJECT=... | artifacts/compose.yaml | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STARTER="${SERIES_DIR}/starter/compose.yaml"

if   [ -n "${SUBJECT:-}" ];                           then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/compose.yaml" ];   then CFG="${SERIES_DIR}/artifacts/compose.yaml"
elif [ -f "${SERIES_DIR}/compose.yaml" ];             then CFG="${SERIES_DIR}/compose.yaml"
else CFG="${SERIES_DIR}/solution/compose.yaml"
     echo "ℹ️  Свой compose.yaml не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/compose.yaml artifacts/compose.yaml"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e06 tests — конфиг: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${CFG}" ]; then ok "compose.yaml найден"
else no "compose.yaml не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

BODY="$(sed -e 's/\r$//' -e 's/[[:space:]]*#.*$//' "${CFG}" | grep -v '^[[:space:]]*$')"

# top <ключ> — блок верхнего уровня (всё, что с отступом, до следующего уровня 0)
top() {
    printf '%s\n' "${BODY}" | awk -v k="$1" '
        $0 ~ ("^" k ":") {f=1; next}
        /^[^[:space:]]/ {f=0}
        f'
}
# svc <имя> — блок службы внутри services:
svc() {
    top services | awk -v s="$1" '
        $0 ~ ("^  " s ":") {f=1; next}
        /^  [^[:space:]]/ {f=0}
        f'
}
services() { top services | awk '/^  [^[:space:]#]/ {sub(/:.*/,""); gsub(/ /,""); print}'; }
has_key()  { svc "$1" | grep -qE "^    $2:"; }
key_val()  { svc "$1" | awk -v k="$2" '$0 ~ ("^    " k ":") {sub(/^[^:]*:[[:space:]]*/,""); print; exit}'; }
sub_block(){ svc "$1" | awk -v k="$2" '$0 ~ ("^    " k ":") {f=1; next} /^    [^[:space:]]/ {f=0} f'; }

SVCS="$(services)"
n_svc="$(printf '%s\n' "${SVCS}" | grep -c . || true)"

# ---- 1. структура ------------------------------------------------------------
if printf '%s\n' "${BODY}" | grep -qE '^version:'; then
    no "ключ version: устарел с 2020 года — современный compose его игнорирует"
else
    ok "устаревшего ключа version: нет"
fi
if [ "${n_svc}" -ge 2 ]; then ok "служб описано: ${n_svc} ($(printf '%s' "${SVCS}" | tr '\n' ' '))"
else no "служб меньше двух — стек из одного контейнера не нужен"; fi

# ---- 2. образы ---------------------------------------------------------------
bad_img=""
for s in ${SVCS}; do
    img="$(key_val "${s}" image)"
    [ -n "${img}" ] || continue
    printf '%s' "${img}" | grep -qE ':latest$|^[^:]+$' && bad_img="${bad_img} ${s}=${img}"
done
if [ -z "${bad_img}" ]; then
    ok "у всех служб образы с точной версией"
else
    no "образ без версии или с latest:${bad_img} — завтра поднимется другое"
fi

# ---- 3. что смотрит наружу ---------------------------------------------------
db_ports="$(sub_block db ports || true)"
if [ -z "${db_ports}" ]; then
    ok "у базы нет publish-портов — внутри сети её и так видно по имени"
else
    no "база публикует порт наружу: $(printf '%s' "${db_ports}" | head -1 | tr -d ' -')"
fi
pub="$(printf '%s\n' "${BODY}" | grep -E '^ *- *"?[0-9]+:[0-9]+"?' || true)"
if [ -z "${pub}" ]; then
    ok "все публикуемые порты привязаны к конкретному адресу"
else
    no "порт опубликован на всех интерфейсах: $(printf '%s' "${pub}" | head -1 | tr -d ' -') — нужен префикс 127.0.0.1:"
fi

# ---- 4. секреты --------------------------------------------------------------
plain="$(printf '%s\n' "${BODY}" | grep -iE '^ +[A-Z_]*(PASSWORD|TOKEN|SECRET|API_KEY):[[:space:]]*[^[:space:]]' \
         | grep -viE '_FILE:' || true)"
if [ -z "${plain}" ]; then
    ok "паролей и токенов открытым текстом нет"
else
    no "секрет прямо в файле: $(printf '%s' "${plain}" | head -1 | sed 's/^ *//') — его видно в docker compose config"
fi
if printf '%s\n' "${BODY}" | grep -qE '^secrets:' && printf '%s\n' "${BODY}" | grep -qE '_FILE:'; then
    ok "пароль передаётся через secrets и переменную *_FILE"
else
    no "нет блока secrets: или переменной вида PASSWORD_FILE — секрет негде взять"
fi

# ---- 5. данные ---------------------------------------------------------------
if printf '%s\n' "${BODY}" | grep -qE '^volumes:'; then
    ok "именованные тома объявлены"
else
    no "нет блока volumes: — данные базы исчезнут при пересоздании контейнера"
fi
if sub_block db volumes | grep -qE '^ *- *[a-z_]+:/'; then
    ok "данные базы лежат в именованном томе"
else
    no "у базы нет именованного тома: данные в записываемом слое контейнера"
fi

# ---- 6. порядок запуска ------------------------------------------------------
if has_key db healthcheck; then
    ok "у базы задан healthcheck"
else
    no "у базы нет healthcheck — дождаться её готовности будет нечем"
fi
dep="$(sub_block collector depends_on || true)"
if [ -z "${dep}" ]; then
    no "collector не зависит от базы"
elif printf '%s' "${dep}" | grep -q 'service_healthy'; then
    ok "collector ждёт готовности базы (condition: service_healthy)"
else
    no "depends_on без condition: контейнер базы запустится, а сама база ещё нет — сборщик получит отказ"
fi

# ---- 7. ограничения контейнера -----------------------------------------------
u="$(key_val collector user)"
if [ -n "${u}" ] && [ "${u}" != "root" ] && ! printf '%s' "${u}" | grep -q '^"\?0'; then
    ok "collector работает не от root: user ${u}"
else
    no "у collector не задан user (или он root)"
fi
if printf '%s\n' "${BODY}" | grep -qE '^ +privileged:[[:space:]]*true'; then
    no "privileged: true отключает почти всю изоляцию"
else
    ok "privileged нигде не включён"
fi
if printf '%s\n' "${BODY}" | grep -q 'docker.sock'; then
    no "монтирование docker.sock даёт контейнеру контроль над хостом"
else
    ok "docker.sock не монтируется"
fi
if printf '%s\n' "${BODY}" | grep -qE '^ +cap_drop:'; then
    ok "возможности ядра урезаны (cap_drop)"
else
    no "cap_drop не задан — контейнер получает набор возможностей по умолчанию"
fi
if [ "$(key_val collector read_only)" = "true" ]; then
    ok "файловая система collector только на чтение"
else
    no "read_only не включён: контейнер может писать куда угодно внутри себя"
fi

# ---- 8. сеть -----------------------------------------------------------------
if printf '%s\n' "${BODY}" | grep -qE '^networks:'; then
    ok "сети объявлены явно"
else
    no "нет блока networks: все службы окажутся в одной сети по умолчанию"
fi
if top networks | grep -q 'internal: *true'; then
    ok "есть сеть без выхода наружу (internal: true)"
else
    no "ни одна сеть не помечена internal — база сможет обращаться в интернет"
fi

# ---- 9. перезапуск -----------------------------------------------------------
bad_restart=""
for s in ${SVCS}; do
    r="$(key_val "${s}" restart)"
    case "${r}" in unless-stopped|always|on-failure) : ;; *) bad_restart="${bad_restart} ${s}" ;; esac
done
if [ -z "${bad_restart}" ]; then
    ok "политика перезапуска задана у всех служб"
else
    no "нет restart у:${bad_restart} — после перезагрузки хоста стек не поднимется"
fi

# ---- 10. самопроверки --------------------------------------------------------
if [ -f "${STARTER}" ] && grep -qE '^version:' "${STARTER}" && grep -q 'docker.sock' "${STARTER}"; then
    ok "самопроверка: в стартере ловушки на месте (version и docker.sock)"
else
    no "самопроверка: стартер больше не содержит исходных ошибок"
fi
if [ -f "${STARTER}" ] && grep -qE '^ +- "5432:5432"' "${STARTER}"; then
    ok "самопроверка: в стартере база смотрит наружу"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
