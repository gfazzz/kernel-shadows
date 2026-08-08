#!/usr/bin/env bash
#
# s04e05 «Двенадцать строк» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства Dockerfile: инструкции разбираются
# по порядку, потому что порядок здесь и есть предмет — от него зависит,
# что попадёт в кеш и что попадёт в слой.
#
# Без root, без сети, **без docker**: файл проверяется как текст.
#
# Выбор артефактов: SUBJECT_DIR=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT_DIR:-}" ];                    then DIR="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/Dockerfile" ];  then DIR="${SERIES_DIR}/artifacts"
elif [ -f "${SERIES_DIR}/Dockerfile" ];            then DIR="${SERIES_DIR}"
else DIR="${SERIES_DIR}/solution"
     echo "ℹ️  Своих файлов не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/Dockerfile starter/dockerignore artifacts/"; echo ""
fi
DIR="$(cd "${DIR}" && pwd)"
DF="${DIR}/Dockerfile"
DI="${DIR}/dockerignore"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e05 tests — файлы: ${DIR#"$SERIES_DIR"/}/"
echo "════════════════════════════════════════════════════════════"

miss=0
for f in "${DF}" "${DI}"; do
    if [ -f "${f}" ]; then ok "$(basename "${f}") найден"; else no "$(basename "${f}") не найден"; miss=1; fi
done
[ "${miss}" -eq 0 ] || { echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

# ---- разбор: инструкции по порядку, с учётом переносов строк ------------------
INSTR="$(sed -e 's/\r$//' "${DF}" | awk '
    /^[[:space:]]*#/ { next }
    { line=$0; sub(/[[:space:]]+$/,"",line)
      buf = (cont ? buf " " line : line)
      if (buf ~ /\\$/) { sub(/\\$/,"",buf); cont=1; next }
      cont=0
      gsub(/^[[:space:]]+/,"",buf)
      if (buf != "") print buf }')"

nth()   { printf '%s\n' "${INSTR}" | awk -v k="$1" 'toupper($1)==toupper(k){print NR; exit}'; }
first() { printf '%s\n' "${INSTR}" | awk -v k="$1" 'toupper($1)==toupper(k){print; exit}'; }
all_of(){ printf '%s\n' "${INSTR}" | awk -v k="$1" 'toupper($1)==toupper(k)'; }
line_of(){ printf '%s\n' "${INSTR}" | grep -n -- "$1" | head -1 | cut -d: -f1; }

# ---- 1. база -----------------------------------------------------------------
from="$(first FROM)"
img="$(printf '%s' "${from}" | awk '{print $2}')"
if [ -z "${img}" ]; then
    no "нет инструкции FROM"
elif printf '%s' "${img}" | grep -q ':latest$\|^[^:]*$'; then
    no "FROM ${img}: тег latest или отсутствует — сборка через месяц даст другое"
elif printf '%s' "${img}" | grep -qE '^python:3\.[0-9]+$'; then
    no "FROM ${img}: полная база на гигабайт; для сборщика достаточно slim"
elif printf '%s' "${img}" | grep -qE '(slim|alpine|distroless)'; then
    ok "FROM ${img} — облегчённая база с точной версией"
else
    no "FROM ${img}: непонятно, облегчённая ли это база"
fi
if printf '%s' "${img}" | grep -qE ':[0-9]+\.[0-9]+\.[0-9]+'; then
    ok "версия базы задана точно (patch-версия)"
else
    no "версия базы задана неточно: ${img} — обновление базы изменит сборку молча"
fi

# ---- 2. секретов внутри нет --------------------------------------------------
bad_env="$(all_of ENV | grep -iE '(PASSWORD|SECRET|TOKEN|API[_-]?KEY)' || true)"
if [ -z "${bad_env}" ]; then
    ok "ни одного ENV с секретом"
else
    no "секрет в ENV — его печатает docker inspect: $(printf '%s' "${bad_env}" | head -1)"
fi
bad_copy="$(all_of COPY; all_of ADD)"
if printf '%s\n' "${bad_copy}" | grep -qE '(deploy_key|id_rsa|id_ed25519|\.pem|\.key|\.env([[:space:]]|$))'; then
    no "в образ копируется ключ или .env: $(printf '%s\n' "${bad_copy}" | grep -E 'key|pem|env' | head -1)"
else
    ok "ключи и .env в образ не копируются"
fi
if printf '%s\n' "${INSTR}" | grep -qE '^RUN .*rm -rf /tmp/(deploy_key|.*key)'; then
    no "остался приём «скопировали и удалили»: файл всё равно в слое"
else
    ok "приёма «скопировали и удалили ключ» нет"
fi

# ---- 3. порядок инструкций ---------------------------------------------------
req_line="$(printf '%s\n' "${INSTR}" | grep -n -iE '^COPY .*requirements' | head -1 | cut -d: -f1)"
pip_line="$(printf '%s\n' "${INSTR}" | grep -n -iE '^RUN .*pip install' | head -1 | cut -d: -f1)"
code_line="$(printf '%s\n' "${INSTR}" | grep -n -E '^COPY (--[^ ]+ )*\. ' | head -1 | cut -d: -f1)"
if [ -n "${req_line}" ] && [ -n "${pip_line}" ] && [ -n "${code_line}" ]; then
    if [ "${req_line}" -lt "${pip_line}" ] && [ "${pip_line}" -lt "${code_line}" ]; then
        ok "порядок: requirements → установка → код (кеш не сбрасывается на правке кода)"
    else
        no "порядок нарушен: COPY requirements (${req_line}), pip (${pip_line}), COPY . (${code_line}) — при правке кода зависимости будут ставиться заново"
    fi
else
    no "не найдено разделение «зависимости отдельно, код отдельно»: requirements=${req_line:-нет} pip=${pip_line:-нет} 'COPY .'=${code_line:-нет}"
fi

# ---- 4. apt и pip ------------------------------------------------------------
apt_instr="$(printf '%s\n' "${INSTR}" | grep -iE '^RUN .*apt-get install' || true)"
if [ -z "${apt_instr}" ]; then
    ok "системные пакеты не ставятся — меньше поверхность"
else
    if printf '%s' "${apt_instr}" | grep -q -- '--no-install-recommends'; then
        ok "apt-get с --no-install-recommends"
    else
        no "apt-get без --no-install-recommends: приедут десятки лишних пакетов"
    fi
    if printf '%s' "${apt_instr}" | grep -q 'rm -rf /var/lib/apt/lists'; then
        ok "кеш apt удаляется в той же инструкции"
    else
        no "кеш apt не удалён в той же инструкции — отдельным RUN он останется в слое"
    fi
fi
if printf '%s\n' "${INSTR}" | grep -iE '^RUN .*pip install' | grep -q -- '--no-cache-dir'; then
    ok "pip с --no-cache-dir"
else
    no "pip без --no-cache-dir — кеш колёс останется в слое"
fi

# ---- 5. от кого работает -----------------------------------------------------
user_last="$(all_of USER | tail -1 | awk '{print $2}')"
if [ -z "${user_last}" ]; then
    no "нет инструкции USER — контейнер стартует от root"
elif [ "${user_last}" = "root" ] || [ "${user_last}" = "0" ]; then
    no "USER ${user_last}: контейнеру сборщика root не нужен"
else
    ok "USER ${user_last} — контейнер работает не от root"
fi
if printf '%s\n' "${INSTR}" | grep -qiE '^RUN .*(useradd|adduser|addgroup)'; then
    ok "непривилегированный пользователь создаётся в образе"
else
    no "пользователь USER нигде не создан — контейнер не стартует"
fi
u_line="$(printf '%s\n' "${INSTR}" | grep -n '^USER ' | tail -1 | cut -d: -f1)"
c_line="$(printf '%s\n' "${INSTR}" | grep -nE '^(CMD|ENTRYPOINT) ' | tail -1 | cut -d: -f1)"
if [ -n "${u_line}" ] && [ -n "${c_line}" ] && [ "${u_line}" -lt "${c_line}" ]; then
    ok "USER стоит до CMD"
else
    no "USER должен стоять после установки, но до CMD"
fi

# ---- 6. запуск ---------------------------------------------------------------
cmd="$(printf '%s\n' "${INSTR}" | grep -E '^(CMD|ENTRYPOINT) ' | tail -1)"
if [ -z "${cmd}" ]; then
    no "нет CMD или ENTRYPOINT"
elif printf '%s' "${cmd}" | grep -qE '^(CMD|ENTRYPOINT) *\['; then
    ok "запуск в exec-форме: $(printf '%s' "${cmd}" | cut -c1-48)"
else
    no "запуск строкой, а не массивом: процесс пойдёт под /bin/sh, и docker stop его не остановит"
fi
if [ -n "$(first WORKDIR)" ]; then ok "WORKDIR задан"; else no "WORKDIR не задан"; fi

# ---- 7. .dockerignore --------------------------------------------------------
missing_di=""
for p in '.git' '.env' '*.pem'; do
    grep -qxF -- "${p}" "${DI}" || missing_di="${missing_di} ${p}"
done
if [ -z "${missing_di}" ]; then
    ok ".dockerignore закрывает .git, .env и ключи"
else
    no "в .dockerignore не хватает:${missing_di} — они уедут в контекст сборки"
fi
if [ "$(grep -cvE '^[[:space:]]*(#|$)' "${DI}")" -ge 8 ]; then
    ok ".dockerignore заполнен ($(grep -cvE '^[[:space:]]*(#|$)' "${DI}") правил)"
else
    no ".dockerignore почти пуст — COPY . затянет внутрь всё подряд"
fi

# ---- 8. самопроверки ---------------------------------------------------------
ST="${SERIES_DIR}/starter/Dockerfile"
if [ -f "${ST}" ] && grep -qE '^ENV DB_PASSWORD' "${ST}" && grep -qE '^COPY deploy_key' "${ST}"; then
    ok "самопроверка: в стартере обе ловушки на месте (секрет в ENV и ключ в COPY)"
else
    no "самопроверка: стартер больше не содержит исходных ошибок"
fi
if [ -f "${ST}" ] && ! grep -qiE '^COPY .*requirements' "${ST}" && grep -q 'pip install' "${ST}"; then
    ok "самопроверка: в стартере зависимости не выделены отдельным слоем — ловушка на месте"
else
    no "самопроверка: ловушка с порядком инструкций исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
