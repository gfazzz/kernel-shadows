#!/usr/bin/env bash
#
# s08e08 «Очистка, которую можно доказать» — тест скрипта (Type A).
#
# Тест строит собственное дерево (tests/build_tree.sh) и проверяет три
# вещи, которых обычно нет у скриптов очистки:
#
#   1. Состояние достигнуто — не «команда выполнена», а проверено после.
#   2. Повторный прогон безопасен и честно говорит ALREADY, а не FIXED.
#   3. Законное содержимое не задето: в authorized_keys есть чужой ключ и
#      свой, и свой обязан остаться.
#
# Отдельно проверяется режим --verify: он не имеет права ничего менять и
# обязан отличать «уже чисто» от «ещё нет».
#
# Без root, без сети.
#
# Выбор скрипта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
T="${SERIES_DIR}/tests"
PLAN="${SERIES_DIR}/data/cleanup_plan.txt"

if   [ -n "${SUBJECT:-}" ];                            then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/cleanup.sh" ];      then S="${SERIES_DIR}/artifacts/cleanup.sh"
elif [ -f "${SERIES_DIR}/cleanup.sh" ];                then S="${SERIES_DIR}/cleanup.sh"
else S="${SERIES_DIR}/solution/cleanup.sh"
     echo "ℹ️  Своего cleanup.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/cleanup.sh artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e08 tests — скрипт: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${S}" ]    || { echo "  FAIL: нет ${S}"; echo " Итог: 0 passed, 1 failed"; exit 1; }
[ -f "${PLAN}" ] || { echo "  FAIL: нет ${PLAN}"; exit 1; }

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
fresh() { rm -rf "$1"; bash "${T}/build_tree.sh" "$1" dirty; }

N_PLAN=$(sed 's/#.*//' "${PLAN}" | grep -c '[a-z]' || true)

echo ""
echo "── 0. Стенд собран ──"
fresh "${TMP}/n1"
[ "${N_PLAN}" -ge 6 ] && ok "пунктов в плане: ${N_PLAN}" || no "план вырожден: ${N_PLAN} пунктов"
grep -q backup@localhost "${TMP}/n1/root/.ssh/authorized_keys" \
    && grep -q ansible@shadow-iac "${TMP}/n1/root/.ssh/authorized_keys" \
    && ok "в authorized_keys есть и чужой ключ, и свой" \
    || no "стенд вырожден: в authorized_keys не два разных ключа"
grep -q '^sysbackup:' "${TMP}/n1/etc/passwd" && ok "учётная запись sysbackup на месте" \
    || no "стенд вырожден: нечего удалять из passwd"

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
bash "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}"
bash "${S}" "${TMP}/нет" "${PLAN}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий корень — код 2" || no "несуществующий корень: код ${rc}"
bash "${S}" "${TMP}/n1" "${TMP}/нет.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий план — код 2" || no "несуществующий план: код ${rc}"

echo ""
echo "── 2. Проверка до очистки ──"
bash "${S}" --verify "${TMP}/n1" "${PLAN}" > "${TMP}/v1" 2>/dev/null; RCV=$?
[ "${RCV}" = 1 ] && ok "--verify на грязном узле возвращает 1" || no "--verify вернул ${RCV}, ожидается 1"
n_failed=$(awk '$1=="ITEM" && $2=="FAILED"' "${TMP}/v1" | grep -c . || true)
[ "${n_failed}" = "${N_PLAN}" ] && ok "все ${N_PLAN} пунктов помечены как не выполненные" \
    || no "не выполненных ${n_failed}, ожидается ${N_PLAN}"
bash "${T}/../tests/build_tree.sh" "${TMP}/ref" dirty 2>/dev/null
if diff -r "${TMP}/n1" "${TMP}/ref" >/dev/null 2>&1; then
    ok "--verify ничего не изменил"
else no "--verify изменил дерево — режим проверки обязан только читать"; fi

echo ""
echo "── 3. Очистка ──"
bash "${S}" "${TMP}/n1" "${PLAN}" > "${TMP}/o1" 2>/dev/null; RC1=$?
[ "${RC1}" = 0 ] && ok "код возврата 0" || no "код возврата ${RC1}"
n_fixed=$(awk '$1=="ITEM" && $2=="FIXED"' "${TMP}/o1" | grep -c . || true)
[ "${n_fixed}" = "${N_PLAN}" ] && ok "исправлено ${n_fixed} пунктов из ${N_PLAN}" \
    || no "исправлено ${n_fixed}, ожидается ${N_PLAN}"
sum() { awk -v k="$1" '$1=="SUMMARY" {for (i=2;i<=NF;i++) {split($i,a,"="); if (a[1]==k) print a[2]}}' "$2"; }
[ "$(sum fixed "${TMP}/o1")" = "${N_PLAN}" ] && ok "итог совпадает: fixed=${N_PLAN}" \
    || no "SUMMARY fixed=$(sum fixed "${TMP}/o1"), ожидается ${N_PLAN}"
