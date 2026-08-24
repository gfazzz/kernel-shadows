#!/usr/bin/env bash
#
# s08e10 «Область действия и раскрытие» — тест конфигурации (Type B).
#
# Проверяет свойства файла правил и его применение к заявкам: default-deny,
# область из ордера, запреты на разрушительные действия, вычистку PII при
# раскрытии. Затем прогоняет targets.txt через правила и сверяет решение с
# независимо посчитанной истиной.
#
# Ожидания берутся из data/authorization.txt, а не зашиты: сузится ордер —
# сузятся и ожидания.
#
# Без root, без сети, без активных действий: всё на снимках.
#
# Выбор конфигурации: SUBJECT=... | artifacts/ | <серия>/ | solution/.

set -uo pipefail

SERIES_DIR="$(cd "$(dirname "$0")/.." && pwd)"
D="${SERIES_DIR}/data"
AUTH="${D}/authorization.txt"; TGT="${D}/targets.txt"; EF="${D}/evidence_fields.txt"

if   [ -n "${SUBJECT:-}" ];                              then C="${SUBJECT}"
elif [ -f "${SERIES_DIR}/artifacts/engagement.conf" ];   then C="${SERIES_DIR}/artifacts/engagement.conf"
elif [ -f "${SERIES_DIR}/engagement.conf" ];             then C="${SERIES_DIR}/engagement.conf"
else C="${SERIES_DIR}/solution/engagement.conf"
     echo "ℹ️  Своего engagement.conf не найдено — проверяю ЭТАЛОН (solution/)."
     echo "   Начни своё:  cp starter/engagement.conf artifacts/"; echo ""
fi

