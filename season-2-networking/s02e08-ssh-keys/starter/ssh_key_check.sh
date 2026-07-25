#!/usr/bin/env bash
#
# ssh_key_check.sh — s02e08 «Ключи вместо паролей» (СТАРТЕР)
#
# Задача: проверить приватные SSH-ключи (id_*) в каталоге:
#   - права должны быть 600 или 400 (иначе SSH откажется их использовать);
#   - тип: ed25519 (хорошо), rsa (ок), dsa (устарел).
# Публичные (*.pub) не проверять.
#
# Как проходить:
#   1. cp starter/ssh_key_check.sh ./ssh_key_check.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash + stat. Критерии — в mission.md.

set -uo pipefail

keydir="${1:?Использование: ssh_key_check.sh SSH_DIR}"
[ -d "${keydir}" ] || { echo "Каталог не найден: ${keydir}" >&2; exit 1; }

# Права в восьмеричном виде (кроссплатформенно).
perm_of() { stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null; }

issues=0
found=0
for key in "${keydir}"/id_*; do
    [ -f "${key}" ] || continue
    case "${key}" in *.pub) continue ;; esac
    found=$((found + 1))
    name="$(basename "${key}")"
    perm="$(perm_of "${key}")"

    # TODO 1: если perm НЕ 600 и НЕ 400 — предупреждение, issues++.
    # TODO 2: по имени определи тип (id_ed25519 / id_rsa / id_dsa),
    #         для dsa — предупреждение и issues++.
    :
done

echo "---"
echo "Ключей проверено: ${found} | Проблем: ${issues}"
