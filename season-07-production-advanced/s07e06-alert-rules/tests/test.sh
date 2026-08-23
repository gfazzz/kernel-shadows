#!/usr/bin/env bash
#
# s07e06 «Правила, по которым будят» — тест конфигурации (Type B).
#
# Проверяются свойства правил, а не их текст: есть ли обязательные
# оповещения, соответствует ли выдержка разбору происшествий, не короче ли
# окно rate() четырёх периодов сбора, существуют ли метрики, на которые
# ссылаются выражения, и делятся ли числитель со знаменателем на одном
# окне.
#
# Все пороги и выдержки берутся из data/: incidents.txt, scrape.txt,
# required_alerts.txt. Констант в тесте нет.
#
# Без root, без сети, без Prometheus и promtool.
#
# Выбор файла: SUBJECT=... | artifacts/rules.yml | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
INC="${D}/incidents.txt"; REQ="${D}/required_alerts.txt"
SCR="${D}/scrape.txt"; AVAIL="${D}/metrics_available.txt"
KW="${D}/promql_keywords.txt"; CUR="${D}/current_rules.yml"

if   [ -n "${SUBJECT:-}" ];                        then R="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/rules.yml" ];   then R="${SERIES_DIR}/artifacts/rules.yml"
elif [ -f "${SERIES_DIR}/rules.yml" ];             then R="${SERIES_DIR}/rules.yml"
else R="${SERIES_DIR}/solution/rules.yml"
     echo "ℹ️  Своего rules.yml не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/rules.yml artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e06 tests — правила: ${R#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${INC}" "${REQ}" "${SCR}" "${AVAIL}" "${KW}" "${CUR}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${R}" ]; then ok "rules.yml найден"
else no "rules.yml не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

cat > "${TMP}/flat.awk" <<'AWK'
{
    line = $0
    sub(/\r$/, "", line)
    if (line ~ /^[[:space:]]*#/) next
    if (line ~ /^[[:space:]]*$/) next
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
awk -f "${TMP}/flat.awk" "${R}" > "${TMP}/f"

g() { awk -F= -v k="$1" '$1==k {sub(/^[^=]*=/,""); print; exit}' "${TMP}/f"; }
# Путь до правила с данным именем: groups[i].rules[j]
path_of() { awk -F= -v n="$1" '$2==n && $1 ~ /\.alert$/ {p=$1; sub(/\.alert$/,"",p); print p; exit}' "${TMP}/f"; }

v() { awk -v k="$1" '/^[[:space:]]*#/{next} $1==k {print $2; exit}' "${INC}"; }
dur_s() { awk -v d="$1" 'BEGIN{ n=d; sub(/[a-z]$/,"",n); n+=0
    if      (d ~ /s$/) print n
    else if (d ~ /m$/) print n*60
    else if (d ~ /h$/) print n*3600
    else if (d ~ /d$/) print n*86400
    else print 0 }'; }

SCRAPE=$(awk '$1=="scrape_interval:" {print $2; exit}' "${SCR}")
SCRAPE_S=$(dur_s "${SCRAPE}")
MIN_WIN=$(( SCRAPE_S * 4 ))
KEYWORDS=" $(grep -v '^[[:space:]]*#' "${KW}" | tr '\n' ' ') "
METRICS=" $(awk '/^[[:space:]]*#/{next} NF>=1 {print $1}' "${AVAIL}" | tr '\n' ' ') "

echo ""
echo "── Исходные данные ──"
NORM=$(v error_ratio_normal); INCV=$(v error_ratio_incident); THR=$(v threshold_error_ratio)
if awk -v a="${NORM}" -v b="${THR}" -v c="${INCV}" 'BEGIN{exit !(a<b && b<c)}'
then ok "порог доли ошибок ${THR} лежит между обычными ${NORM} и аварийными ${INCV}"
else no "данные вырождены: порог не между обычным и аварийным значением"; fi
N_REQ=$(awk '$1=="alert"' "${REQ}" | grep -c . || true)
if [ "${N_REQ}" -ge 5 ]; then ok "обязательных оповещений: ${N_REQ}"
else no "в required_alerts.txt всего ${N_REQ} правил"; fi
if [ "$(awk '$1=="alert"' "${REQ}" | grep -c 'severity=page'   || true)" -gt 0 ] \
   && [ "$(awk '$1=="alert"' "${REQ}" | grep -c 'severity=ticket' || true)" -gt 0 ]
then ok "в требованиях есть и page, и ticket"
else no "данные вырождены: все требования одной важности"; fi
if grep -q 'severity: page' "${CUR}" && ! grep -q 'for:' "${CUR}"
then ok "в нынешних правилах ни одной выдержки — вот откуда 74 срабатывания"
else no "данные вырождены: нынешние правила не демонстрируют проблему"; fi

echo ""
echo "── 1. Группа ──"
[ -n "$(g 'groups[0].name')" ] && ok "группа названа: $(g 'groups[0].name')" || no "у группы нет имени"
INTV="$(g 'groups[0].interval')"
if [ -n "${INTV}" ] && [ "$(dur_s "${INTV}")" -gt 0 ]
then ok "период вычисления задан (${INTV})"
else no "не задан interval группы: правила будут считаться с общим evaluation_interval, и это стоит написать явно"; fi

# ── правила по требованиям ───────────────────────────────────────────
while read -r _ name sev minfor metric thr; do
    [ -n "${name}" ] || continue
    sev="${sev#severity=}"; minfor="${minfor#min_for=}"
    metric="${metric#metric=}"; thr="${thr#threshold=}"
    echo ""
    echo "── ${name} ──"
    p="$(path_of "${name}")"
    if [ -z "${p}" ]; then no "правила ${name} нет — происшествие такого рода снова заметит пользователь"; continue; fi
    ok "правило есть"

    expr="$(g "${p}.expr")"
    [ -n "${expr}" ] && ok "expr задан" || no "expr пуст"

    f="$(g "${p}.for")"
    need=$(dur_s "$(v "${minfor}")")
    if [ -z "${f}" ]; then
        no "нет for: правило сработает на первой же выборке, и в это время человека будят"
    elif [ "$(dur_s "${f}")" -ge "${need}" ]; then
        ok "выдержка ${f} не меньше согласованных $(v "${minfor}")"
    else
        no "выдержка ${f} меньше согласованных $(v "${minfor}") — всплеск в одну выборку разбудит человека"
    fi

    have_sev="$(g "${p}.labels.severity")"
    [ "${have_sev}" = "${sev}" ] && ok "важность ${sev}" \
        || no "важность «${have_sev}», по разбору происшествий ${sev}"

    [ -n "$(g "${p}.annotations.summary")" ] && ok "summary есть" || no "нет annotations.summary"
    descr="$(g "${p}.annotations.description")"
    if [ -z "${descr}" ]; then no "нет annotations.description"
    elif printf '%s' "${descr}" | grep -q '{{'
    then ok "в описании есть подстановка — дежурный увидит числа, а не текст"
    else no "описание без подстановки: «${descr}» одинаково для любого значения"; fi

    case "${expr}" in *"${metric}"*) ok "опирается на ${metric}" ;;
        *) no "не ссылается на ${metric} — на чём тогда основано условие?" ;; esac

    if [ "${thr}" != "-" ]; then
        want="$(v "${thr}")"
        case "${expr}" in *"${want}"*) ok "порог ${want} на месте" ;;
            *) no "порога ${want} в выражении нет: он согласован тикетом AUR-503" ;; esac
    fi
