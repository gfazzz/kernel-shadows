#!/usr/bin/env bash
#
# s07e03 «Кого нашёл Service» — тест конфигурации (Type B).
#
# Два артефакта: service.yaml и config.yaml. Проверяются свойства, а не
# текст: сколько подов находит селектор (считается по реальным меткам из
# data/pods.txt), совпадает ли targetPort с портом контейнера, не утекла ли
# в ConfigMap настройка, помеченная как secret, и разрешается ли адрес,
# записанный в AURORA_MESH_URL.
#
# Без root, без сети, без кластера.
#
# Выбор артефактов: SUBJECT_SVC=... SUBJECT_CM=... | artifacts/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
PODS="${D}/pods.txt"; DEPL="${D}/deployment_excerpt.yaml"; CUR="${D}/current_service.yaml"
EPF="${D}/endpoints.txt"; APPCFG="${D}/app_config.txt"; SVCS="${D}/services.txt"

pick() { # $1 — имя файла артефакта, $2 — переменная переопределения
    local name="$1" over="$2"
    if   [ -n "${over}" ];                          then printf '%s' "${over}"
    elif [ -f "${SERIES_DIR}/artifacts/${name}" ];  then printf '%s' "${SERIES_DIR}/artifacts/${name}"
    elif [ -f "${SERIES_DIR}/${name}" ];            then printf '%s' "${SERIES_DIR}/${name}"
    else printf '%s' "${SERIES_DIR}/solution/${name}"; fi
}
SVC="$(pick service.yaml "${SUBJECT_SVC:-}")"
CM="$(pick config.yaml   "${SUBJECT_CM:-}")"
case "${SVC}${CM}" in *solution/*)
    echo "ℹ️  Своих файлов не найдено — проверяю ЭТАЛОН (solution/)."
    echo "   Начни своё:  cp starter/service.yaml starter/config.yaml artifacts/"; echo "" ;;
esac

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e03 tests — ${SVC#"$SERIES_DIR"/} + ${CM#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${PODS}" "${DEPL}" "${CUR}" "${EPF}" "${APPCFG}" "${SVCS}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done

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

if [ -f "${SVC}" ]; then ok "service.yaml найден"; flatten "${SVC}" > "${TMP}/svc"
else no "service.yaml не найден"; : > "${TMP}/svc"; fi
if [ -f "${CM}" ]; then ok "config.yaml найден"; flatten "${CM}" > "${TMP}/cm"
else no "config.yaml не найден"; : > "${TMP}/cm"; fi
flatten "${CUR}"  > "${TMP}/cur"
flatten "${DEPL}" > "${TMP}/dep"

get() { awk -F= -v k="$2" '$1==k {sub(/^[^=]*=/,""); print; exit}' "$1"; }
s()  { get "${TMP}/svc" "$1"; }
c()  { get "${TMP}/cm"  "$1"; }

# ── сколько подов найдёт набор меток ─────────────────────────────────
# Селектор берётся из плоского представления: spec.selector.<ключ>=<значение>.
sel_of() { awk -F= '$1 ~ /^spec\.selector\./ {k=$1; sub(/^spec\.selector\./,"",k); print k "=" $2}' "$1"; }
# Метки подов — шестая колонка `--show-labels`, через запятую.
matches() { # $1 — файл с парами ключ=значение селектора
    local selfile="$1"
    awk -v sf="${selfile}" '
      BEGIN { ns = 0; while ((getline l < sf) > 0) if (l != "") sel[++ns] = l }
      /^[[:space:]]*#/ { next }
      /^NAME/ { next }
      NF >= 6 {
          delete lab
          n = split($6, parts, ",")
          for (i = 1; i <= n; i++) lab[parts[i]] = 1
          if (ns == 0) next
          hit = 1
          for (i = 1; i <= ns; i++) if (!(sel[i] in lab)) hit = 0
          if (hit) c++
      }
      END { print c+0 }' "${PODS}"
}

sel_of "${TMP}/svc" > "${TMP}/sel"
sel_of "${TMP}/cur" > "${TMP}/selcur"
N_SEL="$(matches "${TMP}/sel")"
N_CUR="$(matches "${TMP}/selcur")"
# Сколько подов приложения вообще есть: по метке app из шаблона Deployment.
APP_LABEL="app=$(get "${TMP}/dep" spec.template.metadata.labels.app)"
printf '%s\n' "${APP_LABEL}" > "${TMP}/selapp"
N_APP="$(matches "${TMP}/selapp")"

echo ""
echo "── Исходные данные ──"
if [ "${N_APP}" -gt 0 ]
then ok "по метке ${APP_LABEL} в снимке ${N_APP} подов"
else no "данные вырождены: подов с меткой ${APP_LABEL} в снимке нет"; fi
if [ "${N_CUR}" -eq 0 ]
then ok "селектор черновика не находит ни одного пода — вот откуда пустые endpoints"
else no "данные вырождены: черновик кого-то находит, ловушки нет"; fi
if grep -qE '^aurora-api[[:space:]]+<none>' "${EPF}"
then ok "в endpoints.txt у aurora-api список пуст, и ни одного события об этом"
else no "данные вырождены: endpoints не пуст"; fi

echo ""
echo "── 1. Service: форма ──"
[ "$(s kind)" = "Service" ] && ok "kind: Service" || no "kind=$(s kind)"
[ "$(s apiVersion)" = "v1" ] && ok "apiVersion: v1" || no "apiVersion=$(s apiVersion), у Service это v1"
[ "$(s metadata.namespace)" = "$(get "${TMP}/cur" metadata.namespace)" ] \
    && ok "пространство имён $(s metadata.namespace)" || no "metadata.namespace=$(s metadata.namespace)"
[ "$(s metadata.name)" = "$(get "${TMP}/cur" metadata.name)" ] \
    && ok "имя службы $(s metadata.name)" || no "metadata.name=$(s metadata.name)"

echo ""
echo "── 2. Service: кого он находит ──"
if [ "${N_SEL}" -eq "${N_APP}" ] && [ "${N_SEL}" -gt 0 ]
then ok "селектор находит все ${N_SEL} подов приложения"
elif [ "${N_SEL}" -eq 0 ]
then no "селектор не находит ни одного пода: endpoints будут пусты, и никто об этом не сообщит"
else no "селектор находит ${N_SEL} подов из ${N_APP}: часть реплик останется без трафика"; fi

if grep -q 'pod-template-hash' "${TMP}/sel"
then no "в селекторе pod-template-hash: он меняется при каждой правке шаблона, и после первого выката служба опустеет"
else ok "в селекторе нет меток, меняющихся при выкате"; fi

echo ""
echo "── 3. Service: порты и тип ──"
TYPE="$(s spec.type)"
if [ "${TYPE}" = "ClusterIP" ]
then ok "type: ClusterIP — служба внутренняя"
else no "type=${TYPE:-не задан}: NodePort открыл бы порт на каждом узле кластера, включая те, где пода нет"; fi
if [ -n "$(s 'spec.ports[0].nodePort')" ]
then no "задан nodePort — у внутренней службы его быть не должно"
else ok "nodePort не задан"; fi

PORT="$(s 'spec.ports[0].port')"
TPORT="$(s 'spec.ports[0].targetPort')"
PNAME="$(s 'spec.ports[0].name')"
CPORT_NAME="$(get "${TMP}/dep" 'spec.template.spec.containers[0].ports[0].name')"
CPORT_NUM="$(get "${TMP}/dep" 'spec.template.spec.containers[0].ports[0].containerPort')"

[ -n "${PORT}" ] && ok "port задан (${PORT})" || no "port не задан"
if [ "${TPORT}" = "${CPORT_NAME}" ]
then ok "targetPort указан именем порта контейнера (${TPORT}) — число живёт в одном месте"
elif [ "${TPORT}" = "${CPORT_NUM}" ]
then ok "targetPort ${TPORT} совпадает с портом контейнера"
else no "targetPort=${TPORT:-не задан}, а контейнер слушает ${CPORT_NUM} (имя «${CPORT_NAME}») — соединения пойдут в никуда"; fi
if [ -n "${PNAME}" ]
then ok "порт назван (${PNAME}) — по имени на службу подпишется Prometheus"
else no "порт без имени: подписка по имени порта — обычный способ настроить сбор метрик"; fi

echo ""
echo "── 4. ConfigMap: что в нём должно быть ──"
[ "$(c kind)" = "ConfigMap" ] && ok "kind: ConfigMap" || no "kind=$(c kind)"
[ "$(c metadata.namespace)" = "$(s metadata.namespace)" ] \
    && ok "ConfigMap в том же пространстве имён, что и служба" \
    || no "ConfigMap в «$(c metadata.namespace)», а служба в «$(s metadata.namespace)»: под увидит только свой namespace"

PLAIN="$(awk '$1=="key" && $3=="plain" {print $2}' "${APPCFG}")"
SECRET="$(awk '$1=="key" && $3=="secret" {print $2}' "${APPCFG}")"
MISSING=""; for k in ${PLAIN}; do [ -n "$(c "data.${k}")" ] || MISSING="${MISSING} ${k}"; done
if [ -z "${MISSING}" ]
then ok "все обычные настройки на месте ($(echo ${PLAIN} | wc -w | tr -d ' ') шт.)"
else no "не заданы:${MISSING}"; fi

LEAK=""; for k in ${SECRET}; do [ -z "$(c "data.${k}")" ] || LEAK="${LEAK} ${k}"; done
if [ -z "${LEAK}" ]
then ok "секретных настроек в ConfigMap нет"
else no "в ConfigMap попало секретное:${LEAK} — ConfigMap виден любому, кто может читать namespace"; fi

echo ""
echo "── 5. ConfigMap: значения ──"
BAD=""
while read -r _ k v; do
    [ -n "${k}" ] || continue
    have="$(c "data.${k}")"
    [ "${have}" = "${v}" ] || BAD="${BAD} ${k}(=${have:-пусто}, согласовано ${v})"
done < <(awk '$1=="value" {print}' "${APPCFG}")
if [ -z "${BAD}" ]
then ok "согласованные значения совпадают с тикетом"
else no "расходится с тикетом:${BAD}"; fi

# Значения ConfigMap обязаны быть строками: API-сервер отказывает нестроковым.
UNQUOTED="$(awk '
    /^data:/ {f=1; next}
    f && /^[^[:space:]]/ {f=0}
    f && /^[[:space:]]+[A-Za-z_][A-Za-z0-9_.-]*:[[:space:]]/ {
        v = $0; sub(/^[^:]*:[[:space:]]*/, "", v); sub(/[[:space:]]+#.*$/, "", v)
        k = $0; sub(/^[[:space:]]*/, "", k); sub(/:.*$/, "", k)
        if (v ~ /^-?[0-9]+$/ || v == "true" || v == "false") print k
    }' "${CM}")"
