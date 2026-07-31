#!/usr/bin/env bash
#
# block_botnet.sh — s02e07 «Стена против ботнета» (КАПСТОУН ep07)
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: из списка вредоносных IP сгенерировать правила блокировки (ufw).
# ГЕНЕРИРУЕТ скрипт-правила, но НЕ применяет их (применение требует root) —
# это делает капстоун воспроизводимым и безопасным.
# Type B — Linux Tools (правила ufw + минимум bash).
#
# Требования среды: bash, без root, без сети.
#
# Использование: ./block_botnet.sh IP_LIST [OUTPUT_FILE]

set -uo pipefail

list="${1:?Использование: block_botnet.sh IP_LIST [OUTPUT_FILE]}"
out="${2:-block_rules.sh}"
[ -f "${list}" ] || { echo "Файл не найден: ${list}" >&2; exit 1; }

count=0
{
    echo "#!/usr/bin/env bash"
    echo "# Автосгенерированные правила блокировки ботнета."
    echo "# Применять с root:  sudo bash ${out}"
    echo "# Источник: ${list} | Сгенерировано: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "set -euo pipefail"
    while IFS= read -r line; do
        [ -z "${line}" ] && continue
        case "${line}" in \#*) continue ;; esac
        ip="${line%% *}"                    # первое поле — IP (без inline-коммента)
        case "${ip}" in *.*.*.*) ;; *) continue ;; esac   # грубая проверка формата IPv4
        echo "ufw deny from ${ip}"
        count=$((count + 1))
    done < "${list}"
    echo "echo \"Заблокировано IP: ${count}\""
} > "${out}"

chmod +x "${out}" 2>/dev/null || true
echo "Правил сгенерировано: ${count} → ${out}"
[ "${count}" -eq 0 ] && { echo "В списке нет валидных IP" >&2; exit 1; }
exit 0
