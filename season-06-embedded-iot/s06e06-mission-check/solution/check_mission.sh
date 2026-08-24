#!/usr/bin/env bash
#
# check_mission.sh — проверка плана полёта до вылета (ЭТАЛОН, s06e06).
#
# Формат QGC WPL 110 (табуляции):
#   INDEX CURRENT FRAME COMMAND P1 P2 P3 P4 LAT LON ALT AUTOCONTINUE
#
# Все пределы — из файла ограничений (--limits), запретные зоны — из
# --nofly. В коде не зашито ни одного числа: у другого аппарата и другой
# площадки пределы другие, а проверки те же.
#
# Коды возврата:
#   0 — нарушений нет, лететь можно
#   1 — ошибка использования
#   2 — файл не читается или это не план полёта QGC WPL
#   3 — найдены нарушения (перечислены в выводе)

set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
LIMITS="${SELF_DIR}/limits.txt"
NOFLY="${SELF_DIR}/nofly.txt"

usage() {
    cat <<'USAGE'
check_mission.sh [--limits ФАЙЛ] [--nofly ФАЙЛ] ПЛАН.waypoints

Проверяет план полёта до вылета: высоты, длину плеч, общую дальность,
геозону, запретные зоны, нулевые координаты, единство кадра высоты и
наличие команды посадки.

Ключи:
  --limits ФАЙЛ  ограничения аппарата и площадки (ключ=значение)
  --nofly  ФАЙЛ  запретные зоны: имя lat lon радиус_м
  -h, --help     эта справка

Коды: 0 нарушений нет, 1 использование, 2 не тот формат, 3 есть нарушения
USAGE
}

while [ $# -gt 0 ]; do
    case "$1" in
        --limits) [ $# -ge 2 ] || { usage >&2; exit 1; }; LIMITS="$2"; shift 2 ;;
        --nofly)  [ $# -ge 2 ] || { usage >&2; exit 1; }; NOFLY="$2";  shift 2 ;;
        -h|--help) usage; exit 0 ;;
        --) shift; break ;;
        -*) printf 'check_mission: неизвестный ключ: %s\n' "$1" >&2; usage >&2; exit 1 ;;
        *) break ;;
    esac
done

