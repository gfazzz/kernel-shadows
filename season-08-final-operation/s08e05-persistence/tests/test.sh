#!/usr/bin/env bash
#
# s08e05 «Где закрепился гость» — тест скрипта (Type A).
#
# Проверяет поведение, а не текст. Тест строит два собственных дерева во
# временном каталоге — чистое и с восемью закреплениями — и смотрит, что
# скрипт находит на них. Ответы нигде не записаны: дерево создаётся здесь
# же, скриптом tests/build_tree.sh, и эталонный перечень считается по
# чистому дереву тут же.
#
# Отсюда следствие: скрипт, запомнивший находки из data/, тест не пройдёт.
#
# Проверяются обе ошибки: пропущенное закрепление и ложное срабатывание на
# чистом узле. Вторая важнее — охотник, который на чистой машине находит
# двадцать «подозрительных» файлов, перестаёт быть инструментом.
#
# Без root, без сети. Нужен sha256sum, shasum или openssl.
#
# Выбор скрипта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
T="${SERIES_DIR}/tests"

if   [ -n "${SUBJECT:-}" ];                                    then S="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/hunt_persistence.sh" ];     then S="${SERIES_DIR}/artifacts/hunt_persistence.sh"
elif [ -f "${SERIES_DIR}/hunt_persistence.sh" ];               then S="${SERIES_DIR}/hunt_persistence.sh"
else S="${SERIES_DIR}/solution/hunt_persistence.sh"
     echo "ℹ️  Своего hunt_persistence.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/hunt_persistence.sh artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e05 tests — скрипт: ${S#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

[ -f "${S}" ] || { echo "  FAIL: нет ${S}"; echo " Итог: 0 passed, 1 failed"; exit 1; }
if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1 \
   && ! command -v openssl >/dev/null 2>&1; then
    echo "  SKIP: нечем считать контрольные суммы (нужен sha256sum, shasum или openssl)"
    echo " Итог: 0 passed, 0 failed"; exit 0
fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
bash "${T}/build_tree.sh" "${TMP}/clean" clean
bash "${T}/build_tree.sh" "${TMP}/dirty" dirty
{ echo "# путь контрольная_сумма"; bash "${T}/mkmanifest.sh" "${TMP}/clean"; } > "${TMP}/manifest.txt"

run() { bash "${S}" "$@" 2>"${TMP}/err"; }
paths() { awk '$1=="PERSIST" {sub(/:.*/,"",$3); print $3}' "$1" | LC_ALL=C sort -u; }

# Восемь мест, которые build_tree.sh закрепляет в режиме dirty.
PLANTED="etc/cron.d/apt-daily-upgrade
etc/ld.so.preload
etc/passwd
etc/profile.d/00-locale-fix.sh
etc/rc.local
etc/sudoers.d/90-deploy-ci
etc/systemd/system/dbus-broker-relay.service
root/.ssh/authorized_keys"
printf '%s\n' "${PLANTED}" | LC_ALL=C sort > "${TMP}/planted"

echo ""
echo "── 0. Стенд собран ──"
[ "$(find "${TMP}/clean" -type f | wc -l)" -ge 12 ] \
    && ok "чистое дерево построено ($(find "${TMP}/clean" -type f | wc -l) файлов)" \
    || no "чистое дерево не собралось"
D_N=$(find "${TMP}/dirty" -type f | wc -l); C_N=$(find "${TMP}/clean" -type f | wc -l)
[ "${D_N}" -gt "${C_N}" ] && ok "в грязном дереве файлов больше: ${D_N} против ${C_N}" \
    || no "деревья не различаются — проверять нечего"
[ "$(grep -c . "${TMP}/planted")" -eq 8 ] && ok "закреплений заложено: 8" || no "закреплений не 8"

echo ""
echo "── 1. Договор вызова ──"
head -1 "${S}" | grep -q '^#!' && ok "shebang на месте" || no "нет строки #! в начале"
bash "${S}" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "без аргументов — код 2" || no "без аргументов вернул ${rc}"
bash "${S}" "${TMP}/dirty" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "с одним аргументом — код 2" || no "с одним аргументом вернул ${rc}"
bash "${S}" "${TMP}/нет-такого" "${TMP}/manifest.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий корень — код 2" || no "несуществующий корень: код ${rc}"
bash "${S}" "${TMP}/clean" "${TMP}/нет.txt" >/dev/null 2>&1; rc=$?
[ "${rc}" = 2 ] && ok "несуществующий перечень — код 2" || no "несуществующий перечень: код ${rc}"

echo ""
echo "── 2. Чистый узел ──"
run "${TMP}/clean" "${TMP}/manifest.txt" > "${TMP}/out_clean"; RC_CLEAN=$?
N_CLEAN="$(awk '$1=="TOTAL" {print $2; exit}' "${TMP}/out_clean")"
[ "${N_CLEAN}" = 0 ] && ok "на чистом узле находок нет: TOTAL 0" \
    || no "на чистом узле ${N_CLEAN:-нет строки TOTAL} — ложные срабатывания: $(paths "${TMP}/out_clean" | tr '\n' ' ')"
