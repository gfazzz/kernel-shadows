#!/usr/bin/env bash
#
# s07e08 «Где узкое место» — тест находок (Type C).
#
# Проверяет не скрипт, а разбор: каждое значение отчёта пересчитывается из
# снимков в data/ теми же приёмами, что предлагает задание. Констант нет.
#
# Ключевая самопроверка данных — что узкое место ровно одно и что оно не
# аппаратное: если бы упёрлись процессор или диск, серия свелась бы к
# чтению одной колонки.
#
# Все сравниваемые величины — целые: доли секунды и проценты с плавающей
# точкой между машинами и локалями не сравнивают.
#
# Без root, без сети, без кластера.
#
# Выбор отчёта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
VM="${D}/vmstat.txt"; IO="${D}/iostat.txt"; FREE="${D}/free.txt"
NST="${D}/nstat.txt"; CAD="${D}/cadvisor.txt"; APP="${D}/app_metrics.txt"
THR="${D}/use_thresholds.txt"

if   [ -n "${SUBJECT:-}" ];                                   then REP="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/bottleneck_report.txt" ];  then REP="${SERIES_DIR}/artifacts/bottleneck_report.txt"
elif [ -f "${SERIES_DIR}/bottleneck_report.txt" ];            then REP="${SERIES_DIR}/bottleneck_report.txt"
else REP="${SERIES_DIR}/solution/bottleneck_report.txt"
     echo "ℹ️  Своего bottleneck_report.txt не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/bottleneck_report.txt artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s07e08 tests — отчёт: ${REP#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${VM}" "${IO}" "${FREE}" "${NST}" "${CAD}" "${APP}" "${THR}"; do
    [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }
done
if [ -f "${REP}" ]; then ok "bottleneck_report.txt найден"
else no "не найден"; echo " Итог: ${PASS} passed, ${FAIL} failed"; exit 1; fi

got()   { awk -F= -v k="$1" '/^[[:space:]]*#/{next} $1==k {sub(/^[^=]*=/,""); gsub(/^[[:space:]]+|[[:space:]]+$/,""); print; exit}' "${REP}"; }
check() { local k="$1" want="$2" why="$3" have; have="$(got "${k}")"
    if [ -z "${have}" ]; then no "${k}: не заполнено (${why})"
    elif [ "${have}" = "${want}" ]; then ok "${k}=${have}"
    else no "${k}=${have}, из снимков следует «${want}» — ${why}"; fi; }

