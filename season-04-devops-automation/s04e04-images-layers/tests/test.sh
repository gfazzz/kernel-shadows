#!/usr/bin/env bash
#
# s04e04 «Слой, который остался» — тест разведки (Type C).
#
# Проверяет НЕ скрипт, а находки студента: отчёт image_report.txt сверяется
# со снимком образов из data/. Эталон вычисляется здесь же — констант
# в тесте нет.
#
# Без root, без сети, **без docker**: разбирается копия вывода команд.
#
# Выбор отчёта: SUBJECT=... | artifacts/image_report.txt | <серия>/… | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/../data/docker_ops_snapshot.txt"

if   [ -n "${SUBJECT:-}" ];                              then REPORT="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/image_report.txt" ];  then REPORT="${SERIES_DIR}/artifacts/image_report.txt"
elif [ -f "${SERIES_DIR}/image_report.txt" ];            then REPORT="${SERIES_DIR}/image_report.txt"
else REPORT="${SERIES_DIR}/solution/image_report.txt"
     echo "ℹ️  Свой image_report.txt не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/image_report.txt artifacts/image_report.txt"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e04 tests — отчёт: ${REPORT#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ ! -f "${D}" ]; then echo "  FAIL: не найден объект разведки: ${D}" >&2; exit 1; fi
if [ -f "${REPORT}" ]; then ok "отчёт image_report.txt найден"
else no "image_report.txt не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

# ---- эталон ------------------------------------------------------------------
sec() { awk -v s="$1" '$0=="=== "s" ===" {f=1; next} /^=== /{f=0} f' "${D}" \
          | grep -vE '^[[:space:]]*$'; }
tobytes() { awk -v v="$1" 'BEGIN{ n=v; u=""; if (v ~ /GB$/) {u="G"} else if (v ~ /MB$/) {u="M"} else if (v ~ /kB$/) {u="K"}
    gsub(/[A-Za-z]/,"",n)
    m = (u=="G")?1073741824 : (u=="M")?1048576 : (u=="K")?1024 : 1
    printf "%.0f", n*m }'; }

IMG="$(sec 'docker images')"
exp_distinct=$(printf '%s\n' "${IMG}" | awk 'NR>1{print $3}' | sort -u | grep -c .)
naive_distinct=$(printf '%s\n' "${IMG}" | awk 'NR>1' | grep -c .)
read -r exp_largest exp_largest_size <<EOF
$(printf '%s\n' "${IMG}" | awk 'NR>1{print $1":"$2, $NF}' \
  | while read -r n s; do printf '%s %s %s\n' "$(tobytes "${s}")" "${n}" "${s}"; done \
  | sort -rn | awk 'NR==1{print $2, $3}')
EOF

HIS="$(sec 'docker history ops/collector:1.4.0')"
exp_layers=$(printf '%s\n' "${HIS}" | awk 'NR>1' | grep -c .)
# крупнейший слой СБОРКИ: строки базового образа помечены #(nop) и не в счёт
read -r exp_big_instr exp_big_size <<EOF
$(printf '%s\n' "${HIS}" | awk 'NR>1' | grep -v '#(nop)' \
  | while IFS= read -r l; do
        sz="${l##* }"
        cmd="$(printf '%s' "${l}" | sed -E 's/^[^ ]+ +[0-9]+ [a-z]+ ago +//')"
        instr="$(printf '%s' "${cmd}" | sed -E 's|^RUN /bin/sh -c |RUN |' | awk '{print $1}')"
        printf '%s %s %s\n' "$(tobytes "${sz}")" "${instr}" "${sz}"
    done | sort -rn | awk 'NR==1{print $2, $3}')
EOF

exp_deleted=$(printf '%s\n' "${HIS}" | grep -oE 'rm -rf [^ ]+' | awk '{print $3}' | head -1)
exp_secret_var=$(sec 'docker inspect ops/collector:1.4.0' \
    | grep -oE '"[A-Z_]+=[^"]+"' | tr -d '"' | grep -iE 'password|token|secret' | cut -d= -f1 | head -1)
exp_secret_val=$(sec 'docker inspect ops/collector:1.4.0' \
    | grep -oE "\"${exp_secret_var}=[^\"]+\"" | tr -d '"' | cut -d= -f2- | head -1)
exp_base=$(sec 'базовый образ по Dockerfile' | awk '/^FROM/{print $2; exit}')
TRI="$(sec 'trivy image ops/collector:1.4.0 (сводка)')"
exp_crit=$(printf '%s\n' "${TRI}" | awk 'NR==1' | grep -oE 'CRITICAL: [0-9]+' | grep -oE '[0-9]+')
exp_crit_slim=$(printf '%s\n' "${TRI}" | grep 'slim' | grep -oE 'CRITICAL: [0-9]+' | grep -oE '[0-9]+')

# ---- чтение отчёта -----------------------------------------------------------
val() {
    grep -E "^[[:space:]]*$1[[:space:]]*=" "${REPORT}" 2>/dev/null \
        | grep -v '^[[:space:]]*#' | tail -1 | cut -d= -f2- \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/\r//'
}
check() {
    local key="$1" want="$2" desc="$3" got
    got="$(val "${key}")"
    if [ -z "${got}" ];            then no "${desc}: значение не заполнено (${key}=)"
    elif [ "${got}" = "${want}" ]; then ok "${desc}: ${got}"
    else                                no "${desc}: указано '${got}', в снимке '${want}'"
    fi
}

check distinct_images           "${exp_distinct}"   "разных образов"
check largest_image             "${exp_largest}"    "самый крупный образ"
check largest_size              "${exp_largest_size}" "его размер"
check layers                    "${exp_layers}"     "слоёв в ops/collector"
check biggest_build_instruction "${exp_big_instr}"  "инструкция крупнейшего слоя СБОРКИ"
check biggest_build_size        "${exp_big_size}"   "его размер"
check deleted_file              "${exp_deleted}"    "файл, удалённый следующей инструкцией"
check delete_freed_space        "no"                "освободило ли удаление место"
check secret_env_var            "${exp_secret_var}" "переменная окружения с секретом"
check secret_env_value          "${exp_secret_val}" "её значение"
check effective_user            "root"              "от кого работает контейнер"
check base_image                "${exp_base}"       "базовый образ"
check critical_vulns            "${exp_crit}"       "критических уязвимостей"
check critical_vulns_slim       "${exp_crit_slim}"  "их было бы на slim"

# ---- согласованность ---------------------------------------------------------
if [ "$(val critical_vulns)" -gt "$(val critical_vulns_slim)" ] 2>/dev/null; then
    ok "самопроверка отчёта: на облегчённой базе критических уязвимостей меньше"
else
    no "самопроверка отчёта: выигрыш от slim-базы не зафиксирован"
fi

if [ "$(val largest_image)" != "ops/collector:1.4.0" ]; then
    ok "самопроверка отчёта: самый крупный образ — не тот, что собирали"
else
    no "самопроверка отчёта: крупнее собранного образа в снимке есть база"
fi

# ---- ловушки в данных --------------------------------------------------------
if [ "${naive_distinct}" -gt "${exp_distinct}" ]; then
    ok "самопроверка данных: строк в docker images ${naive_distinct} против ${exp_distinct} образов — два тега на один ID"
else
    no "самопроверка данных: повторяющийся IMAGE ID исчез, ловушка пропала"
fi

if printf '%s\n' "${HIS}" | grep -q 'COPY deploy_key' && printf '%s\n' "${HIS}" | grep -q 'rm -rf /tmp/deploy_key'; then
    ok "самопроверка данных: пара «скопировали — удалили» в слоях на месте"
else
    no "самопроверка данных: сюжет про удаление в позднем слое исчез"
fi

if printf '%s\n' "${HIS}" | grep -qE 'rm -rf /tmp/deploy_key +0B'; then
    ok "самопроверка данных: слой удаления весит 0B — место не освободилось"
else
    no "самопроверка данных: размер слоя удаления изменился, вывод серии ослаб"
fi

if sec 'docker inspect ops/collector:1.4.0' | grep -q '"User": ""'; then
    ok "самопроверка данных: поле User пустое — умолчание, а не «никто»"
else
    no "самопроверка данных: ловушка с пустым User исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
