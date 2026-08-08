#!/usr/bin/env bash
#
# s04e11 «Кто проверял описание» (финал Season 4) — тест скрипта (Type A).
#
# Полигон собирается из эталонов и стартеров всего сезона: «чистый»
# репозиторий — это s04e03, s04e05, s04e06, s04e07 и s04e09 в их правильном
# виде, «грязный» — те же файлы в исходном. Ни одного ожидаемого числа
# в тесте не зашито: находки берутся из того, что реально лежит в полигоне.
#
# Отдельно проверяется свойство, ради которого эта серия стоит последней:
# аудит, которому нечего было смотреть, обязан отличаться от аудита,
# который ничего не нашёл.
#
# Без root, без сети, без docker и без ansible.
#
# Выбор скрипта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEASON="$(cd "${SERIES_DIR}/.." && pwd)"
STARTER="${SERIES_DIR}/starter/iac_audit.sh"

if   [ -n "${SUBJECT:-}" ];                          then AU="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/iac_audit.sh" ];  then AU="${SERIES_DIR}/artifacts/iac_audit.sh"
elif [ -f "${SERIES_DIR}/iac_audit.sh" ];            then AU="${SERIES_DIR}/iac_audit.sh"
else AU="${SERIES_DIR}/solution/iac_audit.sh"
     echo "ℹ️  Своего iac_audit.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/iac_audit.sh artifacts/"; echo ""
