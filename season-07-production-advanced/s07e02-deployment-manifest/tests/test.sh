#!/usr/bin/env bash
#
# s07e02 «Манифест» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства манифеста. Ни одного зашитого числа:
# пороги вычисляются из data/ (измеренное потребление, свободное место на
# узлах, длительность старта, список тегов в реестре). Поменяются данные —
# поменяются и требования, а формулировки останутся теми же (§4.3).
#
# YAML разбирается собственным читателем подмножества: блочная запись,
# отступ пробелами, списки через «- ». Курс не тащит зависимостей ради
# одной серии, а kubectl и кластер здесь не нужны вовсе.
#
# Без root, без сети, без кластера.
#
# Выбор манифеста: SUBJECT=... | artifacts/deployment.yaml | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
USAGE="${D}/usage.txt"; CAP="${D}/capacity.txt"; TAGS="${D}/registry_tags.txt"
START="${D}/startup.txt"; EP="${D}/endpoints.txt"; CUR="${D}/current_deployment.yaml"

if   [ -n "${SUBJECT:-}" ];                              then M="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/deployment.yaml" ];   then M="${SERIES_DIR}/artifacts/deployment.yaml"
elif [ -f "${SERIES_DIR}/deployment.yaml" ];             then M="${SERIES_DIR}/deployment.yaml"
else M="${SERIES_DIR}/solution/deployment.yaml"
     echo "ℹ️  Своего deployment.yaml не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/deployment.yaml artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e02 tests — манифест: ${M#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${USAGE}" "${CAP}" "${TAGS}" "${START}" "${EP}" "${CUR}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${M}" ]; then ok "deployment.yaml найден"
