#!/usr/bin/env bash
#
# iac_audit.sh — аудит репозитория инфраструктуры (ЭТАЛОН)
#
# Проверяет не машины, а описание, из которого машины собираются: секреты
# в файлах и в истории, образ и стек, конвейер, инвентарь, права на ключи.
#
# Ничего не изменяет. Работает без сети, без docker и без ansible: всё,
# что нужно, есть в самом репозитории.
#
# Использование:
#   ./iac_audit.sh --repo /путь [--quiet]
#
# Коды возврата:
#   0 — находок нет, и при этом было что проверять
#   1 — есть находки
#   2 — ошибка вызова или проверять оказалось нечего

set -euo pipefail

REPO="."; QUIET=0

while [ $# -gt 0 ]; do
    case "$1" in
        --repo)  REPO="${2:-}"; shift 2 ;;
        --quiet) QUIET=1;       shift   ;;
        -h|--help) echo "использование: $0 --repo ПУТЬ [--quiet]" >&2; exit 2 ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

command -v git >/dev/null 2>&1 || { echo "нужен git" >&2; exit 2; }
g() { git -C "${REPO}" "$@"; }
g rev-parse --git-dir >/dev/null 2>&1 || { echo "не репозиторий: ${REPO}" >&2; exit 2; }

FOUND=0; HIGH=0
say()  { [ "${QUIET}" -eq 1 ] || printf '%s\n' "$*"; }
note() {  # note <важность> <раздел> <где> <что>
    printf '[%-8s] %-9s %-34s %s\n' "$1" "$2" "$3" "$4"
    FOUND=$((FOUND+1))
    [ "$1" = "ВЫСОКАЯ" ] && HIGH=$((HIGH+1)) || true
}

# ---- что вообще проверяем ------------------------------------------------------
# Аудит смотрит на то, что отслеживает git: именно это уедет к другим людям.
FILES="$(g ls-files)"
N_FILES="$(printf '%s\n' "${FILES}" | grep -c . || true)"

pick() { printf '%s\n' "${FILES}" | grep -E "$1" || true; }

DOCKERFILES="$(pick '(^|/)Dockerfile$')"
COMPOSES="$(pick '(^|/)(compose|docker-compose)\.ya?ml$')"
WORKFLOWS="$(pick '^\.github/workflows/.*\.ya?ml$')"
INVENTORIES="$(pick '(^|/)inventory\.(ya?ml|ini)$')"
EXAMPLES="$(pick '\.(example|sample|dist)$')"

cnt() { printf '%s\n' "$1" | grep -c . || true; }

say "═══ аудит описания инфраструктуры: ${REPO} ═══"
say ""

# ---- 1. секреты в отслеживаемых файлах -----------------------------------------
SECRET_RE='(PASSWORD|PASSWD|SECRET|API[_-]?TOKEN|ACCESS[_-]?KEY)[[:space:]]*[=:][[:space:]]*[^[:space:]"'"'"'$]{6,}|BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}'

for f in ${FILES}; do
    # файлы-образцы пропускаются намеренно: в них значений быть не должно,
    # и об этом сказано в итоге
    case "${f}" in *.example|*.sample|*.dist) continue ;; esac
    [ -f "${REPO}/${f}" ] || continue
    grep -Iq . "${REPO}/${f}" 2>/dev/null || continue      # пропустить двоичные
    hit="$(grep -nEm1 "${SECRET_RE}" "${REPO}/${f}" 2>/dev/null || true)"
    [ -n "${hit}" ] || continue
    note ВЫСОКАЯ secrets "${f}:${hit%%:*}" "значение похоже на секрет в открытом виде"
done

# ---- 2. секреты в истории ------------------------------------------------------
# Удалить файл из рабочего дерева и добавить его в .gitignore — не то же самое,
# что убрать его из репозитория: история остаётся у всех, кто клонировал.
FORBIDDEN='(^|/)(\.env|\.env\.[^/]+|id_rsa|id_ed25519|[^/]+\.pem|[^/]+\.key|[^/]+\.p12|vault_pass\.txt)$'
LEAKED="$(g log --all --pretty=format: --name-only 2>/dev/null \
          | grep -E "${FORBIDDEN}" | grep -vE '\.(example|sample|dist)$' | sort -u || true)"
