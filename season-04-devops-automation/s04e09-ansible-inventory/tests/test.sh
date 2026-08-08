#!/usr/bin/env bash
#
# s04e09 «Пятьдесят имён» — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства inventory.yml. Файл разбирается по
# отступам в три вида записей — группа, хост, переменная, — диапазоны
# вида host[01:27] разворачиваются, и дальше считается то, что и должно
# считаться: в какие группы попал каждый хост и какая группа задаёт ему
# какую переменную.
#
# Главная проверка — неоднозначность. Если одна переменная задана в двух
# группах, ни одна из которых не является предком другой, Ansible выберет
# ту, чьё имя позже по алфавиту. Это законно, воспроизводимо и почти
# никогда не то, что имел в виду автор файла.
#
# Без root, без сети, **без ansible**.
#
# Выбор артефакта: SUBJECT=... | artifacts/inventory.yml | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
STARTER="${SERIES_DIR}/starter/inventory.yml"

if   [ -n "${SUBJECT:-}" ];                              then INV="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/inventory.yml" ];     then INV="${SERIES_DIR}/artifacts/inventory.yml"
elif [ -f "${SERIES_DIR}/inventory.yml" ];               then INV="${SERIES_DIR}/inventory.yml"
else INV="${SERIES_DIR}/solution/inventory.yml"
     echo "ℹ️  Своего inventory.yml не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/inventory.yml artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e09 tests — инвентарь: ${INV#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${INV}" ]; then ok "inventory.yml найден"
else no "inventory.yml не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

TMP="$(mktemp -d)"; trap 'rm -rf "${TMP}"' EXIT
mkdir -p "${TMP}/g" "${TMP}/h"

