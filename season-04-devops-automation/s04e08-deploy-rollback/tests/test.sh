#!/usr/bin/env bash
#
# s04e08 «Пять минут» (капстоун Episode 15) — тест скрипта (Type A).
#
# Мок-first: ssh, curl, docker и sleep подменяются заглушками в PATH.
# Ни одного соединения, ни одного контейнера, ни одной секунды ожидания —
# заглушки записывают вызовы, и предметом проверки становится то, ЧТО
# скрипт собирался сделать и в каком порядке.
#
# Никаких ожидаемых значений в тесте не зашито: цель отката вычисляется
# из журнала, а последний сценарий подставляет журнал с другими версиями,
# другим хостом и другим образом — ответы обязаны измениться вместе с ним.
#
# Без root, без сети, без docker.
#
# Выбор скрипта: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DATA="${SERIES_DIR}/data/releases_prod.log"
STARTER="${SERIES_DIR}/starter/rollback.sh"

if   [ -n "${SUBJECT:-}" ];                            then RB="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/rollback.sh" ];     then RB="${SERIES_DIR}/artifacts/rollback.sh"
elif [ -f "${SERIES_DIR}/rollback.sh" ];               then RB="${SERIES_DIR}/rollback.sh"
else RB="${SERIES_DIR}/solution/rollback.sh"
     echo "ℹ️  Своего rollback.sh не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/rollback.sh artifacts/"; echo ""
