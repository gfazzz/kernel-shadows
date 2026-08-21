#!/usr/bin/env bash
#
# s07e01 «Что происходит в кластере» — тест находок (Type C).
#
# Ни одного зашитого ответа: всё пересчитывается из снимков в data/.
# Ключевая проверка — расхождение между «Running» и «Ready»: тест
# отдельно убеждается, что в данных оно есть, иначе серия была бы
# про пересчёт строк, а не про смысл.
#
# Без root, без сети, без кластера.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
PODS="${D}/pods.txt"; NODES="${D}/nodes.txt"; EV="${D}/events.txt"
DC="${D}/describe_c9v7t.txt"; DD="${D}/describe_dk3np.txt"; DEP="${D}/deployments.txt"

if   [ -n "${SUBJECT:-}" ];                               then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/cluster_report.txt" ]; then REP="${SERIES_DIR}/artifacts/cluster_report.txt"
elif [ -f "${SERIES_DIR}/cluster_report.txt" ];           then REP="${SERIES_DIR}/cluster_report.txt"
else REP="${SERIES_DIR}/solution/cluster_report.txt"
     echo "ℹ️  Своего cluster_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/cluster_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e01 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${PODS}" "${NODES}" "${EV}" "${DC}" "${DD}" "${DEP}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${REP}" ]; then ok "cluster_report.txt найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

got()   { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "${REP}"; }
check() { local k="$1" want="$2" why="$3" have; have="$(got "${k}")"
    if [ -z "${have}" ]; then no "${k}: не заполнено (${why})"
    elif [ "${have}" = "${want}" ]; then ok "${k}=${have}"
    else no "${k}=${have}, из снимков следует «${want}» — ${why}"; fi; }

# ── таблица подов: без шапки и комментариев ─────────────────────────
P="$(grep -v '^[[:space:]]*#' "${PODS}" | grep -v '^NAME' | awk 'NF>=4')"
E_TOTAL="$(grep -c . <<<"${P}")"
E_RUNNING="$(awk '$3=="Running"' <<<"${P}" | grep -c .)"
E_READY="$(awk '{split($2,r,"/"); if (r[1]==r[2] && r[2]!="") c++} END{print c+0}' <<<"${P}")"
E_RNR="$(awk '$3=="Running" {split($2,r,"/"); if (r[1]!=r[2]) c++} END{print c+0}' <<<"${P}")"

N="$(grep -v '^[[:space:]]*#' "${NODES}" | grep -v '^NAME' | awk 'NF>=3 && $2 ~ /Ready|NotReady/')"
E_NODES="$(awk '$2=="Ready"' <<<"${N}" | grep -c .)"

E_PENDING="$(awk '$3=="Pending" {print $1; exit}' <<<"${P}")"
E_IMGPULL="$(awk '$3 ~ /ImagePull|ErrImagePull/ {print $1; exit}' <<<"${P}")"
E_CRASH="$(awk '$3=="CrashLoopBackOff" {print $1; exit}' <<<"${P}")"

# перезапуски: колонка RESTARTS может быть вида «47 (2m ago)»
E_MAXPOD="$(awk '{r=$4; gsub(/[^0-9]/,"",r); if (r+0>m) {m=r+0; p=$1}} END{print p}' <<<"${P}")"
E_MAXCNT="$(awk '{r=$4; gsub(/[^0-9]/,"",r); if (r+0>m) m=r+0} END{print m+0}' <<<"${P}")"

