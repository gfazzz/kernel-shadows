#!/usr/bin/env bash
#
# build_shadow_iac.sh — восстановить учебный репозиторий инфраструктуры
#
# Создаёт `shadow_iac` в указанном каталоге: двенадцать коммитов, две ветки,
# одно слияние и один инцидент. Даты, авторы и порядок зафиксированы, поэтому
# репозиторий получается ПОБИТОВО ОДИНАКОВЫМ при каждом запуске — включая
# хеши коммитов. Это позволяет задавать по нему вопросы с точными ответами.
#
# Использование:
#   bash build_shadow_iac.sh /tmp/shadow_iac
#
# Ничего не скачивает и никуда не ходит: всё содержимое здесь же, ниже.

set -euo pipefail

DEST="${1:-}"
[ -n "${DEST}" ] || { echo "укажите каталог: bash $0 /tmp/shadow_iac" >&2; exit 2; }
[ -e "${DEST}" ] && { echo "каталог уже существует: ${DEST}" >&2; exit 1; }

command -v git >/dev/null 2>&1 || { echo "нужен git" >&2; exit 1; }

mkdir -p "${DEST}"
cd "${DEST}"

git init -q --object-format=sha1 2>/dev/null || git init -q
git symbolic-ref HEAD refs/heads/main
git config user.name  "build"
git config user.email "build@ops.local"
git config commit.gpgsign false
git config core.autocrlf false

# c <дата> <автор> <email> <сообщение>
c() {
    local d="$1" an="$2" ae="$3" msg="$4"
    GIT_AUTHOR_NAME="${an}"    GIT_AUTHOR_EMAIL="${ae}"    GIT_AUTHOR_DATE="${d}" \
    GIT_COMMITTER_NAME="${an}" GIT_COMMITTER_EMAIL="${ae}" GIT_COMMITTER_DATE="${d}" \
    git commit -q -m "${msg}"
}

D="2025-10-25T09:00:00+0200"
MAX="Max Sokolov";  MAXE="max@ops.local"
DMI="Dmitry Orlov"; DMIE="dmitry@ops.local"
HAN="Hans Müller";  HANE="hans@ccc.de"

# ── 1 ──────────────────────────────────────────────────────────────────────
cat > README.md <<'EOF'
# shadow_iac

Инфраструктура операции как код.
EOF
git add README.md
c "2025-10-25T09:00:00+0200" "${DMI}" "${DMIE}" "первый коммит: README"

# ── 2 ──────────────────────────────────────────────────────────────────────
mkdir -p hosts
cat > hosts/servers.txt <<'EOF'
shadow-server-01 10.50.1.100
shadow-server-02 10.50.1.101
shadow-db-01     10.50.1.102
EOF
git add hosts/servers.txt
c "2025-10-25T10:14:00+0200" "${DMI}" "${DMIE}" "список серверов операции"

# ── 3 ──────────────────────────────────────────────────────────────────────
cat > deploy.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "выкат начат"
EOF
git add deploy.sh
c "2025-10-25T11:02:00+0200" "${MAX}" "${MAXE}" "скрипт выката, заготовка"

# ── 4 ── ИНЦИДЕНТ: пароль попадает в репозиторий ───────────────────────────
cat > .env <<'EOF'
DB_HOST=10.50.1.102
DB_USER=ops
DB_PASSWORD=Sh4dow-Pr0d-2025!
API_TOKEN=ghp_R7kQ2mNvX9pL4wZ8sT1uY6eA3bC5dF0gH
EOF
git add .env
c "2025-10-25T11:41:00+0200" "${MAX}" "${MAXE}" "переменные окружения для выката"

# ── 5 ──────────────────────────────────────────────────────────────────────
cat >> deploy.sh <<'EOF'
source .env
echo "подключаюсь к ${DB_HOST}"
EOF
git add deploy.sh
c "2025-10-25T12:20:00+0200" "${MAX}" "${MAXE}" "выкат читает переменные"

# ── 6 ── ветка Дмитрия ─────────────────────────────────────────────────────
git branch -q monitoring
git checkout -q monitoring
mkdir -p monitoring
cat > monitoring/check.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
for h in $(awk '{print $2}' hosts/servers.txt); do
    printf '%s\n' "${h}"
done
EOF
git add monitoring/check.sh
c "2025-10-25T14:05:00+0200" "${DMI}" "${DMIE}" "мониторинг: обход списка хостов"

cat >> monitoring/check.sh <<'EOF'
# TODO: добавить проверку доступности
EOF
git add monitoring/check.sh
c "2025-10-25T14:47:00+0200" "${DMI}" "${DMIE}" "мониторинг: заметка на будущее"

# ── 7 ── main продолжается параллельно ─────────────────────────────────────
git checkout -q main
cat > hosts/groups.txt <<'EOF'
web:  shadow-server-01 shadow-server-02
db:   shadow-db-01
EOF
git add hosts/groups.txt
c "2025-10-25T15:30:00+0200" "${MAX}" "${MAXE}" "группы хостов"

# ── 8 ── Hans замечает пароль ──────────────────────────────────────────────
git rm -q --cached .env
rm -f .env
cat > .env.example <<'EOF'
DB_HOST=
DB_USER=
DB_PASSWORD=
API_TOKEN=
EOF
git add .env.example
c "2025-10-26T09:12:00+0200" "${HAN}" "${HANE}" "убрать .env из репозитория, добавить пример"

# ── 9 ── слияние ветки ─────────────────────────────────────────────────────
GIT_AUTHOR_NAME="${MAX}" GIT_AUTHOR_EMAIL="${MAXE}" GIT_AUTHOR_DATE="2025-10-26T10:40:00+0200" \
GIT_COMMITTER_NAME="${MAX}" GIT_COMMITTER_EMAIL="${MAXE}" GIT_COMMITTER_DATE="2025-10-26T10:40:00+0200" \
git merge -q --no-ff -m "слияние ветки monitoring" monitoring

# ── 10 ─────────────────────────────────────────────────────────────────────
cat >> deploy.sh <<'EOF'
echo "выкат завершён"
EOF
git add deploy.sh
c "2025-10-26T11:15:00+0200" "${MAX}" "${MAXE}" "выкат: сообщение о завершении"

# ── 11 ── большой коммит: перенос конфигураций ─────────────────────────────
mkdir -p roles/common/tasks roles/web/tasks
for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
    printf -- "- name: шаг %02d\n  ansible.builtin.debug:\n    msg: заготовка\n" "${i}" >> roles/common/tasks/main.yml
done
for i in 1 2 3 4 5 6 7 8; do
    printf -- "- name: web-шаг %02d\n  ansible.builtin.debug:\n    msg: заготовка\n" "${i}" >> roles/web/tasks/main.yml
done
git add roles
c "2025-10-26T16:03:00+0200" "${DMI}" "${DMIE}" "перенос ролей из старого репозитория"

# ── 12 ─────────────────────────────────────────────────────────────────────
cat > .gitignore <<'EOF'
*.log
EOF
git add .gitignore
c "2025-10-26T17:28:00+0200" "${HAN}" "${HANE}" "не хранить журналы"

git checkout -q main
echo "готово: ${DEST}"
