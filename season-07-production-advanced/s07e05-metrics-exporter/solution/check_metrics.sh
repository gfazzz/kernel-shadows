#!/usr/bin/env bash
#
# check_metrics.sh — аудит выдачи /metrics (ЭТАЛОН)
#
#   check_metrics.sh <файл-выдачи> <файл-соглашений>
#
# Печатает по строке на нарушение и сводку. Код возврата: 0 — чисто,
# 1 — есть нарушения, 2 — не разобрать вход.
#
# Единственное, что здесь по-настоящему трудно, — аккуратно разобрать
# формат: имя, метки, значение, служебные строки HELP и TYPE. Всё
# остальное — шесть правил поверх разобранного.

set -uo pipefail

SRC="${1:-}"; RULES="${2:-}"
if [ -z "${SRC}" ] || [ ! -f "${SRC}" ] || [ -z "${RULES}" ] || [ ! -f "${RULES}" ]; then
    echo "usage: $(basename "$0") <файл-выдачи> <файл-соглашений>" >&2
    exit 2
fi

MAXLV=$(awk '$1=="max_label_values" {print $2; exit}' "${RULES}")
BAD_UNITS=$(awk '$1=="bad_unit" {print $2}' "${RULES}")

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT

# ── разбор выдачи ────────────────────────────────────────────────────
# help.txt  — семейства, у которых есть HELP
# type.txt  — «семейство тип»
# ser.txt   — «семейство<TAB>метки<TAB>значение» по каждому ряду
awk '
  /^#[[:space:]]+HELP[[:space:]]/ { print $3 > "'"${TMP}"'/help.txt"; next }
  /^#[[:space:]]+TYPE[[:space:]]/ { print $3, $4 > "'"${TMP}"'/type.txt"; next }
  /^[[:space:]]*#/ { next }
  /^[[:space:]]*$/ { next }
  {
      line = $0
      name = line; sub(/[{ ].*$/, "", name)
      labels = ""
      if (line ~ /\{/) { labels = line; sub(/^[^{]*\{/, "", labels); sub(/\}.*$/, "", labels) }
      value = line; sub(/^[^ ]* */, "", value)
      print name "\t" labels "\t" value > "'"${TMP}"'/ser.txt"
  }' "${SRC}"
touch "${TMP}/help.txt" "${TMP}/type.txt" "${TMP}/ser.txt"

# Семейство метрики: у гистограмм и сводок к имени приписаны суффиксы.
fam_of() { sed -e 's/_bucket$//' -e 's/_sum$//' -e 's/_count$//' <<<"$1"; }

FAMS="$(cut -f1 "${TMP}/ser.txt" | while read -r n; do fam_of "${n}"; done | sort -u)"
N_SER=$(grep -c . "${TMP}/ser.txt" || true)
N_FAM=$(grep -c . <<<"${FAMS}" || true)

ISSUES=0
issue() { echo "ISSUE $1 $2 $3"; ISSUES=$((ISSUES+1)); }

for fam in ${FAMS}; do
    type=$(awk -v f="${fam}" '$1==f {print $2; exit}' "${TMP}/type.txt")

    # 1. HELP: строка, ради которой метрику вообще можно понять через год.
    grep -qxF "${fam}" "${TMP}/help.txt" || issue no-help "${fam}" "нет строки HELP"

    # 2. TYPE: без него Prometheus считает метрику untyped, и rate() по ней
    #    молча даёт бессмыслицу.
    if [ -z "${type}" ]; then issue no-type "${fam}" "нет строки TYPE"; fi

    # 3. Единица в имени — только базовая.
    suffix="${fam##*_}"
    for bad in ${BAD_UNITS}; do
        if [ "${suffix}" = "${bad}" ]; then
            issue unit "${fam}" "единица «${bad}»: хранить надо в базовых"
            break
        fi
    done

    # 4. Счётчик обязан оканчиваться на _total.
    if [ "${type}" = counter ] && [ "${fam%_total}" = "${fam}" ]; then
        issue counter-suffix "${fam}" "тип counter, а имя не оканчивается на _total"
    fi

    # 5. Гистограмма без корзины +Inf неполна, и её +Inf обязан совпадать
    #    с _count: это одно и то же число, посчитанное дважды.
    if [ "${type}" = histogram ]; then
        inf=$(awk -F'\t' -v f="${fam}_bucket" '$1==f && $2 ~ /le="\+Inf"/ {print $3; exit}' "${TMP}/ser.txt")
        cnt=$(awk -F'\t' -v f="${fam}_count" '$1==f {print $3; exit}' "${TMP}/ser.txt")
        sum=$(awk -F'\t' -v f="${fam}_sum"   '$1==f {print $3; exit}' "${TMP}/ser.txt")
        if   [ -z "${inf}" ]; then issue histogram "${fam}" "нет корзины le=\"+Inf\""
        elif [ -z "${cnt}" ] || [ -z "${sum}" ]; then issue histogram "${fam}" "нет _sum или _count"
        elif [ "${inf}" != "${cnt}" ]; then issue histogram "${fam}" "+Inf=${inf}, а _count=${cnt}"
        fi
    fi

    # 6. Кардинальность: метка, у которой слишком много разных значений.
    #    le и quantile не считаются — их набор задан самим определением.
    worst=$(awk -F'\t' -v f="${fam}" '
        { n=$1; sub(/_bucket$|_sum$|_count$/, "", n); if (n != f) next
          s=$2
          while (match(s, /[a-zA-Z_][a-zA-Z0-9_]*="[^"]*"/)) {
              p = substr(s, RSTART, RLENGTH); s = substr(s, RSTART+RLENGTH)
              k = p; sub(/=.*$/, "", k)
              if (k == "le" || k == "quantile") continue
              if (!((k SUBSEP p) in seen)) { seen[k SUBSEP p]; cnt[k]++ }
          } }
        END { for (k in cnt) if (cnt[k] > best) { best = cnt[k]; bk = k }
              if (bk != "") print bk " " best }' "${TMP}/ser.txt")
    if [ -n "${worst}" ]; then
        set -- ${worst}
        if [ "$2" -gt "${MAXLV}" ]; then
            issue cardinality "${fam}" "у метки «$1» $2 разных значений при пороге ${MAXLV}"
        fi
    fi
done

echo "SUMMARY ${ISSUES} issues, ${N_FAM} metrics, ${N_SER} series"
[ "${ISSUES}" -gt 0 ] && exit 1
exit 0
