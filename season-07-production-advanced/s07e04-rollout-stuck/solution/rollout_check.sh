#!/usr/bin/env bash
#
# rollout_check.sh — «выкат идёт или встал» (ЭТАЛОН)
#
# Отвечает на вопрос, на который `kubectl rollout status` отвечает только
# по истечении таймаута: сейчас ещё едет или уже никогда не доедет.
#
#   rollout_check.sh <каталог-снимка>
#
# Код возврата: 0 — идёт или доехал, 1 — встал, 2 — снимок не разобрать.
# Именно поэтому вывод короткий и машинный: скрипт задуман как шаг
# конвейера, а не как чтение для человека.

set -uo pipefail

DIR="${1:-}"
if [ -z "${DIR}" ] || [ ! -d "${DIR}" ]; then
    echo "usage: $(basename "$0") <каталог-снимка>" >&2
    exit 2
fi

DEPLOY="${DIR}/deploy.txt"; RS="${DIR}/rs.txt"
PODS="${DIR}/pods.txt";     EVENTS="${DIR}/events.txt"
for f in "${DEPLOY}" "${RS}" "${PODS}" "${EVENTS}"; do
    [ -f "${f}" ] || { echo "нет файла: ${f}" >&2; exit 2; }
done

# ── числа из deploy.txt ──────────────────────────────────────────────
# Ключ ищется по имени с двоеточием; отступ не важен, значение — число.
num() { awk -v k="$1" '$1 == k ":" {print $2+0; exit}' "${DEPLOY}"; }
DESIRED=$(num replicas)          # spec.replicas идёт в файле первым
UPDATED=$(num updatedReplicas)
AVAILABLE=$(num availableReplicas)
CURRENT=$(awk '/^status:/{s=1} s && $1=="replicas:" {print $2+0; exit}' "${DEPLOY}")

# Условие Progressing: статус и причина лежат в соседних строках списка.
PROG_STATUS=$(awk '/type: Progressing/{f=1; next} f && /status:/ {gsub(/"/,"",$2); print $2; exit}' "${DEPLOY}")
PROG_REASON=$(awk '/type: Progressing/{f=1; next} f && /reason:/ {print $2; exit}' "${DEPLOY}")

# ── какой ReplicaSet новый ───────────────────────────────────────────
# Различить их можно только по возрасту: имя — это хеш шаблона, и по нему
# порядок не восстановить. AGE в выводе kubectl — «50s», «14m», «6h», «2d».
age_s() { awk -v a="$1" 'BEGIN{
    n = a; sub(/[a-z]$/, "", n)
    if      (a ~ /s$/) print n
    else if (a ~ /m$/) print n * 60
    else if (a ~ /h$/) print n * 3600
    else if (a ~ /d$/) print n * 86400
    else print n }'; }

ROWS=$(grep -v '^[[:space:]]*#' "${RS}" | grep -v '^NAME' | awk 'NF>=5')
NEW_RS=""; NEW_AGE=""; OLD_RS=""; OLD_REPL=0
while read -r name desired _ _ age; do
    [ -n "${name}" ] || continue
    s=$(age_s "${age}")
    if [ -z "${NEW_AGE}" ] || [ "${s}" -lt "${NEW_AGE}" ]; then
        # прежний «новый» становится старым только если он старше
        if [ -n "${NEW_RS}" ]; then OLD_RS="${NEW_RS}"; OLD_REPL="${NEW_REPL}"; fi
        NEW_RS="${name}"; NEW_AGE="${s}"; NEW_REPL="${desired}"
    elif [ -z "${OLD_RS}" ] || [ "${desired}" -gt "${OLD_REPL}" ]; then
        OLD_RS="${name}"; OLD_REPL="${desired}"
    fi
done <<< "${ROWS}"
NEW_HASH="${NEW_RS##*-}"

# ── поды нового ReplicaSet ───────────────────────────────────────────
NEW_PODS=$(grep -v '^[[:space:]]*#' "${PODS}" | grep -v '^NAME' | awk -v h="-${NEW_HASH}-" 'index($1, h)')
N_PENDING=$(awk '$3=="Pending"' <<<"${NEW_PODS}" | grep -c . || true)
N_IMAGE=$(awk '$3 ~ /ImagePull|ErrImagePull/' <<<"${NEW_PODS}" | grep -c . || true)
N_NOTREADY=$(awk '$3=="Running" {split($2,r,"/"); if (r[1]!=r[2]) c++} END{print c+0}' <<<"${NEW_PODS}")

# ── предупреждения о подах нового ReplicaSet ─────────────────────────
WARN=$(grep -v '^[[:space:]]*#' "${EVENTS}" | grep "${NEW_HASH}" | awk '$2=="Warning"')
W_SCHED=$(grep -c 'FailedScheduling' <<<"${WARN}" || true)
W_IMAGE=$(grep -cE 'Failed to pull image|ErrImagePull|Back-off pulling' <<<"${WARN}" || true)

# ── вывод ────────────────────────────────────────────────────────────
VERDICT=progressing; CAUSE=none

if [ "${UPDATED}" -eq "${DESIRED}" ] && [ "${AVAILABLE}" -eq "${DESIRED}" ] \
   && [ "${CURRENT}" -eq "${DESIRED}" ]; then
    VERDICT=complete
elif [ "${PROG_STATUS}" = "False" ]; then
    # Кластер уже признал, что не успел: reason=ProgressDeadlineExceeded.
    VERDICT=stuck
elif [ "${W_SCHED}" -gt 0 ] || [ "${W_IMAGE}" -gt 0 ]; then
    # Ждать нечего: планировщику некуда класть под, либо образа нет.
    # Ни то, ни другое само не рассосётся, а maxUnavailable=0 запрещает
    # убирать старую реплику — значит выкат стоит, а не едет.
    VERDICT=stuck
fi

if [ "${VERDICT}" = stuck ]; then
    if   [ "${W_SCHED}" -gt 0 ] || [ "${N_PENDING}" -gt 0 ]; then CAUSE=scheduling
    elif [ "${W_IMAGE}" -gt 0 ] || [ "${N_IMAGE}"   -gt 0 ]; then CAUSE=image
    elif [ "${N_NOTREADY}" -gt 0 ];                          then CAUSE=readiness
    else CAUSE=deadline; fi
fi

echo "VERDICT ${VERDICT}"
echo "CAUSE ${CAUSE}"
echo "DESIRED ${DESIRED}"
echo "UPDATED ${UPDATED}"
echo "AVAILABLE ${AVAILABLE}"
echo "NEW-RS ${NEW_RS}"
echo "OLD-RS ${OLD_RS:-none} ${OLD_REPL}"
echo "PROGRESSING ${PROG_STATUS:-unknown} ${PROG_REASON:-unknown}"

[ "${VERDICT}" = stuck ] && exit 1
exit 0
