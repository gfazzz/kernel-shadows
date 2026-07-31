#!/usr/bin/env bash
#
# ssh_key_check.sh — s02e08 «Ключи вместо паролей»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: SSH-ключи — проверка ПРАВ приватного ключа (должно быть 600/400)
# и типа (ed25519 предпочтителен, dsa устарел).
# Type A — Bash Automation (аудит каталога ключей).
#
# Требования среды: bash + coreutils (stat), без root, без сети.
#
# Использование: ./ssh_key_check.sh SSH_DIR   (обычно ~/.ssh)

set -uo pipefail

keydir="${1:?Использование: ssh_key_check.sh SSH_DIR}"
[ -d "${keydir}" ] || { echo "Каталог не найден: ${keydir}" >&2; exit 1; }

# Кроссплатформенно: права в восьмеричном виде (Linux stat -c, BSD/macOS stat -f).
perm_of() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null; }

issues=0
found=0
for key in "${keydir}"/id_*; do
    [ -f "${key}" ] || continue
    case "${key}" in *.pub) continue ;; esac   # публичные ключи не проверяем
    found=$((found + 1))
    name="$(basename "${key}")"
    perm="$(perm_of "${key}")"

    if [ "${perm}" = "600" ] || [ "${perm}" = "400" ]; then
        echo "  ✓ ${name} — права ${perm} (ок)"
    else
        echo "  ⚠️ ${name} — права ${perm} (НЕБЕЗОПАСНО, нужно 600; SSH откажется его использовать)"
        issues=$((issues + 1))
    fi

    case "${name}" in
        id_ed25519) echo "     тип: ed25519 (рекомендуется)" ;;
        id_rsa)     echo "     тип: rsa (ок для старых серверов; ed25519 лучше)" ;;
        id_dsa)     echo "     ⚠️ ${name}: тип dsa устарел и небезопасен — замени на ed25519"; issues=$((issues + 1)) ;;
    esac
done

echo "---"
echo "Ключей проверено: ${found} | Проблем: ${issues}"
[ "${issues}" -gt 0 ] && echo "ALERT: исправь права/типы ключей: chmod 600 ~/.ssh/id_*" >&2
exit 0
