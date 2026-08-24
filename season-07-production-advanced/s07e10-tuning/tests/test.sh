#!/usr/bin/env bash
#
# s07e10 «Каждой строке — измерение» — тест конфигурации (Type B).
#
# Проверяются свойства файла настройки: существует ли параметр в ядре,
# есть ли у него обоснование со ссылкой на измерение, удовлетворяет ли
# значение правилу, выведенному из этого измерения, не осталось ли в
# файле параметров из списка вредных и не выставлен ли какой-нибудь в то
# же значение, что уже действует.
#
# Пороги и правила берутся из data/: measurements.txt, requirements.txt,
# harmful.txt, allowed.txt, current_sysctl.txt. Констант в тесте нет.
#
# Без root, без сети, без применения sysctl.
#
# Выбор файла: SUBJECT=... | artifacts/tuning.conf | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
MEAS="${D}/measurements.txt"; REQ="${D}/requirements.txt"
HARM="${D}/harmful.txt"; ALLOW="${D}/allowed.txt"
CUR="${D}/current_sysctl.txt"; CARGO="${D}/cargo_cult.conf"

if   [ -n "${SUBJECT:-}" ];                          then C="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/tuning.conf" ];   then C="${SERIES_DIR}/artifacts/tuning.conf"
elif [ -f "${SERIES_DIR}/tuning.conf" ];             then C="${SERIES_DIR}/tuning.conf"
else C="${SERIES_DIR}/solution/tuning.conf"
     echo "ℹ️  Своего tuning.conf не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/tuning.conf artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e10 tests — настройка: ${C#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${MEAS}" "${REQ}" "${HARM}" "${ALLOW}" "${CUR}" "${CARGO}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${C}" ]; then ok "tuning.conf найден"
else no "tuning.conf не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── разбор файла: «параметр<TAB>значение<TAB>обоснование» ────────────
# Обоснование — все комментарии, стоящие непосредственно над строкой.
awk '
  /^[[:space:]]*#/ { just = just " " $0; next }
  /^[[:space:]]*$/ { just = ""; next }
  /=/ {
      k = $0; sub(/[[:space:]]*=.*$/, "", k); gsub(/^[[:space:]]+/, "", k)
      v = $0; sub(/^[^=]*=[[:space:]]*/, "", v); sub(/[[:space:]]*$/, "", v)
      print k "\t" v "\t" just
      just = ""
  }' "${C}" > "${TMP}/params"

m()   { awk -v k="$1" '/^[[:space:]]*#/{next} $1==k {print $3; exit}' "${MEAS}"; }
cur() { awk -v k="$1" '/^[[:space:]]*#/{next} $1==k {print $3; exit}' "${CUR}"; }
val() { awk -F'\t' -v k="$1" '$1==k {print $2; exit}' "${TMP}/params"; }
jus() { awk -F'\t' -v k="$1" '$1==k {print $3; exit}' "${TMP}/params"; }

N_PARAMS=$(grep -c . "${TMP}/params" || true)
MEAS_IDS="$(awk '/^[[:space:]]*#/{next} $1 ~ /^M[0-9]+$/ {print $1}' "${MEAS}")"

echo ""
echo "── Исходные данные ──"
N_TUNE=$(awk '/^[[:space:]]*#/{next} $4=="tune"' "${MEAS}" | grep -c . || true)
if [ "${N_TUNE}" -ge 3 ]
then ok "измерений, требующих изменения: ${N_TUNE}"
else no "данные вырождены: чинить нечего (${N_TUNE})"; fi
N_HARM=$(awk -F'\t' '/^[[:space:]]*#/{next} NF==2' "${HARM}" | grep -c . || true)
N_CARGO_BAD=0
while IFS=$'\t' read -r h _; do
    [ -n "${h}" ] || continue
    grep -qE "^[[:space:]]*${h}[[:space:]]*=" "${CARGO}" && N_CARGO_BAD=$((N_CARGO_BAD+1))
done < <(awk -F'\t' '/^[[:space:]]*#/{next} NF==2' "${HARM}")
if [ "${N_CARGO_BAD}" -ge 4 ]
then ok "в файле из блога ${N_CARGO_BAD} вредных параметров из ${N_HARM} известных"
else no "данные вырождены: пример из блога не демонстрирует проблему"; fi
if grep -qE '^[[:space:]]*net\.ipv4\.tcp_tw_recycle' "${CARGO}" \
   && ! grep -qx 'net.ipv4.tcp_tw_recycle' "${ALLOW}"
