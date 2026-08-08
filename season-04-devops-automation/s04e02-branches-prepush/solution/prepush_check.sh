#!/usr/bin/env bash
#
# prepush_check.sh — что проверить до `git push` (ЭТАЛОН)
#
# Смотрит на коммиты, которые уйдут (то, чего нет в базовой ветке), и
# отказывает, если среди них есть то, что нельзя отправлять: секреты,
# запрещённые файлы, слишком большие объекты, конфликтные маркеры.
#
# Ничего не изменяет: репозиторий открывается только на чтение.
#
# Использование:
#   ./prepush_check.sh --repo /путь [--base main] [--max-size 100] [--quiet]
#
# Коды возврата: 0 — можно отправлять, 1 — нельзя, 2 — ошибка вызова.

set -euo pipefail

REPO="."
BASE="main"
MAX_KB=100
QUIET=0

while [ $# -gt 0 ]; do
    case "$1" in
        --repo)     REPO="$2";   shift 2 ;;
        --base)     BASE="$2";   shift 2 ;;
        --max-size) MAX_KB="$2"; shift 2 ;;
        --quiet)    QUIET=1;     shift   ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

say()  { [ "${QUIET}" -eq 1 ] || printf '%s\n' "$*"; }
bad()  { printf 'ОТКАЗ: %s\n' "$*" >&2; PROBLEMS=$((PROBLEMS+1)); }
g()    { git -C "${REPO}" "$@"; }

command -v git >/dev/null 2>&1 || { echo "нужен git" >&2; exit 2; }
g rev-parse --git-dir >/dev/null 2>&1 || { echo "не репозиторий: ${REPO}" >&2; exit 2; }

PROBLEMS=0

# ---- 1. не отправляем прямо в основную ветку --------------------------------
branch="$(g rev-parse --abbrev-ref HEAD)"
say "ветка: ${branch}, базовая: ${BASE}"
if [ "${branch}" = "${BASE}" ]; then
    bad "вы на основной ветке ${BASE}: изменения вносят через отдельную ветку"
fi

# ---- 2. что именно уйдёт -----------------------------------------------------
if g rev-parse --verify --quiet "${BASE}" >/dev/null; then
    range="${BASE}..HEAD"
else
    range="HEAD"
    say "базовой ветки ${BASE} нет — проверяю всю историю"
fi
commits="$(g rev-list "${range}" 2>/dev/null || true)"
n_commits="$(printf '%s\n' "${commits}" | grep -c . || true)"
say "коммитов к отправке: ${n_commits}"

# ---- 3. по каждому коммиту ---------------------------------------------------
SECRET_RE='(PASSWORD|PASSWD|SECRET|API[_-]?TOKEN|ACCESS[_-]?KEY)[[:space:]]*[=:][[:space:]]*[^[:space:]"'"'"']{6,}|BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}'
FORBIDDEN_RE='(^|/)(\.env|\.env\..*|id_rsa|id_ed25519|.*\.pem|.*\.key|.*\.p12|.*\.kdbx)$'

for c in ${commits}; do
    short="$(g rev-parse --short=7 "${c}")"

    # файлы, изменённые этим коммитом (у слияний берём первый родитель)
    files="$(g show --pretty=format: --name-only -m --first-parent "${c}" \
             | grep -v '^$' | sort -u || true)"

    for f in ${files}; do
        # файл существует в этом коммите? (удаления пропускаем)
        g cat-file -e "${c}:${f}" 2>/dev/null || continue

        case "${f}" in
            *) if printf '%s' "${f}" | grep -qE "${FORBIDDEN_RE}"; then
                   bad "${short}: файл, которого не должно быть в репозитории — ${f}"
               fi ;;
        esac

        size=$(g cat-file -s "${c}:${f}" 2>/dev/null || echo 0)
        if [ "${size}" -gt $(( MAX_KB * 1024 )) ]; then
            bad "${short}: ${f} — ${size} байт, предел ${MAX_KB} КБ"
        fi

        content="$(g show "${c}:${f}" 2>/dev/null || true)"
        hit="$(printf '%s' "${content}" | grep -inE "${SECRET_RE}" | head -1 || true)"
        if [ -n "${hit}" ]; then
            bad "${short}: похоже на секрет в ${f}, строка ${hit%%:*}"
        fi
        if printf '%s' "${content}" | grep -qE '^(<{7}|={7}|>{7})( |$)'; then
            bad "${short}: конфликтные маркеры остались в ${f}"
        fi
    done
done

# ---- 4. итог ------------------------------------------------------------------
if [ "${PROBLEMS}" -eq 0 ]; then
    say "проверка пройдена: отправлять можно"
    exit 0
fi
printf 'найдено проблем: %s\n' "${PROBLEMS}" >&2
exit 1
