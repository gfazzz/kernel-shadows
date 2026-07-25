#!/usr/bin/env bash
#
# sshd_harden_check.sh — s02e09 «Закалённый вход» (СТАРТЕР, капстоун Season 2)
#
# Задача: проверить sshd_config по ключевым директивам закалки:
#   PermitRootLogin no, PasswordAuthentication no,
#   PermitEmptyPasswords no, X11Forwarding no.
# Для каждой — ✓ если безопасно, ⚠️ + счётчик иначе.
#
# Как проходить:
#   1. cp starter/sshd_harden_check.sh ./sshd_harden_check.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash. Критерии — в mission.md.

set -uo pipefail

cfg="${1:?Использование: sshd_harden_check.sh SSHD_CONFIG}"
[ -f "${cfg}" ] || { echo "Файл не найден: ${cfg}" >&2; exit 1; }

# Значение директивы (последняя незакомментированная строка).
getval() {
    grep -iE "^[[:space:]]*$1[[:space:]]" "${cfg}" 2>/dev/null \
        | grep -vE '^[[:space:]]*#' | tail -1 | awk '{print $2}'
}

issues=0

# TODO: для каждой директивы получи значение через getval и сравни с "no".
#   Совпало → ✓; иначе → ⚠️ + issues++.
#   Директивы: PermitRootLogin, PasswordAuthentication, PermitEmptyPasswords, X11Forwarding.
# Пример:
#   v="$(getval PermitRootLogin)"
#   if printf '%s' "$v" | grep -qiE '^no$'; then echo "✓ ..."; else echo "⚠️ ..."; issues=$((issues+1)); fi

echo "---"
echo "Проблем: ${issues}"