PASS=0; FAIL=0
ok(){ echo "  PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "  FAIL: $1"; FAIL=$((FAIL+1)); }

echo "════════════════════════════════════════════════════════════"
echo " s08e10 tests — правила: ${C#"$SERIES_DIR"/}"
echo "════════════════════════════════════════════════════════════"

for f in "${AUTH}" "${TGT}" "${EF}"; do [ -f "${f}" ] || { echo "  FAIL: нет ${f}"; exit 1; }; done
[ -f "${C}" ] || { echo "  FAIL: нет ${C}"; echo " Итог: 0 passed, 1 failed"; exit 1; }

body() { sed 's/#.*//' "${C}"; }
has() { body | grep -qiE "$1"; }
kv() { body | awk -v k="$1" '$1==k {print $2; exit}'; }

# IP в CIDR: целочисленно, только IPv4.
ip2n() { local IFS=.; set -- $1; echo $(( ($1<<24)+($2<<16)+($3<<8)+$4 )); }
in_cidr() { # $1 ip, $2 cidr
    local ip="$1" base="${2%/*}" bits="${2#*/}"
    local ipn basen mask
    ipn=$(ip2n "$ip"); basen=$(ip2n "$base")
    if [ "$bits" -eq 0 ]; then return 0; fi
    mask=$(( 0xffffffff << (32 - bits) & 0xffffffff ))
    [ $(( ipn & mask )) -eq $(( basen & mask )) ]
}

# scope из ордера и из конфигурации
mapfile -t AUTH_SCOPE < <(awk '{sub(/#.*/,"")} $1=="scope_cidr" {print $2}' "${AUTH}")
mapfile -t CONF_SCOPE < <(body | awk '$1=="allow_scope" {print $2}')
mapfile -t AUTH_ALLOW < <(awk '{sub(/#.*/,"")} $1=="allow_action" {print $2}' "${AUTH}")
mapfile -t AUTH_DENY  < <(awk '{sub(/#.*/,"")} $1=="deny_action" {print $2}' "${AUTH}")

echo ""
echo "── 0. Данные не выродились ──"
[ "${#AUTH_SCOPE[@]}" -ge 2 ] && ok "в ордере ${#AUTH_SCOPE[@]} разрешённые сети" || no "область ордера вырождена"
n_out=$(awk '{sub(/#.*/,"")} NF>=4 {print $2}' "${TGT}" | while read -r ip; do
          inside=no; for c in "${AUTH_SCOPE[@]}"; do in_cidr "$ip" "$c" && inside=yes; done
          [ "$inside" = no ] && echo x; done | grep -c x || true)
[ "${n_out}" -ge 1 ] && ok "среди заявок есть цели вне области (${n_out})" || no "все цели в области — нечего отсеивать"
n_deny=$(awk 'BEGIN{n=0} {sub(/#.*/,"")} NF==4 {for (i in a) if ($3==a[i]) n++} END{print n+0}' \
          a="${AUTH_DENY[*]}" "${TGT}" 2>/dev/null || echo 0)
grep -qE 'ddos|destroy|deface' "${TGT}" && ok "среди заявок есть запрещённые действия" || no "запрещённых действий в заявках нет"

echo ""
echo "── 1. Область: default-deny ──"
has '^(default|on_unlisted)[[:space:]]+deny' && ok "умолчание — запрет" \
    || no "нет строки default deny: незаявленное окажется разрешено"
# scope конфигурации совпадает с ордером и не шире.
extra=""
for c in "${CONF_SCOPE[@]}"; do printf '%s\n' "${AUTH_SCOPE[@]}" | grep -qxF "$c" || extra="$extra $c"; done
[ -z "${extra}" ] && ok "область не шире ордера" || no "в конфигурации сети вне ордера:${extra}"
missing=""
for c in "${AUTH_SCOPE[@]}"; do printf '%s\n' "${CONF_SCOPE[@]}" | grep -qxF "$c" || missing="$missing $c"; done
[ -z "${missing}" ] && ok "вся область ордера перенесена" || no "пропущены сети ордера:${missing}"

echo ""
echo "── 2. Действия ──"
for a in "${AUTH_ALLOW[@]}"; do
    has "^allow_action[[:space:]]+${a}\b" && ok "разрешено действие ${a}" || no "не разрешено ${a} из ордера"
done
for a in "${AUTH_DENY[@]}"; do
    has "^deny_action[[:space:]]+${a}\b" && ok "явно запрещено ${a}" \
        || no "${a} не запрещено явно — при default-deny пройдёт, но запрет обязан быть виден"
done

echo ""
echo "── 3. Раскрытие ──"
[ "$(kv disclosure_redact_pii)" = yes ] && ok "PII при раскрытии вычищается" \
    || no "disclosure_redact_pii не yes: персональные данные жертв уйдут в раскрытие"
has '^disclosure_channel' && ok "канал раскрытия задан (не сразу в прессу)" \
    || no "нет канала раскрытия"

echo ""
echo "── 4. Применение к заявкам ──"
# Истина: заявка разрешена ⇔ действие в allow, не в deny, и цель в области.
allowed_action() { printf '%s\n' "${AUTH_ALLOW[@]}" | grep -qxF "$1"; }
denied_action()  { printf '%s\n' "${AUTH_DENY[@]}"  | grep -qxF "$1"; }
in_scope() { local ip="$1" cc; for cc in "${AUTH_SCOPE[@]}"; do in_cidr "$ip" "$cc" && return 0; done; return 1; }

# Решение по конфигурации студента: те же allow/deny/scope, прочитанные из C.
conf_allow() { body | awk -v a="$1" '$1=="allow_action" && $2==a {f=1} END{exit !f}'; }
conf_deny()  { body | awk -v a="$1" '$1=="deny_action"  && $2==a {f=1} END{exit !f}'; }
conf_scope() { local ip="$1" cc; for cc in "${CONF_SCOPE[@]}"; do in_cidr "$ip" "$cc" && return 0; done; return 1; }

mism=0; permit_truth=0; permit_conf=0
while read -r id ip action rest; do
    case "$id" in ''|\#*) continue ;; esac
    [ -n "${action:-}" ] || continue
    t=DENY; { allowed_action "$action" && ! denied_action "$action" && in_scope "$ip"; } && t=PERMIT
    c=DENY; { conf_allow "$action" && ! conf_deny "$action" && conf_scope "$ip"; } && c=PERMIT
    [ "$t" = PERMIT ] && permit_truth=$((permit_truth+1))
    [ "$c" = PERMIT ] && permit_conf=$((permit_conf+1))
    [ "$t" = "$c" ] || { no "заявка ${id} (${ip} ${action}): правила дают ${c}, ордер — ${t}"; mism=$((mism+1)); }
done < <(sed 's/#.*//' "${TGT}")
[ "${mism}" -eq 0 ] && ok "решение по всем заявкам совпало с ордером (${permit_truth} разрешено)" \
    || no "${mism} заявок решены неверно"
# Ни одна разрушительная заявка не должна пройти.
bad_pass=0
while read -r id ip action rest; do
    case "$id" in ''|\#*) continue ;; esac
    case "$action" in ddos|destroy|deface)
        if conf_allow "$action" && ! conf_deny "$action" && conf_scope "$ip"; then bad_pass=$((bad_pass+1)); fi ;;
    esac
done < <(sed 's/#.*//' "${TGT}")
[ "${bad_pass}" -eq 0 ] && ok "ни одно разрушительное действие не прошло" \
    || no "${bad_pass} разрушительных заявок прошли правила"

echo ""
echo "── 5. Форма ──"
grep -q '^#' "${C}" && ok "комментарии сохранены" || no "комментарии удалены"

echo ""
echo "════════════════════════════════════════════════════════════"
echo " Итог: ${PASS} passed, ${FAIL} failed"
echo "════════════════════════════════════════════════════════════"
[ "${FAIL}" -eq 0 ]
