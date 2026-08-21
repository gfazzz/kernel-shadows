#!/usr/bin/env bash
#
# s06e05 «Телеметрия дрона» — тест разбора потока (Type C).
#
# Ни одного зашитого ответа: заголовок кадра пересчитывается из
# data/frame_sample.hex по смещениям, статистика потока — из
# data/telemetry.txt, имена сообщений и режимов — соединением со
# справочниками. Подмени данные — тест будет ждать другие значения.
#
# Отдельно проверяется, что потери считаются с учётом однобайтового
# счётчика и раздельно по системам: три «почти правильных» способа
# счёта дают три разных неверных числа.
#
# Без root, без сети, без дрона.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HEX="${SERIES_DIR}/data/frame_sample.hex"
TEL="${SERIES_DIR}/data/telemetry.txt"
IDS="${SERIES_DIR}/data/mavlink_msgids.txt"
MODES="${SERIES_DIR}/data/ardupilot_modes.txt"

if   [ -n "${SUBJECT:-}" ];                                 then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/telemetry_report.txt" ]; then REP="${SERIES_DIR}/artifacts/telemetry_report.txt"
elif [ -f "${SERIES_DIR}/telemetry_report.txt" ];           then REP="${SERIES_DIR}/telemetry_report.txt"
else REP="${SERIES_DIR}/solution/telemetry_report.txt"
     echo "ℹ️  Своего telemetry_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/telemetry_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s06e05 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${HEX}" "${TEL}" "${IDS}" "${MODES}"; do [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }; done
if [ -f "${REP}" ]; then ok "telemetry_report.txt найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

got()   { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "${REP}"; }
check() { local k="$1" want="$2" why="$3" have; have="$(got "${k}")"
    if [ -z "${have}" ]; then no "${k}: не заполнено (${why})"
    elif [ "${have}" = "${want}" ]; then ok "${k}=${have}"
    else no "${k}=${have}, из данных следует «${want}» — ${why}"; fi; }

# ── кадр из hex ──────────────────────────────────────────────────────
BYTES=($(grep -v '^[[:space:]]*#' "${HEX}" | tr 'a-f' 'A-F' | tr -cs '0-9A-F' ' '))
b() { printf '%d' "0x${BYTES[$1]}"; }

E_MAGIC="0x${BYTES[0]}"
case "${E_MAGIC}" in 0xFD) E_VER=2; HDR=10 ;; 0xFE) E_VER=1; HDR=6 ;; *) E_VER=0; HDR=0 ;; esac
E_PLEN="$(b 1)"
E_FLEN=$((HDR + E_PLEN + 2))
if [ "${E_VER}" = 2 ]; then
    E_SEQ="$(b 4)"; E_SYS="$(b 5)"; E_COMP="$(b 6)"
    E_MSGID=$(( $(b 7) + $(b 8)*256 + $(b 9)*65536 ))
else
    E_SEQ="$(b 2)"; E_SYS="$(b 3)"; E_COMP="$(b 4)"; E_MSGID="$(b 5)"
fi
E_MNAME="$(awk -v m="${E_MSGID}" '/^[[:space:]]*#/{next} $1==m {print $2; exit}' "${IDS}")"

echo ""
echo "── Исходные данные ──"
if [ "${E_VER}" != 0 ] && [ -n "${E_MNAME}" ]
then ok "кадр разобран: версия ${E_VER}, msgid ${E_MSGID} = ${E_MNAME}"
else no "не разобрался frame_sample.hex (магический байт ${E_MAGIC})"; fi

# ── поток ────────────────────────────────────────────────────────────
R="$(grep -v '^[[:space:]]*#' "${TEL}" | grep -v '^[[:space:]]*$')"
E_SYSN="$(awk '{print $2}' <<<"${R}" | sort -u | grep -c .)"
# аппарат — тот, кто шлёт ATTITUDE (30); станция — второй
E_UAV="$(awk '$5==30 {print $2; exit}' <<<"${R}")"
E_GCS="$(awk -v u="${E_UAV}" '$2!=u {print $2; exit}' <<<"${R}")"
E_UFR="$(awk -v u="${E_UAV}" '$2==u' <<<"${R}" | grep -c .)"
E_TYPES="$(awk -v u="${E_UAV}" '$2==u {print $5}' <<<"${R}" | sort -u | grep -c .)"

# потери: только кадры аппарата, разности по модулю 256
E_LOST="$(awk -v u="${E_UAV}" '$2==u {s=$4; if (p!="") {d=(s-p-1)%256; if(d<0)d+=256; t+=d} p=s} END{print t+0}' <<<"${R}")"
E_PCT="$(awk -v l="${E_LOST}" -v n="${E_UFR}" 'BEGIN{printf "%.1f", l*100/(l+n)}')"
# «почти правильные» способы — для диагностики
W_SKIP="$(awk -v u="${E_UAV}" '$2==u {s=$4; if (p!="" && s>p) t+=s-p-1; p=s} END{print t+0}' <<<"${R}")"
W_MIX="$(awk '{s=$4; if (p!="") {d=(s-p-1)%256; if(d<0)d+=256; t+=d} p=s} END{print t+0}' <<<"${R}")"

