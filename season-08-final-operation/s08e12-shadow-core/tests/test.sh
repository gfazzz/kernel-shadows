#!/usr/bin/env bash
#
# s08e12 «Приёмка shadow_core» — тест капстоуна (Type D), финал курса.
#
# Проверяет не текст, а поведение приёмочного прогона: что все двенадцать
# фаз проходят на исправном состоянии, что КАЖДАЯ фаза действительно ловит
# свою поломку (тест ломает состояние по одной фазе и ждёт ровно один
# провал), что порядок фаз фиксирован и что код возврата связан с итогом.
#
# Тест строит состояние во временном каталоге из data/state, поэтому
# подгонка под конкретные файлы не проходит: ломается копия.
#
# Без root, без сети. Нужен python3.
#
# Выбор программы: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PLAN="${SERIES_DIR}/data/acceptance.txt"
STATE0="${SERIES_DIR}/data/state"

if   [ -n "${SUBJECT:-}" ];                              then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/shadow_core.py" ];    then S="${SERIES_DIR}/artifacts/shadow_core.py"
elif [ -f "${SERIES_DIR}/shadow_core.py" ];              then S="${SERIES_DIR}/shadow_core.py"
else S="${SERIES_DIR}/solution/shadow_core.py"
     echo "ℹ️  Своего shadow_core.py не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/shadow_core.py artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e12 tests — приёмка: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

PY="$(command -v python3 || true)"
if [ -z "${PY}" ]; then
    echo "  SKIP: не найден python3 — капстоун Type D требует Python 3.8+"
    echo " Итог: 0 passed, 0 failed"; exit 0
fi
ok "python3 найден ($("${PY}" -c 'import sys; print(".".join(map(str,sys.version_info[:3])))'))"
[ -f "${S}" ]    || { no "нет ${S}"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; }
[ -f "${PLAN}" ] || { no "нет ${PLAN}"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
ST="${TMP}/state"
seed() { rm -rf "${ST}"; cp -r "${STATE0}" "${ST}"; }

N_PHASES=$(grep -cE '^phase ' "${PLAN}")

echo ""
echo "── 0. План ──"
[ "${N_PHASES}" -ge 10 ] && ok "фаз в плане: ${N_PHASES}" || no "фаз всего ${N_PHASES}"

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
"${PY}" "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}"
"${PY}" "${S}" "${PLAN}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "с одним аргументом — код 2" || no "с одним аргументом вернул ${rc}"
"${PY}" "${S}" "${PLAN}" "${TMP}/нет" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующее состояние — код 2" || no "несуществующее состояние: код ${rc}"

echo ""
echo "── 2. Исправная инфраструктура ──"
seed
"${PY}" "${S}" "${PLAN}" "${ST}" > "${TMP}/out" 2>"${TMP}/err"; RC=$?
[ "${RC}" = 0 ] && ok "прогон вернул 0" || no "прогон вернул ${RC} на исправном состоянии"
n_pass=$(awk '$1=="PHASE" && $4=="pass"' "${TMP}/out" | grep -c . || true)
[ "${n_pass}" = "${N_PHASES}" ] && ok "все ${N_PHASES} фаз прошли" \
    || no "прошло ${n_pass} из ${N_PHASES}: $(awk '$1=="PHASE" && $4=="FAIL"{print $2}' "${TMP}/out" | tr '\n' ' ')"
awk '$1=="SUMMARY"' "${TMP}/out" | grep -q "failed=0" && ok "итог: failed=0" || no "итог не failed=0"
[ -s "${TMP}/err" ] && no "пишет в stderr при успехе" || ok "stderr пуст"

echo ""
echo "── 3. Порядок фаз фиксирован ──"
awk '$1=="PHASE" {print $2}' "${TMP}/out" > "${TMP}/order"
LC_ALL=C sort -c -n "${TMP}/order" 2>/dev/null && ok "фазы идут по возрастанию номера" \
    || no "порядок фаз не фиксирован — финал читается как одна операция"

echo ""
echo "── 4. Каждая фаза ловит свою поломку ──"
# Ломаем состояние ровно под одну фазу и ждём ровно один провал — именно её.
break_phase() { # $1 — номер фазы; печатает, что сломать
    local n="$1"
    local line; line="$(awk -v n="$n" '$1=="phase" && $2==n' "${PLAN}")"
    [ -n "${line}" ] || return 1
    local kind; kind="$(echo "${line}" | awk '{print $4}')"
    local a1; a1="$(echo "${line}" | awk '{print $5}')"
    case "${kind}" in
        present) rm -f "${ST}/${a1}" ;;
        absent)  : > "${ST}/${a1}" ;;                       # создаём то, чего быть не должно
        kv)      local key; key="$(echo "${line}" | awk '{print $6}')"
                 sed -i "s/^${key} .*/${key} СЛОМАНО/" "${ST}/${a1}" 2>/dev/null || echo "${key} СЛОМАНО" >> "${ST}/${a1}" ;;
        max)     local key; key="$(echo "${line}" | awk '{print $6}')"
                 sed -i "s/^${key} .*/${key} 999999/" "${ST}/${a1}" ;;
        min)     local key; key="$(echo "${line}" | awk '{print $6}')"
                 sed -i "s/^${key} .*/${key} 0/" "${ST}/${a1}" ;;
        same)    local a2; a2="$(echo "${line}" | awk '{print $6}')"
                 echo "лишняя-строка-руткита" >> "${ST}/${a1}" ;;
        subset)  local a2; a2="$(echo "${line}" | awk '{print $6}')"
                 echo "8.8.8.8" >> "${ST}/${a1}" ;;         # действие вне ордера
    esac
}

all_caught=yes
for n in $(awk '$1=="phase" {print $2}' "${PLAN}" | sort -n); do
    seed
    break_phase "${n}" || { no "не удалось сломать фазу ${n}"; all_caught=no; continue; }
    "${PY}" "${S}" "${PLAN}" "${ST}" > "${TMP}/o" 2>/dev/null; rc=$?
    fails="$(awk '$1=="PHASE" && $4=="FAIL" {print $2}' "${TMP}/o" | tr '\n' ' ')"
    fails_trim="$(echo ${fails})"
    if [ "${fails_trim}" = "${n}" ] && [ "${rc}" = 1 ]; then
        :  # ровно эта фаза, код 1 — как надо
    else
        no "поломка фазы ${n}: провалились «${fails_trim}», код ${rc} (ждали «${n}», код 1)"
        all_caught=no
    fi
done
[ "${all_caught}" = yes ] && ok "каждая из ${N_PHASES} фаз ловит ровно свою поломку и роняет прогон"

echo ""
echo "── 5. Один провал роняет всю приёмку ──"
seed; break_phase 7
"${PY}" "${S}" "${PLAN}" "${ST}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 1 ] && ok "один провал → код возврата 1" || no "код возврата ${rc} при одной проваленной фазе"

echo ""
echo "── 6. Воспроизводимость ──"
seed
"${PY}" "${S}" "${PLAN}" "${ST}" > "${TMP}/r1" 2>/dev/null
"${PY}" "${S}" "${PLAN}" "${ST}" > "${TMP}/r2" 2>/dev/null
cmp -s "${TMP}/r1" "${TMP}/r2" && ok "два прогона дают один вывод" || no "вывод меняется между прогонами"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
