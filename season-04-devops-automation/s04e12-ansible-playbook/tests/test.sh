#!/usr/bin/env bash
#
# s04e12 «Одной командой» (финал Season 4) — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства playbook. Файл режется на блоки задач по
# строкам «- name:» и «- модуль:» внутри tasks:, и дальше по каждой задаче
# задаётся один и тот же вопрос: **может ли ansible сказать, что изменится,
# не выполняя её**. Задача на command или shell без changed_when/creates
# ответить на него не может — и именно она пропадает из режима проверки.
#
# Без root, без сети, **без ansible**.
#
# Выбор артефакта: SUBJECT=... | artifacts/harden.yml | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STARTER="${SERIES_DIR}/starter/harden.yml"

if   [ -n "${SUBJECT:-}" ];                          then PB="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/harden.yml" ];    then PB="${SERIES_DIR}/artifacts/harden.yml"
elif [ -f "${SERIES_DIR}/harden.yml" ];              then PB="${SERIES_DIR}/harden.yml"
else PB="${SERIES_DIR}/solution/harden.yml"
     echo "ℹ️  Своего harden.yml не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/harden.yml artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e12 tests — playbook: ${PB#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${PB}" ]; then ok "harden.yml найден"
else no "harden.yml не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
BODY="${TMP}/body"
sed -e 's/\r$//' -e 's/^[[:space:]]*#.*$//' -e "s/[[:space:]]#[^\"']*$//" "${PB}" > "${BODY}"

# ---- секции плея ---------------------------------------------------------------
sect() { awk -v k="$1" '$0 ~ ("^  " k ":") {f=1; next} /^  [^[:space:]]/ {f=0} f' "${BODY}"; }
play_key() { awk -v k="$1" '$0 ~ ("^  " k ":") {sub(/^[^:]*:[[:space:]]*/,""); print; exit}' "${BODY}"; }

mkdir -p "${TMP}/t"
sect tasks | awk -v d="${TMP}/t" '
    /^    - / {n++}
    n > 0 {print > (d "/" sprintf("%03d", n))}'
TASKS="$(ls "${TMP}/t" 2>/dev/null)"
N_TASKS="$(printf '%s\n' "${TASKS}" | grep -c . || true)"
tf() { printf '%s' "${TMP}/t/$1"; }
mod_of() { grep -oE '(ansible\.builtin\.|ansible\.posix\.)?[a-z_]+:' "$(tf "$1")" \
           | grep -vE '^(name|become|tags|when|notify|register|vars|loop|until|args|delegate_to|no_log|changed_when|failed_when|check_mode|ignore_errors|listen|msg|path|line|state|mode|owner|group|src|dest|content|regexp|validate|update_cache|cache_valid_time)?:$' \
           | head -1 | sed -e 's/ansible\.[a-z]*\.//' -e 's/:$//'; }

if [ "${N_TASKS}" -ge 5 ]; then ok "разобрано задач: ${N_TASKS}"
else no "задач разобрано ${N_TASKS}: playbook на четыре строки не решает задачу"; fi

# ---- 1. кому адресован плей -----------------------------------------------------
h="$(play_key hosts)"
if [ -n "${h}" ] && [ "${h}" != "all" ] && [ "${h}" != '"*"' ]; then
    ok "плей адресован группе «${h}», а не всем машинам сразу"
else
    no "hosts: ${h:-не задан} — прогон затронет и стенд, и всё остальное"
fi

# ---- 2. права повышаются по месту -------------------------------------------------
if grep -qE '^  become:[[:space:]]*true' "${BODY}"; then
    no "become: true на уровне плея: root получают все задачи, включая те, которым он не нужен"
else
    ok "root не выдан всему плею разом"
fi
if grep -qE '^      become:[[:space:]]*true' "${BODY}"; then
    ok "права повышаются у отдельных задач"
else
    no "ни одна задача не просит become: изменить системные файлы не выйдет"
fi

# ---- 3. у каждой задачи есть имя ---------------------------------------------------
noname=""
for t in ${TASKS}; do grep -q '^    - name:' "$(tf "${t}")" || noname="${noname} ${t}"; done
if [ -z "${noname}" ]; then ok "у всех задач есть name"
else no "задачи без name (${noname# }): в выводе прогона их не отличить друг от друга"; fi

# ---- 4. главное: описываем состояние, а не действия ---------------------------------
SHELLY=""; BLIND=""
for t in ${TASKS}; do
    f="$(tf "${t}")"
    grep -qE '^      (ansible\.builtin\.)?(command|shell|raw):' "${f}" || continue
    SHELLY="${SHELLY} ${t}"
    # команда, которой можно доверять: она объявлена неизменяющей
    # или защищена условием создания
    grep -qE '^      (changed_when|creates|args):' "${f}" || BLIND="${BLIND} ${t}"
done
n_shelly="$(printf '%s' "${SHELLY}" | wc -w | tr -d ' ')"
if [ "${n_shelly}" -le 1 ]; then
    ok "команд оболочки в playbook: ${n_shelly} — остальное описано модулями"
else
    no "задач на command/shell: ${n_shelly} — это скрипт с отступами: ни diff, ни режима проверки"
fi
if [ -z "${BLIND}" ]; then
    ok "каждая команда объявлена неизменяющей (changed_when) или защищена creates"
else
    no "команда без changed_when/creates (задачи${BLIND}): ansible не может сказать, что изменится"
fi