E_GAP="$(awk -v u="${E_UAV}" '$2==u {if (p!="" && $1-p>g) g=$1-p; p=$1} END{print g+0}' <<<"${R}")"
E_GPS="$(awk -v u="${E_UAV}" '$2==u && $5==24 {for(i=6;i<=NF;i++) if ($i ~ /^fix_type=/) {split($i,a,"="); if (a[2]<3) {print $1; exit}}}' <<<"${R}")"
E_SATS="$(awk -v u="${E_UAV}" '$2==u && $5==24 {for(i=6;i<=NF;i++) if ($i ~ /^satellites_visible=/) {split($i,a,"="); if (m==""||a[2]<m) m=a[2]}} END{print m}' <<<"${R}")"
E_VMIN="$(awk -v u="${E_UAV}" '$2==u && $5==147 {for(i=6;i<=NF;i++) if ($i ~ /^voltage=/) {split($i,a,"="); if (m==""||a[2]+0<m+0) m=a[2]}} END{print m}' <<<"${R}")"
E_PMIN="$(awk -v u="${E_UAV}" '$2==u && $5==147 {for(i=6;i<=NF;i++) if ($i ~ /^battery_remaining=/) {split($i,a,"="); if (m==""||a[2]+0<m+0) m=a[2]}} END{print m}' <<<"${R}")"
E_SEV="$(awk -v u="${E_UAV}" '$2==u && $5==253 {for(i=6;i<=NF;i++) if ($i ~ /^severity=/) {split($i,a,"="); if (m==""||a[2]+0<m+0) m=a[2]}} END{print m}' <<<"${R}")"
E_MODEN="$(awk -v u="${E_UAV}" '$2==u && $5==0 {for(i=6;i<=NF;i++) if ($i ~ /^custom_mode=/) {split($i,a,"="); m=a[2]}} END{print m}' <<<"${R}")"
E_MODE="$(awk -v m="${E_MODEN}" '/^[[:space:]]*#/{next} $1==m {print $2; exit}' "${MODES}")"

if [ "${E_SYSN}" -ge 2 ] && [ "${E_LOST}" -gt 0 ] && [ "${E_LOST}" != "${W_SKIP}" ]
then ok "поток разобран: ${E_SYSN} системы, потери ${E_LOST} (иначе вышло бы ${W_SKIP} или ${W_MIX})"
else no "данные вырождены: потери ${E_LOST}, способы счёта не различаются"; fi

echo ""
echo "── 1. Разбор кадра ──"
check frame_magic     "${E_MAGIC}"  "первый байт потока"
check mavlink_version "${E_VER}"    "версию объявляет магический байт"
check payload_len     "${E_PLEN}"   "второй байт заголовка"
check frame_len       "${E_FLEN}"   "заголовок ${HDR} + нагрузка ${E_PLEN} + сумма 2"
check frame_seq       "${E_SEQ}"    "смещение 4"
check frame_sysid     "${E_SYS}"    "смещение 5"
check frame_compid    "${E_COMP}"   "смещение 6"
check frame_msgid     "${E_MSGID}"  "смещения 7..9, младший байт первым"
check frame_msg_name  "${E_MNAME}"  "по справочнику msgid -> имя"

echo ""
echo "── 2. Линия и потери ──"
check systems_on_link "${E_SYSN}"  "разных sysid в потоке"
check uav_sysid       "${E_UAV}"   "тот, кто шлёт ATTITUDE и GPS_RAW_INT"
check gcs_sysid       "${E_GCS}"   "второй участник линии"
check uav_frames      "${E_UFR}"   "число дошедших кадров аппарата"

HAVE_LOST="$(got lost_frames)"
if [ "${HAVE_LOST}" = "${E_LOST}" ]; then ok "lost_frames=${HAVE_LOST}"
elif [ "${HAVE_LOST}" = "${W_SKIP}" ]; then no "lost_frames=${HAVE_LOST}: убывания seq просто пропущены — потеря на переходе 255->0 не посчитана (верно ${E_LOST})"
elif [ "${HAVE_LOST}" = "${W_MIX}" ]; then no "lost_frames=${HAVE_LOST}: посчитано по всем кадрам сразу — у каждой системы свой счётчик (верно ${E_LOST})"
elif [ -z "${HAVE_LOST}" ]; then no "lost_frames: не заполнено"
else no "lost_frames=${HAVE_LOST}, из данных следует ${E_LOST} — разрывы seq аппарата по модулю 256"; fi

check loss_percent    "${E_PCT}"   "потери от отправленного, один знак после точки"
check msg_types       "${E_TYPES}" "разных msgid у аппарата"

echo ""
echo "── 3. Что случилось ──"
check link_gap_ms     "${E_GAP}"   "наибольший промежуток между кадрами аппарата"
check gps_lost_ms     "${E_GPS}"   "первый GPS_RAW_INT с fix_type < 3"
check sats_min        "${E_SATS}"  "минимум satellites_visible"
check battery_min_v   "${E_VMIN}"  "минимум voltage в BATTERY_STATUS"
check battery_min_pct "${E_PMIN}"  "минимум battery_remaining"
check worst_severity  "${E_SEV}"   "в MAVLink меньшее severity = серьёзнее"
check final_mode      "${E_MODE}"  "custom_mode=${E_MODEN} по таблице режимов"

echo ""
echo "── Комментарии сохранены ──"
grep -qE '^[[:space:]]*#' "${REP}" && ok "пояснения в файле остались" \
                                   || no "все комментарии вырезаны — отчёт должен объяснять, откуда значения"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
