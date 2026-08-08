#!/usr/bin/env bash
#
# build_check_snapshot.sh — собирает снимок ansible_check_prod.txt.
#
# Снимок лежит в репозитории готовым; этот скрипт нужен, чтобы было видно,
# из чего он состоит, и чтобы его можно было пересобрать байт в байт.
#
#   bash data/build_check_snapshot.sh > data/ansible_check_prod.txt

set -euo pipefail
export LC_ALL=C

# ---- хосты боевого контура (36) ----------------------------------------------
HOSTS=()
for i in $(seq 1 27); do HOSTS+=("prod-web$(printf '%02d' "$i").shadow.io");   done
for i in $(seq 1 5);  do HOSTS+=("prod-db$(printf '%02d' "$i").shadow.io");    done
for i in $(seq 1 2);  do HOSTS+=("prod-cache$(printf '%02d' "$i").shadow.io"); done
for i in $(seq 1 2);  do HOSTS+=("prod-mon$(printf '%02d' "$i").shadow.io");   done

DOWN=("prod-db04.shadow.io" "prod-cache02.shadow.io")
NO_NTP=("prod-web25.shadow.io" "prod-web26.shadow.io" "prod-mon02.shadow.io")
DRIFT="prod-web27.shadow.io"

is_in() { local n="$1"; shift; for x in "$@"; do [ "$x" = "$n" ] && return 0; done; return 1; }
up()    { ! is_in "$1" "${DOWN[@]}"; }

hdr() { printf '\nTASK [%s] %s\n' "$1" \
        "$(printf '%*s' $((78 - ${#1} - 7)) '' | tr ' ' '*')"; }

# ---- шапка --------------------------------------------------------------------
cat <<'EOF'
# Снимок прогона в режиме проверки, боевой контур, 31 октября 2025, 16:12.
#
# Собран командой:
#   ansible-playbook -i inventory.yml site.yml --limit production --check --diff
#
# Сокращения при снятии снимка:
#   * diff печатается один раз на задачу — для остальных хостов он совпадает,
#     кроме случаев, где явно указан хост;
#   * служебные сообщения ansible (предупреждения о версии python) убраны.
# Строки ok:/changed:/skipping:/fatal: оставлены полностью, PLAY RECAP — целиком.

$ ansible-playbook -i inventory.yml site.yml --limit production --check --diff

PLAY [production] **************************************************************
EOF

# ---- 1. facts -----------------------------------------------------------------
hdr "common : facts"
for h in "${HOSTS[@]}"; do
    if up "${h}"; then printf 'ok: [%s]\n' "${h}"
    else printf 'fatal: [%s]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host %s port 22: Connection timed out", "unreachable": true}\n' "${h}" "${h}"
    fi
done

# ---- 2. packages --------------------------------------------------------------
hdr "common : packages"
for h in "${HOSTS[@]}"; do up "${h}" && printf 'ok: [%s]\n' "${h}"; done

# ---- 3. users -----------------------------------------------------------------
hdr "common : users"
for h in "${HOSTS[@]}"; do up "${h}" && printf 'ok: [%s]\n' "${h}"; done

# ---- 4. ssh-keys ---------------------------------------------------------------
hdr "common : ssh-keys"
cat <<EOF
--- before: /home/ops/.ssh/authorized_keys (${DRIFT})
+++ after: /home/ops/.ssh/authorized_keys (${DRIFT})
@@ -1,3 +1,2 @@
 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKq3rV8mJ2sQd1xTn0bYcF7wLpE4hRzS max@ops
 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH9vGtY6kPmW3sXbN1qDcJ8fRhLzA5Ue dmitry@ops
-ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP2wKdN7bQxS4mVcE8hTrY1oZjG6aLuF root@kali
EOF
for h in "${HOSTS[@]}"; do
    up "${h}" || continue
    if [ "${h}" = "${DRIFT}" ]; then printf 'changed: [%s]\n' "${h}"
    else printf 'ok: [%s]\n' "${h}"; fi
done

# ---- 5. sudoers ----------------------------------------------------------------
hdr "common : sudoers"
for h in "${HOSTS[@]}"; do up "${h}" && printf 'ok: [%s]\n' "${h}"; done

# ---- 6. ntp --------------------------------------------------------------------
hdr "common : ntp"
cat <<'EOF'
--- before: /etc/systemd/timesyncd.conf
+++ after: /etc/systemd/timesyncd.conf
@@ -1,3 +1,3 @@
 [Time]
-NTP=ntp.ubuntu.com
+NTP=0.nl.pool.ntp.org 1.nl.pool.ntp.org
EOF
for h in "${HOSTS[@]}"; do
    up "${h}" || continue
    if is_in "${h}" "${NO_NTP[@]}"; then printf 'ok: [%s]\n' "${h}"
    else printf 'changed: [%s]\n' "${h}"; fi
done

