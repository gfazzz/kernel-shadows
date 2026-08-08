#!/usr/bin/env bash
#
# rollback.sh — вернуть в бой предыдущую рабочую версию (ЭТАЛОН)
#
# Работает по журналу выкатов: время, версия, состояние, была ли миграция.
# Журнал читается так же, как юнит systemd, — **последняя запись о версии
# побеждает**: одна и та же версия могла быть здоровой утром и снятой с боя
# вечером, и значение имеет последнее.
#
# Использование:
#   ./rollback.sh --journal FILE --host HOST --image IMAGE
#                 [--to ВЕРСИЯ] [--force] [--dry-run] [--health URL]
#
# Коды возврата:
#   0 — откат выполнен и подтверждён проверкой готовности
#   1 — откат выполнен, но служба не отвечает (журнал это фиксирует)
#   2 — ошибка вызова или откатываться некуда (ничего не изменено)
#   3 — на пути отката есть миграция схемы (ничего не изменено)

set -euo pipefail

JOURNAL=""; HOST=""; IMAGE=""; TO=""; HEALTH=""
FORCE=0; DRY=0

usage() {
    echo "использование: $0 --journal FILE --host HOST --image IMAGE [--to ВЕРСИЯ] [--force] [--dry-run] [--health URL]" >&2
    exit 2
}

while [ $# -gt 0 ]; do
    case "$1" in
        --journal) JOURNAL="${2:-}"; shift 2 ;;
        --host)    HOST="${2:-}";    shift 2 ;;
        --image)   IMAGE="${2:-}";   shift 2 ;;
        --to)      TO="${2:-}";      shift 2 ;;
        --health)  HEALTH="${2:-}";  shift 2 ;;
        --force)   FORCE=1;          shift   ;;
        --dry-run) DRY=1;            shift   ;;
        -h|--help) usage ;;
        *) echo "неизвестный аргумент: $1" >&2; usage ;;
    esac
done

[ -n "${JOURNAL}" ] && [ -n "${HOST}" ] && [ -n "${IMAGE}" ] || usage
[ -f "${JOURNAL}" ] || { echo "нет журнала выкатов: ${JOURNAL}" >&2; exit 2; }
HEALTH="${HEALTH:-https://${HOST}/healthz}"

# ---- чтение журнала ----------------------------------------------------------
# Значащие строки: время  версия  состояние  миграция  [комментарий]
entries() { grep -vE '^[[:space:]]*(#|$)' "${JOURNAL}"; }

n_entries="$(entries | grep -c . || true)"
[ "${n_entries}" -ge 1 ] || { echo "журнал пуст: откатываться не к чему" >&2; exit 2; }

CURRENT="$(entries | tail -1 | awk '{print $2}')"

# последняя запись о версии побеждает
status_of()   { entries | awk -v v="$1" '$2==v {s=$3} END{print s}'; }
last_line_of(){ entries | awk -v v="$1" '$2==v {n=NR} END{print n+0}'; }

# версии в порядке последнего упоминания, свежие первыми
versions_desc() {
    entries | awk '{last[$2]=NR} END {for (v in last) printf "%d %s\n", last[v], v}' \
            | sort -rn | awk '{print $2}'
}

# ---- выбор цели --------------------------------------------------------------
if [ -n "${TO}" ]; then
    TARGET="${TO}"
    [ "$(last_line_of "${TARGET}")" -gt 0 ] \
        || { echo "версии ${TARGET} нет в журнале: откатываться на неё нельзя" >&2; exit 2; }
    if [ "$(status_of "${TARGET}")" != "healthy" ] && [ "${FORCE}" -eq 0 ]; then
        echo "ОТКАЗ: последняя запись о ${TARGET} — «$(status_of "${TARGET}")»." >&2
        echo "  Эта версия уже снималась с боя. Если решение осознанное — --force." >&2
        exit 2
    fi
else
    TARGET=""
    for v in $(versions_desc); do
        [ "${v}" = "${CURRENT}" ] && continue
        # предыдущая по времени версия — не обязательно рабочая:
        # берём последнюю, чьё ПОСЛЕДНЕЕ состояние healthy
        if [ "$(status_of "${v}")" = "healthy" ]; then TARGET="${v}"; break; fi
    done
    [ -n "${TARGET}" ] || {
        echo "в журнале нет ни одной здоровой версии, кроме текущей (${CURRENT})" >&2
        echo "  откат не поможет: чинить придётся вперёд" >&2
        exit 2; }
fi

echo "сейчас в бою: ${CURRENT}"
echo "цель отката:  ${TARGET}  (состояние по журналу: $(status_of "${TARGET}"))"

# ---- миграции на пути отката -------------------------------------------------
# Значение имеют только миграции, применённые ПОСЛЕ цели: то, что было раньше,
# откатом не затрагивается.
tgt_line="$(last_line_of "${TARGET}")"
MIGRATIONS="$(entries | awk -v n="${tgt_line}" 'NR>n && $4=="yes" {printf "%s ", $2}')"

if [ -n "${MIGRATIONS}" ]; then
    if [ "${FORCE}" -eq 0 ]; then
        echo "ОТКАЗ: между ${TARGET} и ${CURRENT} применялись миграции схемы: ${MIGRATIONS}" >&2
        echo "  Откат кода их не отменяет: старая версия увидит изменённую базу." >&2
        echo "  Это решение принимает человек, а не скрипт. Осознанно — --force." >&2
        exit 3
    fi
    echo "ВНИМАНИЕ: откат через миграции (${MIGRATIONS}) — по явному --force" >&2
fi

# ---- план --------------------------------------------------------------------
PULL="docker pull ${IMAGE}:${TARGET}"
UP="cd /srv/ops && IMAGE_TAG=${TARGET} docker compose up -d"

if [ "${DRY}" -eq 1 ]; then
    echo "--- план (ничего не выполняется) ---"
    echo "ssh ${HOST} '${PULL}'"
    echo "ssh ${HOST} '${UP}'"
    echo "проверка готовности: ${HEALTH}"
    echo "запись в журнал: ${CURRENT} -> failed, ${TARGET} -> healthy"
    exit 0
fi

# ---- выкат -------------------------------------------------------------------
# Тег точный: «предыдущая версия» существует только потому, что у неё есть имя.
ssh "${HOST}" "${PULL}"
ssh "${HOST}" "${UP}"

# ---- проверка готовности ------------------------------------------------------
# «Команда выполнена» не значит «служба отвечает»: решает ответ машины.
verify() {
    local i=0
    while [ "${i}" -lt 10 ]; do
        if curl -fsS --max-time 5 "${HEALTH}" >/dev/null 2>&1; then return 0; fi
        i=$((i+1)); sleep 3
    done
    return 1
}

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
note_line() { printf '%s  %s  %-8s %-3s %s\n' "${now}" "$1" "$2" no "$3" >> "${JOURNAL}"; }

if verify; then
    note_line "${CURRENT}" failed  "снята с боя откатом"
    note_line "${TARGET}"  healthy "откат с ${CURRENT}, готовность подтверждена"
    echo "откат выполнен: в бою ${TARGET}, служба отвечает"
    exit 0
fi

note_line "${CURRENT}" failed "снята с боя откатом"
note_line "${TARGET}"  failed "откат с ${CURRENT}, готовность НЕ подтверждена"
echo "ОТКАТ ВЫПОЛНЕН, НО СЛУЖБА НЕ ОТВЕЧАЕТ: ${HEALTH}" >&2
echo "  обе версии помечены в журнале как снятые: следующий откат уйдёт глубже" >&2
exit 1