[ $# -eq 1 ] || { usage >&2; exit 1; }
PLAN="$1"

[ -r "${PLAN}" ]   || { printf 'check_mission: не читается план: %s\n' "${PLAN}" >&2; exit 2; }
[ -r "${LIMITS}" ] || { printf 'check_mission: не читаются ограничения: %s\n' "${LIMITS}" >&2; exit 2; }
[ -r "${NOFLY}" ]  || { printf 'check_mission: не читаются запретные зоны: %s\n' "${NOFLY}" >&2; exit 2; }

# Заголовок — первая проверка: разбирать чужой формат как свой опаснее,
# чем отказаться его разбирать.
head -1 "${PLAN}" | grep -qE '^QGC WPL [0-9]+' \
    || { printf 'check_mission: не план полёта QGC WPL: %s\n' "${PLAN}" >&2; exit 2; }

VIOL="$(awk -v LIM="${LIMITS}" -v NF_="${NOFLY}" '
function rad(x) { return x * 3.141592653589793 / 180 }
function dist(la1, lo1, la2, lo2,   p1, p2, dp, dl, h) {
    p1 = rad(la1); p2 = rad(la2)
    dp = p2 - p1;  dl = rad(lo2 - lo1)
    h = sin(dp/2)^2 + cos(p1)*cos(p2)*sin(dl/2)^2
    if (h > 1) h = 1
    return 2 * 6371000.0 * atan2(sqrt(h), sqrt(1-h))
}
function viol(kind, msg) { printf "НАРУШЕНИЕ [%s] %s\n", kind, msg; n++ }

BEGIN {
    while ((getline line < LIM) > 0) {
        if (line ~ /^[[:space:]]*#/ || line !~ /=/) continue
        eq = index(line, "="); k = substr(line, 1, eq-1); v = substr(line, eq+1)
        gsub(/[[:space:]]/, "", k); gsub(/[[:space:]]/, "", v)
        L[k] = v
    }
    close(LIM)
    while ((getline line < NF_) > 0) {
        if (line ~ /^[[:space:]]*#/) continue
        if (split(line, f, /[[:space:]]+/) < 4) continue
        zn[++zc] = f[1]; zla[zc] = f[2]; zlo[zc] = f[3]; zr[zc] = f[4]
    }
    close(NF_)
}

# сам план: пропускаем заголовок и комментарии
FNR == 1 { next }
/^[[:space:]]*#/ || NF < 12 { next }
{
    i = $1
    idx[++m] = i; cur[m] = $2; frame[m] = $3; cmd[m] = $4
    lat[m] = $9; lon[m] = $10; alt[m] = $11; auto[m] = $12
}

END {
    if (m == 0) { print "НАРУШЕНИЕ [пусто] в плане нет ни одной точки"; n++; print "Нарушений: " n; exit }

    # 1. нумерация подряд с нуля
    for (j = 1; j <= m; j++)
        if (idx[j] + 0 != j - 1)
            viol("нумерация", sprintf("строка %d: индекс %s, ожидался %d", j, idx[j], j-1))

    # 2. первая точка — дом, и она текущая
    if (cmd[1] + 0 != 16 || cur[1] + 0 != 1)
        viol("дом", sprintf("точка 0: команда %s, current %s — первой должна быть точка дома (16) с current=1", cmd[1], cur[1]))

    # 3. последняя команда — посадка (21) или возврат (20)
    if (cmd[m] + 0 != 20 && cmd[m] + 0 != 21)
        viol("посадка", sprintf("точка %s: последняя команда %s — план не заканчивается посадкой (21) или возвратом (20)", idx[m], cmd[m]))

    # 4. нулевые координаты: точка, которую забыли заполнить
    for (j = 1; j <= m; j++)
        if (lat[j] + 0 == 0 && lon[j] + 0 == 0)
            viol("нулевая точка", sprintf("точка %s: координаты 0,0 — точка не заполнена", idx[j]))

    # 5. единый кадр высоты у путевых точек (дом задаётся отдельно)
    for (j = 2; j <= m; j++) {
        if (frame[j] + 0 != frame[2] + 0)
            viol("кадр высоты", sprintf("точка %s: frame %s, у остальных %s — высоты в разных системах отсчёта", idx[j], frame[j], frame[2]))
    }

    # 6. высоты в пределах
    for (j = 2; j <= m; j++) {
        if (cmd[j] + 0 == 21 || cmd[j] + 0 == 20) continue      # посадка/возврат — высота 0
        if (alt[j] + 0 > L["alt_max_m"] + 0)
            viol("высота", sprintf("точка %s: %s м выше предела %s", idx[j], alt[j], L["alt_max_m"]))
        else if (alt[j] + 0 < L["alt_min_m"] + 0)
            viol("высота", sprintf("точка %s: %s м ниже предела %s", idx[j], alt[j], L["alt_min_m"]))
    }

    # 7. запретные зоны
    for (j = 1; j <= m; j++) {
        if (lat[j] + 0 == 0 && lon[j] + 0 == 0) continue
        for (z = 1; z <= zc; z++) {
            dz = dist(lat[j], lon[j], zla[z], zlo[z])
            if (dz <= zr[z] + 0)
                viol("запретная зона", sprintf("точка %s: внутри «%s» (%d м до центра при радиусе %s)", idx[j], zn[z], int(dz+0.5), zr[z]))
        }
    }

    # 8. геозона: расстояние от дома
    for (j = 1; j <= m; j++) {
        if (lat[j] + 0 == 0 && lon[j] + 0 == 0) continue
        dh = dist(L["home_lat"], L["home_lon"], lat[j], lon[j])
        if (dh > L["geofence_radius_m"] + 0)
            viol("геозона", sprintf("точка %s: %d м от дома при радиусе %s", idx[j], int(dh+0.5), L["geofence_radius_m"]))
    }

    # 9. длина плеч и общая дальность.
    # Нулевые точки в цепочку не берём: считать до них бессмысленно,
    # о них уже сказано отдельно.
    p = 0; total = 0
    for (j = 1; j <= m; j++) {
        if (lat[j] + 0 == 0 && lon[j] + 0 == 0) continue
        if (p) {
            leg = dist(lat[p], lon[p], lat[j], lon[j])
            total += leg
            if (leg > L["leg_max_m"] + 0)
                viol("плечо", sprintf("точки %s->%s: %d м при пределе %s", idx[p], idx[j], int(leg+0.5), L["leg_max_m"]))
        }
        p = j
    }
    if (total > L["total_max_m"] + 0)
        viol("дальность", sprintf("маршрут %d м при пределе %s — не хватит заряда", int(total+0.5), L["total_max_m"]))

    printf "Всего точек: %d, маршрут %d м\n", m, int(total+0.5)
    printf "Нарушений: %d\n", n+0
}
' "${PLAN}")"

printf '%s\n' "${VIOL}"

COUNT="$(printf '%s\n' "${VIOL}" | awk -F': ' '/^Нарушений: /{print $2; exit}')"
[ "${COUNT:-0}" -eq 0 ] || exit 3
exit 0
