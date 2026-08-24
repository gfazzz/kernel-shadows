#!/usr/bin/env bash
# Строит дерево-снимок. $1 — корень, $2 — dirty|clean.
set -eu
R="$1"; MODE="${2:-clean}"
mkdir -p "$R"/etc/{cron.d,systemd/system,profile.d,sudoers.d} \
         "$R"/var/spool/cron/crontabs "$R"/root/.ssh "$R"/home/anna/.ssh "$R"/home/deploy/.ssh

cat > "$R/etc/crontab" <<'EOF'
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
17 *	* * *	root	cd / && run-parts --report /etc/cron.hourly
25 6	* * *	root	test -x /usr/sbin/anacron || run-parts --report /etc/cron.daily
EOF
cat > "$R/etc/cron.d/logrotate-aurora" <<'EOF'
# Ротация журналов aurora-api. Поставлено ролью ansible 49-го дня.
30 3 * * * root /usr/sbin/logrotate /etc/logrotate.d/aurora
EOF
cat > "$R/var/spool/cron/crontabs/deploy" <<'EOF'
# Личное расписание учётной записи deploy.
*/10 * * * * /opt/aurora/bin/health-report.sh
EOF
cat > "$R/etc/systemd/system/aurora-api.service" <<'EOF'
[Unit]
Description=aurora-api
After=network-online.target

[Service]
ExecStart=/opt/aurora/bin/aurora-api --config /etc/aurora/api.yml
User=aurora
NoNewPrivileges=yes

[Install]
WantedBy=multi-user.target
EOF
cat > "$R/etc/systemd/system/node-exporter.service" <<'EOF'
[Unit]
Description=node_exporter

[Service]
ExecStart=/usr/local/bin/node_exporter
User=nodeexp

[Install]
WantedBy=multi-user.target
EOF
cat > "$R/etc/profile.d/aurora-env.sh" <<'EOF'
export AURORA_ENV=production
export PATH="$PATH:/opt/aurora/bin"
EOF
cat > "$R/root/.bashrc" <<'EOF'
# ~/.bashrc для root
export PS1='\[\e[31m\]\h:\w# \[\e[0m\]'
alias ll='ls -alF'
EOF
cat > "$R/root/.ssh/authorized_keys" <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB1yQvVn4Zk2mQ7pRxTf0aLd8sWc3EjHnKpMvXuYzAbC ansible@shadow-iac
EOF
cat > "$R/home/anna/.ssh/authorized_keys" <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC7dNqPwEr5tYu9iOp2aSdFgHjKlZxCvBnM3QwErTyUi anna@zurich-laptop
EOF
cat > "$R/home/deploy/.ssh/authorized_keys" <<'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDq4WsXeCrVtBgNhYmJkLp0oI9uY7tR6eW5qZ3xC1vAs deploy@ci-runner
EOF
cat > "$R/etc/sudoers.d/aurora-ops" <<'EOF'
%ops ALL=(ALL) /usr/bin/systemctl restart aurora-api
EOF
cat > "$R/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
aurora:x:997:997:aurora-api:/opt/aurora:/usr/sbin/nologin
nodeexp:x:996:996:node_exporter:/nonexistent:/usr/sbin/nologin
anna:x:1000:1000:Anna Kovaleva:/home/anna:/bin/bash
deploy:x:1001:1001:CI deploy:/home/deploy:/bin/bash
EOF
cat > "$R/etc/rc.local" <<'EOF'
#!/bin/sh -e
# rc.local — оставлен образом, ничего не делает
exit 0
EOF

if [ "$MODE" = dirty ]; then
    # 1. расписание, которого не было в эталоне
    cat > "$R/etc/cron.d/apt-daily-upgrade" <<'EOF'
*/7 * * * * root /usr/lib/apt/apt.systemd.daily.sh >/dev/null 2>&1
EOF
    # 2. юнит, которого не было в эталоне
    cat > "$R/etc/systemd/system/dbus-broker-relay.service" <<'EOF'
[Unit]
Description=D-Bus Broker Relay

[Service]
ExecStart=/usr/lib/dbus-1.0/dbus-relay --daemon
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    # 3. лишний ключ дописан в существующий файл
    cat >> "$R/root/.ssh/authorized_keys" <<'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9xKmPvTr3sWqZnBdLfGh2YuIoPaSdXcVbNm4Qw backup@localhost
EOF
    # 4. учётная запись с нулевым uid и человеческим именем
    sed -i.bak 's|^nobody:.*|&\nsysbackup:x:0:0:System Backup:/var/backups:/bin/bash|' "$R/etc/passwd" && rm -f "$R/etc/passwd.bak"
    # 5. библиотека в каждый процесс
    echo "/usr/lib/x86_64-linux-gnu/libnss_files2.so" > "$R/etc/ld.so.preload"
    # 6. строка в rc.local
    sed -i.bak 's|^exit 0|/usr/lib/dbus-1.0/dbus-relay --daemon \&\nexit 0|' "$R/etc/rc.local" && rm -f "$R/etc/rc.local.bak"
    # 7. скрипт, выполняемый при каждом входе
    cat > "$R/etc/profile.d/00-locale-fix.sh" <<'EOF'
[ -x /usr/lib/dbus-1.0/dbus-relay ] && (/usr/lib/dbus-1.0/dbus-relay --once &) 2>/dev/null
EOF
    # 8. повышение прав без пароля
    echo "deploy ALL=(ALL) NOPASSWD: ALL" > "$R/etc/sudoers.d/90-deploy-ci"
fi