# запрет на подмену модулей командами
for pat in 'systemctl restart' 'apt-get install' 'chmod ' 'useradd ' 'echo .*>'; do
    if grep -qE "^      (ansible\.builtin\.)?(command|shell|raw):.*${pat}" "${BODY}"; then
        no "«${pat}» вызвано командой: для этого есть модуль (systemd, apt, file, user, copy)"
    else
        ok "«${pat}» не подменяет модуль"
    fi
done

# ---- 5. перезапуск как следствие ---------------------------------------------------
HAND="$(sect handlers)"
if [ -n "${HAND}" ]; then ok "handlers объявлены"
else no "нет handlers: перезапуск станет отдельным шагом и будет рвать соединения каждый прогон"; fi
notify="$(grep -E '^      notify:' "${BODY}" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '[]')"
if [ -n "${notify}" ]; then
    if printf '%s\n' "${HAND}" | grep -qF -- "${notify}"; then
        ok "notify «${notify}» указывает на существующий handler"
    else
        no "notify «${notify}» не совпадает ни с одним handler: перезапуска не будет, и никто не заметит"
    fi
else
    no "ни одна задача не вызывает handler через notify"
fi
if printf '%s\n' "${TASKS}" | while read -r t; do
       grep -qE '^      (ansible\.builtin\.)?(systemd|service):' "$(tf "${t}")" \
         && grep -q 'state:[[:space:]]*restarted' "$(tf "${t}")" && echo yes; done | grep -q yes; then
    no "перезапуск задан обычной задачей: он выполнится и тогда, когда ничего не менялось"
else
    ok "перезапуск живёт только в handler"
fi

# ---- 6. правка строки в конфигурации ------------------------------------------------
LI=""
for t in ${TASKS}; do grep -qE '^      (ansible\.builtin\.)?lineinfile:' "$(tf "${t}")" && LI="${t}"; done
if [ -n "${LI}" ]; then
    if grep -q '^        regexp:' "$(tf "${LI}")"; then
        ok "lineinfile ищет строку по regexp, а не дописывает новую при каждом прогоне"
    else
        no "lineinfile без regexp: строка будет добавляться заново каждый прогон"
    fi
    if grep -q '^        validate:' "$(tf "${LI}")"; then
        ok "результат правки проверяется до подмены файла (validate)"
    else
        no "нет validate: сломанный sshd_config уедет на полсотни машин и закроет вход"
    fi
else
    no "PermitRootLogin никак не приводится к нужному значению"
fi
if grep -q 'PermitRootLogin no' "${BODY}"; then ok "вход root по ssh запрещается"
else no "в playbook нет PermitRootLogin no — находка s04e10 не закрыта"; fi

# ---- 7. остальные находки s04e10 -----------------------------------------------------
if grep -qE '^        mode:[[:space:]]*"?0700"?' "${BODY}"; then
    ok "каталог закрытых ключей приводится к 0700"
else
    no "права 0700 на /etc/ssl/private нигде не задаются"
fi
if grep -qE '^      (ansible\.builtin\.)?(template|copy):' "${BODY}"; then
    ok "файлы раскладываются модулем template/copy"
else
    no "нет ни одной задачи template/copy: authorized_keys нечем привести к описанию"
fi

# ---- 8. секреты ------------------------------------------------------------------------
if grep -qiE '^ +[a-z_]*(password|token|secret):[[:space:]]*[^[:space:]{"]' "${BODY}"; then
    no "секрет открытым текстом в playbook: $(grep -iEm1 '^ +[a-z_]*(password|token|secret):' "${BODY}" | sed 's/^ *//')"
else
    ok "паролей открытым текстом нет — значение приходит извне"
fi
if grep -qE '^      no_log:[[:space:]]*true' "${BODY}"; then
    ok "задача с секретом закрыта no_log"
else
    no "нет no_log: значение секрета напечатается в выводе прогона и в diff"
fi

# ---- 9. ошибки не заметаются -------------------------------------------------------------
if grep -qE '^      ignore_errors:[[:space:]]*true' "${BODY}"; then
    no "ignore_errors: true — та же ошибка, что «|| true» в конвейере: задача падает, прогон зеленеет"
else
    ok "ignore_errors нигде не включён"
fi
if grep -qE '^      (failed_when|when|check_mode):' "${BODY}"; then
    ok "условия выполнения и провала заданы явно"
else
    no "нет ни одного when/failed_when/check_mode: поведение задач нечем настроить"
fi

# ---- 10. метки ------------------------------------------------------------------------
n_tags="$(grep -cE '^      tags:' "${BODY}" || true)"
if [ "${n_tags}" -ge 3 ]; then
    ok "задачи размечены tags (${n_tags}): прогон можно ограничить одной темой"
else
    no "меток мало (${n_tags}): на полусотне машин нельзя будет запустить только нужное"
fi

# ---- 11. самопроверки ---------------------------------------------------------------
if [ -f "${STARTER}" ] && grep -q 'hosts: all' "${STARTER}" \
   && grep -q 'systemctl restart' "${STARTER}"; then
    ok "самопроверка: в стартере ловушки на месте (hosts: all и перезапуск командой)"
else
    no "самопроверка: стартер больше не содержит исходных ошибок"
fi
if [ -f "${STARTER}" ] && grep -q 'ignore_errors' "${STARTER}" \
   && grep -qE 'registry_password: Sh4dow' "${STARTER}"; then
    ok "самопроверка: в стартере остались ignore_errors и пароль в vars"
else
    no "самопроверка: вторая пара ловушек стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
