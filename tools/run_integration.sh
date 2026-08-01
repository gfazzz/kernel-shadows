#!/usr/bin/env bash
#
# run_integration.sh — прогон тестов, которым нужен живой хост (план §7.1).
#
# Двухуровневая модель курса:
#   unit        — обязателен, зелёный без root и сети, работает на фикстурах
#                 и подменённых бинарниках; запускается через tools/run_tests.sh;
#   integration — для серий, которым реально нужны systemd, Docker или root.
#
# Такой тест объявляется наличием файла tests/integration.sh в серии и
# декларацией требований в её mission.md. Раннер их находит сам.
#
# СОСТОЯНИЕ НА СЕЙЧАС: интеграционных тестов в курсе нет. Все 23 серии S1–S2
# проходят на unit-уровне без root и сети — включая те три, что план §7.1
# и §17 числили требующими живого хоста (s01e14, s02e06, s02e07): первая
# мокает dpkg, вторая стала разведкой по снимку из data/, третья подменяет
# ufw заглушкой-регистратором вызовов.
#
# Цель существует заранее, чтобы у S3+ было куда класть такие тесты: там
# появятся systemd (S3), Docker (S4) и модуль ядра (S6), и часть проверок
# честно не сведётся к фикстуре.
#
# Использование:
#   bash tools/run_integration.sh              # все интеграционные тесты
#   SEASON=season-03-… bash tools/run_integration.sh
#
# Код возврата: 0 — все зелёные либо запускать нечего; 1 — есть падения.

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

filter="${1:-${SEASON:-}}"
LOGDIR="${ROOT}/tests/logs"
mkdir -p "${LOGDIR}"

if [ -n "${filter}" ]; then
    # shellcheck disable=SC2086
    mapfile -t tests < <(find ${filter} -maxdepth 3 -type f -name 'integration.sh' 2>/dev/null | sort)
else
    mapfile -t tests < <(find . -maxdepth 4 -type f -name 'integration.sh' -not -path './personal/*' 2>/dev/null | sort)
fi

echo "════════════════════════════════════════════════════════════"
echo " KERNEL SHADOWS — интеграционные тесты"
echo "════════════════════════════════════════════════════════════"

if [ "${#tests[@]}" -eq 0 ]; then
    echo " Интеграционных тестов нет: все серии проходят на unit-уровне."
    echo " Такой тест объявляется файлом <серия>/tests/integration.sh"
    echo " и декларацией требований в mission.md (план §7.1)."
    echo "════════════════════════════════════════════════════════════"
    exit 0
fi

pass=0; fail=0
failed_list=()

for t in "${tests[@]}"; do
    series="$(basename "$(dirname "$(dirname "${t}")")")"
    season="$(basename "$(dirname "$(dirname "$(dirname "${t}")")")")"
    log="${LOGDIR}/${season}-integration.log"

    out="$(bash "${t}" 2>&1)"; rc=$?
    {
        printf '\n===== %s (integration) =====\n' "${series}"
        printf '%s\n' "${out}"
    } >> "${log}"

    res="$(printf '%s' "${out}" | grep -oE '[0-9]+ passed, [0-9]+ failed' | tail -1)"
    if [ "${rc}" -eq 0 ]; then
        printf '  PASS  %-32s %s\n' "${series}" "${res}"
        pass=$((pass + 1))
    else
        printf '  FAIL  %-32s %s\n' "${series}" "${res:-нет сводки}"
        fail=$((fail + 1))
        failed_list+=("${season}/${series}")
    fi
done

echo "════════════════════════════════════════════════════════════"
echo " Итог: PASS=${pass}  FAIL=${fail}"
[ "${fail}" -gt 0 ] && printf '   %s\n' "${failed_list[@]}"
echo "════════════════════════════════════════════════════════════"

[ "${fail}" -eq 0 ]