fi
[ -f "${RB}" ] || { echo "  FAIL: rollback.sh не найден"; exit 1; }
RB="$(cd "$(dirname "${RB}")" && pwd)/$(basename "${RB}")"

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s04e08 tests — скрипт: ${RB#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

# ---- полигон -----------------------------------------------------------------
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
BIN="${TMP}/bin"; mkdir -p "${BIN}"
export CALLS="${TMP}/calls.log"
export HEALTH_STATE="${TMP}/health"
: > "${CALLS}"; echo ok > "${HEALTH_STATE}"

cat > "${BIN}/ssh" <<'EOF'
#!/usr/bin/env bash
printf 'ssh %s\n' "$*" >> "${CALLS}"
exit 0
EOF
cat > "${BIN}/curl" <<'EOF'
#!/usr/bin/env bash
printf 'curl %s\n' "$*" >> "${CALLS}"
[ "$(cat "${HEALTH_STATE}")" = ok ] && exit 0
exit 22
EOF
cat > "${BIN}/docker" <<'EOF'
#!/usr/bin/env bash
printf 'docker %s\n' "$*" >> "${CALLS}"
exit 0
EOF
cat > "${BIN}/sleep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${BIN}"/*
PATH="${BIN}:${PATH}"; export PATH

OUT=""; RC=0
run() { : > "${CALLS}"; OUT="$(bash "${RB}" "$@" 2>&1)"; RC=$?; }
sshcalls() { grep '^ssh ' "${CALLS}" 2>/dev/null || true; }
journal_of() { cp "$1" "${TMP}/j.log"; echo "${TMP}/j.log"; }

# ---- 0. статика --------------------------------------------------------------
if bash -n "${RB}" 2>/dev/null; then ok "синтаксис скрипта корректен"
else no "синтаксис: $(bash -n "${RB}" 2>&1 | head -1)"; fi
if grep -qE '^set -[a-z]*e[a-z]*u|^set -euo' "${RB}"; then
    ok "включены строгие режимы оболочки (set -eu)"
else
    no "нет 'set -euo pipefail': необъявленная переменная тихо станет пустой строкой"
fi

# ---- 1. основной сценарий: журнал боевого контура -----------------------------
J="$(journal_of "${DATA}")"
BEFORE="$(cat "${J}")"
run --journal "${J}" --host prod.shadow.io --image registry.shadow.io/ops/collector

if [ "${RC}" -eq 0 ]; then ok "откат по журналу инцидента завершается успешно"
else no "откат завершился с кодом ${RC}: ${OUT}"; fi

if sshcalls | grep -q ':3f8ba110'; then
    ok "цель отката — 3f8ba110: последняя версия, чьё последнее состояние healthy"
else
    no "цель выбрана неверно (ожидалась 3f8ba110): $(sshcalls | head -1)"
fi
if sshcalls | grep -q 'b0c4d5e6'; then
    no "откат на b0c4d5e6 — это строка перед текущей, но она failed: версия в бой не пошла"
else
    ok "версия со статусом failed целью не выбрана"
fi
if sshcalls | grep -q ':latest'; then
    no "выкат тегом latest: у версии должно быть точное имя, иначе откат ничего не значит"
else
    ok "выкат идёт точным тегом версии"
fi
if printf '%s' "${OUT}" | grep -qi 'отказ'; then
    no "скрипт отказал из-за миграции 7c1d9e02, но она применена ДО цели и откатом не затрагивается"
else
    ok "миграция раньше цели откату не мешает"
fi
ssh_n="$(grep -n '^ssh ' "${CALLS}" | head -1 | cut -d: -f1)"
curl_n="$(grep -n '^curl ' "${CALLS}" | head -1 | cut -d: -f1)"
if [ -n "${curl_n}" ] && [ -n "${ssh_n}" ] && [ "${ssh_n}" -lt "${curl_n}" ]; then
    ok "готовность проверяется после выката, а не вместо него"
elif [ -z "${curl_n}" ]; then
    no "проверки готовности нет: «команда выполнена» не значит «служба отвечает»"
else
    no "проверка готовности выполнена до выката"
fi
if grep -q '^docker ' "${CALLS}"; then
    no "скрипт запускает docker на своей машине: откат делается на хосте из --host, по ssh"
else
    ok "локальный docker не вызывается — вся работа идёт по ssh"
fi

AFTER="$(cat "${J}")"
if [ "${BEFORE}" = "${AFTER}" ]; then
    no "журнал не дописан: следующий откат снова выберет ту же версию"
else
    ok "журнал дописан"
fi
if grep -vE '^[[:space:]]*(#|$)' "${J}" | tail -1 | grep -q '3f8ba110.*healthy'; then
    ok "восстановленная версия записана как healthy — это она теперь в бою"
else
    no "последняя запись журнала не говорит, что в бою 3f8ba110: $(grep -vE '^[[:space:]]*(#|$)' "${J}" | tail -1)"
fi
if [ "$(grep -vE '^[[:space:]]*(#|$)' "${J}" | awk '$2=="a1b2c3d4" {s=$3} END{print s}')" = failed ]; then
    ok "снятая версия помечена failed — повторный откат её больше не выберет"
else
    no "a1b2c3d4 осталась в журнале здоровой: следующий откат вернёт в бой сломанное"
fi

# ---- 2. повторный откат: глубже, а не по кругу --------------------------------
run --journal "${J}" --host prod.shadow.io --image registry.shadow.io/ops/collector
if sshcalls | grep -q ':7c1d9e02'; then
    ok "повторный откат уходит глубже (7c1d9e02), а не возвращает снятую версию"
elif sshcalls | grep -q ':a1b2c3d4'; then
    no "повторный откат вернул в бой a1b2c3d4 — ту самую, из-за которой всё началось"
else
    no "повторный откат выбрал не ту версию: $(sshcalls | head -1)"
fi

# ---- 3. миграция после цели: отказ, ничего не тронуто -------------------------
cat > "${TMP}/mig.log" <<'EOF'
# время               версия    состояние миграция
2025-11-01T10:00:00Z  aa110000  healthy   no
2025-11-01T12:00:00Z  bb220000  healthy   yes      миграция: orders.split
EOF
MB="$(cat "${TMP}/mig.log")"
run --journal "${TMP}/mig.log" --host prod.shadow.io --image reg/x
if [ "${RC}" -eq 3 ]; then
    ok "откат через миграцию схемы: отказ с кодом 3"
else
    no "миграция между целью и текущей версией не остановила откат (код ${RC})"
fi
if [ -z "$(sshcalls)" ]; then ok "при отказе по миграции ничего не выкатывалось"
else no "при отказе по миграции скрипт всё-таки сходил на хост"; fi
if [ "${MB}" = "$(cat "${TMP}/mig.log")" ]; then ok "при отказе журнал не изменён"
else no "журнал изменён, хотя откат не состоялся"; fi
run --journal "${TMP}/mig.log" --host prod.shadow.io --image reg/x --force
if [ "${RC}" -eq 0 ] && sshcalls | grep -q ':aa110000'; then
    ok "явный --force разрешает откат через миграцию"
else
    no "--force не позволил откатиться через миграцию (код ${RC})"
fi

# ---- 4. служба не поднялась ---------------------------------------------------
echo bad > "${HEALTH_STATE}"
J2="$(journal_of "${DATA}")"
run --journal "${J2}" --host prod.shadow.io --image registry.shadow.io/ops/collector
if [ "${RC}" -ne 0 ]; then
    ok "готовность не подтвердилась — код возврата ненулевой"
else
    no "служба не отвечает, а скрипт отчитался об успехе: это и есть зелёная галочка ни о чём"
fi
if grep -vE '^[[:space:]]*(#|$)' "${J2}" | tail -1 | grep -q 'failed'; then
    ok "неподтверждённая версия записана в журнал как failed"
else
    no "журнал говорит, что всё хорошо, хотя служба не ответила"
fi
echo ok > "${HEALTH_STATE}"

# ---- 5. --dry-run -------------------------------------------------------------
J3="$(journal_of "${DATA}")"
DB="$(cat "${J3}")"
run --journal "${J3}" --host prod.shadow.io --image registry.shadow.io/ops/collector --dry-run
if [ "${RC}" -eq 0 ] && [ -z "$(sshcalls)" ]; then
    ok "--dry-run ничего не выкатывает"
else
    no "--dry-run сходил на хост (код ${RC})"
fi
if [ "${DB}" = "$(cat "${J3}")" ]; then ok "--dry-run не трогает журнал"
else no "--dry-run дописал журнал"; fi
if printf '%s' "${OUT}" | grep -q '3f8ba110'; then
    ok "--dry-run называет версию, на которую собирается откатиться"
else
    no "--dry-run не показал план: непонятно, что именно произойдёт"
fi

# ---- 6. откатываться некуда ---------------------------------------------------
printf '2025-11-02T09:00:00Z  only0001  healthy  no\n' > "${TMP}/one.log"
run --journal "${TMP}/one.log" --host h --image i
if [ "${RC}" -eq 2 ] && [ -z "$(sshcalls)" ]; then
    ok "единственная версия в журнале: отказ с кодом 2, ничего не тронуто"
else
    no "при отсутствии цели отката скрипт не отказался внятно (код ${RC})"
fi

# ---- 7. явная цель ------------------------------------------------------------
cat > "${TMP}/to.log" <<'EOF'
2025-11-03T08:00:00Z  v1aaaaaa  healthy  no
2025-11-03T09:00:00Z  v2bbbbbb  healthy  no
2025-11-03T10:00:00Z  v3cccccc  failed   no
2025-11-03T11:00:00Z  v4dddddd  healthy  no
EOF
run --journal "${TMP}/to.log" --host h --image reg/app --to v1aaaaaa
if [ "${RC}" -eq 0 ] && sshcalls | grep -q ':v1aaaaaa'; then
    ok "--to выкатывает указанную версию"
else
    no "--to не сработал (код ${RC}): $(sshcalls | head -1)"
fi
run --journal "${TMP}/to.log" --host h --image reg/app --to deadbeef
if [ "${RC}" -ne 0 ] && [ -z "$(sshcalls)" ]; then
    ok "--to на версию, которой нет в журнале: отказ"
else
    no "скрипт согласился откатиться на версию, которой никогда не выкатывали"
fi
run --journal "${TMP}/to.log" --host h --image reg/app --to v3cccccc
if [ "${RC}" -ne 0 ] && [ -z "$(sshcalls)" ]; then
    ok "--to на версию с последним состоянием failed: отказ"
else
    no "скрипт согласился вернуть в бой версию, которая уже снималась"
fi

# ---- 8. журнал в другом форматировании ----------------------------------------
printf '\n#  комментарий\n\n2025-11-04T08:00:00Z\tk1aaaaaa\thealthy\tno\n\n   2025-11-04T09:00:00Z   k2bbbbbb   healthy   no\n' > "${TMP}/fmt.log"
run --journal "${TMP}/fmt.log" --host h --image reg/app
if [ "${RC}" -eq 0 ] && sshcalls | grep -q ':k1aaaaaa'; then
    ok "пустые строки, комментарии и табуляции в журнале разбираются верно"
else
    no "форматирование журнала сбило разбор (код ${RC}): $(sshcalls | head -1)"
fi

# ---- 9. ничего не зашито ------------------------------------------------------
cat > "${TMP}/other.log" <<'EOF'
2026-02-01T10:00:00Z  alpha001  healthy  no
2026-02-01T11:00:00Z  beta0002  failed   no
2026-02-01T12:00:00Z  gamma003  healthy  no
EOF
run --journal "${TMP}/other.log" --host deploy.example.net --image reg.example.net/team/app
if sshcalls | grep -q 'reg.example.net/team/app:alpha001'; then
    ok "на другом журнале, хосте и образе ответ пересчитывается: reg.example.net/team/app:alpha001"
else
    no "подставлен другой журнал — цель должна была стать alpha001: $(sshcalls | head -1)"
fi
if sshcalls | grep -q 'deploy.example.net'; then
    ok "хост берётся из --host, а не из текста скрипта"
else
    no "в вызове ssh нет хоста deploy.example.net"
fi
if printf '%s' "${OUT}" | grep -qE '3f8ba110|a1b2c3d4|prod\.shadow\.io'; then
    no "в выводе всплыли значения из другого журнала — что-то зашито в скрипт"
else
    ok "значений из журнала инцидента в выводе нет"
fi

# ---- 10. самопроверка ---------------------------------------------------------
if [ -f "${STARTER}" ] && [ "${RB}" != "${STARTER}" ]; then
    J4="$(journal_of "${DATA}")"
    : > "${CALLS}"
    bash "${STARTER}" --journal "${J4}" --host h --image i >/dev/null 2>&1
    if [ -z "$(sshcalls)" ]; then
        ok "самопроверка: стартер задачу не решает — проверять есть что"
    else
        no "самопроверка: стартер уже выкатывает — задание потеряло смысл"
    fi
else
    ok "самопроверка: пропущена (проверяется сам стартер)"
fi

echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