[ "${RC_CLEAN}" = 0 ] && ok "и код возврата 0" || no "код возврата ${RC_CLEAN} на чистом узле"

echo ""
echo "── 3. Узел с закреплениями ──"
run "${TMP}/dirty" "${TMP}/manifest.txt" > "${TMP}/out_dirty"; RC_DIRTY=$?
paths "${TMP}/out_dirty" > "${TMP}/found"
N_DIRTY="$(awk '$1=="TOTAL" {print $2; exit}' "${TMP}/out_dirty")"
[ -n "${N_DIRTY}" ] && [ "${N_DIRTY}" -ge 8 ] 2>/dev/null \
    && ok "итог напечатан: TOTAL ${N_DIRTY}" || no "нет строки TOTAL или значение меньше числа закреплений"
[ "${RC_DIRTY}" = 1 ] && ok "код возврата 1 при находках" || no "код возврата ${RC_DIRTY}, ожидается 1"

MISSED="$(LC_ALL=C comm -23 "${TMP}/planted" "${TMP}/found")"
EXTRA="$(LC_ALL=C comm -13 "${TMP}/planted" "${TMP}/found")"
while IFS= read -r p; do
    [ -n "${p}" ] || continue
    grep -qx "${p}" "${TMP}/found" && ok "найдено: ${p}" || no "ПРОПУЩЕНО: ${p}"
done < "${TMP}/planted"
[ -z "${EXTRA}" ] && ok "лишнего не названо" \
    || no "ложные срабатывания: $(printf '%s' "${EXTRA}" | tr '\n' ' ')"

echo ""
echo "── 4. Категории названы верно ──"
cat_of() { awk -v p="$1" '$1=="PERSIST" {q=$3; sub(/:.*/,"",q); if (q==p) {print $2; exit}}' "${TMP}/out_dirty"; }
check_cat() {
    got="$(cat_of "$1")"
    [ "${got}" = "$2" ] && ok "$1 → $2" || no "$1 → ${got:-нет}, ожидается $2"
}
check_cat etc/cron.d/apt-daily-upgrade                  cron
check_cat etc/systemd/system/dbus-broker-relay.service  systemd
check_cat etc/profile.d/00-locale-fix.sh                shell-profile
check_cat root/.ssh/authorized_keys                     ssh-key
check_cat etc/passwd                                    account
check_cat etc/sudoers.d/90-deploy-ci                    sudoers
check_cat etc/ld.so.preload                             preload
check_cat etc/rc.local                                  rc-local

echo ""
echo "── 5. Два признака, а не один ──"
# Учётная запись с uid 0 обязана находиться и тогда, когда файл совпал с
# эталоном: закрепление могло случиться до его снятия.
cp -R "${TMP}/dirty" "${TMP}/pre"
{ echo "# путь контрольная_сумма"; bash "${T}/mkmanifest.sh" "${TMP}/pre"; } > "${TMP}/manifest_pre.txt"
run "${TMP}/pre" "${TMP}/manifest_pre.txt" > "${TMP}/out_pre"
grep -q 'uid 0\|uid=0\|нулев' "${TMP}/out_pre" \
    && ok "uid 0 найден даже при совпадении с эталоном" \
    || no "при эталоне, снятом после проникновения, скрипт не находит ничего — нужен признак, не зависящий от перечня"
grep -qi 'ld.so.preload' "${TMP}/out_pre" \
    && ok "ld.so.preload найден независимо от эталона" \
    || no "ld.so.preload виден только через расхождение с эталоном"

echo ""
echo "── 6. Скрипт ничего не меняет ──"
bash "${T}/mkmanifest.sh" "${TMP}/dirty" > "${TMP}/before"
run "${TMP}/dirty" "${TMP}/manifest.txt" > /dev/null
bash "${T}/mkmanifest.sh" "${TMP}/dirty" > "${TMP}/after"
cmp -s "${TMP}/before" "${TMP}/after" && ok "снимок после прогона не изменился" \
    || no "скрипт изменил дерево, которое обязан только читать"

echo ""
echo "── 7. Воспроизводимость ──"
run "${TMP}/dirty" "${TMP}/manifest.txt" > "${TMP}/out2"
cmp -s "${TMP}/out_dirty" "${TMP}/out2" && ok "два прогона дают один вывод" \
    || no "вывод меняется между прогонами"
LC_ALL=C sort -c "${TMP}/found" 2>/dev/null && ok "вывод отсортирован — порядок обхода не просачивается" \
    || no "порядок строк зависит от обхода файловой системы"
( cd / && bash "${S}" "${TMP}/dirty" "${TMP}/manifest.txt" > "${TMP}/out3" 2>/dev/null )
cmp -s "${TMP}/out_dirty" "${TMP}/out3" && ok "результат не зависит от текущего каталога" \
    || no "из другого каталога вывод другой — где-то относительный путь"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
