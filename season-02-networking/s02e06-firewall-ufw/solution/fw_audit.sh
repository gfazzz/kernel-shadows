#!/usr/bin/env bash
#
# fw_audit.sh — s02e06 «Читаем стену»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: firewall (ufw/iptables) — читаем правила и ловим опасные ALLOW
# (чувствительные порты, открытые наружу «Anywhere»).
# Type B — Linux Tools: анализ вывода `ufw status`, bash только оформляет.
#
# Требования среды: bash, без root. Работает над фикстурой-выводом `ufw status`
# (реальный ufw трогает ядро и требует root — здесь только читаем правила из файла).
#
# Использование: ./fw_audit.sh UFW_STATUS_FILE

set -uo pipefail

rules="${1:?Использование: fw_audit.sh UFW_STATUS_FILE}"
[ -f "${rules}" ] || { echo "Файл не найден: ${rules}" >&2; exit 1; }

# Порты, которые НЕ должны торчать в интернет (БД, кэши, поиск).
sensitive="3306 5432 6379 27017 9200 11211"

issues=0
echo "=== ALLOW-правила ==="
while IFS= read -r line; do
    case "${line}" in *ALLOW*) ;; *) continue ;; esac
    port="${line%% *}"        # первое поле — порт ("3306" или "22/tcp")
    port="${port%%/*}"        # отрезаем /tcp
    echo "  ALLOW: ${line}"
    for s in ${sensitive}; do
        if [ "${port}" = "${s}" ] && printf '%s' "${line}" | grep -qi "Anywhere"; then
            echo "    ⚠️ чувствительный порт ${port} открыт наружу (Anywhere)!"
            issues=$((issues + 1))
        fi
    done
done < "${rules}"

echo "---"
echo "Проблем: ${issues}"
if [ "${issues}" -gt 0 ]; then
    echo "ALERT: есть сервисы, открытые в интернет — привяжи их к 127.0.0.1 или ограничь From" >&2
fi
exit 0
