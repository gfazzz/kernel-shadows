#!/usr/bin/env bash
#
# gpio_ctl.sh — управление ножками GPIO через sysfs (ЭТАЛОН, s06e02).
#
# Ядро выставляет GPIO наружу обычными файлами: пишешь номер в export —
# появляется каталог gpioN; пишешь in/out в direction — меняешь режим;
# пишешь 0/1 в value — меняешь уровень на ножке. Никакого C не нужно.
#
# Занятость ножек берётся из карты гребёнки (--map), а не зашита в код:
# у другой платы карта другая, а скрипт тот же.
#
# Коды возврата:
#   0 — успех
#   1 — ошибка использования (аргументы, неизвестная команда, плохое значение)
#   2 — нет sysfs GPIO (каталога или файла export)
#   3 — такого пина нет на гребёнке
#   4 — пин не экспортирован или направление не позволяет операцию
#   5 — пин занят другой периферией

set -uo pipefail

ROOT="/sys/class/gpio"
MAP="$(cd "$(dirname "$0")" && pwd)/gpio_map.txt"

usage() {
    cat <<'USAGE'
gpio_ctl.sh [--root КАТАЛОГ] [--map ФАЙЛ] КОМАНДА [АРГУМЕНТЫ]

Команды:
  export PIN             занять ножку (создаётся gpioN/)
  unexport PIN           освободить ножку
  direction PIN in|out   задать направление
  write PIN 0|1          выставить уровень (только для out)
  read PIN               напечатать текущий уровень
  status                 показать занятые нами ножки

Ключи:
  --root КАТАЛОГ  корень sysfs GPIO (по умолчанию /sys/class/gpio)
  --map ФАЙЛ      карта гребёнки: «пин функция», free — свободна
  -h, --help      эта справка

Коды: 0 успех, 1 использование, 2 нет sysfs, 3 нет такого пина,
      4 не экспортирован / не то направление, 5 занят периферией
USAGE
}

die() { printf 'gpio_ctl: %s\n' "$1" >&2; exit "$2"; }

# ── разбор аргументов ────────────────────────────────────────────────
while [ $# -gt 0 ]; do
    case "$1" in
        --root) [ $# -ge 2 ] || { usage >&2; exit 1; }; ROOT="$2"; shift 2 ;;
        --map)  [ $# -ge 2 ] || { usage >&2; exit 1; }; MAP="$2";  shift 2 ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) printf 'gpio_ctl: неизвестный ключ: %s\n' "$1" >&2; usage >&2; exit 1 ;;
        *) break ;;
    esac
done

[ $# -ge 1 ] || { usage >&2; exit 1; }
CMD="$1"; shift

# ── карта гребёнки ───────────────────────────────────────────────────
[ -f "${MAP}" ] || die "нет карты гребёнки: ${MAP}" 1

# функция ножки по карте; пустая строка — такой ножки на гребёнке нет
pin_function() {
    awk -v p="$1" '/^[[:space:]]*#/{next} NF>=2 && $1==p {print $2; exit}' "${MAP}"
}

# проверка «это вообще номер»
is_number() { case "$1" in ''|*[!0-9]*) return 1 ;; *) return 0 ;; esac; }

# полная проверка пина: существует на гребёнке и свободен
check_pin() {
    local pin="$1" fn
    is_number "${pin}" || die "номер пина должен быть числом: «${pin}»" 1
    fn="$(pin_function "${pin}")"
    [ -n "${fn}" ] || die "пина ${pin} нет на гребёнке (см. ${MAP})" 3
    [ "${fn}" = "free" ] || die "пин ${pin} занят периферией: ${fn} — не трогаем" 5
}

# ── sysfs ────────────────────────────────────────────────────────────
need_sysfs() {
    [ -d "${ROOT}" ]        || die "нет каталога sysfs GPIO: ${ROOT}" 2
    [ -e "${ROOT}/export" ] || die "нет ${ROOT}/export — это не sysfs GPIO" 2
}

pin_dir()      { printf '%s/gpio%s' "${ROOT}" "$1"; }
is_exported()  { [ -d "$(pin_dir "$1")" ]; }