if [ -z "${UNQUOTED}" ]
then ok "все значения записаны строками"
else no "без кавычек: $(echo ${UNQUOTED} | tr '\n' ' ')— YAML прочитает их числом и логическим, а ConfigMap принимает только строки"; fi

echo ""
echo "── 6. Адрес, который выведен, а не назначен ──"
URL="$(c data.AURORA_MESH_URL)"
HOST="$(printf '%s' "${URL}" | sed -e 's|^[a-z]*://||' -e 's|/.*$||' -e 's|:.*$||')"
UPORT="$(printf '%s' "${URL}" | sed -n 's|^[a-z]*://[^:/]*:\([0-9]*\).*|\1|p')"
SVC_ROW="$(awk -v h="${HOST}" '/^[[:space:]]*#/{next} $1==h {print; exit}' "${SVCS}")"
SVC_PORT="$(printf '%s' "${SVC_ROW}" | awk '{print $5}' | sed 's|/.*||')"

if [ -z "${URL}" ]; then no "AURORA_MESH_URL не задан"
else
    if printf '%s' "${HOST}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
    then no "в адресе IP ${HOST}: адрес пода живёт до перезапуска и не разрешается по имени"
    else ok "в адресе имя, а не IP (${HOST})"; fi
    if [ -n "${SVC_ROW}" ]
    then ok "служба ${HOST} есть в кластере"
    else no "службы «${HOST}» в services.txt нет"; fi
    if [ -n "${UPORT}" ] && [ "${UPORT}" = "${SVC_PORT}" ]
    then ok "порт ${UPORT} совпадает с портом службы ${HOST}"
    else no "порт в адресе — «${UPORT:-не указан}», а служба ${HOST} слушает ${SVC_PORT:-?}"; fi
    printf '%s' "${URL}" | grep -q '^http://' && ok "схема http, как в описании настройки" \
        || no "схема в адресе «${URL}» не http"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
