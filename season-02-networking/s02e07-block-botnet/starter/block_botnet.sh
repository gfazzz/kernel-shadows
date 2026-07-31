#!/usr/bin/env bash
#
# block_botnet.sh — s02e07 «Стена против ботнета» (СТАРТЕР, капстоун ep07)
#
# Задача: из списка вредоносных IP сгенерировать скрипт с правилами блокировки
# (ufw deny from <ip>) — НЕ применяя их. Пропускать # и пустые строки.
#
# Как проходить:
#   1. cp starter/block_botnet.sh artifacts/block_botnet.sh
#   2. заменить TODO
#   3. bash tests/test.sh
#
# Требования среды: bash. Критерии — в mission.md.

set -uo pipefail

list="${1:?Использование: block_botnet.sh IP_LIST [OUTPUT_FILE]}"
out="${2:-block_rules.sh}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

count=0
{
    echo "#!/usr/bin/env bash"
    echo "# Автосгенерированные правила блокировки. Применять: sudo bash ${out}"
    # TODO 1: пройди по списку (пропуская # и пустые), возьми IP как первое поле
    #         (ip="${line%% *}"), грубо проверь формат (*.*.*.*),
    #         на каждый валидный выведи "ufw deny from ${ip}" и count++.
    :
} > "${out}"

chmod +x "${out}" 2>/dev/null || true
echo "Правил сгенерировано: ${count} → ${out}"