# запись в файл sysfs с внятной ошибкой вместо «Permission denied»
put() {
    local file="$1" val="$2"
    printf '%s\n' "${val}" > "${file}" 2>/dev/null \
        || die "не удалось записать «${val}» в ${file} (права? занято?)" 4
}

need_exported() {
    is_exported "$1" || die "пин $1 не экспортирован — сначала: export $1" 4
}

get_direction() {
    local d="$(pin_dir "$1")/direction"
    [ -r "${d}" ] && tr -d '[:space:]' < "${d}" || printf ''
}

# ── команды ──────────────────────────────────────────────────────────
cmd_export() {
    [ $# -eq 1 ] || { usage >&2; exit 1; }
    check_pin "$1"; need_sysfs
    # Идемпотентность: повторная запись уже занятого номера в export —
    # это EBUSY, «Device or resource busy». Уже занято — значит готово.
    if is_exported "$1"; then
        printf 'пин %s уже экспортирован\n' "$1"
        return 0
    fi
    put "${ROOT}/export" "$1"
    printf 'пин %s экспортирован\n' "$1"
}

cmd_unexport() {
    [ $# -eq 1 ] || { usage >&2; exit 1; }
    check_pin "$1"; need_sysfs
    # Освобождать то, что уже свободно, — не ошибка: цель достигнута.
    if ! is_exported "$1"; then
        printf 'пин %s и так свободен\n' "$1"
        return 0
    fi
    put "${ROOT}/unexport" "$1"
    printf 'пин %s освобождён\n' "$1"
}

cmd_direction() {
    [ $# -eq 2 ] || { usage >&2; exit 1; }
    case "$2" in in|out) : ;; *) die "направление должно быть in или out: «$2»" 1 ;; esac
    check_pin "$1"; need_sysfs; need_exported "$1"
    put "$(pin_dir "$1")/direction" "$2"
    printf 'пин %s: направление %s\n' "$1" "$2"
}

cmd_write() {
    [ $# -eq 2 ] || { usage >&2; exit 1; }
    case "$2" in 0|1) : ;; *) die "значение должно быть 0 или 1: «$2»" 1 ;; esac
    check_pin "$1"; need_sysfs; need_exported "$1"
    local dir; dir="$(get_direction "$1")"
    # Вход управляется внешним миром: писать в него бессмысленно, а на
    # некоторых платах — вредно. Проверяем направление ДО записи.
    [ "${dir}" = "out" ] || die "пин $1 в режиме «${dir:-неизвестно}» — записать можно только в out" 4
    put "$(pin_dir "$1")/value" "$2"
    printf 'пин %s: значение %s\n' "$1" "$2"
}

cmd_read() {
    [ $# -eq 1 ] || { usage >&2; exit 1; }
    check_pin "$1"; need_sysfs; need_exported "$1"
    local v="$(pin_dir "$1")/value"
    [ -r "${v}" ] || die "нет ${v}" 4
    tr -d '[:space:]' < "${v}"; printf '\n'
}

cmd_status() {
    [ $# -eq 0 ] || { usage >&2; exit 1; }
    need_sysfs
    local found=0 d pin dir val
    for d in "${ROOT}"/gpio[0-9]*; do
        [ -d "${d}" ] || continue
        pin="${d##*/gpio}"
        is_number "${pin}" || continue
        found=$((found+1))
        dir="$(get_direction "${pin}")"
        val="$( [ -r "${d}/value" ] && tr -d '[:space:]' < "${d}/value" || printf '?' )"
        printf 'пин %-3s направление %-3s значение %s функция %s\n' \
               "${pin}" "${dir:-?}" "${val}" "$(pin_function "${pin}")"
    done
    [ "${found}" -gt 0 ] || printf 'экспортированных пинов нет\n'
    return 0
}

case "${CMD}" in
    export)    cmd_export    "$@" ;;
    unexport)  cmd_unexport  "$@" ;;
    direction) cmd_direction "$@" ;;
    write)     cmd_write     "$@" ;;
    read)      cmd_read      "$@" ;;
    status)    cmd_status    "$@" ;;
    help)      usage ;;
    *) printf 'gpio_ctl: неизвестная команда: %s\n' "${CMD}" >&2; usage >&2; exit 1 ;;
esac
