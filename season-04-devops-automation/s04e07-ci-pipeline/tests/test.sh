#!/usr/bin/env bash
#
# s04e07 «Машина, которую нельзя уговорить» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства файла конвейера. Разбор — по отступам:
# верхний уровень — колонка 0, job'ы — 2 пробела, их ключи — 4. Отдельно
# выделяются строки, входящие в значение `run:`, потому что почти все
# интересные ошибки — это то, что попало (или не попало) именно в команду.
#
# Зависимости между job'ами разбираются в граф, и достижимость считается
# обходом: правило «в бой нельзя попасть в обход проверок» проверяется
# по самому файлу, без единого зашитого имени job'а.
#
# Без root, без сети, без github. Файл проверяется как текст.
#
# Выбор артефакта: SUBJECT=... | artifacts/ci.yml | <серия>/ci.yml | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STARTER="${SERIES_DIR}/starter/ci.yml"

if   [ -n "${SUBJECT:-}" ];                      then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/ci.yml" ];    then CFG="${SERIES_DIR}/artifacts/ci.yml"
elif [ -f "${SERIES_DIR}/ci.yml" ];              then CFG="${SERIES_DIR}/ci.yml"
else CFG="${SERIES_DIR}/solution/ci.yml"
     echo "ℹ️  Своего ci.yml не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/ci.yml artifacts/ci.yml"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e07 tests — конвейер: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${CFG}" ]; then ok "ci.yml найден"
else no "ci.yml не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

# Комментарии убираются, но только целыми строками и хвостами после пробела:
# внутри команд решётка встречается по делу.
BODY="$(sed -e 's/\r$//' -e 's/^[[:space:]]*#.*$//' -e 's/[[:space:]]#[^"'"'"']*$//' \
            -e 's/[[:space:]]*$//' "${CFG}" | grep -v '^[[:space:]]*$')"

