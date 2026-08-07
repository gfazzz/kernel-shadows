#!/usr/bin/env bash
#
# s03e09 «Пятьсот гигабайт, которых не видно» — тест скрипта (Type A).
#
# Проверяет lvm_plan.sh: читает ли он снимок или повторяет заученное.
# Главный приём — ПОДМЕНА ДАННЫХ: тест делает копию снимка с другим именем
# группы, другим устройством и другой файловой системой и требует, чтобы
# вывод следовал за данными. Скрипт с зашитыми значениями это не пройдёт.
#
# Второй приём — МОКИ (§5.3): pvcreate, vgextend, lvextend, resize2fs и
# xfs_growfs подменяются заглушками-регистраторами в PATH. Скрипт обязан
# ПЕЧАТАТЬ команды, а не выполнять их; любой вызов заглушки — провал.
#
# Без root, без сети, без реальных устройств.
#
# Выбор скрипта: SUBJECT=... | artifacts/lvm_plan.sh | <серия>/lvm_plan.sh | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/../data"

if   [ -n "${SUBJECT:-}" ];                          then SCRIPT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/lvm_plan.sh" ];   then SCRIPT="${SERIES_DIR}/artifacts/lvm_plan.sh"
elif [ -f "${SERIES_DIR}/lvm_plan.sh" ];             then SCRIPT="${SERIES_DIR}/lvm_plan.sh"
else SCRIPT="${SERIES_DIR}/solution/lvm_plan.sh"
     echo "ℹ️  Свой lvm_plan.sh не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/lvm_plan.sh artifacts/lvm_plan.sh"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s03e09 tests — скрипт: ${SCRIPT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${SCRIPT}" ]; then
    ok "скрипт lvm_plan.sh найден"
else
    no "lvm_plan.sh не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
BIN="${TMP}/bin"; mkdir -p "${BIN}"
CALLS="${TMP}/calls.log"; : > "${CALLS}"

# ---- моки: любая настоящая команда LVM должна оставить след ------------------
for cmd in pvcreate vgcreate vgextend lvcreate lvextend lvreduce resize2fs xfs_growfs mkfs.ext4 mount umount; do
    cat > "${BIN}/${cmd}" <<EOF
#!/usr/bin/env bash
echo "${cmd} \$*" >> "${CALLS}"
exit 0
EOF
    chmod +x "${BIN}/${cmd}"
done

run() { PATH="${BIN}:${PATH}" bash "${SCRIPT}" "$@" 2>"${TMP}/err"; }

# ---- 1. базовый прогон -------------------------------------------------------
OUT="$(run)"; rc=$?
if [ ${rc} -eq 0 ]; then
    ok "скрипт отработал без ошибок"
else
    no "скрипт завершился с кодом ${rc}: $(head -1 "${TMP}/err")"
fi

if [ -s "${CALLS}" ]; then
    no "скрипт ВЫПОЛНИЛ команду: $(head -1 "${CALLS}") — он должен печатать план, а не менять систему"
else
    ok "ни одна команда LVM не выполнена — скрипт только печатает"
fi

if [ -n "${OUT}" ]; then ok "вывод не пуст"; else no "вывод пуст"; fi

# ---- 2. дисциплина скрипта ---------------------------------------------------
head -1 "${SCRIPT}" | grep -qE '^#!/usr/bin/env bash|^#!/bin/bash' \
  && ok "шебанг на месте" || no "нет строки #!/usr/bin/env bash"
grep -qE '^set -[euo]+' "${SCRIPT}" \
  && ok "set -e/-u включён" || no "нет set -euo pipefail — ошибка в середине пройдёт незамеченной"

# ---- 3. план по исходным данным ---------------------------------------------
for step in pvcreate vgextend lvextend resize2fs; do
    if printf '%s' "${OUT}" | grep -q "${step}"; then
        ok "в плане есть шаг ${step}"
    else
        no "в плане нет шага ${step}"
    fi
done

if printf '%s' "${OUT}" | grep -q 'xfs_growfs'; then
    no "в плане xfs_growfs, а файловая система в снимке ext4 — команда не подойдёт"
else
    ok "растягивание ФС выбрано по её типу, а не наугад"
fi

# порядок шагов
order_ok=1
prev=0
for step in pvcreate vgextend lvextend resize2fs; do
    n=$(printf '%s\n' "${OUT}" | grep -n "${step}" | head -1 | cut -d: -f1)
    [ -z "${n}" ] && { order_ok=0; break; }
    [ "${n}" -lt "${prev}" ] && order_ok=0
    prev="${n}"
done
if [ "${order_ok}" -eq 1 ]; then
    ok "порядок шагов верный: диск → группа → том → файловая система"
else
    no "порядок шагов нарушен: vgextend до pvcreate или resize2fs до lvextend"
fi

# устройство и группа взяты из снимка
exp_vg=$(awk '$0=="=== vgs ===" {f=1; next} /^=== /{f=0} f' "${DATA}/lvm_shadow-01.txt" \
           | awk 'NR>1 {print $1; exit}')
exp_free_disk=$(awk '$0=="=== lsblk -dn -o NAME,SIZE,TYPE ===" {f=1; next} /^=== /{f=0} f' \
                  "${DATA}/lvm_shadow-01.txt" | awk 'NF{print $1}' | tail -1)
printf '%s' "${OUT}" | grep -q "${exp_vg}" \
  && ok "группа томов из снимка: ${exp_vg}" || no "в выводе нет группы ${exp_vg}"
printf '%s' "${OUT}" | grep -q "/dev/${exp_free_disk}" \
  && ok "добавляется свободный диск /dev/${exp_free_disk}" \
  || no "в плане нет /dev/${exp_free_disk} — свободный диск не найден"

pv_dev=$(awk '$0=="=== pvs ===" {f=1; next} /^=== /{f=0} f' "${DATA}/lvm_shadow-01.txt" \
           | awk 'NR>1 {print $1}' | grep -v vda | head -1)
if printf '%s' "${OUT}" | grep -q "pvcreate ${pv_dev}"; then
    no "план предлагает pvcreate на ${pv_dev}, который уже входит в группу"
else
    ok "устройства, уже входящие в группу, повторно не размечаются"
fi

# ---- 4. подмена данных: скрипт обязан следовать снимку -----------------------
sed -e 's/ops-vg/kx-vg/g' -e 's/\bvdc\b/vdz/g' "${DATA}/lvm_shadow-01.txt" > "${TMP}/lvm2.txt"
sed -e 's/ops--vg/kx--vg/g' -e 's/\bext4\b/xfs/g' "${DATA}/disk_shadow-01.txt" > "${TMP}/disk2.txt"
OUT2="$(run --snapshot "${TMP}/lvm2.txt" --fs-snapshot "${TMP}/disk2.txt")"

printf '%s' "${OUT2}" | grep -q 'kx-vg' \
  && ok "подмена данных: имя группы взято из снимка (kx-vg)" \
  || no "подмена данных: в выводе нет kx-vg — имя группы зашито в скрипт"
printf '%s' "${OUT2}" | grep -q '/dev/vdz' \
  && ok "подмена данных: устройство взято из снимка (/dev/vdz)" \
  || no "подмена данных: в выводе нет /dev/vdz — устройство зашито в скрипт"
if printf '%s' "${OUT2}" | grep -q 'xfs_growfs' \
   && ! printf '%s' "${OUT2}" | grep -q 'resize2fs'; then
    ok "подмена данных: для xfs предложен xfs_growfs, а не resize2fs"
else
    no "подмена данных: тип файловой системы не учтён — для xfs нужен xfs_growfs"
fi

# ---- 5. другой целевой том ---------------------------------------------------
OUT3="$(run --target var)"
if printf '%s' "${OUT3}" | grep -q "${exp_vg}/var\|/dev/${exp_vg}/var"; then
    ok "--target переключает том: var"
else
    no "--target не влияет на вывод — целевой том зашит"
fi

if run --target нет-такого >/dev/null 2>&1; then
    no "несуществующий том принят молча — ошибка должна быть явной"
else
    ok "несуществующий том отвергнут с ненулевым кодом"
fi

# ---- 6. воспроизводимость ----------------------------------------------------
A="$(run)"; B="$(LC_ALL=C TZ=Pacific/Auckland run)"
if [ "${A}" = "${B}" ]; then
    ok "вывод не зависит от локали и часового пояса"
else
    no "вывод меняется от локали или TZ — в нём есть дата, сортировка или числа с запятой"
fi

# ---- 7. самопроверка данных --------------------------------------------------
vfree=$(awk '$0=="=== vgs ===" {f=1; next} /^=== /{f=0} f' "${DATA}/lvm_shadow-01.txt" \
          | awk 'NR>1 {print $NF; exit}')
if [ "${vfree}" = "0" ]; then
    ok "самопроверка данных: свободного места в группе нет — расширение требует нового PV"
else
    no "самопроверка данных: в группе появилось свободное место (${vfree}), задание ослабло"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
