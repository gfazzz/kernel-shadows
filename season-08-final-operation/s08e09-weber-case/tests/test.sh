#!/usr/bin/env bash
#
# s08e09 «Обвинение без доказательства» — тест разбора (Type C).
#
# Каждое значение пересчитывается из источников в data/. Констант нет:
# поменяются журналы — поменяются ожидания.
#
# Отдельно проверяется, что данные не выродились: что вход по VPN
# действительно попадает в интервал перелёта, что ключ из сессии
# действительно общий, что через турникет прошло больше одного человека,
# и что доступ к репозиторию был не у одного человека. Без этого разбор
# сводился бы к чтению одной строки.
#
# Без root, без сети.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"

if   [ -n "${SUBJECT:-}" ];                             then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/weber_case.txt" ];   then REP="${SERIES_DIR}/artifacts/weber_case.txt"
elif [ -f "${SERIES_DIR}/weber_case.txt" ];             then REP="${SERIES_DIR}/weber_case.txt"
else REP="${SERIES_DIR}/solution/weber_case.txt"
     echo "ℹ️  Своего weber_case.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/weber_case.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e09 tests — разбор: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in claims.txt vpn.log travel.txt key_inventory.txt ssh_sessions.txt \
         commits.txt badge.txt access_list.txt; do
    [ -f "${D}/${f}" ] || { echo "  FAIL: нет ${D}/${f}"; exit 1; }
done
[ -f "${REP}" ] || { echo "  FAIL: нет ${REP}"; echo " Итог: 0 passed, 1 failed"; exit 1; }

val() { awk -F= -v k="$1" '{sub(/#.*/,"")} $1==k {gsub(/[ \t\r]/,"",$2); print $2; exit}' "${REP}"; }
check() { got="$(val "$1")"; [ "${got}" = "$2" ] && ok "$1=$2${3:+ — $3}" \
          || no "$1=${got:-пусто}, ожидается $2${3:+ — $3}"; }

# ── величины, пересчитанные из источников ────────────────────────────
# Ночной вход: самая ранняя запись VPN под учётной записью Вебера.
VPN_T="$(awk '{sub(/#.*/,"")} $2=="m.weber" {print $1; exit}' "${D}/vpn.log")"
read -r FL_DEP FL_ARR <<<"$(awk '{sub(/#.*/,"")} $1=="m.weber" {print $4, $5; exit}' "${D}/travel.txt")"
IN_FLIGHT=no
[[ "${VPN_T}" > "${FL_DEP}" && "${VPN_T}" < "${FL_ARR}" ]] && IN_FLIGHT=yes

# Ключ из сессии на узле, где появилось закрепление.
FP="$(awk '{sub(/#.*/,"")} $2=="zurich-app3" {print $4; exit}' "${D}/ssh_sessions.txt")"
KEY_OWNER="$(awk -v f="${FP}" '{sub(/#.*/,"")} $1==f {print $2; exit}' "${D}/key_inventory.txt")"
KEY_PEOPLE="$(awk -v f="${FP}" '{sub(/#.*/,"")} $1==f {print $3; exit}' "${D}/key_inventory.txt")"

# Коммит, автором которого значится Вебер.
read -r C_SIGNED C_COMMITTER <<<"$(awk '{sub(/#.*/,"")} $2 ~ /weber/ {print $3, $4; exit}' "${D}/commits.txt")"

# Проход по пропуску Вебера: сколько людей прошло за одно прикладывание.
PASSED="$(awk '{sub(/#.*/,"")} $3=="m.weber" {if ($5+0>m) m=$5+0} END {print m+0}' "${D}/badge.txt")"

# Доступ к репозиторию: сколько людей, не считая служебных записей.
ACCESS="$(awk '{sub(/#.*/,"")} NF==2 && $2!="automation" {n++} END {print n+0}' "${D}/access_list.txt")"

echo ""
echo "── 0. Данные не выродились ──"
[ "${IN_FLIGHT}" = yes ] && ok "ночной вход попадает в интервал перелёта" \
    || no "данные вырождены: вход ${VPN_T} вне интервала ${FL_DEP}…${FL_ARR}"
[ "${KEY_PEOPLE}" -gt 1 ] && ok "ключ из сессии общий: доступ у ${KEY_PEOPLE} человек" \
    || no "данные вырождены: ключ личный, довод было бы нечем опровергать"
[ "${PASSED}" -gt 1 ] && ok "через турникет прошло ${PASSED} человека по одному пропуску" \
    || no "данные вырождены: по пропуску прошёл один"
[ "${ACCESS}" -gt 5 ] && ok "доступ к репозиторию был у ${ACCESS} человек" \
    || no "данные вырождены: доступ у ${ACCESS}"
[ "${C_SIGNED}" = no ] && ok "коммит не подписан — авторство ничем не подтверждено" \
    || no "данные вырождены: коммит подписан"

echo ""
echo "── 1. Довод 1: вход по VPN ──"
check claim1_person_in_flight "${IN_FLIGHT}" "в момент входа он был в воздухе"
check claim1_checked_by       travel
check claim1_shows            account "журнал знает учётную запись, а не человека"
check claim1_verdict          refutes

echo ""
echo "── 2. Довод 2: ключ SSH ──"
check claim2_key_owner        "${KEY_OWNER}"
check claim2_people_with_access "${KEY_PEOPLE}"
check claim2_checked_by       key_inventory
check claim2_verdict          refutes "ключ не его"

echo ""
echo "── 3. Довод 3: коммит ──"
check claim3_signed           "${C_SIGNED}"
check claim3_committer        "${C_COMMITTER}"
check claim3_checked_by       commits
check claim3_verdict          inconclusive "поле автора заполняет отправитель"

echo ""
echo "── 4. Довод 4: пропуск ──"
check claim4_people_passed    "${PASSED}"
check claim4_shows            door "система фиксирует дверь, а не человека"
check claim4_checked_by       badge
check claim4_verdict          inconclusive

echo ""
echo "── 5. Довод 5: «знал только он» ──"
check claim5_people_with_access "${ACCESS}"
check claim5_checked_by       access_list
check claim5_verdict          refutes "утверждение об исключительности неверно"

echo ""
echo "── 6. Итог ──"
E_REF=0; E_INC=0; E_SUP=0
for i in 1 2 3 4 5; do
    case "$(val "claim${i}_verdict")" in
        refutes)      E_REF=$((E_REF+1)) ;;
        inconclusive) E_INC=$((E_INC+1)) ;;
        supports)     E_SUP=$((E_SUP+1)) ;;
    esac
done
check refuted_count      "${E_REF}" "совпадает с приговорами выше"
check inconclusive_count "${E_INC}"
check supporting_count   "${E_SUP}"
check verdict            insufficient
check named_suspect      none "назвать человека по этим данным нельзя"
check all_claims_point_at account
check missing_link       second-factor "предмет связывает с человеком второй фактор"

echo ""
echo "── 7. Форма ──"
grep -q '^#' "${REP}" && ok "комментарии сохранены" || no "комментарии удалены"
if grep -qE '^[a-z0-9_]+= *$' "${REP}"; then
    no "есть незаполненные ключи: $(grep -cE '^[a-z0-9_]+= *$' "${REP}")"
else ok "незаполненных ключей нет"; fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