for p in ${LEAKED}; do
    c="$(g log --all --oneline -1 -- "${p}" 2>/dev/null | awk '{print $1}')"
    note ВЫСОКАЯ history "${p}" "файл был в истории (коммит ${c}): утечка не отменяется удалением"
done

# ---- 3. .gitignore -------------------------------------------------------------
if [ -f "${REPO}/.gitignore" ]; then
    for p in .env id_rsa secret.pem private.key; do
        g check-ignore -q "${p}" 2>/dev/null \
            || note СРЕДНЯЯ gitignore ".gitignore" "не закрывает ${p}"
    done
    g check-ignore -q ".env.example" 2>/dev/null \
        && note СРЕДНЯЯ gitignore ".gitignore" "закрывает .env.example: пример конфигурации нужен всем"
else
    note ВЫСОКАЯ gitignore "(нет файла)" ".gitignore отсутствует: секрет попадёт в репозиторий первым же add"
fi

# Дальше файлы читаются без комментариев: строка «privileged: true» в пояснении
# к правильному файлу — не находка. Строки не удаляются, а очищаются, чтобы
# номера строк в отчёте остались настоящими.
WORK="$(mktemp -d)"; trap 'rm -rf "${WORK}"' EXIT
strip() {
    sed -e 's/^[[:space:]]*#.*$//' -e 's/[[:space:]]#[^"'"'"']*$//' "$1" > "${WORK}/f"
    printf '%s' "${WORK}/f"
}

# ---- 4. образ ------------------------------------------------------------------
for f in ${DOCKERFILES}; do
    p="$(strip "${REPO}/${f}")"
    from="$(grep -im1 '^[[:space:]]*FROM ' "${p}" | awk '{print $2}' || true)"
    case "${from}" in
        *:latest|"") note СРЕДНЯЯ docker "${f}" "база без точной версии (${from:-нет FROM})" ;;
        *:*) : ;;
        *)   note СРЕДНЯЯ docker "${f}" "база без тега: ${from}" ;;
    esac
    u="$(grep -i '^[[:space:]]*USER ' "${p}" | tail -1 | awk '{print $2}' || true)"
    if [ -z "${u}" ] || [ "${u}" = "root" ] || [ "${u}" = "0" ]; then
        note ВЫСОКАЯ docker "${f}" "контейнер работает от root (USER ${u:-не задан})"
    fi
    grep -qiE '^[[:space:]]*(COPY|ADD) .*(deploy_key|id_rsa|id_ed25519|\.pem|\.key)' "${p}" \
        && note ВЫСОКАЯ docker "${f}" "ключ копируется в образ: он останется в слое"
done

# ---- 5. стек -------------------------------------------------------------------
for f in ${COMPOSES}; do
    p="$(strip "${REPO}/${f}")"
    grep -qE '^[[:space:]]+privileged:[[:space:]]*true' "${p}" \
        && note ВЫСОКАЯ compose "${f}" "privileged: true отключает изоляцию"
    grep -q 'docker\.sock' "${p}" \
        && note ВЫСОКАЯ compose "${f}" "монтирование docker.sock равносильно выдаче root на хосте"
    hit="$(grep -nEm1 '^[[:space:]]*-[[:space:]]*"?[0-9]+:[0-9]+"?' "${p}" || true)"
    [ -n "${hit}" ] && note СРЕДНЯЯ compose "${f}:${hit%%:*}" "порт опубликован на всех интерфейсах хоста"
    grep -qE '^[[:space:]]+image:.*:latest' "${p}" \
        && note СРЕДНЯЯ compose "${f}" "образ с тегом latest: завтра поднимется другое"
done

