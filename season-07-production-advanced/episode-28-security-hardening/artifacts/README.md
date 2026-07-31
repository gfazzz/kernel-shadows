# 📦 ARTIFACTS - EPISODE 28

Вспомогательные материалы для Episode 28: Security Hardening.

---

## 📋 Содержимое

### 1. **SELINUX_QUICKSTART.md**
Краткое руководство по SELinux (contexts, policies, troubleshooting).

### 2. **AUDITD_RULES.md**
Готовые audit rules для различных сценариев.

### 3. **FAIL2BAN_JAILS.md**
Конфигурации fail2ban jails для различных сервисов.

### 4. **SSH_HARDENING_CHECKLIST.md**
Чек-лист по укреплению SSH.

### 5. **SYSCTL_SECURITY.conf**
Готовый sysctl конфиг для security hardening.

---

## 🚀 Быстрая справка

### SELinux

```bash
# Проверить режим
getenforce

# Переключить в enforcing
sudo setenforce 1

# Посмотреть context
ls -Z /var/www/html/

# Восстановить context
sudo restorecon -Rv /var/www/html/

# Проверить denials
sudo ausearch -m avc -ts recent
```

### auditd

```bash
# Статус
sudo systemctl status auditd

# Загрузить rules
sudo augenrules --load

# Поиск в audit log
sudo ausearch -k passwd_changes

# Отчёт
sudo aureport --summary
```

### fail2ban

```bash
# Статус
sudo fail2ban-client status

# Статус jail
sudo fail2ban-client status sshd

# Разбанить IP
sudo fail2ban-client set sshd unbanip 1.2.3.4

# Логи
sudo tail -f /var/log/fail2ban.log
```

### SSH Hardening

```bash
# Тест конфигурации
sudo sshd -t

# Перезапустить после изменений
sudo systemctl restart sshd

# Проверить активные сессии
who

# Логи аутентификации
sudo tail -f /var/log/auth.log
```

---

## 📚 Дополнительные ресурсы

- **SELinux User Guide:** https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/using_selinux/
- **Linux Audit Documentation:** https://github.com/linux-audit/audit-documentation
- **fail2ban Manual:** https://www.fail2ban.org/wiki/index.php/MANUAL_0_8
- **CIS Benchmarks:** https://www.cisecurity.org/cis-benchmarks/

---

**LILITH:** "Security чек-листы сохранят тебе часы настройки. Но НЕ копируй слепо — адаптируй под свою систему. **Defense in depth = множество слоёв, каждый настроен правильно.**"

