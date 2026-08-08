#!/usr/bin/env bash
#
# s04e03 «Чтобы не заметить» (капстоун Episode 13) — тест конфигурации (Type B).
#
# Проверяет НЕ текст правил, а их ПОВЕДЕНИЕ: тест создаёт репозиторий во
# временном каталоге, кладёт туда файл студента как .gitignore и спрашивает
# у самого git — `git check-ignore`, — что он будет игнорировать. Так
# проверяется именно то, что произойдёт на практике, включая порядок правил
# и отмену через «!».
#
# Второй артефакт — .env.example — проверяется на состав ключей и на то,
# что в нём не осталось настоящих значений.
#
# Без root, без сети. Нужен `git`.
#
# Выбор артефактов: SUBJECT_DIR=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT_DIR:-}" ];                    then DIR="${SUBJECT_DIR}"
elif [ -f "${SERIES_DIR}/artifacts/gitignore" ];   then DIR="${SERIES_DIR}/artifacts"
elif [ -f "${SERIES_DIR}/gitignore" ];             then DIR="${SERIES_DIR}"
else DIR="${SERIES_DIR}/solution"
     echo "ℹ️  Своих файлов не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/gitignore starter/env.example artifacts/"; echo ""
fi
DIR="$(cd "${DIR}" && pwd)"
GI="${DIR}/gitignore"
EX="${DIR}/env.example"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e03 tests — файлы: ${DIR#"$SERIES_DIR"/}/"
echo "════════════════════════════════════════════════════════════"

command -v git >/dev/null 2>&1 || { echo "  SKIP: git не установлен"; exit 0; }
miss=0
for f in "${GI}" "${EX}"; do
    if [ -f "${f}" ]; then ok "$(basename "${f}") найден"; else no "$(basename "${f}") не найден"; miss=1; fi
done
[ "${miss}" -eq 0 ] || { echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
R="${TMP}/repo"; mkdir -p "${R}"
( cd "${R}" && git init -q && git config user.name t && git config user.email t@t )
cp "${GI}" "${R}/.gitignore"

# создать пути, ничего не коммитя
mk() { mkdir -p "${R}/$(dirname "$1")"; printf 'x\n' > "${R}/$1"; }
IGNORE_PATHS="
.env
.env.local
secrets/db.key
keys/id_ed25519
deploy.pem
ansible/vault_pass.txt
terraform.tfstate
.terraform/plugin.so
logs/run.log
deep/nested/debug.log
node_modules/pkg/index.js
__pycache__/mod.pyc
.DS_Store
tmp/scratch.txt
"
KEEP_PATHS="
.env.example
README.md
deploy.sh
roles/common/tasks/main.yml
hosts/servers.txt
docs/keys.md
docs/secrets-policy.md
"
for p in ${IGNORE_PATHS} ${KEEP_PATHS}; do mk "${p}"; done

ignored() { git -C "${R}" check-ignore -q -- "$1"; }

# ---- 1. синтаксис ------------------------------------------------------------
bad="$(grep -nE '^[[:space:]]+[^[:space:]#]' "${GI}" || true)"
if [ -z "${bad}" ]; then
    ok "синтаксис: нет строк с ведущими пробелами (они значимы для git)"
else
    no "строка с ведущим пробелом — git воспримет его как часть шаблона: $(printf '%s' "${bad}" | head -1)"
fi
if grep -qE '^\*$|^/\*$|^/$' "${GI}"; then
    no "правило, игнорирующее всё подряд: новый файл молча не попадёт в репозиторий"
else
    ok "правила «игнорировать всё» нет"
fi

# ---- 2. что должно игнорироваться --------------------------------------------
missed=""
for p in ${IGNORE_PATHS}; do ignored "${p}" || missed="${missed} ${p}"; done
if [ -z "${missed}" ]; then
    ok "игнорируется всё, что должно: секреты, ключи, состояние, мусор ($(printf '%s' "${IGNORE_PATHS}" | grep -c .) путей)"
else
    no "НЕ игнорируется:${missed}"
fi

# по группам — чтобы отказ был диагностируемым
for grp in "секреты:.env .env.local secrets/db.key" \
           "ключи:keys/id_ed25519 deploy.pem ansible/vault_pass.txt" \
           "состояние:terraform.tfstate .terraform/plugin.so" \
           "журналы на любой глубине:logs/run.log deep/nested/debug.log" \
           "мусор:node_modules/pkg/index.js __pycache__/mod.pyc .DS_Store tmp/scratch.txt"; do
    name="${grp%%:*}"; paths="${grp#*:}"; bad2=""
    for p in ${paths}; do ignored "${p}" || bad2="${bad2} ${p}"; done
    [ -z "${bad2}" ] && ok "игнорируются: ${name}" || no "${name}: не игнорируется${bad2}"
done

# ---- 3. что игнорироваться НЕ должно -----------------------------------------
overreach=""
for p in ${KEEP_PATHS}; do ignored "${p}" && overreach="${overreach} ${p}"; done
if [ -z "${overreach}" ]; then
    ok "нужные файлы не игнорируются, включая .env.example и docs/keys.md"
else
    no "правило слишком широкое, из репозитория выпадет:${overreach}"
fi

if ignored .env && ! ignored .env.example; then
    ok ".env игнорируется, а .env.example — нет: отмена через «!» стоит после шаблона"
else
    no "пара «.env игнорируем, .env.example оставляем» не работает — проверьте порядок правил"
fi

for p in docs/keys.md docs/secrets-policy.md; do
    if ignored "${p}"; then
        no "${p} игнорируется: шаблон вида *key* или *secret* выбрасывает документацию"
    else
        ok "${p} остаётся в репозитории"
    fi
done

# ---- 4. .env.example ---------------------------------------------------------
keys_ex="$(grep -oE '^[A-Z_]+=' "${EX}" | tr -d '=' | sort)"
n_keys="$(printf '%s\n' "${keys_ex}" | grep -c . || true)"
if [ "${n_keys}" -ge 4 ]; then
    ok "в примере ${n_keys} переменные: $(printf '%s' "${keys_ex}" | tr '\n' ' ')"
else
    no "в примере ${n_keys} переменных — состав неполон"
fi

filled="$(grep -E '^[A-Z_]+=.+' "${EX}" || true)"
if [ -z "${filled}" ]; then
    ok "в примере нет ни одного заполненного значения"
else
    no "в примере осталось настоящее значение: $(printf '%s' "${filled}" | head -1)"
fi

if grep -qiE 'password[[:space:]]*=[[:space:]]*.+|ghp_[A-Za-z0-9]{20,}' "${EX}"; then
    no "в примере остался пароль или токен"
else
    ok "пароля и токена в примере нет"
fi

# ---- 5. пример не выпадает из репозитория ------------------------------------
( cd "${R}" && git add -A >/dev/null 2>&1 )
if git -C "${R}" ls-files --error-unmatch .env.example >/dev/null 2>&1; then
    ok "после git add пример действительно попал в индекс"
else
    no "после git add примера в индексе нет — он всё-таки игнорируется"
fi
if git -C "${R}" ls-files --error-unmatch .env >/dev/null 2>&1; then
    no "после git add в индекс попал .env"
else
    ok "после git add .env в индекс не попал"
fi

# ---- 6. самопроверки ---------------------------------------------------------
ST="${SERIES_DIR}/starter/gitignore"
if [ -f "${ST}" ] && [ "$(grep -cvE '^[[:space:]]*(#|$)' "${ST}")" -le 2 ]; then
    ok "самопроверка: в стартере почти нет правил — чинить есть что"
else
    no "самопроверка: стартер перестал быть пустым, задание выродилось"
fi
STE="${SERIES_DIR}/starter/env.example"
if [ -f "${STE}" ] && grep -qE '^[A-Z_]+=.+' "${STE}"; then
    ok "самопроверка: в стартовом примере остались настоящие значения"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