# ── пересчёт из снимков ──────────────────────────────────────────────
# Строки vmstat: две шапки отброшены, у данных ровно 17 полей.
vmrows() { awk '/^[[:space:]]*#/{next} /^procs/{next} /^ r  b/{next} NF>=17' "${VM}"; }
E_CPU=$(vmrows | awk '{if (min=="" || $15<min) min=$15} END{print 100-min}')
E_RQ=$(vmrows  | awk '{if ($1>m) m=$1} END{print m+0}')
E_WA=$(vmrows  | awk '{if ($16>m) m=$16} END{print m+0}')
E_SWAP=$(vmrows | awk '{s+=$7+$8} END{print s+0}')
E_MEM=$(awk '/^Mem:/ {printf "%d\n", $7*100/$2}' "${FREE}")
E_DISK=$(awk '/^[[:space:]]*#/{next} /^Device/{next} NF>=9 {if ($9+0>m) m=$9+0} END{printf "%d\n", m}' "${IO}")
E_RETR=$(awk '$1=="TcpRetransSegs" {print $2; exit}' "${NST}")
E_OVER=$(awk '$1=="TcpExtListenOverflows" {print $2; exit}' "${NST}")
E_THR=$(awk '$1=="container_cpu_cfs_periods_total"{p=$2}
             $1=="container_cpu_cfs_throttled_periods_total"{t=$2}
             END{printf "%d\n", t*100/p}' "${CAD}")
E_CMEM=$(awk '$1=="container_memory_working_set_bytes"{w=$2}
              $1=="container_spec_memory_limit_bytes"{l=$2}
              END{printf "%d\n", w*100/l}' "${CAD}")
a() { awk -v k="$1" '/^[[:space:]]*#/{next} $1==k {print $2; exit}' "${APP}"; }
E_PMAX=$(a pool_max); E_PUSE=$(a pool_in_use_max); E_PWAIT=$(a pool_waiters_max)
E_PUTIL=$(awk -v u="${E_PUSE}" -v m="${E_PMAX}" 'BEGIN{printf "%d\n", u*100/m}')
E_SHARE=$(awk -v w="$(a pool_wait_p95_ms)" -v r="$(a request_p95_ms)" 'BEGIN{printf "%d\n", w*100/r}')
t() { awk -v k="$1" '/^[[:space:]]*#/{next} $1==k {print $2; exit}' "${THR}"; }
verdict() { [ "$1" -gt "$2" ] && echo saturated || echo ok; }
E_VCPU=$(verdict "${E_CPU}"   "$(t cpu_util_warn_pct)")
E_VMEM=$(verdict "$(( 100 - E_MEM ))" "$(t mem_util_warn_pct)")
E_VDSK=$(verdict "${E_DISK}"  "$(t disk_util_warn_pct)")
E_VNET=$(verdict "${E_RETR}"  "$(t retrans_warn)")
E_VCON=$(verdict "${E_THR}"   "$(t throttle_warn_pct)")
E_VPOOL=$(verdict "${E_PUTIL}" "$(t pool_util_warn_pct)")

echo ""
echo "── Исходные данные ──"
N_SAT=0
for v in "${E_VCPU}" "${E_VMEM}" "${E_VDSK}" "${E_VNET}" "${E_VCON}" "${E_VPOOL}"; do
    [ "${v}" = saturated ] && N_SAT=$(( N_SAT + 1 ))
done
if [ "${N_SAT}" -eq 1 ]
then ok "по порогам узкое место ровно одно — разбор имеет однозначный ответ"
else no "данные вырождены: ресурсов за порогом ${N_SAT}, а не один"; fi
if [ "${E_VCPU}" = ok ] && [ "${E_VDSK}" = ok ] && [ "${E_VMEM}" = ok ]
then ok "процессор, память и диск в норме — упёрлось не в железо"
else no "данные вырождены: упёрлось в аппаратный ресурс, и разбор сводится к одной колонке"; fi
if [ "${E_SHARE}" -ge 50 ]
then ok "ожидание соединения — ${E_SHARE} % времени ответа, то есть большая его часть"
else no "данные вырождены: ожидание пула не объясняет задержку"; fi
if [ "${E_PWAIT}" -gt "${E_PMAX}" ]
then ok "очередь к пулу (${E_PWAIT}) длиннее самого пула (${E_PMAX}) — насыщение налицо"
else no "данные вырождены: очереди к пулу нет"; fi

echo ""
echo "── 1. Процессор узла ──"
check cpu_util_max_pct "${E_CPU}"  "100 минус наименьший id в vmstat"
check run_queue_max    "${E_RQ}"   "наибольшее r"
check iowait_max_pct   "${E_WA}"   "наибольшее wa"

echo ""
echo "── 2. Память узла ──"
check mem_available_pct "${E_MEM}"  "available к total в free"
check swap_traffic_kb   "${E_SWAP}" "сумма si и so"

echo ""
echo "── 3. Диск ──"
check disk_util_max_pct "${E_DISK}" "наибольший %util"

echo ""
echo "── 4. Сеть ──"
check tcp_retrans      "${E_RETR}" "TcpRetransSegs"
check listen_overflows "${E_OVER}" "TcpExtListenOverflows"

echo ""
echo "── 5. Контейнер ──"
check cpu_throttled_pct      "${E_THR}"  "throttled_periods к periods"
check container_mem_util_pct "${E_CMEM}" "working_set к пределу"

echo ""
echo "── 6. Пул соединений ──"
check pool_max         "${E_PMAX}"  "потолок из app_metrics"
check pool_in_use_max  "${E_PUSE}"  "наибольшая занятость"
check pool_util_pct    "${E_PUTIL}" "занято к потолку"
check pool_waiters_max "${E_PWAIT}" "наибольшая очередь ожидающих"

echo ""
echo "── 7. Куда уходит время ──"
check wait_share_pct "${E_SHARE}" "ожидание пула к полному времени ответа"

echo ""
echo "── 8. Приговор ──"
check cpu_verdict           "${E_VCPU}"  "утилизация против порога"
check memory_verdict        "${E_VMEM}"  "занято = 100 минус доступно"
check disk_verdict          "${E_VDSK}"  "занятость устройства против порога"
check network_verdict       "${E_VNET}"  "повторы против порога"
check container_cpu_verdict "${E_VCON}"  "троттлинг против порога"
check pool_verdict          "${E_VPOOL}" "утилизация пула против порога"

E_BN=db-pool
check bottleneck      "${E_BN}"     "единственный ресурс за порогом"
check bottleneck_kind "saturation"  "утилизация 100 % и растущая очередь — это насыщение"

echo ""
echo "── Выводы ──"
if [ "$(got bottleneck)" != cpu ] && [ "$(got bottleneck)" != disk ]
then ok "узким местом назван не аппаратный ресурс"
else no "названо железо, хотя процессор занят на ${E_CPU} %, а диск на ${E_DISK} %"; fi
grep -qE '^[[:space:]]*#' "${REP}" && ok "пояснения в файле остались" \
    || no "все комментарии вырезаны — отчёт должен объяснять, откуда значения"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