done < <(awk '$1=="alert"' "${REQ}")

echo ""
echo "── 2. Окна rate() ──"
WINDOWS="$(awk -F= '$1 ~ /\.expr$/ {sub(/^[^=]*=/,""); while (match($0, /\[[0-9]+[smhd]\]/)) {
              w=substr($0, RSTART+1, RLENGTH-2); print w; $0=substr($0, RSTART+RLENGTH) }}' "${TMP}/f")"
BAD=""
for w in ${WINDOWS}; do [ "$(dur_s "${w}")" -ge "${MIN_WIN}" ] || BAD="${BAD} ${w}"; done
if [ -z "${BAD}" ]
then ok "все окна не короче четырёх периодов сбора (${SCRAPE} × 4 = ${MIN_WIN}s)"
else no "окна короче ${MIN_WIN}s:${BAD} — одна пропущенная выборка оставит rate() без данных, и правило промолчит"; fi

# Числитель и знаменатель доли обязаны считаться на одном окне.
RATIO_EXPR="$(g "$(path_of AuroraHighErrorRate).expr")"
RW="$(printf '%s' "${RATIO_EXPR}" | grep -o '\[[0-9]*[smhd]\]' | sort -u | grep -c . || true)"
if [ "${RW}" = "1" ]
then ok "доля ошибок считается на одном окне в числителе и знаменателе"
else no "в выражении доли ${RW} разных окон: делятся величины из разных отрезков времени"; fi

echo ""
echo "── 3. Метрики, которых нет ──"
# Из выражения сначала выбрасываются строковые значения меток ("aurora-api")
# и длительности ([5m]) — иначе в имена метрик попадут их куски.
IDENT="$(awk -F= '$1 ~ /\.expr$/ {sub(/^[^=]*=/,""); e=$0
          gsub(/"[^"]*"/, " ", e); gsub(/\[[0-9]+[smhd]\]/, " ", e)
          while (match(e, /[a-zA-Z_][a-zA-Z0-9_]*/)) {
              print substr(e, RSTART, RLENGTH); e = substr(e, RSTART+RLENGTH) }}' "${TMP}/f" | sort -u)"
UNKNOWN=""
for id in ${IDENT}; do
    case "${KEYWORDS}" in *" ${id} "*) continue ;; esac
    case "${METRICS}"  in *" ${id} "*) continue ;; esac
    # метки внутри селектора — не метрики
    case "${id}" in code|job|namespace|le|instance|pod|container|severity) continue ;; esac
    UNKNOWN="${UNKNOWN} ${id}"
done
if [ -z "${UNKNOWN}" ]
then ok "все имена в выражениях существуют в хранилище"
else no "имён нет в metrics_available.txt:${UNKNOWN} — PromQL вернёт пусто, и правило не сработает никогда"; fi

echo ""
echo "── 4. Общие свойства всех правил ──"
ALL="$(awk -F= '$1 ~ /\.alert$/ {print $2}' "${TMP}/f")"
N_ALL=$(grep -c . <<<"${ALL}" || true)
NOFOR=""
for a in ${ALL}; do [ -n "$(g "$(path_of "${a}").for")" ] || NOFOR="${NOFOR} ${a}"; done
[ -z "${NOFOR}" ] && ok "у всех ${N_ALL} правил задана выдержка" \
    || no "без выдержки:${NOFOR}"
PAGES="$(for a in ${ALL}; do [ "$(g "$(path_of "${a}").labels.severity")" = page ] && echo "${a}"; done)"
REQ_PAGES="$(awk '$1=="alert" && /severity=page/ {print $2}' "${REQ}" | sort)"
if [ "$(sort <<<"${PAGES}")" = "${REQ_PAGES}" ]
then ok "будят ровно по симптомам: $(tr '\n' ' ' <<<"${REQ_PAGES}")"
else no "ночью будят: $(tr '\n' ' ' <<<"${PAGES}") — а по разбору происшествий это $(tr '\n' ' ' <<<"${REQ_PAGES}")"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