# ── события ─────────────────────────────────────────────────────────
EVB="$(grep -v '^[[:space:]]*#' "${EV}" | grep -v '^LAST SEEN')"
SCHED_MSG="$(grep "${E_PENDING}" <<<"${EVB}" | grep 'FailedScheduling' | head -1)"
if   grep -qi 'Insufficient memory' <<<"${SCHED_MSG}"; then E_SHORT=memory
elif grep -qi 'Insufficient cpu'    <<<"${SCHED_MSG}"; then E_SHORT=cpu
else E_SHORT=taint; fi
E_TAG="$(grep "${E_IMGPULL}" <<<"${EVB}" | sed -n 's/.*manifest tagged by "\([^"]*\)".*/\1/p' | head -1)"
E_RCODE="$(grep "${E_MAXPOD}" <<<"${EVB}" | sed -n 's/.*Readiness probe failed.*statuscode: \([0-9]*\).*/\1/p' | head -1)"

# ── describe ────────────────────────────────────────────────────────
E_RREASON="$(awk '/Last State:/{f=1} f && /Reason:/ {print $2; exit}' "${DC}")"
E_REXIT="$(awk '/Last State:/{f=1} f && /Exit Code:/ {print $3; exit}' "${DC}")"
E_MEMLIM="$(awk '/Limits:/{f=1} f && /memory:/ {print $2; exit}' "${DC}")"
E_CEXIT="$(awk '/Last State:/{f=1} f && /Exit Code:/ {print $3; exit}' "${DD}")"
E_CKEY="$(sed -n 's/.*required key "\([^"]*\)" is missing.*/\1/p' "${DD}" | head -1)"

# ── deployment ──────────────────────────────────────────────────────
E_DESIRED="$(awk '/^  replicas:/ {print $2; exit}' "${DEP}")"
E_AVAIL="$(awk '/availableReplicas:/ {print $2; exit}' "${DEP}")"
APP="$(printf '%s\n' "${E_DESIRED}" >/dev/null; awk '$1 ~ /^aurora-api-/' <<<"${P}")"
E_SERVING="$(awk '{split($2,r,"/"); if (r[1]==r[2] && r[2]!="") c++} END{print c+0}' <<<"${APP}")"

echo ""
echo "── Исходные данные ──"
if [ "${E_RNR}" -ge 1 ]; then ok "в снимке есть под Running, но не Ready — расхождение, ради которого серия"
else no "данные вырождены: Running и Ready совпадают у всех"; fi
if [ -n "${E_PENDING}" ] && [ -n "${E_IMGPULL}" ] && [ -n "${E_CRASH}" ]
then ok "три разные причины незапуска присутствуют"
else no "не все причины найдены (pending=${E_PENDING:-?}, imagepull=${E_IMGPULL:-?}, crash=${E_CRASH:-?})"; fi

echo ""
echo "── 1. Обзор ──"
check pods_total       "${E_TOTAL}"   "строки таблицы без шапки"
check pods_running     "${E_RUNNING}" "колонка STATUS"
check pods_ready       "${E_READY}"   "в READY левое число равно правому"
check running_not_ready "${E_RNR}"    "Running, но READY не полный"
check nodes_ready      "${E_NODES}"   "узлы в состоянии Ready"

echo ""
echo "── 2. Причины незапуска ──"
check pending_pod        "${E_PENDING}" "STATUS=Pending"
check pending_shortage   "${E_SHORT}"   "чего не хватило планировщику"
check imagepull_pod      "${E_IMGPULL}" "ImagePullBackOff"
check imagepull_tag      "${E_TAG}"     "тег из сообщения реестра"
check crashloop_pod      "${E_CRASH}"   "CrashLoopBackOff"
check crashloop_exit_code "${E_CEXIT}"  "Exit Code последнего завершения"
check crashloop_missing_key "${E_CKEY}" "ключ из лога предыдущего запуска"

echo ""
echo "── 3. Тот, кто «работает» ──"
check max_restarts_pod   "${E_MAXPOD}"  "наибольшее число в колонке RESTARTS"
check max_restarts_count "${E_MAXCNT}"  "само число, без «(2m ago)»"
check restart_reason     "${E_RREASON}" "Last State -> Reason"
check restart_exit_code  "${E_REXIT}"   "Last State -> Exit Code"
check memory_limit       "${E_MEMLIM}"  "Limits -> memory"
check readiness_http_code "${E_RCODE}"  "код из события Unhealthy"

echo ""
echo "── 4. Что это значит ──"
check desired_replicas   "${E_DESIRED}" "spec.replicas"
check available_replicas "${E_AVAIL}"   "status.availableReplicas"
check serving_replicas   "${E_SERVING}" "подов aurora-api с полным READY"

echo ""
echo "── Выводы ──"
if [ "${E_SERVING}" -lt "${E_RUNNING}" ]
then ok "принимают трафик ${E_SERVING} из ${E_RUNNING} «работающих» — счёт по статусу завышает"
else no "данные вырождены: счёт по статусу совпадает со счётом по готовности"; fi
grep -qE '^[[:space:]]*#' "${REP}" && ok "пояснения в файле остались" \
                                   || no "все комментарии вырезаны — отчёт должен объяснять, откуда значения"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