# ---- 6. конвейер ---------------------------------------------------------------
for f in ${WORKFLOWS}; do
    p="$(strip "${REPO}/${f}")"
    while read -r u; do
        [ -n "${u}" ] || continue
        case "${u}" in ./*|docker://*) continue ;; esac
        ref="${u##*@}"
        if [ "${ref}" = "${u}" ] || ! printf '%s' "${ref}" \
             | grep -qE '^[0-9a-f]{40}$|^v[0-9]+\.[0-9]+\.[0-9]+$'; then
            note СРЕДНЯЯ ci "${f}" "версия действия не закреплена: ${u}"
        fi
    done <<EOF
$(awk '/^[[:space:]]*-?[[:space:]]*uses:/ {sub(/^.*uses:[[:space:]]*/, ""); sub(/[[:space:]]+#.*$/, ""); print}' "${p}")
EOF
    grep -qE 'continue-on-error:[[:space:]]*true' "${p}" \
        && note ВЫСОКАЯ ci "${f}" "continue-on-error: true — шаг падает, а прогон зеленеет"
    hit="$(grep -nEm1 '\|\|[[:space:]]*(true|:)[[:space:]]*$' "${p}" || true)"
    [ -n "${hit}" ] && note ВЫСОКАЯ ci "${f}:${hit%%:*}" "код возврата проглочен: проверка не может провалиться"
    grep -qE '^permissions:' "${p}" \
        || note СРЕДНЯЯ ci "${f}" "права токена не заданы: по умолчанию он умеет писать в репозиторий"
done

# ---- 7. инвентарь и vault -------------------------------------------------------
for f in ${INVENTORIES}; do
    p="$(strip "${REPO}/${f}")"
    grep -qiE '(ansible_(password|ssh_pass|become_pass)):' "${p}" \
        && note ВЫСОКАЯ ansible "${f}" "пароль подключения лежит в инвентаре"
    grep -qE 'ansible_user:[[:space:]]*root' "${p}" \
        && note СРЕДНЯЯ ansible "${f}" "подключение от root: права повышают по месту, а не на входе"
    grep -q 'StrictHostKeyChecking=no' "${p}" \
        && note ВЫСОКАЯ ansible "${f}" "проверка ключа хоста отключена: подмена сервера станет незаметной"
done
for f in ${FILES}; do
    case "${f}" in
        *vault_pass*|*.vault_pass|*vault-password*)
            note ВЫСОКАЯ ansible "${f}" "пароль vault отслеживается git: шифровать после этого нечего" ;;
    esac
done

# ---- 8. права на ключи ----------------------------------------------------------
for f in ${FILES}; do
    case "${f}" in
        *.pem|*.key|*/id_rsa|*/id_ed25519|id_rsa|id_ed25519) ;;
        *) continue ;;
    esac
    [ -f "${REPO}/${f}" ] || continue
    m="$(ls -l "${REPO}/${f}" | cut -c1-10)"
    case "${m}" in
        ????------) : ;;
        *) note СРЕДНЯЯ perms "${f}" "права ${m}: закрытый ключ читается не только владельцем" ;;
    esac
done

# ---- итог -----------------------------------------------------------------------
say ""
say "--- проверено ---"
say "отслеживаемых файлов: ${N_FILES}"
say "Dockerfile: $(cnt "${DOCKERFILES}"), compose: $(cnt "${COMPOSES}"), конвейеров: $(cnt "${WORKFLOWS}"), инвентарей: $(cnt "${INVENTORIES}")"
say "пропущено файлов-образцов: $(cnt "${EXAMPLES}")"
say "коммитов в истории: $(g rev-list --all --count 2>/dev/null || echo 0)"
say ""

# Аудит, которому нечего было смотреть, обязан сказать это вслух:
# «находок нет» и «искать было негде» снаружи выглядят одинаково.
if [ "${N_FILES}" -eq 0 ]; then
    echo "ПРОВЕРЯТЬ НЕЧЕГО: git не отслеживает ни одного файла" >&2
    exit 2
fi

echo "находок: ${FOUND} (высокой важности: ${HIGH})"
[ "${FOUND}" -eq 0 ] || exit 1
exit 0