# ---- 7. sshd -------------------------------------------------------------------
hdr "common : sshd"
cat <<EOF
--- before: /etc/ssh/sshd_config (${DRIFT})
+++ after: /etc/ssh/sshd_config (${DRIFT})
@@ -32,7 +32,7 @@
 #LoginGraceTime 2m
-PermitRootLogin yes
+PermitRootLogin no
 StrictModes yes
EOF
for h in "${HOSTS[@]}"; do
    up "${h}" || continue
    if [ "${h}" = "${DRIFT}" ]; then printf 'changed: [%s]\n' "${h}"
    else printf 'ok: [%s]\n' "${h}"; fi
done

# ---- 8. firewall ----------------------------------------------------------------
hdr "common : firewall"
for h in "${HOSTS[@]}"; do up "${h}" && printf 'ok: [%s]\n' "${h}"; done

# ---- 9. unit --------------------------------------------------------------------
hdr "monitor : unit"
cat <<'EOF'
--- before: /etc/systemd/system/ops-monitor.service (prod-mon01.shadow.io)
+++ after: /etc/systemd/system/ops-monitor.service (prod-mon01.shadow.io)
@@ -8,4 +8,5 @@
 Restart=on-failure
+RestartSec=5s
 User=ops
EOF
for h in "${HOSTS[@]}"; do
    up "${h}" || continue
    if [ "${h}" = "prod-mon01.shadow.io" ]; then printf 'changed: [%s]\n' "${h}"
    else printf 'ok: [%s]\n' "${h}"; fi
done

# ---- 10. timer -------------------------------------------------------------------
hdr "monitor : timer"
for h in "${HOSTS[@]}"; do up "${h}" && printf 'ok: [%s]\n' "${h}"; done

# ---- 11. logrotate ---------------------------------------------------------------
hdr "common : logrotate"
cat <<'EOF'
--- before: /etc/logrotate.d/ops (prod-db02.shadow.io)
+++ after: /etc/logrotate.d/ops (prod-db02.shadow.io)
@@ -1,5 +1,5 @@
 /var/log/ops/*.log {
-    rotate 4
+    rotate 14
     daily
EOF
for h in "${HOSTS[@]}"; do
    up "${h}" || continue
    if [ "${h}" = "prod-db02.shadow.io" ]; then printf 'changed: [%s]\n' "${h}"
    else printf 'ok: [%s]\n' "${h}"; fi
done

# ---- 12. ssl-perms ----------------------------------------------------------------
hdr "common : ssl-perms"
cat <<EOF
--- before: /etc/ssl/private (${DRIFT})
+++ after: /etc/ssl/private (${DRIFT})
@@ -1,4 +1,4 @@
 {
-    "mode": "0755",
+    "mode": "0700",
     "owner": "root",
     "path": "/etc/ssl/private"
EOF
for h in "${HOSTS[@]}"; do
    up "${h}" || continue
    if [ "${h}" = "${DRIFT}" ]; then printf 'changed: [%s]\n' "${h}"
    else printf 'ok: [%s]\n' "${h}"; fi
done

# ---- 13-14. аудит: молчит в режиме проверки ----------------------------------------
hdr "audit : checksums"
for h in "${HOSTS[@]}"; do up "${h}" && printf 'skipping: [%s]\n' "${h}"; done

hdr "audit : cert-expiry"
for h in "${HOSTS[@]}"; do up "${h}" && printf 'skipping: [%s]\n' "${h}"; done

# ---- PLAY RECAP ---------------------------------------------------------------------
printf '\nPLAY RECAP %s\n' "$(printf '%*s' 68 '' | tr ' ' '*')"
for h in "${HOSTS[@]}"; do
    if ! up "${h}"; then
        printf '%-24s : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0\n' "${h}"
        continue
    fi
    ch=0
    is_in "${h}" "${NO_NTP[@]}" || ch=$((ch+1))
    [ "${h}" = "${DRIFT}" ] && ch=$((ch+3))
    [ "${h}" = "prod-mon01.shadow.io" ] && ch=$((ch+1))
    [ "${h}" = "prod-db02.shadow.io" ]  && ch=$((ch+1))
    printf '%-24s : ok=%-4s changed=%-4s unreachable=0    failed=0    skipped=2    rescued=0    ignored=0\n' \
           "${h}" "$((12 - ch))" "${ch}"
done

# ---- фрагмент playbook --------------------------------------------------------------
cat <<'EOF'

# Для справки — те две задачи, которые в выводе выше пропущены на всех хостах:

$ sed -n '96,110p' site.yml

    - name: checksums
      ansible.builtin.command: debsums -c
      register: sums
      changed_when: sums.rc != 0

    - name: cert-expiry
      ansible.builtin.command: openssl x509 -checkend 604800 -noout -in /etc/ssl/certs/ops.crt
      register: cert
      changed_when: false
      failed_when: cert.rc != 0

    - name: logrotate
      ansible.builtin.copy:
        src: logrotate-ops
        dest: /etc/logrotate.d/ops
EOF
