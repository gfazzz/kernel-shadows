#!/usr/bin/env bash
#
# ipinfo.sh — s02e01 «Твой адрес в сети»
# Эталон (открывать ПОСЛЕ своей попытки).
#
# Концепт: IPv4-адресация — валидация, класс, private/public, спец-адреса.
# Type A — Bash Automation (разбор адреса чистым bash, без сети).
#
# Требования среды: bash, без root, без сети.
#
# Использование: ./ipinfo.sh 10.50.1.100

set -uo pipefail

ip="${1:?Использование: ipinfo.sh IPv4}"

# --- Валидация: ровно 4 октета, каждый число 0-255 -------------------------
IFS='.' read -r -a oct <<< "${ip}"
valid=1
[ "${#oct[@]}" -eq 4 ] || valid=0
if [ "${valid}" -eq 1 ]; then
    for o in "${oct[@]}"; do
        case "${o}" in
            ''|*[!0-9]*) valid=0 ;;                        # пусто или не только цифры
            *) [ "${o}" -ge 0 ] && [ "${o}" -le 255 ] || valid=0 ;;
        esac
    done
fi
if [ "${valid}" -ne 1 ]; then
    echo "НЕВАЛИДНЫЙ IPv4: ${ip}" >&2
    exit 1
fi

a="${oct[0]}"; b="${oct[1]}"

echo "IP: ${ip}"

# --- Класс по первому октету -----------------------------------------------
if   [ "${a}" -lt 128 ]; then cls="A"
elif [ "${a}" -lt 192 ]; then cls="B"
elif [ "${a}" -lt 224 ]; then cls="C"
else                          cls="D/E (multicast/reserved)"
fi
echo "Класс: ${cls}"

# --- Тип: спец / private / public ------------------------------------------
if   [ "${a}" -eq 127 ]; then kind="loopback (localhost)"
elif [ "${ip}" = "255.255.255.255" ]; then kind="broadcast"
elif [ "${a}" -eq 10 ]; then kind="private (10.0.0.0/8)"
elif [ "${a}" -eq 172 ] && [ "${b}" -ge 16 ] && [ "${b}" -le 31 ]; then kind="private (172.16.0.0/12)"
elif [ "${a}" -eq 192 ] && [ "${b}" -eq 168 ]; then kind="private (192.168.0.0/16)"
else kind="public"
fi
echo "Тип: ${kind}"
