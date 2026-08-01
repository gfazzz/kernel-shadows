#!/usr/bin/env bash
#
# s02e09 «Закрыть и спрятать» (капстоун Season 2) — тест конфигурации (Type B).
#
# Проверяет НЕ скрипт, а свойства конфига, который написал студент: читает
# artifacts/sshd_config ровно так, как это делает sshd (первое вхождение,
# комментарии не в счёт, регистр не важен, отступ допустим) и сверяет
# эффективные значения директив с требованиями закалки.
#
# Отдельно ловится попытка «пройти проверку», закомментировав опасную строку
# вместо её исправления, и директива, заданная дважды.
#
# Без root, без сети: реальный sshd не запускается.
#
# Выбор артефакта: SUBJECT=... | artifacts/sshd_config | <серия>/sshd_config | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if   [ -n "${SUBJECT:-}" ];                        then CFG="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/sshd_config" ]; then CFG="${SERIES_DIR}/artifacts/sshd_config"
elif [ -f "${SERIES_DIR}/sshd_config" ];           then CFG="${SERIES_DIR}/sshd_config"
else CFG="${SERIES_DIR}/solution/sshd_config"
     echo "ℹ️  Свой sshd_config не найден — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/sshd_config artifacts/sshd_config"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s02e09 tests — конфиг: ${CFG#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

if [ -f "${CFG}" ]; then
    ok "конфигурация sshd_config найдена"
else
    no "sshd_config не найден"
    echo " Итог: ${PASS} passed, ${FAIL} failed"
    exit 1
fi

# ---- чтение конфига так, как это делает sshd -------------------------------
# ПЕРВОЕ вхождение активной директивы; комментарии игнорируются;
# имя директивы регистронезависимо; допускается отступ.
effective() {
    grep -iE "^[[:space:]]*$1([[:space:]]|=)" "${CFG}" 2>/dev/null \
        | grep -vE '^[[:space:]]*#' | head -1 \
        | sed -E 's/^[[:space:]]*[^[:space:]=]+[[:space:]=]+//' | tr -d '\r' | awk '{print $1}'
}

want() {  # want <директива> <ожидаемое> <зачем>
    local name="$1" expect="$2" why="$3" got
    got="$(effective "${name}")"
    if [ -z "${got}" ]; then
        no "${name}: не задана — действует умолчание (${why})"
    elif printf '%s' "${got}" | grep -qix "${expect}"; then
        ok "${name} = ${got}"
    else
        no "${name} = ${got}, ожидалось ${expect} (${why})"
    fi
}

# ---- требования закалки ----------------------------------------------------
want PermitRootLogin              "no"  "root — только через sudo от именованного пользователя"
want PasswordAuthentication       "no"  "вход только по ключам"
want KbdInteractiveAuthentication "no"  "иначе пароли возвращаются через PAM"
want PermitEmptyPasswords         "no"  "учётные записи без пароля недопустимы"
want PubkeyAuthentication         "yes" "иначе войти станет нечем"
want X11Forwarding                "no"  "на сервере не нужен"

# MaxAuthTries — не «равно», а «не больше трёх»
mat="$(effective MaxAuthTries)"
if [ -z "${mat}" ]; then
    no "MaxAuthTries: не задан — по умолчанию 6 попыток за соединение"
elif printf '%s' "${mat}" | grep -qE '^[0-9]+$' && [ "${mat}" -le 3 ] && [ "${mat}" -ge 1 ]; then
    ok "MaxAuthTries = ${mat} (не больше 3)"
else
    no "MaxAuthTries = ${mat}, нужно значение от 1 до 3"
fi

# Явный список допущенных
if [ -n "$(effective AllowGroups)" ] || [ -n "$(effective AllowUsers)" ]; then
    ok "доступ ограничен явным списком (AllowGroups/AllowUsers)"
else
    no "нет AllowGroups или AllowUsers — войти может любой, у кого есть учётная запись"
fi

# Журнал должен сохранять отпечаток ключа
if printf '%s' "$(effective LogLevel)" | grep -qix "verbose"; then
    ok "LogLevel = VERBOSE (в журнал попадает отпечаток ключа)"
else
    no "LogLevel = $(effective LogLevel) — при INFO неизвестно, каким ключом вошли"
fi

# ---- ловушка: закомментировать вместо исправления --------------------------
commented_only=""
for d in PermitRootLogin PasswordAuthentication PermitEmptyPasswords; do
    if [ -z "$(effective ${d})" ] \
       && grep -qiE "^[[:space:]]*#[[:space:]]*${d}[[:space:]]" "${CFG}"; then
        commented_only="${commented_only} ${d}"
    fi
done
if [ -z "${commented_only}" ]; then
    ok "нужные директивы заданы явно, а не оставлены в комментариях"
else
    no "директива закомментирована вместо исправления:${commented_only} — действует умолчание"
fi

# ---- ловушка: первое вхождение побеждает -----------------------------------
dupes=""
for d in PermitRootLogin PasswordAuthentication PermitEmptyPasswords X11Forwarding; do
    n_active=$(grep -iE "^[[:space:]]*${d}([[:space:]]|=)" "${CFG}" 2>/dev/null | grep -vcE '^[[:space:]]*#' || true)
    [ "${n_active:-0}" -gt 1 ] && dupes="${dupes} ${d}"
done
if [ -z "${dupes}" ]; then
    ok "нет директив, заданных дважды (sshd взял бы первую)"
else
    no "директива задана дважды:${dupes} — sshd применит первую, а не последнюю"
fi

# ---- целостность: конфигурация осталась рабочей ----------------------------
if [ -n "$(effective Port)" ] && [ -n "$(effective Subsystem)" ]; then
    ok "конфигурация осталась рабочей (Port и Subsystem на месте)"
else
    no "из конфигурации пропали базовые директивы (Port / Subsystem)"
fi

# ---- самопроверка задания: стартовый конфиг обязан быть НЕ закалённым ------
START="${SERIES_DIR}/starter/sshd_config"
if [ -f "${START}" ]; then
    start_root=$(grep -iE '^[[:space:]]*PermitRootLogin[[:space:]]' "${START}" \
                   | grep -vE '^[[:space:]]*#' | head -1 | awk '{print $2}')
    if printf '%s' "${start_root}" | grep -qix "yes"; then
        ok "самопроверка: стартовая конфигурация действительно не закалена"
    else
        no "самопроверка: в starter/ уже всё исправлено, задание вырождено"
    fi
else
    no "самопроверка: не найден starter/sshd_config"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
