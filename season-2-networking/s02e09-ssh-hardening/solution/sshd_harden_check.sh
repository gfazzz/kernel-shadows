#!/usr/bin/env bash
#
# sshd_harden_check.sh — s02e09 «Закалённый вход» (КАПСТОУН Season 2)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: hardening SSH-сервера — аудит sshd_config по ключевым директивам.
# Type B — Linux Configuration: проверяем конфиг, а не пишем сервер.
#
# Требования среды: bash + coreutils, без root, без сети. Работает над файлом sshd_config
# (реальный sshd/рестарт службы не нужны — только читаем конфиг).
#
# Использование: ./sshd_harden_check.sh SSHD_CONFIG

set -uo pipefail

cfg="${1:?Использование: sshd_harden_check.sh SSHD_CONFIG}"
[ -f "${cfg}" ] || { echo "Файл не найден: ${cfg}" >&2; exit 1; }

# Эффективное значение директивы: последняя НЕзакомментированная строка (sshd берёт первую,
# но для аудита достаточно поймать наличие небезопасного значения — берём активное).
getval() {
    grep -iE "^[[:space:]]*$1[[:space:]]" "${cfg}" 2>/dev/null \
        | grep -vE '^[[:space:]]*#' | tail -1 | awk '{print $2}'
}

issues=0
check() {  # $1 директива  $2 ожидаемое  $3 сообщение
    local name="$1" want="$2" msg="$3"
    local actual; actual="$(getval "${name}")"
    if printf '%s' "${actual}" | grep -qiE "^${want}$"; then
        echo "  ✓ ${name} = ${actual} (ок)"
    else
        echo "  ⚠️ ${name} = ${actual:-<не задано>} — ${msg}"
        issues=$((issues + 1))
    fi
}

echo "=== Аудит закалки sshd_config: ${cfg} ==="
check PermitRootLogin        "no"  "root-логин должен быть запрещён (PermitRootLogin no)"
check PasswordAuthentication "no"  "парольный вход выключить, оставить только ключи"
check PermitEmptyPasswords   "no"  "пустые пароли недопустимы"
check X11Forwarding          "no"  "X11 forwarding обычно не нужен на сервере"

echo "---"
echo "Проблем: ${issues}"
if [ "${issues}" -gt 0 ]; then
    echo "ALERT: закали sshd_config и перезапусти sshd (systemctl — разберём в Season 3)" >&2
fi
exit 0