fi
[ -f "${AU}" ] || { echo "  FAIL: iac_audit.sh не найден"; exit 1; }
AU="$(cd "$(dirname "${AU}")" && pwd)/$(basename "${AU}")"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e11 tests — скрипт: ${AU#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
BIN="${TMP}/bin"; mkdir -p "${BIN}"
export CALLS="${TMP}/calls.log"; : > "${CALLS}"
for t in docker ansible ansible-playbook curl; do
    cat > "${BIN}/${t}" <<EOF
#!/usr/bin/env bash
printf '${t} %s\n' "\$*" >> "\${CALLS}"
exit 0
EOF
done
chmod +x "${BIN}"/*
PATH="${BIN}:${PATH}"; export PATH

export GIT_AUTHOR_NAME=ops GIT_AUTHOR_EMAIL=ops@shadow.io
export GIT_COMMITTER_NAME=ops GIT_COMMITTER_EMAIL=ops@shadow.io
export GIT_AUTHOR_DATE='2025-10-31T10:00:00+0000'
export GIT_COMMITTER_DATE='2025-10-31T10:00:00+0000'

gi() { git -C "$1" -c commit.gpgsign=false -c user.name=ops -c user.email=ops@shadow.io "${@:2}"; }
mkrepo() { mkdir -p "$1"; git init -q "$1"; git -C "$1" symbolic-ref HEAD refs/heads/main; }
commit() { gi "$1" add -A; gi "$1" commit -q -m "${2:-снимок}"; }

# ---- полигон: репозиторий из артефактов сезона ---------------------------------
build() {  # build <каталог> <solution|starter>
    local d="$1" v="$2"
    mkrepo "${d}"
    mkdir -p "${d}/.github/workflows" "${d}/ansible"
    cp "${SEASON}/s04e03-gitignore-secrets/${v}/gitignore"    "${d}/.gitignore"
    cp "${SEASON}/s04e03-gitignore-secrets/${v}/env.example"  "${d}/.env.example"
    cp "${SEASON}/s04e05-dockerfile/${v}/Dockerfile"          "${d}/Dockerfile"
    cp "${SEASON}/s04e05-dockerfile/${v}/dockerignore"        "${d}/.dockerignore"
    cp "${SEASON}/s04e06-compose/${v}/compose.yaml"           "${d}/compose.yaml"
    cp "${SEASON}/s04e07-ci-pipeline/${v}/ci.yml"             "${d}/.github/workflows/ci.yml"
    cp "${SEASON}/s04e09-ansible-inventory/${v}/inventory.yml" "${d}/ansible/inventory.yml"
    commit "${d}" "инфраструктура операции"
}

OUT=""; RC=0
run() { : > "${CALLS}"; OUT="$(bash "${AU}" "$@" 2>&1)"; RC=$?; }
sect() { printf '%s\n' "${OUT}" | grep -c "^\[.*\] *$1 " || true; }

# ---- 0. статика ----------------------------------------------------------------
if bash -n "${AU}" 2>/dev/null; then ok "синтаксис скрипта корректен"
else no "синтаксис: $(bash -n "${AU}" 2>&1 | head -1)"; fi
if grep -qE '^set -[a-z]*e[a-z]*u|^set -euo' "${AU}"; then ok "включены строгие режимы оболочки"
else no "нет 'set -euo pipefail'"; fi

# ---- 1. чистый репозиторий ------------------------------------------------------
CLEAN="${TMP}/clean"; build "${CLEAN}" solution
run --repo "${CLEAN}"
if [ "${RC}" -eq 0 ]; then
    ok "репозиторий из эталонов сезона проходит аудит (код 0)"
else
    no "аудит нашёл проблемы в правильных артефактах сезона (код ${RC}): $(printf '%s\n' "${OUT}" | grep '^\[' | head -2)"
fi
if printf '%s\n' "${OUT}" | grep -qE 'находок: *0'; then ok "в чистом репозитории находок нет"
else no "нет строки «находок: 0»"; fi
n_files="$(gi "${CLEAN}" ls-files | grep -c . || true)"
if printf '%s\n' "${OUT}" | grep -q "${n_files}"; then
    ok "отчёт называет, сколько файлов проверено (${n_files})"
else
    no "отчёт не говорит, какой объём был проверен: «чисто» без числа ничем не подтверждено"
fi

before="$(gi "${CLEAN}" status --porcelain; find "${CLEAN}" -type f | sort | wc -l)"
run --repo "${CLEAN}"
after="$(gi "${CLEAN}" status --porcelain; find "${CLEAN}" -type f | sort | wc -l)"
if [ "${before}" = "${after}" ]; then ok "аудит ничего не изменяет в репозитории"
else no "после аудита репозиторий изменился"; fi
if [ ! -s "${CALLS}" ]; then ok "docker и ansible не запускаются: проверяется описание, а не машины"
else no "скрипт вызвал: $(head -1 "${CALLS}")"; fi

# ---- 2. грязный репозиторий ------------------------------------------------------
DIRTY="${TMP}/dirty"; build "${DIRTY}" starter
run --repo "${DIRTY}"
if [ "${RC}" -eq 1 ]; then ok "репозиторий из стартеров аудит не проходит (код 1)"
else no "аудит не нашёл проблем в исходных артефактах (код ${RC})"; fi

for s in secrets gitignore docker compose ci ansible; do
    if [ "$(sect "${s}")" -ge 1 ]; then
        ok "раздел ${s}: $(sect "${s}") находок"
    else
        no "раздел ${s}: ни одной находки, хотя в стартерах они есть"
    fi
done
if printf '%s\n' "${OUT}" | grep -q 'ВЫСОКАЯ'; then ok "находки разделены по важности"
else no "важность находок не указана: пароль и отсутствие permissions — не одно и то же"; fi
if printf '%s\n' "${OUT}" | grep -q 'Dockerfile'; then ok "отчёт называет путь находки"
else no "в отчёте нет путей: находку негде исправлять"; fi

# ---- 3. пустой репозиторий -------------------------------------------------------
EMPTY="${TMP}/empty"; mkrepo "${EMPTY}"
run --repo "${EMPTY}"
if [ "${RC}" -eq 2 ]; then
    ok "пустой репозиторий: код 2 — проверять было нечего, а не «чисто»"
else
    no "пустой репозиторий дал код ${RC}: «находок нет» и «искать было негде» стали неразличимы"
fi

# ---- 4. секрет только в истории ---------------------------------------------------
HIST="${TMP}/hist"; build "${HIST}" solution
printf 'DB_PASSWORD=Sh4dow-Pr0d-2025!\n' > "${HIST}/.env"
gi "${HIST}" add -f .env >/dev/null 2>&1
gi "${HIST}" commit -q -m "временно, потом уберу"
gi "${HIST}" rm -q --cached .env >/dev/null 2>&1
rm -f "${HIST}/.env"
gi "${HIST}" commit -q -m "убрал секрет"
run --repo "${HIST}"
if [ "${RC}" -ne 0 ] && [ "$(sect history)" -ge 1 ]; then
    ok "секрет найден в истории, хотя рабочее дерево чистое"
else
    no "файл .env был закоммичен и удалён — аудит этого не заметил (код ${RC})"
fi

# ---- 5. ключ с открытыми правами ---------------------------------------------------
PERM="${TMP}/perm"; build "${PERM}" solution
mkdir -p "${PERM}/certs"
printf 'заглушка\n' > "${PERM}/certs/service.pem"
chmod 644 "${PERM}/certs/service.pem"
gi "${PERM}" add -f certs/service.pem >/dev/null 2>&1
gi "${PERM}" commit -q -m "сертификат службы"
run --repo "${PERM}"
if [ "$(sect perms)" -ge 1 ]; then ok "закрытый ключ с правами 644 замечен"
else no "ключ доступен на чтение всем, аудит молчит"; fi

# ---- 6. пароль vault в репозитории --------------------------------------------------
VAULT="${TMP}/vault"; build "${VAULT}" solution
printf 'Sh4dow-Vault-2025\n' > "${VAULT}/ansible/vault_pass.txt"
gi "${VAULT}" add -f ansible/vault_pass.txt >/dev/null 2>&1
gi "${VAULT}" commit -q -m "чтобы не вводить руками"
run --repo "${VAULT}"
if [ "${RC}" -ne 0 ] && [ "$(sect ansible)" -ge 1 ]; then
    ok "пароль vault в репозитории замечен: шифровать после этого нечего"
else
    no "vault_pass.txt лежит в репозитории, аудит молчит"
fi

# ---- 7. пример конфигурации — не находка ---------------------------------------------
run --repo "${CLEAN}"
if ! printf '%s\n' "${OUT}" | grep -q 'env.example'; then
    ok ".env.example находкой не считается — иначе аудит перестанут читать"
else
    no "ложное срабатывание на .env.example"
fi

# ---- 8. ничего не зашито: другие пути ------------------------------------------------
OTHER="${TMP}/other"; mkrepo "${OTHER}"
mkdir -p "${OTHER}/build" "${OTHER}/deploy" "${OTHER}/.github/workflows" "${OTHER}/infra"
cp "${SEASON}/s04e05-dockerfile/starter/Dockerfile"           "${OTHER}/build/Dockerfile"
cp "${SEASON}/s04e06-compose/starter/compose.yaml"            "${OTHER}/deploy/compose.yml"
cp "${SEASON}/s04e07-ci-pipeline/starter/ci.yml"              "${OTHER}/.github/workflows/pipeline.yml"
cp "${SEASON}/s04e09-ansible-inventory/starter/inventory.yml" "${OTHER}/infra/inventory.yml"
commit "${OTHER}" "другая раскладка"
run --repo "${OTHER}"
if [ "${RC}" -eq 1 ] \
   && [ "$(sect docker)" -ge 1 ] && [ "$(sect compose)" -ge 1 ] \
   && [ "$(sect ci)" -ge 1 ] && [ "$(sect ansible)" -ge 1 ]; then
    ok "файлы находятся по имени, а не по зашитому пути (build/, deploy/, infra/)"
else
    no "при другой раскладке каталогов аудит потерял файлы (код ${RC})"
fi

# ---- 9. --quiet -----------------------------------------------------------------------
run --repo "${DIRTY}" --quiet
if [ "${RC}" -eq 1 ] && printf '%s\n' "${OUT}" | grep -q 'находок:' \
   && ! printf '%s\n' "${OUT}" | grep -q '^--- проверено'; then
    ok "--quiet оставляет находки и итог, убирая остальное"
else
    no "--quiet работает не так: нужен тот же результат без пояснительной части"
fi

# ---- 10. самопроверка -------------------------------------------------------------------
if [ -f "${STARTER}" ] && [ "${AU}" != "${STARTER}" ]; then
    o="$(bash "${STARTER}" --repo "${DIRTY}" 2>&1)"; rc=$?
    if [ "${rc}" -eq 0 ] && ! printf '%s\n' "${o}" | grep -q '^\['; then
        ok "самопроверка: стартер задачу не решает — проверять есть что"
    else
        no "самопроверка: стартер уже находит проблемы"
    fi
else
    ok "самопроверка: пропущена (проверяется сам стартер)"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
