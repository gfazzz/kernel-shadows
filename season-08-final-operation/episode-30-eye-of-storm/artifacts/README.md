# Episode 30: Артефакты - Око бури

Эта директория содержит все данные для расследования Day 58.

## 📂 Структура

```
artifacts/
├── forensics/          # Криминалистические данные
│   └── aide_anomalies.txt
├── docker/             # Docker образы анализ
│   ├── compromised_images.txt
│   └── official_digests.txt
├── threat_intel/       # Разведка угроз
│   ├── suspicious_ips.txt
│   ├── ip_classification.txt
│   └── c2_server.txt
└── logs/               # Системные логи
    ├── selinux_violations.log
    └── fail2ban_banned_ips.txt
```

## 🔍 Использование

### 1. Forensics (Криминалистика)

**aide_anomalies.txt** — Результаты AIDE сканирования до очистки (Day 57).

```bash
# Серверы с аномалиями (до rebuild)
# После rebuild Day 58: все чисто
```

### 2. Docker Analysis

**compromised_images.txt** — Список скомпрометированных Docker образов.

```bash
# viktor/crypto-toolkit:latest
# Digest mismatch: a2b3c4d5... (official) vs 7f8a3d9e... (compromised)
```

**official_digests.txt** — Эталонные контрольные суммы официальных образов.

### 3. Threat Intelligence

**suspicious_ips.txt** — Все подозрительные IP из логов Day 57-58.

**ip_classification.txt** — Классификация IP адресов:
- TOR exit nodes
- VPN endpoints
- Botnet members
- Known malicious actors

**c2_server.txt** — Command & Control сервер "Новой Эры".

### 4. System Logs

**selinux_violations.log** — Нарушения политик SELinux.

**fail2ban_banned_ips.txt** — IP адреса заблокированные Fail2ban.

## 🎯 Сценарии использования

### Проверка Docker образов

```bash
# Сравнить контрольные суммы
docker images --digests > current_digests.txt
diff current_digests.txt artifacts/docker/official_digests.txt
```

### Анализ AIDE

```bash
# Проверить какие серверы были скомпрометированы
grep "server-" artifacts/forensics/aide_anomalies.txt
```

### OSINT Threat Intelligence

```bash
# Проверить классификацию IP
grep "195.123.221.47" artifacts/threat_intel/ip_classification.txt

# Найти C2 server
cat artifacts/threat_intel/c2_server.txt
```

### Анализ атак

```bash
# Топ атакующих IP
sort artifacts/logs/fail2ban_banned_ips.txt | uniq -c | sort -rn | head -10

# География атак
# Используй GeoIP database или API
```

## 📊 Статистика

**Day 57-58 Attack Summary:**
- **Total suspicious IPs:** 847
- **Docker images compromised:** 1 (viktor/crypto-toolkit)
- **Servers affected:** 47/50
- **Fail2ban bans:** 847 IP addresses
- **SELinux violations:** Variable (check logs)
- **AIDE anomalies:** 0 (after cleanup)

## ⚠️ Примечания

1. **Артефакты Day 57:** Данные собраны ДО очистки
2. **Day 58 статус:** После rebuild все чисто
3. **Mock данные:** Для локального тестирования (real attack data confidential)
4. **C2 Server:** 195.123.221.47 (St. Petersburg) — для Episode 31 counterattack

## 🔗 Связанные файлы

- **Episode 29:** `../episode-29-storm-begins/artifacts/` (Day 57 attack data)
- **Solution:** `../solution/security_audit_day58.sh` (audit script)
- **Tests:** `../tests/test.sh` (verification)

---

*"Данные не врут. Люди врут."* — Anna Kovaleva