else no "deployment.yaml не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── читатель подмножества YAML: «путь=значение» ──────────────────────
cat > "${TMP}/flat.awk" <<'AWK'
{
    line = $0
    sub(/\r$/, "", line)
    if (line ~ /^[[:space:]]*#/) next
    if (line ~ /^[[:space:]]*$/) next
    sub(/[[:space:]]+#.*$/, "", line)
    sub(/[[:space:]]+$/, "", line)
    if (line == "" || line ~ /^---/) next

    match(line, /^ */); ind = RLENGTH
    body = substr(line, ind + 1)

    item = 0
    if (body == "-") { item = 1; body = ""; ind += 2 }
    else if (body ~ /^- /) { item = 1; sub(/^- +/, "", body); ind += 2 }

    popto = item ? ind - 1 : ind
    while (top > 0 && sind[top] >= popto) top--
    prefix = (top > 0) ? spath[top] : ""

    if (item) {
        n = cnt[prefix]++
        prefix = prefix "[" n "]"
        top++; sind[top] = ind - 1; spath[top] = prefix
        if (body == "") next
    }
    if (body ~ /^[^:]+:$/) {
        key = body; sub(/:$/, "", key)
        top++; sind[top] = ind
        spath[top] = (prefix == "") ? key : prefix "." key
        next
    }
    if (body ~ /^[^:]+:[[:space:]]/) {
        key = body; sub(/:.*$/, "", key)
        val = body; sub(/^[^:]*:[[:space:]]*/, "", val)
        gsub(/^["']|["']$/, "", val)
        print ((prefix == "") ? key : prefix "." key) "=" val
        next
    }
    if (item) print prefix "=" body
}
AWK

flatten() { awk -f "${TMP}/flat.awk" "$1"; }
flatten "${M}"   > "${TMP}/man"
flatten "${CUR}" > "${TMP}/cur"

g()  { awk -F= -v k="$1" '$1==k {sub(/^[^=]*=/,""); print; exit}' "${TMP}/man"; }
gc() { awk -F= -v k="$1" '$1==k {sub(/^[^=]*=/,""); print; exit}' "${TMP}/cur"; }
C='spec.template.spec.containers[0]'

# ── величины из data/ ────────────────────────────────────────────────
u() { awk -v k="$1" '/^[[:space:]]*#/{next} $1==k {print $2; exit}' "${USAGE}"; }
MEM_P50=$(u memory_p50_Mi); MEM_MAX=$(u memory_max_Mi)
CPU_P50=$(u cpu_p50_m);     CPU_MAX=$(u cpu_max_m)
HEAD=$(u memory_headroom_pct)
# потолок памяти: измеренный максимум плюс запас, вверх до целого Mi
MEM_FLOOR=$(( (MEM_MAX * (100 + HEAD) + 99) / 100 ))

# свободное место по узлам
FREE="$(awk '/^[[:space:]]*#/{next} NF==4 {print $3 - $4}' "${CAP}")"
DESIRED="$(gc spec.replicas)"

# длительность холодного старта: от первой метки времени до строки «listening»
STARTUP="$(awk '
  /^[[:space:]]*#/ {next}
  match($1, /T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z/) {
      t = substr($1, RSTART+1, 8); split(t, p, ":")
      s = p[1]*3600 + p[2]*60 + p[3]
      if (first == "") first = s
      if ($0 ~ /listening/) last = s
  }
  END { print (last == "" ? 0 : last - first) }' "${START}")"

# ручки: какая ходит в зависимости, какая нет
EP_ROWS="$(awk '/^[[:space:]]*#/{next} NF>=3 && $1 ~ /^\// {print}' "${EP}")"
EP_SELF="$(awk '$2=="none" && $1!="/metrics" {print $1; exit}' <<<"${EP_ROWS}")"
EP_DEPS="$(awk '$2!="none" {print $1; exit}' <<<"${EP_ROWS}")"

# ── перевод единиц ───────────────────────────────────────────────────
# Незаполненное или непонятное значение даёт 0 — «не задано». Отрицательных
# величин здесь быть не может, и печатать их студенту незачем.
mem_mi() { awk -v v="$1" 'BEGIN{
    if (v ~ /^[0-9]+Gi$/) { sub(/Gi$/,"",v); print v*1024 }
    else if (v ~ /^[0-9]+Mi$/) { sub(/Mi$/,"",v); print v+0 }
    else if (v ~ /^[0-9]+$/) { print int(v/1048576) }
    else print 0 }'; }
cpu_m() { awk -v v="$1" 'BEGIN{
    if (v ~ /^[0-9]+m$/) { sub(/m$/,"",v); print v+0 }
    else if (v ~ /^[0-9.]+$/) { print int(v*1000) }
    else print 0 }'; }
# сколько реплик размера r влезет на узлы: под кладётся целиком на один узел
fits() { if [ "$1" -le 0 ]; then echo 0; return; fi
         awk -v r="$1" '{ n += int($1 / r) } END { print n+0 }' <<<"${FREE}"; }

echo ""
echo "── Исходные данные ──"
CUR_LIM=$(mem_mi "$(gc "${C}.resources.limits.memory")")
CUR_REQ=$(mem_mi "$(gc "${C}.resources.requests.memory")")
if [ "${CUR_LIM}" -lt "${MEM_MAX}" ]
then ok "нынешний предел ${CUR_LIM} Mi ниже измеренного пика ${MEM_MAX} Mi — вот откуда OOMKilled"
else no "данные вырождены: нынешний предел уже покрывает пик, чинить нечего"; fi
if [ "$(fits "${CUR_REQ}")" -lt "${DESIRED}" ] && [ "$(fits "${MEM_P50}")" -ge "${DESIRED}" ]
then ok "с нынешними requests ${CUR_REQ} Mi встают $(fits "${CUR_REQ}") реплики из ${DESIRED}, с p50 — все"
else no "данные вырождены: размещение не зависит от размера requests"; fi
if [ -n "${EP_SELF}" ] && [ -n "${EP_DEPS}" ] && [ "${EP_SELF}" != "${EP_DEPS}" ]
then ok "в endpoints.txt различены ручка без зависимостей (${EP_SELF}) и с ними (${EP_DEPS})"
else no "данные вырождены: ручки неразличимы"; fi
if [ "${STARTUP}" -gt 0 ]
then ok "холодный старт по журналу: ${STARTUP} с"
else no "в startup.txt не нашлось строки «listening» с меткой времени"; fi

echo ""
echo "── 1. Форма ──"
if grep -qE ':[[:space:]]*[[{]' "${M}"
then no "потоковая запись ({...} или [...]) — проверяющий читает только блочную; разверни в отступы"
else ok "запись блочная"; fi
[ "$(g kind)" = "Deployment" ] && ok "kind: Deployment" || no "kind=$(g kind), ожидается Deployment"
[ "$(g apiVersion)" = "apps/v1" ] && ok "apiVersion: apps/v1" || no "apiVersion=$(g apiVersion), у Deployment это apps/v1"
[ "$(g metadata.name)" = "$(gc metadata.name)" ] && ok "имя совпадает с нынешним ($(gc metadata.name))" \
    || no "metadata.name=$(g metadata.name), а правим мы $(gc metadata.name)"
[ "$(g metadata.namespace)" = "$(gc metadata.namespace)" ] && ok "пространство имён $(gc metadata.namespace)" \
    || no "metadata.namespace=$(g metadata.namespace)"

SEL="$(g spec.selector.matchLabels.app)"; LBL="$(g spec.template.metadata.labels.app)"
if [ -n "${SEL}" ] && [ "${SEL}" = "${LBL}" ]
then ok "селектор совпадает с метками шаблона (${SEL})"
else no "селектор «${SEL}» не находит поды с меткой «${LBL}» — Deployment не увидит собственные реплики"; fi

R="$(g spec.replicas)"
[ "${R}" = "${DESIRED}" ] && ok "replicas=${R} — заказано столько же, сколько сейчас" \
    || no "replicas=${R}, а заказано ${DESIRED}: задача — исполнить желаемое, а не уменьшить его"

echo ""
echo "── 2. Образ ──"
IMG="$(g "${C}.image")"; TAG="${IMG##*:}"
if [ "${IMG}" = "${TAG}" ] || [ -z "${TAG}" ]
then no "у образа «${IMG}» нет тега: без тега подставится latest"
else ok "тег указан явно: ${TAG}"
     if [ "${TAG}" = "latest" ]
     then no "тег latest подвижен: две реплики одного Deployment могут оказаться на разных образах"
     else ok "тег не latest"; fi
     if grep -qxF "${TAG}" <(grep -v '^[[:space:]]*#' "${TAGS}")
     then ok "тег ${TAG} есть в реестре"
     else no "тега ${TAG} в реестре нет — это ImagePullBackOff, ровно как у aurora-worker"; fi
fi

echo ""
echo "── 3. Память: место и потолок ──"
RQ=$(mem_mi "$(g "${C}.resources.requests.memory")")
LM=$(mem_mi "$(g "${C}.resources.limits.memory")")
if [ "${RQ}" -gt 0 ]; then ok "requests.memory задан (${RQ} Mi)"
else no "requests.memory не задан: без него под попадает в класс BestEffort и выселяется первым"; fi
if [ "${LM}" -gt 0 ]; then ok "limits.memory задан (${LM} Mi)"
else no "limits.memory не задан: один протекающий под выселит с узла соседей"; fi
if [ "${RQ}" -ge "${MEM_P50}" ]
then ok "requests.memory ${RQ} ≥ обычного потребления ${MEM_P50} Mi"
else no "requests.memory ${RQ} ниже обычных ${MEM_P50} Mi: планировщик считает узел свободнее, чем он есть"; fi
if [ "${LM}" -ge "${MEM_FLOOR}" ]
then ok "limits.memory ${LM} ≥ пик ${MEM_MAX} + ${HEAD} % = ${MEM_FLOOR} Mi"
else no "limits.memory ${LM} Mi ниже ${MEM_FLOOR} (пик ${MEM_MAX} плюс запас ${HEAD} %) — вернётся 137"; fi
if [ "${RQ}" -gt 0 ] && [ "${RQ}" -lt "${LM}" ]
then ok "requests < limits: место резервируется под обычную жизнь, потолок — под всплеск"
elif [ "${RQ}" -gt 0 ] && [ "${RQ}" -eq "${LM}" ]
then no "requests=limits=${RQ} Mi: кластеру придётся резервировать пик под каждую реплику, и пять таких не встанут"
else no "requests и limits не сравнить, пока оба не заданы числом"; fi

echo ""
echo "── 4. Размещение пяти реплик ──"
N_FIT="$(fits "${RQ}")"
if [ "${N_FIT}" -ge "${DESIRED}" ]
then ok "по свободному месту узлов встают ${N_FIT} реплик при заказанных ${DESIRED}"
else no "встают только ${N_FIT} из ${DESIRED}: свободно $(tr '\n' ' ' <<<"${FREE}")Mi, а просим ${RQ} Mi на реплику — это снова Pending"; fi

echo ""
echo "── 5. Процессор ──"
RC=$(cpu_m "$(g "${C}.resources.requests.cpu")")
LC=$(cpu_m "$(g "${C}.resources.limits.cpu")")
if [ "${RC}" -ge "${CPU_P50}" ]
then ok "requests.cpu ${RC}m ≥ обычных ${CPU_P50}m"
else no "requests.cpu ${RC}m ниже обычных ${CPU_P50}m"; fi
if [ "${LC}" -le 0 ]
then ok "предел на процессор не задан — законный выбор: CPU сжимаем, всплеск не убивает"
elif [ "${LC}" -ge "${CPU_MAX}" ]
then ok "limits.cpu ${LC}m ≥ измеренного пика ${CPU_MAX}m"
else no "limits.cpu ${LC}m ниже пика ${CPU_MAX}m: всплеск превратится в задержку (троттлинг), а не в отказ"; fi

echo ""
echo "── 6. Три пробы, три вопроса ──"
SP_PER=$(g "${C}.startupProbe.periodSeconds"); SP_THR=$(g "${C}.startupProbe.failureThreshold")
LV_PATH="$(g "${C}.livenessProbe.httpGet.path")"; RD_PATH="$(g "${C}.readinessProbe.httpGet.path")"
SP_PATH="$(g "${C}.startupProbe.httpGet.path")"
BUDGET_MIN=$(( (STARTUP * 3 + 1) / 2 ))   # полуторный запас к измеренному старту

if [ -n "${SP_PATH}" ]; then ok "startupProbe задана"
else no "startupProbe нет: пробе живости никто не мешает убить приложение на прогреве"; fi
if [ -n "${SP_PER}" ] && [ -n "${SP_THR}" ]; then
    BUDGET=$(( SP_PER * SP_THR ))
    if [ "${BUDGET}" -ge "${BUDGET_MIN}" ]
    then ok "бюджет старта ${SP_PER}×${SP_THR}=${BUDGET} с ≥ ${BUDGET_MIN} (полтора холодных старта по ${STARTUP} с)"
    else no "бюджет старта ${BUDGET} с меньше ${BUDGET_MIN}: таблица маршрутов грузится ${STARTUP} с и растёт"; fi
else no "у startupProbe не заданы periodSeconds и failureThreshold — бюджета старта нет"; fi

if [ -n "${RD_PATH}" ] && [ "${RD_PATH}" = "${EP_DEPS}" ]
then ok "готовность спрашивает ${RD_PATH} — ручку, которая проверяет зависимости"
else no "readinessProbe смотрит «${RD_PATH}», а зависимости проверяет ${EP_DEPS}"; fi
if [ -n "${LV_PATH}" ] && [ "${LV_PATH}" = "${EP_SELF}" ]
then ok "живость спрашивает ${LV_PATH} — ручку, которая не ходит наружу"
else no "livenessProbe смотрит «${LV_PATH}»: проба живости обязана отвечать только за свой процесс, иначе падение базы перезапустит все реплики"; fi
if [ -n "${LV_PATH}" ] && [ "${LV_PATH}" != "${RD_PATH}" ]
then ok "живость и готовность спрашивают разное"
else no "живость и готовность смотрят один путь: временная неготовность превращается в перезапуск"; fi

echo ""
echo "── 7. Конфигурация, которой не хватало ──"
NEED="$(sed -n 's/^#[[:space:]]*\(AURORA_DB_DSN\).*/\1/p' "${EP}" | head -1)"
IDX="$(awk -F= -v n="${NEED}" '$2==n && $1 ~ /^spec\.template\.spec\.containers\[0\]\.env\[[0-9]+\]\.name$/ {
        k=$1; sub(/.*env\[/,"",k); sub(/\].*/,"",k); print k; exit}' "${TMP}/man")"
if [ -n "${IDX}" ]; then
    ok "${NEED} задана — та самая переменная, без которой падал dk3np"
    if [ -n "$(g "${C}.env[${IDX}].valueFrom.secretKeyRef.name")" ]
    then ok "${NEED} приходит ссылкой на Secret, а не значением"
    else no "${NEED} задана значением: DSN содержит пароль, а манифест лежит в git"; fi
else no "${NEED} в env не найдена — под снова упадёт с «required key is missing»"; fi
if grep -qE '://[^[:space:]/]*:[^[:space:]/]*@' "${M}"
then no "в манифесте открытая строка подключения с паролем"
else ok "открытых паролей в манифесте нет"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