then ok "в примере есть параметр, которого в ядре вообще нет"
else no "данные вырождены: несуществующего параметра в примере нет"; fi

echo ""
echo "── 1. Форма ──"
if [ "${N_PARAMS}" -gt 0 ]; then ok "разобрано параметров: ${N_PARAMS}"
else no "не нашлось ни одной строки вида «параметр = значение»"; fi

echo ""
echo "── 2. Параметры существуют ──"
UNKNOWN=""
while IFS=$'\t' read -r k _ _; do
    grep -qx "${k}" "${ALLOW}" || UNKNOWN="${UNKNOWN} ${k}"
done < "${TMP}/params"
[ -z "${UNKNOWN}" ] && ok "все параметры есть в ядре" \
    || no "в ядре нет:${UNKNOWN} — sysctl откажет, а systemd-sysctl молча поедет дальше"

echo ""
echo "── 3. У каждой строки есть измерение ──"
NOJUST=""
for k in $(cut -f1 "${TMP}/params"); do
    found=""
    for id in ${MEAS_IDS}; do
        case " $(jus "${k}") " in *" ${id}"*|*"${id}:"*|*"${id},"*|*"(${id}"*) found=1; break ;; esac
    done
    [ -n "${found}" ] || NOJUST="${NOJUST} ${k}"
done
[ -z "${NOJUST}" ] && ok "у каждого параметра в обосновании есть ссылка на измерение" \
    || no "без ссылки на измерение:${NOJUST} — через год никто не вспомнит, зачем строка и можно ли её убрать"

echo ""
echo "── 4. Вредное и бесполезное ──"
BAD=""
while IFS=$'\t' read -r h why; do
    [ -n "${h}" ] || continue
    [ -n "$(val "${h}")" ] && BAD="${BAD}
        ${h} — ${why}"
done < <(awk -F'\t' '/^[[:space:]]*#/{next} NF==2' "${HARM}")
[ -z "${BAD}" ] && ok "параметров из списка вредных нет" \
    || { no "в файле остались параметры, которые кочуют из статьи в статью:"; printf '%s\n' "${BAD}"; }

NOOP=""
while IFS=$'\t' read -r k v _; do
    [ "$(cur "${k}")" = "${v}" ] && NOOP="${NOOP} ${k}"
done < "${TMP}/params"
[ -z "${NOOP}" ] && ok "ни один параметр не выставлен в уже действующее значение" \
    || no "выставлены в то же, что уже есть:${NOOP} — строка есть, эффекта нет"

echo ""
echo "── 5. Значения выведены из измерений ──"
while read -r _ param addr rule; do
    param="${param}"; addr="${addr#addresses=}"; rule="${rule#rule=}"
    have="$(val "${param}")"
    if [ -z "${have}" ]; then
        no "${param} не задан, хотя ${addr} требует изменения"
        continue
    fi
    # rule вида >=K*Mn
    mult="${rule#>=}"; mult="${mult%%\**}"
    src="${rule##*\*}"
    base="$(m "${src}")"
    need=$(( mult * base ))
    if [ "${have}" -ge "${need}" ]
    then ok "${param} = ${have} ≥ ${mult} × ${src}(${base}) = ${need}"
    else no "${param} = ${have}, а из ${src} (${base}) следует не меньше ${need}"; fi
    case " $(jus "${param}") " in *" ${addr}"*|*"${addr}:"*|*"${addr},"*|*"(${addr}"*)
        ok "  обоснование ссылается на ${addr}" ;;
      *) no "  обоснование не ссылается на ${addr} — на что тогда опирается значение?" ;;
    esac
done < <(awk '$1=="param"' "${REQ}")

echo ""
echo "── 6. Ничего лишнего ──"
EXTRA=""
for k in $(cut -f1 "${TMP}/params"); do
    awk -v p="${k}" '$1=="param" && $2==p {f=1} END{exit !f}' "${REQ}" || EXTRA="${EXTRA} ${k}"
done
if [ -z "${EXTRA}" ]
then ok "в файле только то, что закрывает измерения"
else no "параметров без требования:${EXTRA} — каждый лишний придётся объяснять при следующем разборе"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