[ "$(sum failed "${TMP}/o1")" = 0 ] && ok "failed=0" || no "failed=$(sum failed "${TMP}/o1")"

echo ""
echo "── 4. Состояние действительно достигнуто ──"
for f in etc/cron.d/apt-daily-upgrade etc/systemd/system/dbus-broker-relay.service \
         etc/profile.d/00-locale-fix.sh etc/sudoers.d/90-deploy-ci etc/ld.so.preload; do
    [ ! -e "${TMP}/n1/${f}" ] && ok "удалено: ${f}" || no "осталось: ${f}"
done
grep -q backup@localhost "${TMP}/n1/root/.ssh/authorized_keys" \
    && no "чужой ключ остался в authorized_keys" || ok "чужой ключ удалён"
grep -q '^sysbackup:' "${TMP}/n1/etc/passwd" \
    && no "учётная запись sysbackup осталась" || ok "учётная запись удалена"
grep -q dbus-relay "${TMP}/n1/etc/rc.local" \
    && no "строка в rc.local осталась" || ok "строка в rc.local удалена"

echo ""
echo "── 5. Законное не задето ──"
grep -q ansible@shadow-iac "${TMP}/n1/root/.ssh/authorized_keys" \
    && ok "свой ключ в authorized_keys остался" \
    || no "свой ключ удалён вместе с чужим — файл почищен целиком"
[ -s "${TMP}/n1/etc/rc.local" ] && grep -q 'exit 0' "${TMP}/n1/etc/rc.local" \
    && ok "rc.local остался рабочим файлом" || no "rc.local опустошён или сломан"
for f in etc/cron.d/logrotate-aurora etc/systemd/system/aurora-api.service \
         etc/profile.d/aurora-env.sh etc/sudoers.d/aurora-ops; do
    [ -e "${TMP}/n1/${f}" ] && ok "не тронуто: ${f}" || no "удалено лишнее: ${f}"
done
grep -q '^root:x:0:' "${TMP}/n1/etc/passwd" && ok "root в passwd на месте" \
    || no "из passwd удалён root — совпадение по uid вместо имени"
n_users=$(grep -c ':' "${TMP}/n1/etc/passwd")
[ "${n_users}" -ge 8 ] && ok "остальные учётные записи целы (${n_users})" \
    || no "в passwd осталось ${n_users} строк — удалено лишнее"

echo ""
echo "── 6. Повторный прогон ──"
bash "${S}" "${TMP}/n1" "${PLAN}" > "${TMP}/o2" 2>/dev/null; RC2=$?
[ "${RC2}" = 0 ] && ok "второй прогон возвращает 0" || no "второй прогон вернул ${RC2}"
[ "$(sum already "${TMP}/o2")" = "${N_PLAN}" ] \
    && ok "все пункты помечены ALREADY, а не FIXED" \
    || no "already=$(sum already "${TMP}/o2"), ожидается ${N_PLAN} — состояние спутано с действием"
[ "$(sum fixed "${TMP}/o2")" = 0 ] && ok "ничего не «исправлено» повторно" \
    || no "fixed=$(sum fixed "${TMP}/o2") на уже чистом узле"
# Состояние дерева до и после третьего прогона: содержимое каждого файла
# и список путей.
state() { ( cd "$1" && find . -type f | LC_ALL=C sort \
             && find . -type f | LC_ALL=C sort | xargs cat ) ; }
state "${TMP}/n1" > "${TMP}/st1"
bash "${S}" "${TMP}/n1" "${PLAN}" > /dev/null 2>&1
state "${TMP}/n1" > "${TMP}/st2"
cmp -s "${TMP}/st1" "${TMP}/st2" && ok "третий прогон не меняет содержимое" \
    || no "повторный прогон правит уже чистый узел"

echo ""
echo "── 7. Проверка после очистки ──"
bash "${S}" --verify "${TMP}/n1" "${PLAN}" > "${TMP}/v2" 2>/dev/null; RCV2=$?
[ "${RCV2}" = 0 ] && ok "--verify на чистом узле возвращает 0" || no "--verify вернул ${RCV2}"
[ "$(sum already "${TMP}/v2")" = "${N_PLAN}" ] && ok "и подтверждает все ${N_PLAN} пунктов" \
    || no "подтверждено $(sum already "${TMP}/v2") из ${N_PLAN}"

echo ""
echo "── 8. Воспроизводимость ──"
fresh "${TMP}/n2"
bash "${S}" "${TMP}/n2" "${PLAN}" > "${TMP}/o3" 2>/dev/null
cmp -s "${TMP}/o1" "${TMP}/o3" && ok "на одинаковых узлах — одинаковый вывод" \
    || no "вывод отличается на одинаковых деревьях"
diff -r "${TMP}/n1" "${TMP}/n2" >/dev/null 2>&1 && ok "и одинаковый результат на диске" \
    || no "деревья после очистки различаются"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