# ---- разбор ------------------------------------------------------------------
# G <группа> <родитель> | H <группа> <шаблон хоста> | V <группа> <ключ> <значение>
REC="${TMP}/records"
awk '
    { line = $0; sub(/\r$/, "", line) }
    line ~ /^[[:space:]]*#/ { next }
    { sub(/[[:space:]]+#.*$/, "", line) }
    line ~ /^[[:space:]]*$/ { next }
    line ~ /\t/ { print "E tab " NR; next }
    {
        ind = match(line, /[^ ]/) - 1
        body = substr(line, ind + 1)
        if (body !~ /:/) next
        if (ind % 2 != 0) { print "E indent " NR; next }

        if (body ~ /:[[:space:]]*$/) {
            key = body; sub(/:[[:space:]]*$/, "", key); val = ""
        } else {
            i = index(body, ": ")
            if (i == 0) next
            key = substr(body, 1, i - 1); val = substr(body, i + 2)
            sub(/[[:space:]]+$/, "", val)
        }

        if (ind == 0) { groupat[0] = key; print "G " key " -"; next }

        if (key == "vars" || key == "hosts" || key == "children") {
            sectat[ind] = key; next
        }

        sect = sectat[ind - 2]; owner = groupat[ind - 4]
        if (sect == "children") { groupat[ind] = key; print "G " key " " owner }
        else if (sect == "hosts") { print "H " owner " " key }
        else if (sect == "vars")  { print "V " owner " " key " " val }
    }
' "${INV}" > "${REC}"

if grep -q '^E tab' "${REC}"; then
    no "в файле есть символы табуляции: YAML их не допускает в отступах"
elif grep -q '^E indent' "${REC}"; then
    no "отступ не кратен двум (строка $(grep -m1 '^E indent' "${REC}" | awk '{print $3}'))"
else
    ok "отступы корректны: только пробелы, кратно двум"
fi

# ---- разворачивание диапазонов ------------------------------------------------
expand() {
    local p="$1" pre a b suf w i
    if [[ "${p}" =~ ^(.*)\[([0-9]+):([0-9]+)\](.*)$ ]]; then
        pre="${BASH_REMATCH[1]}"; a="${BASH_REMATCH[2]}"
        b="${BASH_REMATCH[3]}";   suf="${BASH_REMATCH[4]}"; w=${#a}
        for ((i = 10#$a; i <= 10#$b; i++)); do printf "%s%0${w}d%s\n" "${pre}" "${i}" "${suf}"; done
    else
        printf '%s\n' "${p}"
    fi
}

GRPS="$(awk '$1=="G" {print $2}' "${REC}")"
for g in ${GRPS}; do
    mkdir -p "${TMP}/g/${g}"
    awk -v g="${g}" '$1=="G" && $2==g {print $3}' "${REC}" > "${TMP}/g/${g}/parent"
    awk -v g="${g}" '$1=="V" && $2==g {k=$3; $1=$2=$3=""; sub(/^ +/,""); print k "=" $0}' "${REC}" \
        > "${TMP}/g/${g}/vars"
    : > "${TMP}/g/${g}/hosts"
    while read -r pat; do
        [ -n "${pat}" ] || continue
        expand "${pat}" >> "${TMP}/g/${g}/hosts"
    done < <(awk -v g="${g}" '$1=="H" && $2==g {print $3}' "${REC}")
done

n_groups="$(printf '%s\n' "${GRPS}" | grep -c . || true)"
if [ "${n_groups}" -ge 4 ]; then ok "разобрано групп: ${n_groups}"
else no "групп разобрано ${n_groups}: инвентарь без структуры не отличается от списка"; fi

# все хосты
ALLHOSTS="$(cat "${TMP}"/g/*/hosts 2>/dev/null | sort -u)"
n_hosts="$(printf '%s\n' "${ALLHOSTS}" | grep -c . || true)"
if [ "${n_hosts}" -eq 50 ]; then ok "уникальных хостов: 50"
else no "хостов ${n_hosts}, а серверов операции пятьдесят"; fi

n_hostlines="$(awk '$1=="H"' "${REC}" | grep -c . || true)"
if [ "${n_hostlines}" -le 15 ]; then
    ok "хосты записаны диапазонами: ${n_hostlines} строк вместо полусотни"
else
    no "хосты перечислены по одному (${n_hostlines} строк): нужны диапазоны вида web[01:27]"
fi

# ---- предки -------------------------------------------------------------------
ancestors() {  # все предки группы, включая её саму
    local g="$1" p
    while [ -n "${g}" ] && [ "${g}" != "-" ]; do
        printf '%s\n' "${g}"
        p="$(cat "${TMP}/g/${g}/parent" 2>/dev/null || echo -)"
        g="${p}"
    done
}
groups_of() {  # все группы хоста, с учётом предков
    local h="$1" g
    for g in ${GRPS}; do
        grep -qxF "${h}" "${TMP}/g/${g}/hosts" 2>/dev/null && ancestors "${g}"
    done | sort -u
}
defines() { grep -q "^$2=" "${TMP}/g/$1/vars" 2>/dev/null; }
valof()   { awk -F= -v k="$2" '$1==k {sub(/^[^=]*=/,""); print; exit}' "${TMP}/g/$1/vars" 2>/dev/null; }

ROLE_GROUPS=""; ENV_GROUPS=""; BOTH=""
for g in ${GRPS}; do
    defines "${g}" ops_role && ROLE_GROUPS="${ROLE_GROUPS} ${g}"
    defines "${g}" ops_env  && ENV_GROUPS="${ENV_GROUPS} ${g}"
    { defines "${g}" ops_role && defines "${g}" ops_env; } && BOTH="${BOTH} ${g}"
done
n_role="$(printf '%s' "${ROLE_GROUPS}" | wc -w | tr -d ' ')"
n_env="$(printf '%s' "${ENV_GROUPS}" | wc -w | tr -d ' ')"

if [ "${n_role}" -ge 3 ]; then ok "групп по роли: ${n_role} (${ROLE_GROUPS# })"
else no "групп с переменной ops_role — ${n_role}: роли серверов не разведены"; fi
if [ "${n_env}" -eq 2 ]; then ok "контуров два: ${ENV_GROUPS# }"
else no "групп с переменной ops_env — ${n_env}, ожидалось два контура (боевой и стенд)"; fi
if [ -z "${BOTH}" ]; then ok "оси не смешаны: ни одна группа не задаёт и роль, и контур"
else no "группа задаёт обе оси сразу:${BOTH} — тогда сервер нельзя переставить между контурами"; fi

# ---- покрытие обеими осями ----------------------------------------------------
bad_role=""; bad_env=""
for h in ${ALLHOSTS}; do
    hg="$(groups_of "${h}")"
    c_role=0; c_env=0
    for g in ${hg}; do
        defines "${g}" ops_role && c_role=$((c_role+1))
        defines "${g}" ops_env  && c_env=$((c_env+1))
    done
    [ "${c_role}" -eq 1 ] || bad_role="${bad_role} ${h}(${c_role})"
    [ "${c_env}"  -eq 1 ] || bad_env="${bad_env} ${h}(${c_env})"
done
if [ -z "${bad_role}" ]; then ok "каждый хост ровно в одной группе по роли"
else no "хосты вне ровно одной ролевой группы:$(printf '%s' "${bad_role}" | cut -c1-90)"; fi
if [ -z "${bad_env}" ]; then ok "каждый хост ровно в одной группе по контуру"
else no "хосты вне ровно одной группы-контура:$(printf '%s' "${bad_env}" | cut -c1-90)"; fi

# ---- главная проверка: неоднозначные переменные -------------------------------
is_ancestor() { ancestors "$2" | grep -qxF "$1"; }
AMBIG=""
for h in ${ALLHOSTS}; do
    hg="$(groups_of "${h}")"
    keys="$(for g in ${hg}; do cut -d= -f1 "${TMP}/g/${g}/vars" 2>/dev/null; done | sort -u)"
    for k in ${keys}; do
        owners="$(for g in ${hg}; do defines "${g}" "${k}" && printf '%s ' "${g}"; done)"
        n="$(printf '%s' "${owners}" | wc -w | tr -d ' ')"
        [ "${n}" -le 1 ] && continue
        for a in ${owners}; do for b in ${owners}; do
            [ "${a}" = "${b}" ] && continue
            if ! is_ancestor "${a}" "${b}" && ! is_ancestor "${b}" "${a}"; then
                winner="$(printf '%s\n%s\n' "${a}" "${b}" | sort | tail -1)"
                AMBIG="${k} в группах ${a} и ${b} (победит ${winner}: позже по алфавиту)"
                break 3
            fi
        done; done
    done
done
if [ -z "${AMBIG}" ]; then
    ok "ни одна переменная не задана в двух несравнимых группах"
else
    no "неоднозначность: ${AMBIG} — спор решает алфавит, а не смысл"
fi

# ---- доступ --------------------------------------------------------------------
u_owners="$(for g in ${GRPS}; do defines "${g}" ansible_user && printf '%s ' "${g}"; done)"
n_u="$(printf '%s' "${u_owners}" | wc -w | tr -d ' ')"
if [ "${n_u}" -eq 1 ]; then
    ok "ansible_user задан один раз (в ${u_owners% })"
else
    no "ansible_user задан в ${n_u} местах: общая переменная размножена по группам"
fi
u_val=""
for g in ${GRPS}; do defines "${g}" ansible_user && u_val="$(valof "${g}" ansible_user)"; done
if [ -n "${u_val}" ] && [ "${u_val}" != "root" ]; then
    ok "подключение не от root: ansible_user=${u_val}"
else
    no "ansible_user=${u_val:-не задан}: полномочия повышают там, где они нужны, а не на входе"
fi
if grep -qiE '^V .*(password|ssh_pass|_pass|become_pass|vault_pass) ' "${REC}"; then
    no "пароль в инвентаре: $(grep -iE '^V .*(password|ssh_pass|_pass) ' "${REC}" | head -1 | cut -d' ' -f3-) — файл лежит в репозитории"
else
    ok "паролей в инвентаре нет"
fi
if grep -q 'StrictHostKeyChecking=no' "${INV}"; then
    no "StrictHostKeyChecking=no отключает проверку ключа хоста: подмена сервера перестаёт быть заметной"
else
    ok "проверка ключа хоста не отключена"
fi

# ---- смысл переменных ---------------------------------------------------------
prod_g=""; stg_g=""
for g in ${ENV_GROUPS}; do
    case "$(valof "${g}" ops_env)" in prod|production) prod_g="${g}" ;; *) stg_g="${g}" ;; esac
done
if [ -n "${prod_g}" ] && [ -n "${stg_g}" ] \
   && [ "$(valof "${prod_g}" ops_env)" != "$(valof "${stg_g}" ops_env)" ]; then
    ok "контуры различимы по ops_env: ${prod_g}=$(valof "${prod_g}" ops_env), ${stg_g}=$(valof "${stg_g}" ops_env)"
else
    no "контуры не различаются по ops_env"
fi
if [ -n "${prod_g}" ] && [ "$(valof "${prod_g}" log_level)" != "debug" ]; then
    ok "в боевом контуре уровень журналирования не debug"
else
    no "в боевом контуре log_level=debug: подробный журнал в бою — это и объём, и лишние данные в нём"
fi
no_ports=""
for g in ${ROLE_GROUPS}; do defines "${g}" open_ports || no_ports="${no_ports} ${g}"; done
if [ -z "${no_ports}" ]; then ok "у каждой роли перечислены свои порты"
else no "роль без open_ports:${no_ports}"; fi

# ---- наследование работает ----------------------------------------------------
noport=""
for h in ${ALLHOSTS}; do
    found=0
    for g in $(groups_of "${h}"); do defines "${g}" ansible_port && found=1; done
    [ "${found}" -eq 1 ] || noport="${noport} ${h}"
done
if [ -z "${noport}" ]; then
    ok "общие переменные доходят до всех хостов по цепочке групп"
else
    no "ansible_port не достаётся хостам:$(printf '%s' "${noport}" | cut -c1-60)"
fi

# ---- самопроверки --------------------------------------------------------------
if [ -f "${STARTER}" ] && grep -q 'ansible_password' "${STARTER}" && grep -q 'ansible_user: root' "${STARTER}"; then
    ok "самопроверка: в стартере ловушки на месте (root и пароль)"
else
    no "самопроверка: стартер больше не содержит исходных ошибок"
fi
if [ -f "${STARTER}" ] && [ "$(awk '/^ +[a-z-]+[0-9]+\.shadow\.io:/' "${STARTER}" | grep -c . || true)" -gt 30 ]; then
    ok "самопроверка: в стартере хосты по-прежнему перечислены по одному"
else
    no "самопроверка: вторая ловушка стартера исчезла"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