# ---- разбор ------------------------------------------------------------------
top()  { printf '%s\n' "${BODY}" | awk -v k="$1" '
             $0 ~ ("^" k ":") {f=1; next} /^[^[:space:]]/ {f=0} f'; }
job()  { top jobs | awk -v s="$1" '
             $0 ~ ("^  " s ":") {f=1; next} /^  [^[:space:]]/ {f=0} f'; }
job_names() { top jobs | awk '/^  [a-zA-Z]/ {sub(/:.*/,""); gsub(/ /,""); print}'; }
job_key()   { job "$1" | awk -v k="$2" '
                  $0 ~ ("^    " k ":") {sub(/^[^:]*:[[:space:]]*/,""); print; exit}'; }

# все строки, входящие в значение run: (и однострочные, и блочные)
RUNLINES="$(printf '%s\n' "${BODY}" | awk '
    { ind = match($0, /[^ ]/) }
    inrun { if (ind > runind) { print; next } else { inrun = 0 } }
    /^[[:space:]]*run:/ { print; if ($0 ~ /run:[[:space:]]*[|>]/) { inrun = 1; runind = ind } }')"

needs_of() {
    job "$1" | awk '
        /^    [a-zA-Z]/ && $0 !~ /^    needs:/ { f = 0 }
        /^    needs:/ { line = $0; sub(/^    needs:[[:space:]]*/, "", line)
                        gsub(/[][,]/, " ", line)
                        if (line ~ /[^[:space:]]/) { print line; exit }
                        f = 1; next }
        f && /^ *- / { line = $0; sub(/^ *- */, "", line); print line }' | tr -d "\"'"
}

# достижимость по цепочке needs: reaches <откуда> <куда>
reaches() {
    local frontier="$1" target="$2" seen="" nxt cur
    while [ -n "${frontier// /}" ]; do
        nxt=""
        for cur in ${frontier}; do
            case " ${seen} " in *" ${cur} "*) continue ;; esac
            seen="${seen} ${cur}"
            [ "${cur}" = "${target}" ] && return 0
            nxt="${nxt} $(needs_of "${cur}" | tr '\n' ' ')"
        done
        frontier="${nxt}"
    done
    return 1
}

JOBS="$(job_names)"
n_jobs="$(printf '%s\n' "${JOBS}" | grep -c . || true)"

# ---- 1. когда запускается ----------------------------------------------------
if top on | grep -qE '^  pull_request:'; then
    ok "конвейер запускается на pull_request — проверка приходит до слияния"
else
    no "нет триггера pull_request: проверка узнает о беде уже после слияния в main"
fi
if printf '%s\n' "${BODY}" | grep -q 'pull_request_target'; then
    no "pull_request_target даёт коду из чужой ветки доступ к секретам репозитория"
else
    ok "pull_request_target не используется"
fi

# ---- 2. чужой код: закреплены ли версии действий ------------------------------
USES="$(printf '%s\n' "${BODY}" | awk '/^[[:space:]]*-?[[:space:]]*uses:/ {sub(/^.*uses:[[:space:]]*/,""); print}')"
n_uses="$(printf '%s\n' "${USES}" | grep -c . || true)"
float=""
while IFS= read -r u; do
    [ -n "${u}" ] || continue
    case "${u}" in ./*|docker://*) continue ;; esac
    ref="${u##*@}"
    if [ "${ref}" = "${u}" ]; then float="${float} ${u}(без версии)"; continue; fi
    printf '%s' "${ref}" | grep -qE '^[0-9a-f]{40}$|^v[0-9]+\.[0-9]+\.[0-9]+$' || float="${float} ${u}"
done <<< "${USES}"
if [ "${n_uses}" -eq 0 ]; then
    no "ни одного uses: — конвейер даже не забирает репозиторий"
elif [ -z "${float}" ]; then
    ok "все ${n_uses} действий закреплены (хеш или версия до patch)"
else
    no "версия действия не закреплена:${float} — завтра это будет другой код на вашей машине"
fi

# ---- 3. права токена ---------------------------------------------------------
if printf '%s\n' "${BODY}" | grep -qE '^permissions:'; then
    ok "права токена заданы явно"
else
    no "нет блока permissions: токен job'а по умолчанию умеет писать в репозиторий"
fi
if top permissions | grep -qE '(write-all|: *write)'; then
    no "токен получает право записи: $(top permissions | grep -E '(write-all|: *write)' | head -1 | sed 's/^ *//')"
else
    ok "право записи токену не выдано"
fi

# ---- 4. секреты --------------------------------------------------------------
plain="$(printf '%s\n' "${BODY}" \
         | grep -iE '^[[:space:]]*[A-Z_]*(PASSWORD|PASSWD|TOKEN|SECRET|API_KEY):[[:space:]]*[^[:space:]$]' || true)"
if [ -z "${plain}" ]; then
    ok "паролей открытым текстом в файле нет"
else
    no "секрет прямо в конвейере: $(printf '%s' "${plain}" | head -1 | sed 's/^ *//') — файл лежит в репозитории"
fi
if printf '%s\n' "${BODY}" | grep -q 'secrets\.'; then
    ok "секреты берутся из хранилища (secrets.*)"
else
    no "ни одной ссылки на secrets.* — брать пароль неоткуда"
fi
if printf '%s\n' "${RUNLINES}" | grep -q '{{[[:space:]]*secrets\.'; then
    no "секрет подставляется прямо в команду: он окажется в тексте команды и в журнале прогона; передавайте через env:"
else
    ok "секреты не подставляются в текст команды"
fi

# ---- 5. подстановка данных события в команду ---------------------------------
inj="$(printf '%s\n' "${RUNLINES}" | grep -E '\{\{[[:space:]]*github\.event\.' || true)"
if [ -z "${inj}" ]; then
    ok "данные события не вклеиваются в команду"
else
    no "подстановка github.event.* в run: $(printf '%s' "${inj}" | head -1 | sed 's/^ *//') — текст из чужого коммита попадёт в команду до её разбора"
fi

# ---- 6. может ли проверка провалиться ----------------------------------------
if printf '%s\n' "${BODY}" | grep -qE 'continue-on-error:[[:space:]]*true'; then
    no "continue-on-error: true — шаг падает, job зеленеет"
else
    ok "ни один шаг не помечен continue-on-error"
fi
swallow="$(printf '%s\n' "${RUNLINES}" | grep -E '\|\|[[:space:]]*(true|:)[[:space:]]*$|;[[:space:]]*true[[:space:]]*$' || true)"
if [ -z "${swallow}" ]; then
    ok "ни одна проверка не заканчивается «|| true»"
else
    no "код возврата проглочен: $(printf '%s' "${swallow}" | head -1 | sed 's/^ *//') — проверка не может провалиться, значит это не проверка"
fi

# ---- 7. граф: можно ли попасть в бой в обход проверок ------------------------
CHECKJOB=""
for j in ${JOBS}; do
    job "${j}" | grep -q 'prepush_check' && { CHECKJOB="${j}"; break; }
done
if [ -n "${CHECKJOB}" ]; then
    ok "проверки репозитория выполняются в конвейере (job «${CHECKJOB}»)"
else
    no "ни один job не запускает scripts/prepush_check.sh — проверять нечем"
fi
outward=""; bypass=""
for j in ${JOBS}; do
    if job "${j}" | grep -qE '(docker push|ssh [a-z])'; then
        outward="${outward} ${j}"
        [ -n "${CHECKJOB}" ] && { reaches "${j}" "${CHECKJOB}" || bypass="${bypass} ${j}"; }
    fi
done
if [ -z "${outward// /}" ]; then
    no "ни один job ничего не выкатывает — конвейер обрывается на проверках"
elif [ -z "${bypass}" ] && [ -n "${CHECKJOB}" ]; then
    ok "каждый job, выходящий наружу (${outward# }), зависит от проверок по цепочке needs"
else
    no "в обход проверок:${bypass} — этот job стартует параллельно с ними, а не после"
fi

# ---- 8. чем именно выкатываем ------------------------------------------------
if printf '%s\n' "${RUNLINES}" | grep -qE 'docker (build|push|pull).*:latest'; then
    no "выкат тегом latest: у предыдущей версии не будет имени, и откатываться будет некуда"
else
    ok "тег latest в выкате не используется"
fi
if printf '%s\n' "${RUNLINES}" | grep -qE '(GITHUB_SHA|github\.sha)'; then
    ok "образ помечен хешем коммита — у каждой сборки есть неизменяемое имя"
else
    no "образ не помечен хешем коммита: непонятно, что именно сейчас в бою"
fi

# ---- 9. кто пускает в бой ----------------------------------------------------
PRODJOB=""
for j in ${JOBS}; do
    [ "$(job_key "${j}" environment)" = "production" ] && { PRODJOB="${j}"; break; }
done
if [ -n "${PRODJOB}" ]; then
    ok "выкат в бой идёт через окружение production (там же живёт ручное одобрение)"
else
    no "ни один job не привязан к environment: production — одобрять выкат некому и негде"
fi
if [ -n "${PRODJOB}" ] && job_key "${PRODJOB}" if | grep -q 'refs/heads/main'; then
    ok "в бой выкатывается только main"
else
    no "выкат в бой не ограничен веткой main: в бой уедет любая ветка, дошедшая до этого job"
fi

# ---- 10. дисциплина job'ов ---------------------------------------------------
no_runner=""; latest_runner=""; no_timeout=""
for j in ${JOBS}; do
    r="$(job_key "${j}" runs-on)"
    [ -n "${r}" ] || no_runner="${no_runner} ${j}"
    printf '%s' "${r}" | grep -q 'latest' && latest_runner="${latest_runner} ${j}"
    [ -n "$(job_key "${j}" timeout-minutes)" ] || no_timeout="${no_timeout} ${j}"
done
if [ "${n_jobs}" -ge 2 ] && [ -z "${no_runner}" ]; then
    ok "у всех ${n_jobs} job задан runs-on"
else
    no "job без runs-on:${no_runner} (всего job: ${n_jobs}, нужно не меньше двух)"
fi
if [ -z "${latest_runner}" ]; then
    ok "версия рантайма закреплена (не ubuntu-latest)"
else
    no "runs-on: *-latest у:${latest_runner} — то же самое, что тег latest у образа"
fi
if [ -z "${no_timeout}" ]; then
    ok "у всех job'ов задан timeout-minutes"
else
    no "нет timeout-minutes у:${no_timeout} — зависший job держит очередь до шести часов"
fi

# ---- 11. выкат заканчивается ответом машины ----------------------------------
noverify=""
for j in ${JOBS}; do
    [ -n "$(job_key "${j}" environment)" ] || continue
    job "${j}" | grep -qE '(healthz|curl -f|--fail)' || noverify="${noverify} ${j}"
done
if [ -z "${noverify}" ] && [ -n "${PRODJOB}" ]; then
    ok "каждый выкат заканчивается проверкой готовности"
else
    no "выкат без проверки готовности:${noverify} — «команда выполнена» не значит «служба отвечает»"
fi

# ---- 12. самопроверки --------------------------------------------------------
if [ -f "${STARTER}" ] && grep -q '@main' "${STARTER}" && grep -q '|| true' "${STARTER}"; then
    ok "самопроверка: в стартере ловушки на месте (плавающее действие и проглоченный код возврата)"
else
    no "самопроверка: стартер больше не содержит исходных ошибок"
fi
if [ -f "${STARTER}" ] && grep -q 'REGISTRY_PASSWORD: Sh4dow' "${STARTER}" && grep -q ':latest' "${STARTER}"; then
    ok "самопроверка: в стартере остались пароль открытым текстом и выкат тегом latest"
else
    no "самопроверка: вторая пара ловушек стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
