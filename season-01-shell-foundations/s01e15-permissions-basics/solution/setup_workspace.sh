#!/usr/bin/env bash
#
# setup_workspace.sh — подготовка рабочего каталога операции (ЭТАЛОН)
#
# Создаёт структуру и выставляет права. Главное свойство: скрипт можно
# запускать сколько угодно раз, и он ПРИВОДИТ каталог к нужному виду —
# а не только создаёт его с нуля. Каталог, который кто-то уже испортил,
# он чинит.
#
# Прав root не нужно: всё происходит в своём каталоге.
#
# Использование:
#   ./setup_workspace.sh --root ~/ops [--quiet]

set -euo pipefail

ROOT=""
QUIET=0

while [ $# -gt 0 ]; do
    case "$1" in
        --root)  ROOT="$2"; shift 2 ;;
        --quiet) QUIET=1;   shift   ;;
        *) echo "неизвестный аргумент: $1" >&2; exit 2 ;;
    esac
done

[ -n "${ROOT}" ] || { echo "не задан --root" >&2; exit 2; }
if [ -e "${ROOT}" ] && [ ! -d "${ROOT}" ]; then
    echo "по этому пути уже есть файл, а нужен каталог: ${ROOT}" >&2; exit 1
fi

say() { [ "${QUIET}" -eq 1 ] || printf '%s\n' "$*"; }

# права одинаково читаются в GNU и BSD
mode_of() {
    stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null
}

# ensure_mode ПУТЬ РЕЖИМ — выставить, только если он не такой; сообщить об изменении
ensure_mode() {
    local path="$1" want="$2" have
    have="$(mode_of "${path}")"
    # ведущий ноль в выводе stat не значим: 0700 и 700 — одно и то же
    if [ "$(( 8#${have} ))" -ne "$(( 8#${want} ))" ]; then
        chmod "${want}" "${path}"
        say "  ${path}: ${have} → ${want}"
    fi
}

mkdir -p "${ROOT}"
say "рабочий каталог: ${ROOT}"

# ---- каталоги ----------------------------------------------------------------
# scripts  700 — свои инструменты: читать, писать и запускать может только владелец
# secrets  700 — сюда лягут ключи и пароли; посторонним нечего даже перечислять
# reports  755 — отчёты отдают другим, значит их читают
# logs     750 — журналы читает группа, посторонние нет
for pair in "scripts 700" "secrets 700" "reports 755" "logs 750"; do
    set -- ${pair}
    dir="${ROOT}/$1"; mode="$2"
    [ -d "${dir}" ] || { mkdir -p "${dir}"; say "  создан ${dir}"; }
    ensure_mode "${dir}" "${mode}"
done

# ---- файлы внутри ------------------------------------------------------------
# всё в secrets/ — строго 600, независимо от того, как оно там появилось
find "${ROOT}/secrets" -type f -print | while IFS= read -r f; do
    ensure_mode "${f}" 600
done

# скрипты — 700: исполняемые и только для владельца
find "${ROOT}/scripts" -type f -name '*.sh' -print | while IFS= read -r f; do
    ensure_mode "${f}" 700
done

# отчёты читаемы, но не исполняемы: 644
find "${ROOT}/reports" -type f -print | while IFS= read -r f; do
    ensure_mode "${f}" 644
done

say "готово"
